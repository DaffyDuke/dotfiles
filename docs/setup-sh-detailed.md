# Documentation Exhaustive - setup.sh

**Généré le :** 14 janvier 2026  
**Niveau de scan :** Deep Dive - Analyse exhaustive  
**Fichier :** `/home/daffy/Documents/Code/git/github/dotfiles/setup.sh`  
**Taille :** 1689 lignes | 107 fonctions

---

## 📋 Vue d'ensemble

`setup.sh` est le **cœur du système d'installation** des dotfiles. Ce script bash monolithique automatise l'installation complète d'un environnement de développement Ubuntu/Debian avec 100+ outils, applications et configurations.

### 🎯 Objectif

Transformer une installation Ubuntu/Debian fraîche en poste de développement complet et configuré en une seule commande.

### 📊 Statistiques

- **Lignes de code :** 1689
- **Fonctions :** 107
- **Catégories :** 15+
- **Packages :** 100+ logiciels
- **Années de maintenance :** Depuis Ubuntu 17.10 (2017)

---

## 🏗️ Architecture du Script

### Structure globale

```bash
#!/bin/bash

# 1. Fonction d'installation initiale
Setup()              # Configuration système de base

# 2. Fonctions utilitaires système
WIFI()              # Configuration WiFi
PPA()               # Ajout de repositories
Packages()          # Installation packages de base

# 3. Langages de programmation (3 fonctions)
Python()            # Python + pip + virtualenv
GO()                # Golang + tools
Rust()              # Rust + cargo + tools

# 4. Applications (70+ fonctions)
Docker()
Chrome()
VSCodium()
# ... 70+ autres

# 5. Configuration environnement (10+ fonctions)
GnomeExtensions()
GnomeConfigurations()
Terminal()
ZSH()

# 6. Orchestration
Main()              # Fonction principale
if [ -n $1 ]; then  # Exécution
  $1
else
  Main
fi
```

---

## 🎮 Modes d'utilisation

### Mode 1 : Installation complète

```bash
./setup.sh          # Exécute Main() = ~50 fonctions actives
```

**Durée :** 1-3 heures  
**Actions :** Installation massive ~50 packages/apps

### Mode 2 : Installation sélective

```bash
./setup.sh Docker   # Installe uniquement Docker
./setup.sh ZSH      # Installe uniquement Zsh + Oh-My-Zsh
./setup.sh Python   # Python seulement
```

**Durée :** 2-30 minutes  
**Avantage :** Ciblé, rapide

### Mode 3 : Personnalisation

Éditer `Main()` pour activer/désactiver fonctions :

```bash
Main() {
  # Actif
  Docker
  ZSH
  
  # Désactivé (commenté)
  #  Chrome
  #  Atom
}
```

---

## 📚 Catalogue Complet des 107 Fonctions

### 🖥️ Système et Configuration de Base (5 fonctions)

#### 1. **Setup()** ⭐ FONDAMENTAL
**Ligne :** 3-36  
**Rôle :** Configuration initiale système Ubuntu

**Actions :**
1. **Tmux :** Nettoyage `/tmp/tmux-1000/`
2. **Horloge :** `timedatectl set-local-rtc 1` (dual-boot Windows)
3. **Langue :** Installation pack français
4. **TLP :** Gestion énergie laptop
5. **Packages base :** git, zsh, expect
6. **Laptop mode :** Optimisation (vm.laptop_mode=5, vm.swappiness=10)
7. **Redshift :** Service geoclue pour géolocalisation
8. **Permissions :** Ajout user au groupe cdrom
9. **Stubby :** Configuration DNS over TLS (FDN.fr)

**Dépendances :**
```bash
sudo apt install -y language-pack-gnome-fr-base \
  tlp tlp-rdw i8kutils git zsh expect
```

**Configuration avancée :**
- DNS FDN (ns0.fdn.fr, ns1.fdn.fr) pour privacy
- Sysctl optimisé laptop
- Géolocalisation Lille (50.633, 3.0586)

---

#### 2. **WIFI()** 
**Ligne :** 38-88  
**Rôle :** Correction bugs WiFi après suspend

**Problèmes résolus :**
1. WiFi ne se reconnecte pas après suspend
2. Carte iwlwifi instable
3. Performances réseau dégradées

**Solutions :**
- Script `/etc/pm/sleep.d/10_resume_wifi` (restart nmcli)
- Service systemd `wifi-resume.service`
- Désactivation watchdog iwlwifi
- Déchargement modules au suspend

**Fichiers créés :**
- `/etc/pm/sleep.d/10_resume_wifi`
- `/etc/systemd/system/wifi-resume.service`
- `/etc/modprobe.d/iwlwifi.conf`
- `/etc/pm/config.d/unload_modules`

**Bonus :** Installation bettercap (network sniffing)

---

#### 3. **PPA()** 
**Ligne :** 90-124  
**Rôle :** Ajout de repositories Ubuntu

**PPAs ajoutés :**
```bash
ppa:pbek/qownnotes         # Notes app
ppa:peterlevi/ppa          # Variety wallpapers
ppa:teejee2008/ppa         # Timeshift backup
ppa:unit193/encryption     # Cryptography tools
ppa:vincent-vandevyvre/vvv # Vokoscreenng
```

**Packages tiers :**
- Calibre (ebook manager)
- Dropbox
- Google Chrome
- Spotify
- VSCodium

---

#### 4. **Packages()** 
**Ligne :** 126-164  
**Rôle :** Installation massive packages système

**Catégories installées :**

