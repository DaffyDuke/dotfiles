#!/bin/bash
# Script pour gérer les répertoires avec dates au format YYYY-MM-DD
# - Si un répertoire YYYY existe, supprime YYYY-MM-DD
# - Sinon, renomme YYYY-MM-DD en YYYY
# - Opère uniquement sur les répertoires non vides

set -euo pipefail

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Mode d'exécution (dry-run par défaut)
DRY_RUN=true
VERBOSE=false

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY]

Gère les répertoires avec dates au format YYYY-MM-DD.
- Si un répertoire YYYY existe, supprime YYYY-MM-DD
- Sinon, renomme YYYY-MM-DD en YYYY

Options:
    -n, --dry-run     Mode simulation (défaut) - affiche les actions sans les exécuter
    -x, --execute     Mode exécution - effectue réellement les actions
    -v, --verbose     Mode verbeux - affiche les répertoires analysés
    -h, --help        Affiche cette aide

Arguments:
    DIRECTORY         Répertoire de départ (défaut: répertoire courant)

Exemples:
    $(basename "$0")                    # Simulation dans le répertoire courant
    $(basename "$0") -x                 # Exécution dans le répertoire courant
    $(basename "$0") -n /path/to/dir    # Simulation dans /path/to/dir
    $(basename "$0") -x /path/to/dir    # Exécution dans /path/to/dir
EOF
    exit 0
}

# Fonction pour vérifier si un répertoire est vide
is_empty_dir() {
    local dir="$1"
    [ -z "$(ls -A "$dir" 2>/dev/null)" ]
}

# Fonction pour traiter un répertoire
process_directory() {
    local full_path="$1"
    local dir_name=$(basename "$full_path")
    local parent_dir=$(dirname "$full_path")
    
    # Vérifier que le répertoire n'est pas vide
    if is_empty_dir "$full_path"; then
        echo -e "${YELLOW}Ignoré (vide):${NC} $full_path"
        return
    fi
    
    # Retirer -MM-DD pour ne garder que l'année (transforme YYYY-MM-DD en YYYY)
    local base_name=$(echo "$dir_name" | sed -E 's/-[0-9]{2}-[0-9]{2}$//')
    
    # Si aucune modification n'a été faite, ce n'est pas un nom avec date complète à la fin
    if [ "$base_name" = "$dir_name" ]; then
        return
    fi
    
    local target_dir="$parent_dir/$base_name"
    
    # Si le répertoire avec juste l'année existe
    if [ -d "$target_dir" ]; then
        # Vérifier que le répertoire cible n'est pas vide également
        if ! is_empty_dir "$target_dir"; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "${RED}[DRY-RUN] Supprimerait:${NC} $full_path (car $target_dir existe et n'est pas vide)"
            else
                echo -e "${RED}Suppression:${NC} $full_path (car $target_dir existe et n'est pas vide)"
                rm -rf "$full_path"
            fi
        else
            echo -e "${YELLOW}Ignoré:${NC} $full_path (le répertoire $target_dir existe mais est vide)"
        fi
    else
        # Renommer en retirant le mois et le jour (garde l'année)
        if [ "$DRY_RUN" = true ]; then
            echo -e "${GREEN}[DRY-RUN] Renommerait:${NC} $full_path → $target_dir"
        else
            echo -e "${GREEN}Renommage:${NC} $full_path → $target_dir"
            mv "$full_path" "$target_dir"
        fi
    fi
}

# Traitement des arguments
START_DIR=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -x|--execute)
            DRY_RUN=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo -e "${RED}Erreur:${NC} Option inconnue: $1"
            echo "Utilisez -h ou --help pour l'aide"
            exit 1
            ;;
        *)
            START_DIR="$1"
            shift
            ;;
    esac
done

# Répertoire de départ (par défaut: répertoire courant)
START_DIR="${START_DIR:-.}"

if [ ! -d "$START_DIR" ]; then
    echo -e "${RED}Erreur:${NC} Le répertoire '$START_DIR' n'existe pas"
    exit 1
fi

echo "Répertoire de départ: $(realpath "$START_DIR")"
echo "Nombre de répertoires trouvés par find: $(find "$START_DIR" -mindepth 1 -type d | wc -l)"

# Affichage du mode
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}=== MODE SIMULATION (DRY-RUN) ===${NC}"
    echo -e "${YELLOW}Aucune modification ne sera effectuée${NC}"
else
    echo -e "${BLUE}=== MODE EXÉCUTION ===${NC}"
    echo -e "${RED}Les modifications seront effectuées !${NC}"
fi
echo ""
echo "Recherche des répertoires au format YYYY-MM-DD dans: $START_DIR"
echo "=================================================="

# Trouver tous les répertoires se terminant par une date YYYY-MM-DD
found_count=0
checked_count=0

echo "Début de l'analyse..."

# Test direct sans fichier temporaire
echo "Test de la boucle..."

find "$START_DIR" -mindepth 1 -type d | while IFS= read -r dir; do
    checked_count=$((checked_count + 1))
    
    # Afficher les 3 premiers pour debug
    if [ $checked_count -le 3 ]; then
        echo "DEBUG [$checked_count]: $dir"
    fi
    
    dir_name=$(basename "$dir")
    
    if [ "$VERBOSE" = true ] && [ $checked_count -le 10 ]; then
        echo "[$checked_count] Analyse: $dir_name"
    fi
    
    # Vérifier que le nom se termine par YYYY-MM-DD
    if echo "$dir_name" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        echo -e "${BLUE}  → Match trouvé:${NC} $dir_name"
        process_directory "$dir"
        found_count=$((found_count + 1))
    fi
    
    # Afficher la progression tous les 100 répertoires
    if [ $((checked_count % 100)) -eq 0 ]; then
        echo "Progression: $checked_count répertoires analysés, $found_count correspondances..."
    fi
done

echo "Boucle terminée avec checked_count final"

echo "=================================================="
echo "Traitement terminé. $found_count répertoire(s) traité(s) sur $checked_count analysé(s)."
