#!/usr/bin/env bash
# ==============================================================================
# Script de configuration YubiKey (FIDO2 / U2F) pour Ubuntu
# Mode : Clé OU Mot de passe (1FA alternatif / repli automatique)
# Périmètre : Sudo, GDM (connexion graphique), Déverrouillage d'écran & Polkit
# ==============================================================================

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Ce script doit être exécuté avec les privilèges root (sudo).${NC}" >&2
    echo -e "Exécutez : ${YELLOW}sudo bash $0${NC}"
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}   Configuration de l'authentification par YubiKey     ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Utilisateur cible : ${GREEN}$TARGET_USER${NC}"
echo ""

# 1. Vérification / Installation des paquets requis
echo -e "${BLUE}[1/5] Vérification et installation des paquets nécessaires...${NC}"
MISSING_PKGS=()
dpkg -s libpam-u2f &>/dev/null || MISSING_PKGS+=(libpam-u2f)
dpkg -s pamu2fcfg &>/dev/null || MISSING_PKGS+=(pamu2fcfg)

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "Installation de : ${MISSING_PKGS[*]}..."
    apt-get update -qq
    apt-get install -y "${MISSING_PKGS[@]}"
else
    echo -e "${GREEN}Paquets libpam-u2f et pamu2fcfg déjà installés.${NC}"
fi

# 2. Enregistrement de la YubiKey
echo ""
echo -e "${BLUE}[2/5] Enregistrement de la YubiKey pour $TARGET_USER...${NC}"
MAPPINGS_FILE="/etc/u2f_mappings"

if [ -f "$MAPPINGS_FILE" ] && grep -q "^${TARGET_USER}:" "$MAPPINGS_FILE"; then
    echo -e "${YELLOW}Une clé est déjà enregistrée pour $TARGET_USER dans $MAPPINGS_FILE.${NC}"
    read -r -p "Voulez-vous ajouter une NOUVELLE clé (clé de secours) ? [o/N] " ADD_KEY
    if [[ "$ADD_KEY" =~ ^[oOyY] ]]; then
        echo -e "${YELLOW}>>> Branchez votre deuxième YubiKey et TOUCHEZ-LA dès qu'elle clignote... <<<${NC}"
        NEW_KEY=$(pamu2fcfg -n -u "$TARGET_USER")
        if [ -n "$NEW_KEY" ]; then
            sed -i "/^${TARGET_USER}:/ s/$/${NEW_KEY}/" "$MAPPINGS_FILE"
            echo -e "${GREEN}Clé supplémentaire ajoutée avec succès !${NC}"
        else
            echo -e "${RED}Erreur : aucune donnée reçue de la YubiKey.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}>>> Assurez-vous que votre YubiKey est branchée. <<<${NC}"
    echo -e "${YELLOW}>>> TOUCHEZ le contact métallique / bouton dès qu'il clignote... <<<${NC}"
    
    KEY_DATA=$(pamu2fcfg -u "$TARGET_USER")
    
    if [ -z "$KEY_DATA" ]; then
        echo -e "${RED}[!] Erreur : Impossible d'enregistrer la YubiKey.${NC}" >&2
        exit 1
    fi
    
    echo "$KEY_DATA" > "$MAPPINGS_FILE"
    chmod 644 "$MAPPINGS_FILE"
    chown root:root "$MAPPINGS_FILE"
    echo -e "${GREEN}YubiKey enregistrée avec succès dans $MAPPINGS_FILE !${NC}"
fi

# 3. Sauvegarde des configurations PAM actuelles
echo ""
echo -e "${BLUE}[3/5] Sauvegarde des fichiers PAM d'origine...${NC}"
for file in sudo sudo-i gdm-password; do
    if [ -f "/etc/pam.d/$file" ] && [ ! -f "/etc/pam.d/${file}.bak.yubikey" ]; then
        cp "/etc/pam.d/$file" "/etc/pam.d/${file}.bak.yubikey"
        echo -e "Sauvegarde créée : ${GREEN}/etc/pam.d/${file}.bak.yubikey${NC}"
    fi
done

# 4. Modification sécurisée des fichiers PAM
echo ""
echo -e "${BLUE}[4/5] Application de la configuration PAM (mode suffisant / fallback mot de passe)...${NC}"

PAM_RULE="auth       sufficient   pam_u2f.so authfile=/etc/u2f_mappings cue nouserok"

# Config pour sudo
if ! grep -q "pam_u2f.so" /etc/pam.d/sudo; then
    sed -i "/@include common-auth/i $PAM_RULE" /etc/pam.d/sudo
    echo -e "${GREEN}✓ /etc/pam.d/sudo configuré${NC}"
else
    echo -e "${YELLOW}- /etc/pam.d/sudo contenait déjà pam_u2f.so${NC}"
fi

# Config pour sudo-i
if [ -f /etc/pam.d/sudo-i ]; then
    if ! grep -q "pam_u2f.so" /etc/pam.d/sudo-i; then
        sed -i "/@include common-auth/i $PAM_RULE" /etc/pam.d/sudo-i
        echo -e "${GREEN}✓ /etc/pam.d/sudo-i configuré${NC}"
    else
        echo -e "${YELLOW}- /etc/pam.d/sudo-i contenait déjà pam_u2f.so${NC}"
    fi
fi

# Config pour GDM (connexion graphique et écran de verrouillage)
if [ -f /etc/pam.d/gdm-password ]; then
    if ! grep -q "pam_u2f.so" /etc/pam.d/gdm-password; then
        sed -i "/@include common-auth/i $PAM_RULE" /etc/pam.d/gdm-password
        echo -e "${GREEN}✓ /etc/pam.d/gdm-password configuré${NC}"
    else
        echo -e "${YELLOW}- /etc/pam.d/gdm-password contenait déjà pam_u2f.so${NC}"
    fi
fi

# Config optionnelle pour polkit (boîtes de dialogue graphiques administrateur)
if [ ! -f /etc/pam.d/polkit-1 ]; then
    cat <<EOF > /etc/pam.d/polkit-1
#%PAM-1.0
$PAM_RULE
@include common-auth
@include common-account
@include common-password
@include common-session
EOF
    chmod 644 /etc/pam.d/polkit-1
    echo -e "${GREEN}✓ /etc/pam.d/polkit-1 créé pour les autorisations graphiques${NC}"
fi

# 5. Vérification
echo ""
echo -e "${BLUE}[5/5] Configuration terminée avec succès !${NC}"
echo -e "${GREEN}==============================================================${NC}"
echo -e "${GREEN}La YubiKey est désormais configurée en mode SUFFISANT :${NC}"
echo -e " - ${YELLOW}Si la YubiKey est branchée :${NC} touchez-la pour vous authentifier immédiatement sans mot de passe."
echo -e " - ${YELLOW}Si la YubiKey est absente :${NC} appuyez sur Entrée ou attendez, puis saisissez votre mot de passe habituel."
echo ""
echo -e "${YELLOW}Important concernant la session graphique :${NC}"
echo -e "Lors d'une connexion graphique initiale sans mot de passe, le trousseau de clés GNOME (mots de passe de navigateur, etc.) reste verrouillé jusqu'à ce qu'une application le sollicite ou que vous entriez votre mot de passe."
echo -e "Le déverrouillage de l'écran verrouillé (Super+L) est en revanche 100% transparent."
echo -e "${GREEN}==============================================================${NC}"
echo ""
echo -e "Pour tester sudo immédiatement dans un nouveau terminal :"
echo -e "  ${YELLOW}sudo -k && sudo whoami${NC}"