**Développement :**
```bash
ansible asciinema ccze cheat clang cmake curl deja-dup direnv
dos2unix dpkg-repack exiftool expect fd-find fzf gawk gcc gdb
git gitg git-lfs graphviz htop jq make meld nmap nyancat pv ripgrep
shellcheck tig tldr tree vim wget
```

**Système :**
```bash
ack alacarte arc-theme clamav clamtk cryptkeeper dconf-editor
fail2ban ffmpeg gnome-tweaks gparted hardinfo htop lm-sensors
neofetch ncdu net-tools nmon owncloud-client qownnotes
```

**Productivité :**
```bash
calibre gimp inkscape libreoffice scribus variety vlc
thunderbird krita nextcloud-desktop tusk woeusb
```

**Total :** ~100 packages

---

#### 5. **SNAP()** 
**Ligne :** 166-174  
**Rôle :** Installation packages Snap

**Packages Snap :**
- hub (GitHub CLI)
- github-desktop (beta)
- slack
- spotify
- telegram-desktop

---

### 🐍 Langages de Programmation (3 fonctions)

#### 6. **Python()** ⭐ DÉVELOPPEUR
**Ligne :** 176-192  
**Rôle :** Environnement Python complet

**Packages Python :**
```bash
# Développement
black flake8 mypy pylint pytest ipython jupyter

# CLI Tools
httpie glances howdoi tldr pgcli mycli

# Web scraping
beautifulsoup4 scrapy

# DevOps
ansible molecule ansible-parallel docker-compose

# Data Science
pandas numpy scipy matplotlib
```

**Outils installés :**
- pip (package manager)
- virtualenv (isolation)
- ipython (REPL avancé)
- jupyter (notebooks)

---

#### 7. **GO()** ⭐ DÉVELOPPEUR
**Ligne :** 194-230  
**Rôle :** Golang + outils Go

**Go tools installés :**

**Core :**
```bash
godoc goimports golint  # Documentation et linting
```

**Security/Recon :**
```bash
qsreplace      # Query string manipulation
gau            # Fetch known URLs
waybackurls    # Wayback Machine URLs
assetfinder    # Domain/subdomain finder
ffuf           # Web fuzzer
```

**Utilities :**
```bash
qrcp          # QR code file transfer
curlie        # curl with httpie syntax
pdfcpu        # PDF processor
```

**Installation :**
```bash
sudo apt install -y golang
go get golang.org/x/tools/cmd/godoc
go install github.com/lc/gau/v2/cmd/gau@latest
# ... etc
```

**Conflit résolu :** Désactive alias `gau` de git plugin

---

#### 8. **Rust()** 
**Ligne :** 1139-1152  
**Rôle :** Rust + outils Cargo

**Installation rustup :**
```bash
curl https://sh.rustup.rs -sSf | sh
rustup install stable
rustup default stable
```

**Cargo tools :**
```bash
bat            # cat avec syntax highlighting
delta-git      # Git diff viewer
dog            # DNS client
dust           # du amélioré
erdtree        # Tree avec features
fd-find        # find alternatif
gping          # ping avec graphe
himalaya       # Email TUI
just           # Task runner
kubie          # Kubernetes contexts
mdcat          # Markdown viewer
multigit       # Multi-repo git
navi           # Cheatsheet interactif
ripgrep        # grep ultra-rapide
spotify-tui    # Spotify TUI
trippy         # Network diagnostics
viu            # Image viewer terminal
```

---

### 🐋 Conteneurs et Cloud (5 fonctions)

#### 9. **Docker()** ⭐ ESSENTIEL
**Ligne :** 558-578  
**Rôle :** Installation Docker complète

**Installation officielle :**
```bash
# Ajout clé GPG Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Repository Docker
echo "deb [arch=amd64 ...] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Installation
sudo apt install docker-ce docker-ce-cli containerd.io
```

**Permissions :**
```bash
sudo usermod -aG docker $USER
```

**Outils bonus :**
- docker-compose (orchestration)
- lazydocker (TUI pour Docker)

---

#### 10. **Kubernetes()** 
**Ligne :** 817-896  
**Rôle :** Environnement Kubernetes complet

**Outils installés :**

**kubectl :**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl
```

**Helm :**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**k9s :** TUI pour Kubernetes
**kubectx/kubens :** Switch contexts/namespaces
**krew :** Plugin manager kubectl
**kind :** Kubernetes in Docker
**minikube :** Kubernetes local

**Plugins kubectl installés :**
```bash
kubectl krew install ctx ns view-secret tree images whoami \
  rbac-tool get-all example sick-pods node-shell tail ktop
```

---

#### 11. **K3S()** 
**Ligne :** 803-815  
**Rôle :** Kubernetes léger

```bash
curl -sfL https://get.k3s.io | sh -
sudo systemctl enable k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

---

#### 12. **Minishift()** 
**Ligne :** 956-972  
**Rôle :** OpenShift local

**Installation :**
```bash
wget https://github.com/minishift/minishift/releases/download/v1.25.0/minishift-1.25.0-linux-amd64.tgz
tar xvfz minishift-*
mv minishift-*/minishift ~/bin
```

**Configuration :**
```bash
minishift config set vm-driver virtualbox
minishift start
```

---

#### 13. **CLOUD()** 
**Ligne :** 419-522  
**Rôle :** CLI cloud providers

**AWS :**
```bash
pip install awscli aws-shell
```

**Azure :**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
pip install azure-functions-core-tools
```

**Google Cloud :**
```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
  https://packages.cloud.google.com/apt cloud-sdk main"
