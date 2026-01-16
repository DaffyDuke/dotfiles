# Documentation Détaillée : .tmux.conf

## 📊 Vue d'ensemble

**Fichier** : `~/.tmux.conf`  
**Lignes** : ~297 lignes  
**Type** : Configuration tmux (terminal multiplexer)  
**Rôle** : Configuration complète de tmux avec keybindings personnalisés, thème, et plugins

### Statistiques clés
- **Prefix key** : `Ctrl+F` (au lieu du défaut `Ctrl+B`)
- **Keybindings personnalisés** : 25+ raccourcis
- **Plugins** : 5 plugins (TPM, tmux-sensible, tmux-resurrect, tmux-plugin-spotify, Catppuccin)
- **Thème** : Solarized 256 + Catppuccin Mocha
- **Terminal** : rxvt-unicode-256color
- **Shell par défaut** : Zsh

---

## 🏗️ Architecture du fichier

Le fichier `.tmux.conf` est structuré en plusieurs sections logiques :

```
.tmux.conf (297 lignes)
├── 1. En-tête et commentaires (lignes 1-14)
├── 2. Configuration Prefix Key (lignes 16-18)
├── 3. Configuration générale (lignes 19-45)
│   ├── History limit (5000 lignes)
│   ├── Bell action
│   ├── Terminal type
│   └── Shell par défaut
├── 4. Navigation fenêtres (lignes 46-58)
│   ├── Fonction keys (F1-F8)
│   ├── Ctrl+N/P (next/prev)
│   └── Base index
├── 5. Gestion fenêtres/panes (lignes 60-75)
│   ├── Kill window/pane
│   ├── SSH custom
│   ├── Rename
│   └── Break pane
├── 6. Redimensionnement panes (lignes 77-81)
├── 7. Configuration souris (lignes 84-88, commenté)
├── 8. Synchronisation panes (lignes 91-92)
├── 9. Terminal overrides (lignes 93-98)
├── 10. Pipe et logging (lignes 101-103)
├── 11. Configuration Vim (lignes 106-111, commenté)
├── 12. Configuration copie/coller (lignes 113-138)
├── 13. Thème Solarized 256 (lignes 140-162)
├── 14. Design changes (lignes 164-228)
│   ├── Panes
│   ├── Status bar
│   ├── Window modes
│   ├── Messages
│   └── Statusbar complète
├── 15. Plugins TPM (lignes 230-297)
    ├── TPM
    ├── tmux-sensible
    ├── tmux-resurrect
    ├── tmux-plugin-spotify
    └── Catppuccin
```

---

## 📦 Configuration détaillée

### 1️⃣ Prefix Key personnalisé (lignes 16-18)

```tmux
unbind C-b
set -g prefix ^F
bind f send-prefix
```

**Changement majeur** : `Ctrl+B` → `Ctrl+F`

**Raison** : `Ctrl+B` conflit avec Vim (page up), `Ctrl+F` plus ergonomique.

**Utilisation** :
- `Ctrl+F` puis `c` : Nouvelle fenêtre
- `Ctrl+F` puis `%` : Split vertical
- `Ctrl+F` puis `"` : Split horizontal
- `Ctrl+F` puis `d` : Détacher session

---

### 2️⃣ Configuration générale (lignes 19-45)

#### History limit
```tmux
set -g history-limit 5000
```
**Effet** : 5000 lignes de scrollback (historique).

---

#### Bell action
```tmux
set -g bell-action any
set -g visual-activity on
```
**Effet** : Notifications visuelles pour activité dans autres fenêtres.

---

#### Terminal type
```tmux
set -g default-terminal "rxvt-unicode-256color"
```
**Alternatives** :
- `screen-256color` : Compatibilité maximale
- `xterm-256color` : Terminaux xterm
- `tmux-256color` : Support moderne

**Choix** : `rxvt-unicode-256color` (urxvt avec 256 couleurs).

---

#### Shell par défaut
```tmux
set -g default-command zsh
```
**Effet** : Lance Zsh dans chaque nouveau pane.

---

