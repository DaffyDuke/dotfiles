#!/bin/bash
LOG="/tmp/edge-key-check.log"
URL="https://packages.microsoft.com/repos/edge/dists/stable/InRelease"
MAIL="daffyduke@no-log.org"

if curl -s "$URL" | grep -q "SHA1 is not considered secure"; then
  echo "$(date): Clé toujours SHA1, dépôt non accessible." >> "$LOG"
else
  echo "$(date): Le dépôt Edge est à nouveau accessible, vérifie la clé !" | mail -s "Microsoft Edge dépôt OK" "$MAIL"
fi