sudo apt install google-cloud-cli
```

**Terraform :**
```bash
sudo apt install terraform
```

**Outils DevOps :**
- **ASDF :** Version manager multi-langages
- **MISE :** Runtime manager moderne

---

### 🎨 Environnement de Bureau (10 fonctions)

#### 14. **GnomeExtensions()** ⭐ PERSONNALISATION
**Ligne :** 662-709  
**Rôle :** Installation extensions Gnome Shell

**Extensions installées (15+) :**

| Extension | ID | Fonction |
|-----------|-----|----------|
| sound-output-device-chooser | 906 | Choix sortie audio |
| alternate-tab | 15 | Alt+Tab amélioré |
| drive-menu | 7 | Menu disques |
| windowsNavigator | 10 | Navigation fenêtres |
| refresh-wifi | 905 | Refresh WiFi |
| extensions | 1036 | Manager extensions |
| auto-move-windows | 16 | Auto workspace |
| workspace-switch-wraparound | 1116 | Wraparound workspaces |
| panel-osd | 708 | OSD panel |
| cast-to-tv | 1544 | Chromecast |
| todolist | 1104 | Todo list |
| CoverflowAltTab | 97 | Alt+Tab 3D |
| Burn My Windows | 4679 | Animations fenêtres |
| Emoji Selector | 1162 | Sélecteur emoji |
| Vitals | 1460 | Monitoring système |
| Frippery Move Clock | 2 | Horloge centrale |
| Dynamic Panel Transparency | 1011 | Panel transparent |
| Compiz windows effect | 3210 | Effets fenêtres |

**Configuration panel-osd :**
```bash
dconf write /org/gnome/shell/extensions/panel-osd/y-pos 5.0
dconf write /org/gnome/shell/extensions/panel-osd/x-pos 90.0
```

---

#### 15. **GnomeConfigurations()** ⭐ PERSONNALISATION
**Ligne :** 711-755  
**Rôle :** Configuration complète Gnome

**Thèmes et Apparence :**
```bash
gsettings set org.gnome.desktop.wm.preferences theme 'Radiance'
gsettings set org.gnome.desktop.interface gtk-theme 'Radiance'
gsettings set org.gnome.desktop.interface icon-theme 'La-Capitaine'
gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'
```

**Polices :**
```bash
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
gsettings set org.gnome.meld custom-font 'monospace, 14'
```

**Comportement :**
```bash
# Touchpad sans natural scroll
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

# Night light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-last-coordinates '(50.633, 3.0586)'

# Workspaces fixes
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.mutter workspaces-only-on-primary true

# Nouvelles fenêtres centrées
gsettings set org.gnome.mutter center-new-windows true

# Boutons fenêtres
dconf write /org/gnome/desktop/wm/preferences/button-layout 'close:appmenu'

# Timeout responsive apps
gsettings set org.gnome.mutter check-alive-timeout 30000
```

**Applications favorites :**
```bash
firefox.desktop google-chrome.desktop rhythmbox.desktop
shotwell.desktop libreoffice-writer.desktop nautilus.desktop
spotify.desktop keepass2.desktop tilix.desktop
thunderbird.desktop
```

**Thumbnails vidéos :**
- Configuration ffmpegthumbnailer pour aperçus vidéos Nautilus

---

#### 16. **Terminal()** 
**Ligne :** 1285-1316  
**Rôle :** Configuration terminal Tilix

**Tilix (ex-Terminix) :**
```bash
sudo apt install tilix
```

**Configuration :**
```bash
# Login shell
dconf write /com/gexperts/Tilix/profiles/${default}/login-shell true

# Désactiver avertissements VTE
dconf write /com/gexperts/Tilix/warn-vte-config-issue false

# Zoom avec Ctrl+Scroll
dconf write /com/gexperts/Tilix/control-scroll-zoom true

# Couleurs personnalisées
dconf write /com/gexperts/Tilix/profiles/${default}/use-theme-colors false
dconf write /com/gexperts/Tilix/profiles/${default}/foreground-color '#FFFFFF'
dconf write /com/gexperts/Tilix/profiles/${default}/background-color '#333333'
```

---

#### 17. **ZSH()** ⭐⭐ ESSENTIEL
**Ligne :** 1554-1570  
**Rôle :** Shell Zsh + Oh-My-Zsh + plugins

**Installation Oh-My-Zsh :**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```

**Thème Powerlevel10k :**
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Plugins :**
```bash
# Syntax highlighting
cd ~/.oh-my-zsh && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git

# Autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Ugit (undo git)
git clone https://github.com/Bhupesh-V/ugit.git $ZSH_CUSTOM/plugins/ugit
```

**Nerd Fonts :**
```bash
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts && ./install.sh "FiraCode"
```

**Outils additionnels :**
- **Starship :** Prompt moderne
- **fx :** JSON parser
- **ugit :** Undo git operations

---

#### 18. **FlatPack()** / **FlatPackages()** 
**Ligne :** 622-637  
**Rôle :** Support Flatpak + apps

**Apps Flatpak :**
```bash
ch.openboard.OpenBoard          # Tableau blanc
com.github.tchx84.Flatseal      # Permissions manager
com.getpostman.Postman          # API testing
com.github.xournalpp.xournalpp  # Notes manuscrites
com.valvesoftware.Steam         # Gaming
io.github.qwersyk.Newelle       # AI assistant
org.geogebra.GeoGebra          # Maths
org.gnome.Cheese               # Webcam
org.kde.krita                  # Dessin digital
org.openshot.OpenShot          # Montage vidéo
```

---

#### 19. **Screensavers()** 
**Ligne :** 1175-1187  
**Rôle :** Screensavers Apple TV

**Installation :**
```bash
sudo apt remove gnome-screensaver
sudo apt install -y mpv
```

**Cron automatique :**
```bash
16 02 * * * /home/daffy/bin/get_screensavers.py /home/daffy/Dropbox/Screensavers
```