### 3️⃣ Navigation fenêtres (lignes 46-58)

#### Fonction keys (F1-F8)
```tmux
bind -n F1 select-window -t 1
bind -n F2 select-window -t 2
bind -n F3 select-window -t 3
bind -n F4 select-window -t 4
bind -n F5 select-window -t 5
bind -n F6 select-window -t 6
bind -n F7 select-window -t 7
bind -n F8 select-window -t 8
```
**Effet** : `F1`-`F8` sélectionne directement fenêtre 1-8 (sans prefix).

---

#### Cycle fenêtres
```tmux
bind-key C-n next
bind-key C-p prev
bind-key C-o last-window
```
**Keybindings** :
- `Ctrl+F` puis `Ctrl+N` : Fenêtre suivante
- `Ctrl+F` puis `Ctrl+P` : Fenêtre précédente
- `Ctrl+F` puis `Ctrl+O` : Dernière fenêtre

---

#### Base index
```tmux
set -g base-index 1
```
**Effet** : Fenêtres numérotées à partir de 1 (au lieu de 0).

**Avantage** : Plus ergonomique (touches `1-9` en haut du clavier).

---

### 4️⃣ Gestion fenêtres/panes (lignes 60-75)

#### Kill window/pane
```tmux
bind-key C-k confirm kill-window
bind-key C-e confirm kill-pane
```
**Keybindings** :
- `Ctrl+F` puis `Ctrl+K` : Tuer fenêtre (avec confirmation)
- `Ctrl+F` puis `Ctrl+E` : Tuer pane (avec confirmation)

---

#### SSH personnalisé
```tmux
bind-key S command-prompt "new-window -n %1 'myssh %1'"
```
**Utilisation** :
```bash
Ctrl+F S
# Prompt: server.example.com
# Ouvre nouvelle fenêtre nommée "server.example.com" avec commande myssh
```

**Note** : Nécessite script `myssh` personnalisé.

---

#### Rename window
```tmux
bind-key A command-prompt "rename-window %1"
```
**Utilisation** : `Ctrl+F` puis `A` → Saisir nouveau nom.

---

#### Reload config
```tmux
bind R source-file ~/.tmux.conf\; display-message "Config reloaded..."
```
**Utilisation** : `Ctrl+F` puis `R` → Recharge configuration.

---

#### Break pane
```tmux
bind X break-pane
bind C-b break-pane
```
**Effet** : Transforme pane courant en fenêtre indépendante.

---

### 5️⃣ Redimensionnement panes (lignes 77-81)

```tmux
bind-key J resize-pane -D 5
bind-key K resize-pane -U 5
bind-key H resize-pane -L 5
bind-key L resize-pane -R 5
```

**Keybindings** :
- `Ctrl+F` puis `J` : Agrandir vers le bas (5 lignes)
- `Ctrl+F` puis `K` : Agrandir vers le haut (5 lignes)
- `Ctrl+F` puis `H` : Agrandir vers la gauche (5 colonnes)
- `Ctrl+F` puis `L` : Agrandir vers la droite (5 colonnes)

**Style Vim** : HJKL pour direction.

---

### 6️⃣ Souris (lignes 84-88, désactivée)

```tmux
# setw -g mode-mouse off
# set -g mouse-select-pane off
# set -g mouse-resize-pane off
# set -g mouse-select-window off
```

**État** : Souris explicitement désactivée (mode clavier pur).

**Pour activer** :
```tmux
set -g mouse on
```

---

### 7️⃣ Synchronisation panes (lignes 91-92)

```tmux
bind 'l' set-window-option synchronize-panes on
bind 'm' set-window-option synchronize-panes off
```

**Fonctionnalité puissante** : Taper dans tous les panes simultanément.

**Utilisation** :
1. `Ctrl+F` puis `l` : Activer synchronisation
2. Taper commandes (exécutées dans tous les panes)
3. `Ctrl+F` puis `m` : Désactiver synchronisation

**Cas d'usage** : Administration de plusieurs serveurs en parallèle.

---

### 8️⃣ Terminal overrides (lignes 93-98)

