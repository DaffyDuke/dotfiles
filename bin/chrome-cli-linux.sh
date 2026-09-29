#!/bin/bash

# chrome-cli-linux.sh
# Alternative légère à chrome-cli pour Ubuntu (Chrome déjà lancé)

ACTION=$1
QUERY=$2

# Fonction pour lister les onglets via /proc
list_tabs() {
  echo "🔍 Récupération des onglets ouverts..."

  # Trouve les PIDs de chrome/chromium
  PIDS=$(pgrep -f "chrome|chromium" | head -n 5) # Limite aux premiers PIDs pour éviter le bruit

  if [ -z "$PIDS" ]; then
    echo "❌ Chrome/Chromium ne semble pas être en cours d'exécution."
    exit 1
  fi

  # Extrait les URLs des fdinfo (méthode Linux spécifique)
  # Note: Cela peut prendre quelques secondes selon le nombre d'onglets
  URLS=$(grep -h '^URL=' /proc/{$PIDS}/fdinfo/* 2>/dev/null | sed 's/^URL=//' | sort -u)

  if [ -z "$URLS" ]; then
    echo "⚠️ Aucune URL trouvée via /proc. Essayez d'ouvrir quelques onglets."
    exit 0
  fi

  echo "📑 Onglets détectés :"
  echo "----------------------------------------"
  COUNT=1
  while IFS= read -r url; do
    # Ignore les URLs internes vides ou trop courtes
    if [[ ${#url} -gt 10 ]]; then
      printf "%-4d %s\n" $COUNT "$url"
      ((COUNT++))
    fi
  done <<<"$URLS"
  echo "----------------------------------------"
  echo "💡 Astuce: Pour fermer, assurez-vous que l'onglet cible est actif dans Chrome."
}

# Fonction pour fermer l'onglet actif
close_active_tab() {
  echo "🔒 Tentative de fermeture de l'onglet actif..."

  # Trouve l'ID de la fenêtre Chrome active
  WINDOW_ID=$(xdotool search --class "google-chrome" --limit 1 getwindowfocus 2>/dev/null)

  if [ -z "$WINDOW_ID" ]; then
    # Fallback: cherche n'importe quelle fenêtre chrome
    WINDOW_ID=$(xdotool search --class "google-chrome" | head -1)
  fi

  if [ -z "$WINDOW_ID" ]; then
    echo "❌ Aucune fenêtre Chrome trouvée."
    exit 1
  fi

  # Active la fenêtre pour s'assurer que le raccourci clavier va au bon endroit
  xdotool windowactivate --sync $WINDOW_ID

  # Simule Ctrl+W
  xdotool key ctrl+w

  echo "✅ Commande 'Ctrl+W' envoyée à la fenêtre Chrome (ID: $WINDOW_ID)."
  echo "   Si l'onglet ne se ferme pas, vérifiez qu'il n'y a pas de popup de confirmation."
}

# Fonction pour aller à l'onglet suivant/précédent
switch_tab() {
  DIRECTION=$1
  WINDOW_ID=$(xdotool search --class "google-chrome" | head -1)

  if [ -z "$WINDOW_ID" ]; then
    echo "❌ Chrome non trouvé."
    exit 1
  fi

  xdotool windowactivate --sync $WINDOW_ID

  if [ "$DIRECTION" == "next" ]; then
    xdotool key ctrl+Tab
    echo "➡️ Onglet suivant"
  elif [ "$DIRECTION" == "prev" ]; then
    xdotool key ctrl+shift+Tab
    echo "⬅️ Onglet précédent"
  fi
}

# Menu principal
case "$ACTION" in
list | ls | l)
  list_tabs
  ;;
close | c | rm)
  close_active_tab
  ;;
next | n)
  switch_tab "next"
  ;;
prev | p)
  switch_tab "prev"
  ;;
*)
  echo "Usage: $0 {list|close|next|prev}"
  echo ""
  echo "Commandes:"
  echo "  list   : Liste les URLs des onglets ouverts (via /proc)"
  echo "  close  : Ferme l'onglet ACTIF dans Chrome (simule Ctrl+W)"
  echo "  next   : Passe à l'onglet suivant"
  echo "  prev   : Passe à l'onglet précédent"
  echo ""
  echo "⚠️ Note: 'close' nécessite que la fenêtre Chrome soit visible ou au moins présente."
  ;;
esac