**Service xscreensaver :**
```bash
systemctl --user enable xscreensaver
```

---

#### 20-23. **Themes et Customization**

**Albert()** - Lanceur type Spotlight macOS  
**Fuzzy()** - fzf fuzzy finder  
**Variety()** - Wallpaper changer (via PPA)  
**coolretroterm()** - Terminal rétro

---

### 💻 Éditeurs et IDEs (5 fonctions)

#### 24. **VIM()** ⭐ DÉVELOPPEUR
**Ligne :** 1352-1392  
**Rôle :** Vim + plugins Vundle

**Vundle (plugin manager) :**
```bash
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

**Plugins installés (via .vimrc) :**
```vim
Plugin 'nvie/vim-flake8'        " Python linting
Plugin 'fatih/vim-go'           " Go development
Plugin 'pangloss/vim-javascript'" JavaScript syntax
Plugin 'scrooloose/nerdtree'    " File explorer
Plugin 'tpope/vim-fugitive'     " Git integration
Plugin 'vim-airline/vim-airline'" Status bar
Plugin 'w0rp/ale'               " Async linting
```

**Configuration :**
```bash
vim +PluginInstall +qall  # Install plugins
```

---

#### 25. **NeoVim()** 
**Ligne :** 1002-1013  
**Rôle :** NeoVim + LazyVim

**Installation :**
```bash
sudo apt install neovim

# Backup anciennes configs
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}

# LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

---

#### 26. **Atom()** 
**Ligne :** 285-316  
**Rôle :** Atom editor + packages

**Packages Atom :**
```bash
git-plus go-plus intentions hugofy language-hugo
language-powershell language-puppet language-terraform
linter linter-docker linter-golinter linter-shellcheck
pandoc-convert terraform-fmt
```

---

#### 27. **VSCodium()** ⭐ MODERNE
**Ligne :** 1416-1493  
**Rôle :** VSCodium (VS Code sans tracking) + extensions

**Installation :**
```bash
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
  | gpg --dearmor | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] \
  https://download.vscodium.com/debs vscodium main' \
  | sudo tee /etc/apt/sources.list.d/vscodium.list

sudo apt update && sudo apt install codium
```

**Extensions (60+) :**

**Langages :**
```bash
golang.go ms-python.python rust-lang.rust-analyzer
hashicorp.terraform rebornix.ruby redhat.vscode-yaml
ms-azuretools.vscode-docker ms-kubernetes-tools.vscode-kubernetes-tools
```

**Productivité :**
```bash
eamodio.gitlens vscodevim.vim streetsidesoftware.code-spell-checker
github.copilot oderwat.indent-rainbow
```

**Themes :**
```bash
dracula-theme.theme-dracula pkief.material-icon-theme
```

---

#### 28. **Vivaldi()** 
**Ligne :** 1408-1414  
**Rôle :** Navigateur Vivaldi

---

### 🛠️ Outils Développement (20+ fonctions)

#### 29. **Git Tools**

**Github() :** GitHub Desktop + hub CLI  
**git-lfs :** Git Large File Storage (dans Packages)

---

#### 30. **Ansible()** 
**Ligne :** 262-273  
**Rôle :** Ansible + ARA + Molecule

**Installation :**
```bash
pip install --user ansible "ara[server]" molecule ansible-parallel
```

**ARA :** Ansible Run Analysis (enregistre playbooks)  
**Molecule :** Test-Driven Development pour Ansible  
**ansible-parallel :** Exécution parallèle playbooks

---

#### 31. **Terraform (dans CLOUD)**

Installation via apt après ajout repository HashiCorp.

---

#### 32. **Puppet()** 
**Ligne :** 1096-1101  
**Rôle :** Puppet configuration management

```bash
wget http://apt.puppetlabs.com/puppet-release-xenial.deb
sudo dpkg -i puppet-release-xenial.deb
```

---

#### 33. **Powershell()** 
**Ligne :** 1079-1094  
**Rôle :** PowerShell sur Linux

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/17.10/prod.list \
  | sudo tee /etc/apt/sources.list.d/microsoft.list
sudo apt install -y powershell
```

---

#### 34. **Delta()** 
**Ligne :** 335-340  
**Rôle :** Git diff viewer amélioré

```bash
wget https://github.com/barnumbirr/delta-debian/releases/download/v0.1.1-1/delta_0.1.1-1_amd64_debian_buster.deb
sudo dpkg -i delta_*.deb
sudo apt-mark hold delta
```

---

#### 35. **Hurl()** 
**Ligne :** 786-793  
**Rôle :** HTTP request runner (alternative curl)

```bash
curl --location --remote-name \
  https://github.com/Orange-OpenSource/hurl/releases/download/6.0.0/hurl_6.0.0_amd64.deb
sudo apt install ./hurl_6.0.0_amd64.deb
```

---

#### 36-45. **Autres outils dev**

**Bat()** - cat avec syntax highlighting  
**Argbash()** - Bash argument parser generator  
**bcctools()** - BPF tools (eBPF)  
**Ctop()** - Top pour containers  
**TLDR()** - Man pages simplifiées  
**Taskfile()** - Task runner  
**mkcert()** - Certificats SSL locaux  
**ChatGPT()** - ChatGPT CLI  
**IssueHelper()** - Issue management (Rust)  

---

### 📱 Communication et Productivité (10 fonctions)

#### 46. **Signal()** ⭐ MESSAGERIE
**Ligne :** 1189-1208  
**Rôle :** Signal Desktop

**Installation officielle :**
```bash
wget -O- https://updates.signal.org/desktop/apt/keys.asc \
  | gpg --dearmor > signal-desktop-keyring.gpg
sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg

echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" \
  | sudo tee /etc/apt/sources.list.d/signal-xenial.list

sudo apt update && sudo apt install signal-desktop
```

**Tweak :** Ajoute `--use-tray-icon` automatiquement

---

#### 47. **Slack()** 
**Ligne :** 1210-1231  
**Rôle :** Slack Desktop

**Installation :**
```bash
sudo snap install slack --classic
```

**Alternative Debian :**
```bash
wget https://downloads.slack-edge.com/releases/linux/4.38.125/prod/x64/slack-desktop-4.38.125-amd64.deb
sudo apt install ./slack-desktop-*.deb
```

---

#### 48. **Teams()** 
**Ligne :** 1275-1283  
**Rôle :** Microsoft Teams

```bash
wget -O- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
  https://packages.microsoft.com/repos/ms-teams stable main" \
  | sudo tee /etc/apt/sources.list.d/teams.list
sudo apt update && sudo apt install teams
```

---

#### 49. **Element()** 
**Ligne :** 613-620  
**Rôle :** Matrix client

**Installation :**
```bash
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg \
  https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] \
  https://packages.element.io/debian/ default main" \
  | sudo tee /etc/apt/sources.list.d/element-io.list
sudo apt install element-desktop
```

---

#### 50. **Dropbox()** ⭐ CLOUD STORAGE
**Ligne :** 598-605  
**Rôle :** Dropbox + augmentation inotify

**Configuration inotify :**
```bash
echo fs.inotify.max_user_watches=500000 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Installation :**
```bash
sudo apt install nautilus-dropbox -y
wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
dropbox start -i
```

---

#### 51-55. **Autres communication**

**Keybase()** - Crypto messaging + file sharing  
**RocketChat()** - Pidgin plugin RocketChat  
**YakYak()** - Google Hangouts client  
**Trello()** - Trello CLI (3llo)  
**Spotify()** - Spotify client

---

### 🎮 Gaming et Multimédia (8 fonctions)

#### 56. **lutris()** 
**Ligne :** 906-912  
**Rôle :** Gaming platform

**Installation :**
```bash
sudo add-apt-repository ppa:lutris-team/lutris
sudo apt update && sudo apt install lutris
```

---

#### 57. **Music()** 
**Ligne :** 997-1000  
**Rôle :** Logiciels musique

**Apps installées :**
```bash
audacity easyeffects giada guitarix hydrogen kluppe
mixxx muse qwinff rosegarden seq24 soundconverter
tk707 yoshimi zytrax
```

---

#### 58. **PlayOnLinux()** 
**Ligne :** 1072-1077  
**Rôle :** Wine + PlayOnLinux

```bash
wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
sudo add-apt-repository http://deb.playonlinux.com/
sudo apt install playonlinux wine
```

---

#### 59. **Children()** 
**Ligne :** 393-402  
**Rôle :** Jeux éducatifs enfants

**Jeux :**
```bash
brainparty briquolo cgoban colobot connectagram
extremetuxracer frozen-bubble gbrainy gcompris-qt
khangman lutris mu-cade opencity pingus supertuxkart
tuxmath tuxtype tomatoes
```

**Config :** Ajoute users au groupe `junior-programming`

---

#### 60. **Students()** 
**Ligne :** 1252-1260  
**Rôle :** Logiciels éducatifs scientifiques

```bash
avogadro filius fritzing geogebra kalzium kgeography
marble pyacidobasic python3-mecavideo qalculate-gtk
step tkgate verbiste-gnome zegrapher
```

---

#### 61-63. **Autres multimédia**

**Calibre()** - Ebook manager  
**DVD()** - Support DVDs encryptés  
**nicotine()** - Client Soulseek P2P  
**scrcpy()** - Contrôle Android depuis PC

---

### 🔒 Sécurité et Privacy (10 fonctions)

#### 64. **ProtonVPN()** ⭐ VPN
**Ligne :** 1112-1122  
**Rôle :** ProtonVPN client

**Installation :**
```bash
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb
sudo dpkg -i protonvpn-stable-release_*.deb
sudo apt install proton-vpn-gnome-desktop
```

**Dependencies :**
```bash
libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1
gnome-shell-extension-appindicator
```

---

#### 65. **lynis()** 
**Ligne :** 914-922  
**Rôle :** Security auditing tool

**Installation :**
```bash
sudo apt install apt-transport-https ca-certificates
wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key \
  | sudo apt-key add -
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
sudo apt install lynis
```

**Usage :**
```bash
sudo lynis audit system
```

---

#### 66. **CrowdSec()** 
**Ligne :** 543-550  
**Rôle :** Collaborative security engine

```bash
curl -s https://install.crowdsec.net | sudo sh
sudo apt install crowdsec
```

---

#### 67. **OSQuery()** 
**Ligne :** 1063-1070  
**Rôle :** SQL queries sur OS

```bash
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY
sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
sudo apt install osquery
```

---

#### 68-73. **Autres sécurité**

**Douane()** - Firewall application  
**BootRepair()** - Réparation boot GRUB  
**chromeIPass()** - KeePass browser extension  
**ProtonBridge()** - ProtonMail IMAP bridge  
**OfflineImap()** - Email backup local  
**lynishardening()** - Lynis hardening

---

### 📚 Bureautique et Productivité (5 fonctions)

#### 74. **GCStar()** 
**Ligne :** 646-654  
**Rôle :** Collection manager (films, livres, jeux)