```tmux
set -ga terminal-overrides ',xterm*:smcup@:rmcup@'
set -g terminal-overrides "xterm*:XT:smcup@:rmcup@"
set -g set-titles on
set-option -g set-titles-string '#T'
set-window-option -g automatic-rename on
```

**Options** :
- `smcup@:rmcup@` : Désactive alternate screen buffer (historique préservé)
- `set-titles on` : Met à jour titre de la fenêtre terminal
- `set-titles-string '#T'` : Utilise titre du pane
- `automatic-rename on` : Renommage automatique basé sur commande

---

### 9️⃣ Pipe et logging (lignes 101-103)

```tmux
bind-key P command-prompt -p 'save history to filename:' -I '~/tmux.history' 'capture-pane -S -32768 ; save-buffer %1 ; delete-buffer'
bind-key j join-pane -s !
```

**Keybindings** :
- `Ctrl+F` puis `P` : Sauvegarder historique du pane (32768 lignes) dans fichier
- `Ctrl+F` puis `j` : Joindre dernier pane créé

---

### 🔟 Configuration copie/coller (lignes 113-138)

#### Mode Vi
```tmux
setw -g mode-keys vi
unbind [
bind Escape copy-mode
unbind p
```

**Workflow copie** :
1. `Ctrl+F` puis `Escape` : Entrer en copy mode
2. Déplacer curseur (HJKL)
3. `v` : Activer sélection visuelle
4. Déplacer pour sélectionner
5. `y` : Copier (yank)
6. `q` : Quitter copy mode
7. `Ctrl+F` puis `p` : Coller

**Note** : Lignes 133-134 commentées (ancienne syntaxe tmux).
```tmux
# bind-key -t vi-copy 'v' begin-selection
# bind-key -t vi-copy 'y' copy-selection
```

**Nouvelle syntaxe** (tmux 2.4+) :
```tmux
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection
```

---

## 🎨 Thème et couleurs

### 1️⃣ Thème Solarized 256 (lignes 140-162)

#### Statusbar colors
```tmux
set-option -g status-bg colour235   # base02 (gris foncé)
set-option -g status-fg colour136   # yellow
```

#### Window title colors
```tmux
# Inactive window
set-window-option -g window-status-style fg=colour244  # base0

# Active window
set-window-option -g window-status-current-style fg=colour166  # orange
```

#### Pane border
```tmux
set-option -g pane-border-style fg=colour235        # base02
set-option -g pane-active-border-style fg=colour240 # base01 (légèrement plus clair)
```

#### Messages
```tmux
set-option -g message-style bg=colour235  # base02
set-option -g message-style fg=colour166  # orange
```

#### Clock
```tmux
set-window-option -g clock-mode-colour colour64  # green
```

---

### 2️⃣ Design changes (lignes 164-228)

#### Panes borders (custom)
```tmux
set -g pane-border-style fg=black
set -g pane-active-border-style fg=brightred
```
**Effet** : Pane actif avec bordure rouge vif.

---

#### Status bar
```tmux
set -g status-justify left          # Alignement gauche
set -g status-bg default
set -g status-fg colour12
set -g status-interval 2            # Rafraîchissement toutes les 2s
```

**Statusbar complète** (lignes 246-250) :
```tmux
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
```

**Affichage** :
```
[Gauche: vide]           [Droite: 14/01  15:42:30]
```

---

#### Window status format
```tmux
# Fenêtre courante
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '

# Autres fenêtres
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
```

**Variables** :
- `#I` : Index fenêtre
- `#W` : Nom fenêtre
- `#F` : Flags (*, -, Z)

**Exemple** : ` 1:zsh*  2:vim  3:htop `

---

#### Messages styling
```tmux
set -g message-style "bold"
set -g message-style fg=colour232
set -g message-style bg=colour166
```
**Effet** : Messages tmux en gras, texte noir sur fond orange.

---

### 3️⃣ Plugin Catppuccin (lignes 287-291)

