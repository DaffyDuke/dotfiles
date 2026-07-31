#!/bin/bash
# Localise le fichier certifi actuel
CERT_PATH=$(python3 -m certifi)
ZSCALER_CRT="${HOME}/.ca-certificates/zscaler_combined.pem"

# Vérifie si Zscaler est déjà présent dans le fichier
if ! grep -q "Zscaler" "$CERT_PATH"; then
  echo "Injection de Zscaler dans $CERT_PATH..."
  cat "$ZSCALER_CRT" | sudo tee -a "$CERT_PATH" >/dev/null
  echo "Fait !"
else
  echo "Zscaler est déjà présent dans le bundle Python."
fi