**Installation :**
```bash
# Dependencies Perl
sudo apt install libogg-vorbis-header-pureperl-perl libnet-freedb-perl \
  libmp3-tag-perl libgd-graph3d-perl libdatetime-format-strptime-perl \
  libgtk3-simplelist-perl libxml-simple-perl

wget https://gitlab.com/GCstar/GCstar/-/archive/v1.7.3/GCstar-v1.7.3.tar.gz
tar xvfz GCstar-v1.7.3.tar.gz
cd GCstar-v1.7.3/gcstar && sudo ./install
```

---

#### 75-79. **Autres bureautique**

**Packages()** inclut LibreOffice  
**bluegriffon()** - Éditeur HTML WYSIWYG  
**CozyDrive()** - Cozy Cloud client  
**OneDrive()** - OneDrive Linux client  
**rapidphotodownloader()** - Import photos

---

### 🌐 Web et Réseau (5 fonctions)

#### 80. **Chrome()** 
**Ligne :** 404-412  
**Rôle :** Google Chrome

```bash
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub \
  | sudo apt-key add -
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update && sudo apt install google-chrome-stable
```

---

#### 81. **browsh()** 
**Ligne :** 369-375  
**Rôle :** Navigateur web en texte (avec Firefox)

```bash
wget https://github.com/browsh-org/browsh/releases/download/v1.6.4/browsh_1.6.4_linux_amd64.deb
sudo dpkg -i browsh_1.6.4_linux_amd64.deb
```

---

#### 82-84. **Autres web**

**GrafTCP()** - Transparent proxy  
**GRAPH()** - dgraph database  
**Infrakit()** - Infrastructure toolkit

---

### 📦 Gestionnaires de Paquets (4 fonctions)

#### 85. **Brew()** ⭐ PACKAGE MANAGER
**Ligne :** 357-367  
**Rôle :** Homebrew sur Linux

**Installation :**
```bash
sudo apt install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**macOS :**
```bash
brew bundle  # Utilise Brewfile
```

---

#### 86. **WakeMeOps()** 
**Ligne :** 1495-1500  
**Rôle :** Repository Debian portable apps

```bash
curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository \
  | sudo bash
sudo apt install bottom choose gping himalaya hugo k9s openlens \
  procs rclone ripgrep trivy xh yq
```

---

#### 87. **nix()** 
**Ligne :** 1024-1029  
**Rôle :** Nix package manager

**Configuration permissions :**
```bash
sudo chgrp nix-users /nix/var/nix/daemon-socket
sudo chmod ug=rwx,o= /nix/var/nix/daemon-socket
sudo usermod -aG nix-users daffy
```

---

#### 88. **SNAP()** 

Déjà couvert - Installation packages Snap.

---

### 🛠️ Utilitaires Système (10 fonctions)

#### 89. **Crontab()** 
**Ligne :** 232-239  
**Rôle :** Installation cron automatiques

```bash
cat > /tmp/crontab <<\EOF
16 02 * * * /home/daffy/bin/get_screensavers.py /home/daffy/Dropbox/Screensavers
EOF
crontab /tmp/crontab
```

---

#### 90. **Stacer()** 
**Ligne :** 1245-1250  
**Rôle :** System optimizer GUI

```bash
sudo add-apt-repository ppa:oguzhaninan/stacer
sudo apt update && sudo apt install stacer
```

---

#### 91-100. **Autres utilitaires**

**VirtualBox()** - Virtualisation  
**Android()** - Règles udev Android  
**DroidCAM()** - Webcam depuis Android  
**MultiOSUSB()** / **Multisystem()** - USB multiboot  
**urbackup()** - Backup system  
**Ventoy()** - USB multiboot moderne  
**STui()** - Monitoring CPU graphique  
**XAuth()** - X11 authentication  
**WSS()** - Netflix working set size  
**WTF()** - Dashboard terminal

---

### 🎓 Dernières Fonctions (7 fonctions)

#### 101. **youtube()** 
**Ligne :** 1535-1541  
**Rôle :** youtube-dl + GUI

```bash
pip install youtube-dl
# GUI alternative: youtube-dlg
```

---

#### 102. **YunoHost()** 
**Ligne :** 1543-1547  
**Rôle :** Serveur auto-hébergé

```bash
curl https://install.yunohost.org | bash
```

---

#### 103. **zquests()** 
**Ligne :** 1549-1552  
**Rôle :** Gamification shell

---

#### 104. **Lightworks()** 
**Ligne :** 898-904  
**Rôle :** Éditeur vidéo professionnel

---

#### 105. **Chaos()** 
**Ligne :** 382-386  
**Rôle :** Chaos engineering toolkit

```bash
docker pull chaostoolkit/chaostoolkit
docker run -it chaostoolkit/chaostoolkit discover chaostoolkit-kubernetes
```

---

#### 106. **ttfmscorefontsinstaller()** 
**Ligne :** 1338-1344  
**Rôle :** Fonts Microsoft

---

#### 107. **Annexes()** 
**Ligne :** 1572-1575  
**Rôle :** Notes et liens

```bash
# Lien vers vibreoffice (Vim dans LibreOffice)
echo https://github.com/seanyeh/vibreoffice
```

---

## 🎯 Fonction Main() - Orchestration

**Ligne :** 1577-1678

### Configuration actuelle

**✅ Fonctions ACTIVES (50+) :**
```bash
Packages BootRepair Delta Dropbox DVD FlatPack Fuzzy
GnomeConfigurations GnomeExtensions Hurl Keybase K3S Kubernetes
lutris lynis Minishift mkcert MultiOSUSB Music nicotine nix
OfflineImap PlayOnLinux Powershell ProtonBridge ProtonVPN Puppet
Rust scrcpy Screensavers Signal Slack SNAP Spotify Stacer Students
Teams Terminal TLDR ttfmscorefontsinstaller urbackup VIM
VirtualBox Vivaldi VSCodium WakeMeOps WSS WTF XAuth YakYak
youtube ZSH
```

**❌ Fonctions DÉSACTIVÉES (commentées) :**
```bash
#  Setup
#  WIFI
#  PPA
#  Python
#  GO
#  Albert
#  Android
#  Ansible
#  Argbash
#  Atom
#  Bat
#  bcctools
#  bluegriffon
#  Brew
#  browsh
#  Chaos
#  ChatGPT
#  Children
#  Chrome
#  chromeIPass
#  CLOUD
#  coolretroterm
#  CozyDrive
#  Crontab
#  Crowdsec
#  Ctop
#  Docker
#  Douane
#  DroidCAM
#  Element
#  Feedreader
#  GCStar
#  Github
#  GrafTCP
#  GRAPH
#  Infrakit
#  IssueHelper
#  Lightworks
#  lynishardening
#  Multisystem
#  npmfx
#  OneDrive
#  OSQuery
#  rapidphotodownloader
#  RocketChat
#  s3benchmark
#  Spip-Cli
#  STui
#  Taskfile
#  Trello
#  YunoHost
#  zquests
```

---

## 📊 Analyse Statistique

### Par catégorie

| Catégorie | Fonctions | % Total |
|-----------|-----------|---------|
| Applications | 30 | 28% |
| Développement | 20 | 19% |
| Configuration système | 15 | 14% |
| Cloud & Conteneurs | 10 | 9% |
| Communication | 10 | 9% |
| Sécurité | 10 | 9% |
| Gaming/Multimédia | 8 | 7% |
| Utilitaires | 4 | 4% |

### Par complexité

| Complexité | Fonctions | Lignes moy. |
|------------|-----------|-------------|
| Simple (< 10 lignes) | 20 | ~5 |
| Moyen (10-30 lignes) | 60 | ~18 |
| Complexe (30-100 lignes) | 25 | ~50 |
| Très complexe (> 100) | 2 | ~200 |

**Fonctions les plus longues :**
1. Kubernetes() - ~80 lignes
2. VSCodium() - ~77 lignes
3. CLOUD() - ~103 lignes

---

## 🚀 Guide d'utilisation

### Scénarios courants

#### 1. Nouvelle machine - Installation complète

```bash
# Clone dotfiles
git clone --bare https://github.com/USER/dotfiles.git $HOME/dotfiles
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
config checkout