```tmux
set -g @plugin 'catppuccin/tmux#v2.1.1'
set -g @catppuccin_flavor 'mocha'  # latte, frappe, macchiato ou mocha
```

**Thème moderne** : Catppuccin Mocha (palette pastel sombre).

**Note** : Possiblement en conflit avec Solarized (lignes 140-162). Catppuccin prend le dessus si TPM activé.

---

## 🔌 Plugins TPM (Tmux Plugin Manager)

### Installation TPM
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Gestion plugins
```bash
# Dans tmux
Ctrl+F I       # Installer plugins
Ctrl+F U       # Mettre à jour plugins
Ctrl+F alt+u   # Désinstaller plugins non listés
```

---

### 1️⃣ tmux-sensible

**Plugin** : `tmux-plugins/tmux-sensible`  
**Rôle** : Paramètres par défaut sensés pour tmux.

**Améliorations** :
- Augmente scrollback à 50000
- Focus events activés
- Messages affichés plus longtemps
- Refresh status bar optimisé
- Escape time réduit

---

### 2️⃣ tmux-resurrect

**Plugin** : `tmux-plugins/tmux-resurrect`  
**Rôle** : Sauvegarder et restaurer sessions tmux.

**Utilisation** :
```bash
Ctrl+F Ctrl+s  # Sauvegarder session
Ctrl+F Ctrl+r  # Restaurer session
```

**Sauvegarde** :
- Layout des panes
- Programmes en cours d'exécution
- Répertoires courants

**Cas d'usage** :
- Redémarrage système
- Crash tmux
- Reproduire environnement de travail

---

### 3️⃣ tmux-plugin-spotify

**Plugin** : `pwittchen/tmux-plugin-spotify`  
**Rôle** : Afficher chanson Spotify en cours dans la statusbar.

**Configuration** (ligne 283) :
```tmux
set -g status-right "#[fg=colour136, bg=color235] #{spotify_song}, #{spotify_artist}, #{spotify_album} - #(date +%H:%M)"
```

**Affichage** :
```
Never Gonna Give You Up, Rick Astley, Whenever You Need Somebody - 15:42
```

**Dépendance** : Spotify doit être installé et en cours d'exécution.

---

### 4️⃣ Catppuccin Theme

**Plugin** : `catppuccin/tmux#v2.1.1`  
**Version** : 2.1.1 (tag fixé)  
**Flavor** : Mocha (dark)

**Alternatives** :
- `latte` : Clair
- `frappe` : Moyen sombre
- `macchiato` : Sombre
- `mocha` : Très sombre (choix actuel)

---

### 5️⃣ TPM Initialization

```tmux
run '~/.tmux/plugins/tpm/tpm'
```

**Important** : Doit être la dernière ligne du fichier.

---

## 🔑 Keybindings complets

### Prefix : `Ctrl+F`

| Keybinding | Action |
|------------|--------|
| **Navigation fenêtres** | |
| `F1`-`F8` | Sélectionner fenêtre 1-8 (sans prefix) |
| `Ctrl+F` `Ctrl+N` | Fenêtre suivante |
| `Ctrl+F` `Ctrl+P` | Fenêtre précédente |
| `Ctrl+F` `Ctrl+O` | Dernière fenêtre |
| **Gestion fenêtres** | |
| `Ctrl+F` `c` | Nouvelle fenêtre |
| `Ctrl+F` `Ctrl+K` | Tuer fenêtre |
| `Ctrl+F` `A` | Renommer fenêtre |
| `Ctrl+F` `S` | Nouvelle fenêtre SSH |
| **Gestion panes** | |
| `Ctrl+F` `%` | Split vertical |
| `Ctrl+F` `"` | Split horizontal |
| `Ctrl+F` `Ctrl+E` | Tuer pane |
| `Ctrl+F` `X` | Break pane (→ fenêtre) |
| `Ctrl+F` `C-b` | Break pane (alt) |
| `Ctrl+F` `j` | Join pane |
| **Redimensionnement** | |
| `Ctrl+F` `J` | Agrandir ↓ (5 lignes) |
| `Ctrl+F` `K` | Agrandir ↑ (5 lignes) |
| `Ctrl+F` `H` | Agrandir ← (5 cols) |
| `Ctrl+F` `L` | Agrandir → (5 cols) |
| **Synchronisation** | |
| `Ctrl+F` `l` | Sync panes ON |
| `Ctrl+F` `m` | Sync panes OFF |
| **Copie/Coller** | |
| `Ctrl+F` `Escape` | Copy mode |
| `v` | Sélection visuelle (copy mode) |
| `y` | Copier (copy mode) |
| `q` | Quitter copy mode |
| `Ctrl+F` `p` | Coller |
| **Utilitaires** | |
| `Ctrl+F` `R` | Recharger config |
| `Ctrl+F` `P` | Sauvegarder historique |
| `Ctrl+F` `d` | Détacher session |
| `Ctrl+F` `?` | Liste keybindings |

