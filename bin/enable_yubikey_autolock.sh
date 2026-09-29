#!/usr/bin/env bash
# ==============================================================================
# Script d'activation du verrouillage automatique de session (GNOME)
# lors du retrait de la YubiKey
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Ce script doit être exécuté avec les privilèges root (sudo).${NC}" >&2
    echo -e "Exécutez : ${YELLOW}sudo bash $0${NC}"
    exit 1
fi

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  Activation du verrouillage automatique au retrait de la YubiKey     ${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

# 1. Création du script de verrouillage
LOCK_SCRIPT="/usr/local/bin/yubikey-lock.sh"
echo -e "${BLUE}[1/4] Installation du script de verrouillage dans $LOCK_SCRIPT...${NC}"

cat <<'EOF' > "$LOCK_SCRIPT"
#!/usr/bin/env bash
# Verrouillage universel lors du retrait de la YubiKey

# 1. Méthode standard systemd logind
/usr/bin/loginctl lock-sessions 2>/dev/null || true

# 2. Méthode directe GNOME Shell via le bus D-Bus utilisateur (Wayland & X11)
for uid in $(loginctl list-users --no-legend 2>/dev/null | awk '{print $1}'); do
    if [ -S "/run/user/$uid/bus" ]; then
        user=$(id -nu "$uid")
        sudo -u "$user" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            /usr/bin/dbus-send --type=method_call --dest=org.gnome.ScreenSaver \
            /org/gnome/ScreenSaver org.gnome.ScreenSaver.Lock 2>/dev/null || true
    fi
done
EOF

chmod 755 "$LOCK_SCRIPT"
chown root:root "$LOCK_SCRIPT"
echo -e "${GREEN}✓ Script $LOCK_SCRIPT créé${NC}"

# 2. Création du service systemd
SERVICE_FILE="/etc/systemd/system/yubikey-lock.service"
echo -e "${BLUE}[2/4] Création du service systemd $SERVICE_FILE...${NC}"

cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Verrouiller l'écran lors du retrait de la YubiKey

[Service]
Type=oneshot
ExecStart=$LOCK_SCRIPT
EOF

chmod 644 "$SERVICE_FILE"
systemctl daemon-reload
echo -e "${GREEN}✓ Service systemd créé et rechargé${NC}"

# 3. Création de la règle udev
UDEV_RULE_FILE="/etc/udev/rules.d/80-yubikey-lock.rules"
echo -e "${BLUE}[3/4] Création de la règle udev $UDEV_RULE_FILE...${NC}"

cat <<'EOF' > "$UDEV_RULE_FILE"
# Verrouillage automatique de session lors du retrait d'une clé YubiKey (Vendor 1050)
ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="1050/*", RUN+="/usr/bin/systemctl --no-block start yubikey-lock.service"
EOF

chmod 644 "$UDEV_RULE_FILE"
udevadm control --reload-rules
echo -e "${GREEN}✓ Règle udev créée et règles rechargées${NC}"

# 4. Confirmation
echo ""
echo -e "${BLUE}[4/4] Activation terminée !${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo -e "Le verrouillage automatique est maintenant actif."
echo -e "👉 ${YELLOW}Test :${NC} Débranchez votre YubiKey de son port USB."
echo -e "Votre session GNOME se verrouillera instantanément !"
echo -e "${GREEN}======================================================================${NC}"