# Éditer Main() selon besoins
nano setup.sh

# Lancer installation (1-3h)
./setup.sh

# OU activer tout (risqué)
# Décommenter toutes les lignes dans Main()
```

---

#### 2. Machine existante - Ajout outils spécifiques

```bash
# Docker seulement
./setup.sh Docker

# Stack dev Python
./setup.sh Python
./setup.sh VSCodium

# Stack Kubernetes
./setup.sh Kubernetes
./setup.sh K3S
```

---

#### 3. Maintenance/Update

```bash
# Re-run fonction spécifique
./setup.sh VSCodium  # Update extensions

# Update packages système
./setup.sh Packages  # Réinstalle/update packages APT
```

---

### Personnalisation avancée

#### Créer sa propre fonction

```bash
MyCustomApp() {
  # Description de l'app
  echo "Installation MyCustomApp..."
  
  # Installation
  sudo apt install my-custom-app
  
  # Configuration
  mkdir -p ~/.config/myapp
  cat > ~/.config/myapp/config.yml <<EOF
setting: value
EOF
}

# Ajouter dans Main()
Main() {
  # ... autres fonctions
  MyCustomApp
}
```

---

#### Configuration conditionnelle

```bash
# Basé sur hostname
if [ "$(hostname)" = "laptop-perso" ]; then
  Games
  Music
else
  Docker
  Kubernetes
fi

# Basé sur présence fichier
if [ -f ~/.gaming-machine ]; then
  lutris
  PlayOnLinux
fi
```

---

## ⚙️ Dépendances et Prérequis

### Système

**OS supporté :**
- Ubuntu 17.10+ (originalement)
- Ubuntu 20.04, 22.04, 24.04 (testé)
- Debian 11, 12 (devrait fonctionner)

**Architecture :**
- x86_64 (AMD64) uniquement

**Accès :**
- Utilisateur avec sudo
- Connexion internet

---

### Packages système critiques

**Installation minimale requise :**
```bash
sudo apt install -y curl wget git sudo
```

**Recommandé avant setup.sh :**
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y build-essential
```

---

## 🐛 Problèmes Connus et Solutions

### 1. Erreurs de clés GPG

**Problème :** Clés expirées, keyserver unreachable

**Solution :**
```bash
# Refresh keyring
sudo apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com

# Alternative keyserver
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys KEYID
```

---

### 2. Repositories Ubuntu version non supportée

**Problème :** PPAs pour anciennes versions Ubuntu

**Solution :**
```bash
# Éditer /etc/apt/sources.list.d/
# Remplacer version Ubuntu manuellement
sudo sed -i 's/bionic/focal/g' /etc/apt/sources.list.d/*.list
```

---

### 3. Snap/Flatpak conflicts

**Problème :** Même app en APT, Snap et Flatpak

**Solution :**
- Préférence : APT > Flatpak > Snap
- Désinstaller doublons

---

### 4. Fonction Main() trop longue

**Problème :** Timeout, erreurs réseau

**Solution :**
```bash
# Exécuter par petits lots
./setup.sh Packages
./setup.sh Docker
# etc.
```

---

## 🔧 Maintenance et Évolution