---

## 🧩 Dépendances et Prérequis

### Obligatoires
- ✅ **tmux** : Version 2.6+ (support `set -g ... style`)
- ✅ **Zsh** : Shell par défaut configuré

---

### Recommandées
- 🔹 **TPM** : Tmux Plugin Manager
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

- 🔹 **urxvt** : rxvt-unicode pour `rxvt-unicode-256color`
```bash
sudo apt install rxvt-unicode-256color
```

---

### Optionnelles (plugins)
- 🔸 **Spotify** : Pour `tmux-plugin-spotify`
- 🔸 **myssh** : Script personnalisé pour keybinding `S`

---

## 🎯 Cas d'usage typiques

### Scénario 1 : Session de développement
```bash
$ tmux new -s dev
# Fenêtre 1: Éditeur
Ctrl+F %     # Split vertical
# Gauche: vim, Droite: terminal

# Nouvelle fenêtre pour serveur
Ctrl+F c
npm start

# Nouvelle fenêtre pour logs
Ctrl+F c
tail -f app.log

# Navigation
F1           # Éditeur
F2           # Serveur
F3           # Logs
```

---

### Scénario 2 : Administration multi-serveurs
```bash
$ tmux new -s admin

# Split en 4 panes
Ctrl+F %     # Split vertical
Ctrl+F "     # Split horizontal gauche
Ctrl+F o     # Changer pane
Ctrl+F "     # Split horizontal droite

# Activer synchronisation
Ctrl+F l

# Taper commandes (exécutées dans les 4 panes)
ssh server1.example.com
sudo apt update
sudo apt upgrade -y

# Désactiver synchronisation
Ctrl+F m
```

---

### Scénario 3 : Sauvegarder/Restaurer session
```bash
# Configurer environnement de travail
# ... (plusieurs fenêtres, panes, programmes)

# Sauvegarder
Ctrl+F Ctrl+s

# Redémarrer système
$ sudo reboot

# Après redémarrage
$ tmux
Ctrl+F Ctrl+r    # Restaure toutes les fenêtres/panes
```

---

### Scénario 4 : Copier du texte
```bash
# Dans un pane avec sortie de commande
$ curl https://api.github.com/users/octocat

# Copier une partie
Ctrl+F Escape    # Enter copy mode
# Naviguer avec HJKL
v                # Sélection visuelle
# Sélectionner texte
y                # Copier
q                # Quitter

# Coller
Ctrl+F p
```

---

### Scénario 5 : SSH rapide
```bash
Ctrl+F S
# Prompt: Enter hostname
server.example.com

# Ouvre nouvelle fenêtre nommée "server.example.com"
# Exécute: myssh server.example.com
```

---

## 🐛 Problèmes connus et solutions

### Problème 1 : Couleurs incorrectes
**Symptôme** : Couleurs fades ou incorrectes dans tmux.

**Solution** : Vérifier `TERM` dans et hors tmux.
```bash
# Hors tmux
echo $TERM
# Doit afficher: rxvt-unicode-256color ou xterm-256color

# Dans tmux
echo $TERM
# Doit afficher: rxvt-unicode-256color (ou screen-256color)
```

**Fix** :
```tmux
set -g default-terminal "screen-256color"
```

