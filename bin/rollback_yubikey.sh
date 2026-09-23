#!/usr/bin/env bash
# ==============================================================================
# Script de restauration / annulation de la configuration YubiKey
# Restaure les fichiers PAM d'origine
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

echo -e "${BLUE}Restauration des configurations PAM d'origine...${NC}"

for f in sudo sudo-i gdm-password; do
    if [ -f "/etc/pam.d/${f}.bak.yubikey" ]; then
        cp "/etc/pam.d/${f}.bak.yubikey" "/etc/pam.d/${f}"
        rm -f "/etc/pam.d/${f}.bak.yubikey"
        echo -e "${GREEN}✓ /etc/pam.d/${f} restauré depuis la sauvegarde${NC}"
    else
        sed -i '/pam_u2f\.so/d' "/etc/pam.d/${f}" 2>/dev/null || true
        echo -e "${YELLOW}- /etc/pam.d/${f} nettoyé (règles pam_u2f retirées)${NC}"
    fi
done

if [ -f "/etc/pam.d/polkit-1" ]; then
    rm -f "/etc/pam.d/polkit-1"
    echo -e "${GREEN}✓ /etc/pam.d/polkit-1 supprimé${NC}"
fi

echo ""
echo -e "${GREEN}Restauration terminée avec succès. Votre système utilise à nouveau l'authentification par mot de passe standard.${NC}"