### Mises à jour recommandées

#### Tous les 6 mois

- [ ] Update versions packages (Docker, VSCodium, etc.)
- [ ] Vérifier PPAs actifs
- [ ] Test sur Ubuntu LTS récent
- [ ] Nettoyer fonctions obsolètes

#### Fonctions à moderniser

**Priorité haute :**
1. **Powershell()** - Version obsolète
2. **Atom()** - EOL, remplacer par VSCodium/NeoVim
3. **bluegriffon()** - Plus maintenu
4. **Puppet()** - Version Xenial (16.04)

**Priorité moyenne :**
5. Migrer Snap → Flatpak (philosophy)
6. ASDF → MISE (moderne)
7. Update Kubernetes versions

---

### Bonnes pratiques

#### ✅ À faire

- Tester fonction individuellement avant ajout Main()
- Commenter fonctions obsolètes au lieu de supprimer
- Documenter dépendances externes
- Versionner avec git
- Backup avant exécution setup.sh complet

#### ❌ À éviter

- Exécuter Main() en production sans test
- Sudo dans fonction (préférer apt-get install en début)
- URLs hardcodées sans version
- Pas de gestion erreur

---

## 📈 Métriques de Qualité

### Code Quality

**✅ Points forts :**
- Structure modulaire (107 fonctions)
- Commentaires présents
- Conventions nommage cohérentes
- Gestion sudo appropriée

**⚠️ Points d'amélioration :**
- Pas de gestion erreur systématique
- Versions hardcodées
- Manque tests unitaires
- Dépendances implicites

---

### Maintenabilité

**Score : 7/10**

**Justification :**
- ✅ Facile ajouter nouvelles fonctions
- ✅ Mode sélectif pratique
- ⚠️ Dépendances versions Ubuntu spécifiques
- ⚠️ Certaines URLs 404 (packages obsolètes)
- ❌ Pas de rollback automatique

---

## 🎓 Apprentissage et Concepts

### Patterns bash utilisés

#### 1. Here Documents (heredoc)

```bash
cat > file <<EOF
contenu
multiple
lignes
EOF
```

**Utilisé dans :** WIFI(), Screensavers(), Crontab()

---

#### 2. Command Substitution

```bash
RESULT=$(command)
```

**Utilisé dans :** PPA(), Main()

---

#### 3. Functions avec scope

```bash
MyFunc() {
  local var="value"  # Variable locale
  echo "$var"
}
```

---

#### 4. Conditional execution

```bash
[ -f /file ] && echo "exists"
command || echo "failed"
```

---

#### 5. Package managers pipelines

```bash
curl URL | sudo apt-key add -
wget -O- URL | gpg --dearmor | sudo tee /file
```

---

### Anti-patterns à éviter

#### ❌ 1. Exit on error désactivé

**Problème :**
```bash
#!/bin/bash
# Pas de set -e
```

**Solution :**
```bash
#!/bin/bash
set -euo pipefail
```

---

#### ❌ 2. Variables non quotées

**Problème :**
```bash
cd $HOME/dir
```

**Solution :**
```bash
cd "${HOME}/dir"
```

---

#### ❌ 3. Sudo dans fonctions

**Problème :** Demandes password multiples

**Solution :** Vérifier sudo au début

---

## 🔗 Intégrations

### Avec autres dotfiles

**setup.sh** est complémentaire à :

- **.zshrc** - Configuration shell (installée par ZSH())
- **.aliases** - Alias définis après installation
- **.vimrc** - Config Vim (Vundle installé par VIM())
- **bin/** - Scripts utilisables après Packages()

### Avec gestionnaires config

**Compatible avec :**
- GNU Stow
- Dotbot  
- Ansible (via Ansible())

---

## 📚 Ressources et Documentation

### Références externes

**Ubuntu/Debian :**
- [Ubuntu Packages](https://packages.ubuntu.com/)
- [Debian Packages](https://www.debian.org/distrib/packages)
- [Launchpad PPAs](https://launchpad.net/)

**Tools documentés :**
- [Oh-My-Zsh](https://ohmyz.sh/)
- [Docker Docs](https://docs.docker.com/)
- [Kubernetes Docs](https://kubernetes.io/docs/)
- [VSCodium](https://vscodium.com/)

---

## 🏆 Conclusion

### Points Forts

✅ **Exhaustivité :** 100+ outils couvrant tous besoins dev  
✅ **Modularité :** Installation sélective possible  
✅ **Maintenance :** Actif depuis 2017  
✅ **Personnalisable :** Facile adapter à ses besoins  
✅ **Documentation :** Commentaires utiles

### Points Faibles

⚠️ **Fragilité :** Dépend versions/URLs externes  
⚠️ **Testabilité :** Difficile tester sans VM  
⚠️ **Temps exécution :** Main() = 1-3h  
⚠️ **Gestion erreurs :** Basique  
⚠️ **Obsolescence :** Certaines fonctions datées

### Recommandations

**Usage recommandé :**
```bash
# NE PAS faire (risqué) :
./setup.sh

# FAIRE à la place :
./setup.sh Packages      # Base
./setup.sh Python        # Langages nécessaires
./setup.sh Docker        # Outils critiques
./setup.sh ZSH          # Shell
./setup.sh VSCodium     # IDE
# ... etc selon besoins
```

**Note globale : 8.5/10**

Script excellent comme base, nécessite adaptation et maintenance régulière.

---

*Documentation générée par BMAD Document Project Workflow*  
*Mode : Deep Dive - Exhaustive Analysis*  
*Date : 14 janvier 2026*  
*Fichier analysé : setup.sh (1689 lignes, 107 fonctions)*