---

### Problème 2 : Prefix key ne fonctionne pas
**Symptôme** : `Ctrl+F` ne déclenche pas tmux.

**Solution** : Vérifier que config est chargée.
```bash
tmux source-file ~/.tmux.conf
# Ou dans tmux
Ctrl+F R
```

---

### Problème 3 : TPM plugins ne s'installent pas
**Symptôme** : `Ctrl+F I` ne fait rien.

**Solution** : Installer TPM.
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf
Ctrl+F I
```

---

### Problème 4 : tmux-resurrect ne restaure pas
**Symptôme** : `Ctrl+F Ctrl+r` ne restaure rien.

**Cause** : Pas de sauvegarde effectuée.

**Solution** :
```bash
# Sauvegarder d'abord
Ctrl+F Ctrl+s

# Vérifier fichier de sauvegarde
ls ~/.tmux/resurrect/
```

---

### Problème 5 : Copy mode ne fonctionne pas
**Symptôme** : `v` et `y` ne fonctionnent pas en copy mode.

**Cause** : Ancienne syntaxe tmux.

**Solution** : Ajouter bindings modernes.
```tmux
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
```

---

### Problème 6 : Conflit thèmes Solarized/Catppuccin
**Symptôme** : Couleurs incohérentes.

**Cause** : Deux thèmes configurés (Solarized lignes 140-162 + Catppuccin ligne 288).

**Solution** : Désactiver l'un des deux.
```tmux
# Désactiver Catppuccin
# set -g @plugin 'catppuccin/tmux#v2.1.1'

# OU désactiver Solarized (commenter lignes 140-162)
```

---

## 🔍 Patterns tmux intéressants

### 1. Bind sans prefix (`-n`)
```tmux
bind -n F1 select-window -t 1
```
**Signification** : `F1` fonctionne directement, sans `Ctrl+F`.

---

### 2. Command prompt avec valeur par défaut
```tmux
bind-key P command-prompt -p 'save history to filename:' -I '~/tmux.history' '...'
```
**Signification** : Prompt avec valeur pré-remplie (`-I`).

---

### 3. Display message après action
```tmux
bind R source-file ~/.tmux.conf\; display-message "Config reloaded..."
```
**Signification** : `\;` sépare commandes, affiche message de confirmation.

---

### 4. Variables de format
```tmux
set-option -g set-titles-string '#T'
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
```

**Variables courantes** :
- `#T` : Titre du pane
- `#I` : Index fenêtre
- `#W` : Nom fenêtre
- `#F` : Flags fenêtre (*, -, Z)
- `#S` : Nom session
- `#H` : Hostname

---

### 5. Conditional autocmd (Vim integration, commenté)
```tmux
# bind -n C-h run "(tmux display-message -p '#{pane_title}' | grep -iq vim && tmux send-keys C-h) || tmux select-pane -L"
```
**Signification** : Si pane contient Vim, envoyer `Ctrl+H` à Vim, sinon changer de pane.

---

## 📈 Recommandations d'optimisation

### 1. Activer la souris
**Impact** : ⚙️ Facilite redimensionnement et sélection

**Action** :
```tmux
set -g mouse on
```

---

### 2. Résoudre conflit thèmes
**Impact** : 🎨 Cohérence visuelle

**Action** : Choisir Catppuccin OU Solarized.
```tmux
# Recommandation: Catppuccin (plus moderne)
# Commenter lignes 140-162 (Solarized)
```

---

### 3. Moderniser bindings copy mode
**Impact** : ✅ Compatibilité tmux 2.4+

**Action** :
```tmux
bind-key -T copy-mode-vi 'v' send -X begin-selection
bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle
```

---

### 4. Intégration clipboard système
**Impact** : 📋 Copier vers presse-papier OS

**Action** :
```tmux
# Linux (xclip)
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "xclip -sel clip -i"

# macOS
bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
```

---

### 5. Augmenter history limit
**Impact** : 📜 Plus de scrollback

**Action** :
```tmux
set -g history-limit 50000
```

---

