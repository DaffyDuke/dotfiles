#!/usr/bin/env bash
# ==============================================================================
# Script de désactivation du verrouillage automatique de session
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

echo -e "${BLUE}Désactivation du verrouillage automatique...${NC}"

# Suppression de la règle udev
if [ -f "/etc/udev/rules.d/80-yubikey-lock.rules" ]; then
    rm -f "/etc/udev/rules.d/80-yubikey-lock.rules"
    udevadm control --reload-rules
    echo -e "${GREEN}✓ Règle udev supprimée${NC}"
fi

# Suppression du service systemd
if [ -f "/etc/systemd/system/yubikey-lock.service" ]; then
    rm -f "/etc/systemd/system/yubikey-lock.service"
    systemctl daemon-reload
    echo -e "${GREEN}✓ Service systemd supprimé${NC}"
fi

# Suppression du script
if [ -f "/usr/local/bin/yubikey-lock.sh" ]; then
    rm -f "/usr/local/bin/yubikey-lock.sh"
    echo -e "${GREEN}✓ Script de verrouillage supprimé${NC}"
fi

echo ""
echo -e "${GREEN}Désactivation terminée avec succès. Le retrait de la YubiKey ne verrouillera plus la session.${NC}"