### 6. Activer escape time rapide (Vim)
**Impact** : ⚡ Vim plus réactif dans tmux

**Action** :
```tmux
set -sg escape-time 0
```

---

## 📊 Analyse de complexité

### Par catégorie

| Catégorie | Lignes | Complexité |
|-----------|--------|------------|
| Configuration générale | 30 | ⭐ Simple |
| Keybindings | 50 | ⭐⭐ Moyen |
| Thème Solarized | 25 | ⭐⭐ Moyen |
| Design custom | 65 | ⭐⭐⭐ Complexe |
| Plugins TPM | 15 | ⭐ Simple |
| **TOTAL** | **297** | **⭐⭐ Moyen** |

---

### Top 5 des sections les plus utiles

| Section | Utilité | Fréquence d'usage |
|---------|---------|-------------------|
| Prefix key (`Ctrl+F`) | ⭐⭐⭐⭐⭐ | Constante |
| Navigation F1-F8 | ⭐⭐⭐⭐⭐ | Très fréquente |
| Redimensionnement HJKL | ⭐⭐⭐⭐ | Fréquente |
| Synchronisation panes | ⭐⭐⭐⭐ | Occasionnelle |
| tmux-resurrect | ⭐⭐⭐⭐⭐ | Critique |

---

## 🎓 Conclusion et évaluation

### Points forts ✅
- ✅ **Prefix ergonomique** : `Ctrl+F` meilleur que `Ctrl+B`
- ✅ **Navigation rapide** : F1-F8 sans prefix
- ✅ **Redimensionnement Vim-style** : HJKL intuitif
- ✅ **Synchronisation panes** : Administration multi-serveurs
- ✅ **Copy mode Vi** : Workflow cohérent avec Vim
- ✅ **Plugins essentiels** : resurrect (sauvegarde), sensible (defaults)
- ✅ **Thème moderne** : Catppuccin Mocha
- ✅ **Intégration Spotify** : Statusbar enrichie

### Points d'amélioration ⚠️
- ⚠️ **Conflit thèmes** : Solarized + Catppuccin (choisir un seul)
- ⚠️ **Copy mode bindings** : Syntaxe ancienne commentée (ligne 133-134)
- ⚠️ **Pas de clipboard OS** : Copie tmux seulement
- ⚠️ **Souris désactivée** : Peut être pratique pour certains
- ⚠️ **Script myssh manquant** : Keybinding `S` nécessite script custom

### Complexité globale
- **Lignes** : 297
- **Keybindings** : 25+
- **Plugins** : 5
- **Lisibilité** : 📖 Excellente (commentaires, sections claires)
- **Maintenabilité** : 🔧 Bonne (peu de maintenance requise)

### Note globale : **9.0/10**

**Justification** :
- Configuration professionnelle et optimisée
- Keybindings ergonomiques et intuitifs
- Plugins essentiels bien choisis
- Thème moderne et élégant
- Synchronisation panes (killer feature)
- Quelques optimisations possibles (clipboard, thème unique)

---

## 📚 Ressources

### Documentation officielle
- [tmux Manual](https://man.openbsd.org/tmux)
- [tmux Wiki](https://github.com/tmux/tmux/wiki)

### Plugins
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- [tmux-plugin-spotify](https://github.com/pwittchen/tmux-plugin-spotify)
- [Catppuccin for tmux](https://github.com/catppuccin/tmux)

### Guides
- [A tmux Crash Course](https://thoughtbot.com/blog/a-tmux-crash-course)
- [The Tao of tmux](https://leanpub.com/the-tao-of-tmux/read)
- [tmux Cheat Sheet](https://tmuxcheatsheet.com/)

### Alternatives et comparaisons
- **Screen** : Ancêtre de tmux (moins de fonctionnalités)
- **Zellij** : Multiplexeur moderne en Rust
- **Byobu** : Wrapper pour tmux/screen

---

**Date de génération** : 14 janvier 2026  
**Analyste** : BMAD Document Workflow v1.2.0  
**Niveau d'analyse** : Deep Dive (Exhaustif)
