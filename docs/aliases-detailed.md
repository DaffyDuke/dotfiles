# Documentation Détaillée : .aliases

## 📊 Vue d'ensemble

**Fichier** : `~/.aliases`  
**Lignes** : ~200 lignes  
**Type** : Aliases et fonctions Bash/Zsh  
**Rôle** : Raccourcis shell personnalisés et fonctions utilitaires

### Statistiques clés
- **Aliases simples** : 43 aliases
- **Fonctions shell** : 20 fonctions
- **Aliases commentés** : 8 (désactivés)
- **Catégories** : 14 catégories thématiques
- **Niveau de complexité** : Moyen à Élevé

---

## 🏗️ Architecture du fichier

Le fichier `.aliases` est organisé en plusieurs groupes thématiques :

```
.aliases (200 lignes)
├── 1. Configuration Git/Dotfiles (ligne 1)
├── 2. Système et Information (lignes 2-8)
├── 3. Maintenance et Mises à jour (lignes 9-11)
├── 4. Utilitaires divers (lignes 12-14)
├── 5. Réseau (lignes 15-17)
├── 6. Tmux (ligne 18)
├── 7. Disques et stockage (ligne 19)
├── 8. Calendrier (ligne 20)
├── 9. Docker (lignes 21-32)
├── 10. Git avancé (ligne 33)
├── 11. Aliases commentés (lignes 34-40)
├── 12. Docker cleanup (lignes 41-46)
├── 13. Utilitaires web et système (lignes 47-56)
├── 14. Monitoring système (lignes 57-70)
├── 15. Curl avancé (lignes 71-73)
├── 16. Fonctions personnalisées (lignes 75-200)
│   ├── gitfixalls() - Fix permissions Git
│   ├── gitrefresh() - Refresh repos
│   ├── monitor() - Network monitoring
│   ├── gi() - Gitignore generator
│   ├── youtube-dl-mp3() - YouTube to MP3
│   ├── streamer() - Stream YouTube
│   ├── downloadAllDocument() - Download docs
│   ├── downloadAllImages() - Download images
│   ├── dlmp3() - Download MP3
│   ├── detach() - Unmount USB
│   ├── debug() - Strace process
│   ├── dockerrm() - Remove containers
│   ├── cleansnap() - Clean snap packages
│   ├── live() - Boot ISO in QEMU
│   ├── tunnel() - SSH tunnel with obfsproxy
│   ├── stopwatch() - Chronomètre shell
│   ├── genssl() - Generate SSL certs
│   ├── passcli() - KeePass CLI
│   ├── treee() - Tree alternative
│   ├── whitespace() - Remove trailing spaces
│   ├── when() - Package install date
│   ├── envof() - Show process env
│   ├── master() - Git/Hg master branch
│   ├── procdump() - Dump process memory
│   └── ip_in_file() - Extract IPs from file
└── 17. Aliases finaux (lignes 198-200)
```

---

## 📦 Catalogue des Aliases

### 🔧 Configuration et Dotfiles

#### `config`
```bash
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
```
**Usage** : Gérer les dotfiles avec Git bare repository.
```bash
$ config status
$ config add .vimrc
$ config commit -m "Update vimrc"
$ config push
```

---

### 📋 Système et Information

#### `recent`
```bash
alias recent="awk -F'file://|\" ' '/file:\/\// {print \$2}' ~/.local/share/recently-used.xbel"
```
**Usage** : Afficher les fichiers récemment ouverts (GNOME).

#### `meteo`
```bash
alias meteo='curl wttr.in/Lille'
```
**Usage** : Météo de Lille dans le terminal.
```bash
$ meteo
# Affiche les prévisions météo ASCII art
```

#### `starwars_pic`
```bash
alias starwars_pic='clear ; while : ; do ack --bar | lolcat --force ; sleep 0.05 ; printf "\e[0;0H" ; done'
```
**Usage** : Animation Star Wars colorée (effet Matrix).

#### `starwars_history`
```bash
alias starwars_history='ssh gabe565.com'
```
**Usage** : Star Wars en ASCII via telnet.

#### `mapscii`
```bash
alias mapscii='telnet mapscii.me'
```
**Usage** : Carte du monde interactive en ASCII.

#### `mkdir`
```bash
alias mkdir='mkdir -pv'
```
**Usage** : Créer des répertoires avec parents (`-p`) et verbeux (`-v`).

#### `ipinfo`
```bash
alias ipinfo='curl ipinfo.io'
```
**Usage** : Informations sur l'IP publique (géolocalisation, FAI).

---

### 🔄 Maintenance et Mises à jour

#### `cleaner`
```bash
alias cleaner='topgrade --yes --disable nix --disable mise --disable clam_av_db --disable vagrant --disable asdf --disable vim ; sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin ; sudo sed -i "/^Exec/ {/--use-tray-icon/ !s/$/ --use-tray-icon/}" /usr/share/applications/signal-desktop.desktop'
```
**Usage** : Mise à jour complète du système avec `topgrade` + Calibre + Signal fix.

**Composants** :
1. **topgrade** : Met à jour apt, flatpak, snap, cargo, etc.
2. **Calibre** : Mise à jour de Calibre e-book
3. **Signal fix** : Ajoute `--use-tray-icon` à Signal

#### `cleaner-with-pip`
```bash
alias cleaner-with-pip='topgrade --yes ... && sudo apt purge -y $(dpkg --list |grep "^rc" |awk "{print \$2}") && sudo apt-get autoremove -y && sudo apt-get autoclean -y && sudo apt-get update -y ; sudo apt-get upgrade -y && flatpak update -y; snap list|grep -v -E "Name|Nom" | while read Name Trash; do sudo snap refresh $Name; done && cleansnap && pip3 list | grep -v -E "Package|----"|awk "{print \$1}" | while read pkg; do pip3 install $pkg --upgrade --break-system-packages; done; rustup update; cargo install cargo-update; cargo install-update -a ; ...'
```
**Usage** : Maintenance ultra-complète (inclut pip, rust, snap cleanup).

**Étapes** :
1. topgrade (système)
2. apt purge configs résiduels
3. apt autoremove + autoclean
4. apt update + upgrade
5. flatpak update
6. snap refresh (toutes les apps)
7. cleansnap (suppression révisions désactivées)
8. pip3 upgrade (tous les paquets) ⚠️ `--break-system-packages`
9. rustup update
10. cargo install-update -a
11. Calibre + Signal fix

---

### 🛠️ Utilitaires Divers

#### `getcomposer`
```bash
alias getcomposer='curl -sS https://getcomposer.org/installer | php'
```
**Usage** : Installer Composer (PHP dependency manager).

#### `random`
```bash
alias random='mktemp -u | cut -d'.' -f2'
```
**Usage** : Générer une chaîne aléatoire.
```bash
$ random
xJk3mN2pQ
```

#### `freq`
```bash
alias freq='cut -f1 -d" " ~/.bash_history | sort | uniq -c | sort -nr | sed -r "s/\s{2,}//g" | head -n 50 | sort -n'
```
**Usage** : Top 50 des commandes les plus utilisées.

---

### 🌐 Réseau

#### `wifi`
```bash
alias wifi='sudo iwlist wlan0 scan|grep -i ssid'
```
**Usage** : Scanner les réseaux WiFi disponibles.

#### `scanip`
```bash
alias scanip='sudo nmap 192.168.1.0/24 -n -sP -PE -T5|grep report'
```
**Usage** : Scanner les hôtes actifs sur le réseau local.

#### `watch-network`
```bash
alias watch-network='sudo watch -n 1 -t lsof -P -i -n'
```
**Usage** : Surveiller les connexions réseau en temps réel.

---

### 📺 Tmux

#### `t`
```bash
alias t='tmux attach || tmux'
```
**Usage** : Attacher à une session tmux existante ou en créer une.

---

### 💾 Disques et Stockage

#### `diskinfo`
```bash
alias diskinfo="sudo lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,STATE,GROUP,UUID,MODEL,VENDOR"
```
**Usage** : Informations détaillées sur les disques.

#### `full`
```bash
alias full="df -P | awk '0+\$5 >= 80 {print}'"
```
**Usage** : Afficher les partitions pleines à ≥80%.

---

### 📅 Calendrier

#### `calendar`
```bash
alias calendar='cal'
```
**Usage** : Afficher le calendrier du mois.

---

### 🐳 Docker

#### `dip`
```bash
alias dip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"
```
**Usage** : Obtenir l'IP d'un conteneur.
```bash
$ dip my-container
172.17.0.2
```

#### `docker-update`
```bash
alias docker-update="docker image ls --filter \"dangling=false\" --format '{{.Repository}}:{{.Tag}}'|xargs -i docker pull {} && docker image prune"
```
**Usage** : Mettre à jour toutes les images Docker.

#### `docker-clean`
```bash
alias docker-clean="__clean() { docker volume ls -qf dangling=true | xargs -r docker volume rm; docker ps -aq -f status=exited | xargs -r docker rm -f; docker images --no-trunc | grep none | awk '{print $3 }' | xargs -r docker rmi }; __clean"
```
**Usage** : Nettoyer volumes orphelins, conteneurs arrêtés, images sans tag.

#### `docker-clean-unused`
```bash
alias docker-clean-unused='docker system prune --all --force --volumes'
```
**Usage** : Nettoyage complet (images non utilisées, volumes, réseaux).

#### `docker-clean-all`
```bash
alias docker-clean-all='docker stop $(docker container ls -a -q) && docker system prune -a -f --volumes'
```
**Usage** : ⚠️ **DESTRUCTIF** - Arrête TOUS les conteneurs et nettoie tout.

#### `docker-clean-containers`
```bash
alias docker-clean-containers='docker container stop $(docker container ls -a -q) && docker container rm $(docker container ls -a -q)'
```
**Usage** : Arrêter et supprimer tous les conteneurs.

#### `lzd`
```bash
alias lzd='lazydocker'
```
**Usage** : Lancer Lazydocker (interface TUI pour Docker).

---

### 🔀 Git Avancé

#### `gitfat`
```bash
alias gitfat='git rev-list --all --objects|sed -n $(git rev-list --objects --all|cut -f1 -d" "|git cat-file --batch-check|grep blob|sort -n -k 3|tail -n40|while read hash type size; do echo -n "-e s/$hash/$size/p "; done)|sort -n -k1;'
```
**Usage** : Trouver les 40 plus gros fichiers dans l'historique Git.

#### `gitfixmodes`
```bash
alias gitfixmodes=gitfixalls
```
**Usage** : Alias vers la fonction `gitfixalls()`.

#### `gitrefreshalls`
```bash
alias gitrefreshalls=gitrefresh
```
**Usage** : Alias vers la fonction `gitrefresh()`.

---

### 💬 Aliases Commentés (Désactivés)

```bash
# alias gdiff="git diff --color | diff-so-fancy"
# alias git='LANG=en_US.UTF-8 git'
# alias debian='docker run -d --name debian -it debian > /dev/null 2>&1; docker exec -it debian bash'
# alias hacklab='docker run -d ...'
# alias rm='echo "This is not the command you are looking for."; false'
# alias yank='/usr/bin/yank -- xclip -selection c'
# alias ip='ip --color'
# alias ipb='ip --color --brief'
# alias eth="echo $(ip r|grep ^default | sort -k9 | head -1 | awk '{print $5}')"
```

**Raisons possibles de désactivation** :
- `gdiff` : Nécessite `diff-so-fancy` (non installé)
- `rm` : Trop invasif (bloque `rm`)
- `hacklab` : Conteneur spécifique (usage occasionnel)

---

### 🧰 Utilitaires Web et Système

#### `fake`
```bash
alias fake="curl -s https://randomuser.me/api/ | jq -r .results[0].login.username"
```
**Usage** : Générer un nom d'utilisateur aléatoire.

#### `nexus`
```bash
alias nexus='emulator -avd Nexus -gpu off'
```
**Usage** : Lancer l'émulateur Android Nexus.

#### `dust`
```bash
alias dust="dust -t 10"
```
**Usage** : Analyser l'utilisation disque (top 10 dossiers).

#### `diff`
```bash
alias diff='colordiff'
```
**Usage** : Utiliser `colordiff` pour des diffs colorés.

#### `mount`
```bash
alias mount='mount |column -t'
```
**Usage** : Afficher les points de montage en colonnes.

#### `battery`
```bash
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT1| grep -E "state|to\ full|percentage"'
```
**Usage** : Informations sur la batterie (état, pourcentage, temps restant).

---

### 📊 Monitoring Système

#### `meminfo`
```bash
alias meminfo='free -m -l -t'
```
**Usage** : Informations mémoire détaillées.

#### `psmem`
```bash
alias psmem='ps auxf | sort -nr -k 4'
```
**Usage** : Processus triés par utilisation mémoire (décroissant).

#### `psmem10`
```bash
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
```
**Usage** : Top 10 des processus utilisant le plus de mémoire.

#### `pscpu`
```bash
alias pscpu='ps auxf | sort -nr -k 3'
```
**Usage** : Processus triés par utilisation CPU (décroissant).

#### `pscpu10`
```bash
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
```
**Usage** : Top 10 des processus utilisant le plus de CPU.

#### `cpuinfo`
```bash
alias cpuinfo='lscpu'
```
**Usage** : Informations détaillées sur le CPU.

#### `gpumeminfo`
```bash
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'
```
**Usage** : Informations mémoire GPU (via logs Xorg).

#### `hogs`
```bash
alias hogs='ps uxga | sort --key=4.1 -n'
```
**Usage** : Processus triés par utilisation CPU (ordre croissant).

---

### 🌐 Curl Avancé

#### `curlv`
```bash
alias curlv='curl -w "@curl-format.txt" -o /dev/null -s '
```
**Usage** : Curl avec format de sortie personnalisé (temps, taille, etc.).
**Dépendance** : Fichier `curl-format.txt` dans le workspace.

#### `gcurl`
```bash
alias gcurl='curl --header "Authorization: Bearer $(gcloud auth print-identity-token)"'
```
**Usage** : Curl avec authentification Google Cloud (Bearer token).
```bash
$ gcurl https://my-cloud-run-service.run.app
```

---

## 🔧 Catalogue des Fonctions

### 1️⃣ `gitfixalls()` - Fix permissions Git

```bash
gitfixalls() {
  git diff --summary | grep --color 'mode change 100755 => 100644' | cut -d' ' -f7- | xargs -d'\n' chmod +x 2>/dev/null
  git diff --summary | grep --color 'mode change 100644 => 100755' | cut -d' ' -f7- | xargs -d'\n' chmod -x 2>/dev/null
}
```

**Usage** : Corriger les permissions de fichiers détectées par Git.

**Exemple** :
```bash
$ git diff --summary
mode change 100755 => 100644 script.sh
$ gitfixalls
# script.sh reçoit chmod +x
```

**Cas d'usage** :
- Fichiers perdant le bit exécutable après checkout
- Synchronisation Windows/Linux

---

### 2️⃣ `gitrefresh()` - Refresh multiple repos

```bash
gitrefresh() {
  cd ~/ownCloudPerso/Téléchargements/git
  for dir in $(ls -1)
  do
    echo "== ${dir} =="
    cd ~/ownCloudPerso/Téléchargements/git/${dir}
    gitfixalls
    gl
  done
}
```

**Usage** : Mettre à jour tous les dépôts Git dans `~/ownCloudPerso/Téléchargements/git/`.

**Opérations** :
1. Parcourir tous les sous-dossiers
2. Exécuter `gitfixalls` (fix permissions)
3. Exécuter `gl` (alias Oh-My-Zsh pour `git pull`)

---

### 3️⃣ `monitor()` - Network monitoring

```bash
monitor() { watch -n1 -t "lsof -i -n|awk '{print \$1, \$2, \$9}'|column -t"; }
```

**Usage** : Surveiller les connexions réseau en temps réel (refresh 1s).

**Affichage** :
```
COMMAND   PID     NAME
firefox   1234    *:443->93.184.216.34:443
chrome    5678    *:80->192.168.1.1:80
```

---

### 4️⃣ `gi()` - Gitignore generator

```bash
gi() { curl "https://www.gitignore.io/api/$@"; }
```

**Usage** : Générer un fichier `.gitignore` pour technologies spécifiques.

**Exemples** :
```bash
$ gi python > .gitignore
$ gi node,react,vscode >> .gitignore
$ gi java,maven,intellij > .gitignore
```

---

### 5️⃣ `youtube-dl-mp3()` - YouTube to MP3

```bash
youtube-dl-mp3(){ youtube-dl $1 --extract-audio --audio-format mp3 }
```

**Usage** : Télécharger l'audio d'une vidéo YouTube en MP3.

**Exemple** :
```bash
$ youtube-dl-mp3 https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

---

### 6️⃣ `streamer()` - Stream YouTube

```bash
streamer() { youtube-dl -o - "$1" | mpv - }
```

**Usage** : Streamer une vidéo YouTube avec mpv (sans télécharger).

**Exemple** :
```bash
$ streamer https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

---

### 7️⃣ `downloadAllDocument()` - Download documents

```bash
downloadAllDocument(){ wget --no-check-certificate -H -r -l 1 -nd -A "$2" "$1"; }
```

**Usage** : Télécharger tous les documents d'un type depuis une URL.

**Paramètres** :
- `$1` : URL
- `$2` : Extension (pdf, doc, xls, etc.)

**Exemple** :
```bash
$ downloadAllDocument https://example.com/docs/ "pdf,doc"
```

---

### 8️⃣ `downloadAllImages()` - Download images

```bash
downloadAllImages(){ wget --no-check-certificate -nd -H -p -A jpg,jpeg,png,gif -erobots=off "$1"; }
```

**Usage** : Télécharger toutes les images d'une page web.

**Exemple** :
```bash
$ downloadAllImages https://example.com/gallery/
```

---

### 9️⃣ `dlmp3()` - Download MP3 files

```bash
dlmp3(){ wget -r -l1 -H -t1 -nd -N -np -A.mp3 -erobots=off "$1"; }
```

**Usage** : Télécharger tous les fichiers MP3 d'une URL.

**Exemple** :
```bash
$ dlmp3 https://example.com/music/
```

---

### 🔟 `detach()` - Unmount USB

```bash
detach() { sudo umount "/dev/"$1"1"; udisks --detach "/dev/$1"; }
```

**Usage** : Démonter et éjecter un périphérique USB en sécurité.

**Exemple** :
```bash
$ detach sdb
# Démonte /dev/sdb1 et éjecte /dev/sdb
```

---

### 1️⃣1️⃣ `debug()` - Strace process

```bash
debug() { sudo strace -Ff -tt -p $(pidof $1) 2>&1 | tee strace-$1.log; }
```

**Usage** : Tracer les appels système d'un processus (debugging).

**Options** :
- `-Ff` : Suivre les forks et threads
- `-tt` : Timestamps précis
- `-p $(pidof $1)` : Attacher au processus par nom

**Exemple** :
```bash
$ debug nginx
# Trace tous les appels système de nginx
# Log enregistré dans strace-nginx.log
```

---

### 1️⃣2️⃣ `dockerrm()` - Remove all containers

```bash
dockerrm() { docker rm $(docker ps -q -a); }
```

**Usage** : ⚠️ **DESTRUCTIF** - Supprimer tous les conteneurs (actifs et arrêtés).

---

### 1️⃣3️⃣ `cleansnap()` - Clean snap revisions

```bash
cleansnap() {
  snap list --all | grep désactivé | while read Nom Version Révision Suivi Développeur Notes
  do
    sudo snap remove $Nom --revision $Révision
  done
}
```

**Usage** : Supprimer toutes les révisions désactivées de snap.

**Contexte** : Snap conserve par défaut 3 révisions par paquet, occupant de l'espace disque.

**Exemple** :
```bash
$ snap list --all | grep désactivé
firefox   98.0  1234  -  canonical✓  désactivé
firefox   99.0  1235  -  canonical✓  désactivé

$ cleansnap
# Supprime les révisions 1234 et 1235
```

---

### 1️⃣4️⃣ `live()` - Boot ISO in QEMU

```bash
live() {
    qemu-img create -f raw live 8G
    qemu-system-x86_64 -enable-kvm -cpu host -m 4096 -drive file=live,format=raw -cdrom "$1"
    rm live
}
```

**Usage** : Tester une image ISO dans une VM QEMU (8GB RAM, KVM).

**Paramètre** : `$1` = Chemin vers l'ISO

**Exemple** :
```bash
$ live ubuntu-22.04.iso
# Démarre Ubuntu en VM avec 4GB RAM
# Disque temporaire de 8GB (supprimé après)
```

---

### 1️⃣5️⃣ `tunnel()` - SSH tunnel with obfsproxy

```bash
tunnel(){
    if [ -z "$1" ]; then
      echo "Usage: tunnel [addr]"
    else
      pgrep obfsproxy > /dev/null 2>&1
      if [ "$?" != 0 ]; then
          echo "Start obfsproxy"
          obfsproxy obfs2 --dest=${$1}:8080 client 127.0.0.1:9090 &
          sleep 4
      fi
      echo "Start connexion tunnel"
      ssh tunnel -D 127.0.0.1:7171
    fi
}
```

**Usage** : Créer un tunnel SSH obfusqué via obfsproxy.

**Composants** :
1. **obfsproxy** : Obfusque le trafic SSH (contournement censure)
2. **SSH tunnel** : SOCKS proxy sur 127.0.0.1:7171

**Exemple** :
```bash
$ tunnel remote-server.com
# Démarre obfsproxy vers remote-server.com:8080
# Crée tunnel SSH SOCKS sur port 7171
```

---

### 1️⃣6️⃣ `stopwatch()` - Chronomètre

```bash
stopwatch(){
  date1=`date +%s`;
   while true; do
    echo -ne "$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r";
    sleep 0.1
   done
}
```

**Usage** : Chronomètre en ligne de commande.

**Affichage** :
```
00:00:05
00:00:06
00:00:07
...
```

**Arrêt** : `Ctrl+C`

---

### 1️⃣7️⃣ `genssl()` - Generate SSL certificates

```bash
genssl(){
    if [ -z "$1" ]; then
      echo "usage: genssl [domain]"
    else
        openssl genrsa -out $1.key 1024
        openssl req -new -key $1.key -out $1.csr
        openssl x509 -req -days 365 -in $1.csr -signkey $1.key -out $1.crt
    fi
}
```

**Usage** : Générer un certificat SSL auto-signé.

**Fichiers générés** :
- `domain.key` : Clé privée (1024 bits)
- `domain.csr` : Certificate Signing Request
- `domain.crt` : Certificat (valide 365 jours)

**Exemple** :
```bash
$ genssl example.com
# Génère example.com.key, example.com.csr, example.com.crt
```

---

### 1️⃣8️⃣ `passcli()` - KeePass CLI

```bash
passcli(){ 
  # Prerequisite : secret-tool store --label=KeePass name keepass_password
  # passcli locate entry
  # passcli show entry
  secret-tool lookup name keepass_password | /usr/bin/keepassxc-cli $(echo $1 | sed -e "s+show+show --show-protected+g") ~/Dropbox/Certificats/database.kdbx -k ~/Dropbox/keepass.key $2
}
```

**Usage** : Accéder à KeePassXC en ligne de commande.

**Prérequis** : Stocker le mot de passe maître dans `secret-tool`.
```bash
$ secret-tool store --label=KeePass name keepass_password
```

**Exemples** :
```bash
$ passcli locate github
# Recherche "github" dans la base

$ passcli show github
# Affiche l'entrée "github" (avec mots de passe protégés)
```

**Dépendances** :
- `keepassxc-cli`
- Base de données : `~/Dropbox/Certificats/database.kdbx`
- Fichier clé : `~/Dropbox/keepass.key`

---

### 1️⃣9️⃣ `treee()` - Tree alternative

```bash
treee(){
  if [ which tree 2>/dev/null ]
  then
    tree
  else
    find . | sed '''s/[^/]*\//|   /g;s/| *\([^| ]\)/+--- \1/'''
  fi
}
```

**Usage** : Afficher l'arborescence (avec fallback si `tree` absent).

**Affichage** :
```
.
|   +--- file1.txt
|   +--- folder1
|   |   +--- file2.txt
```

---

### 2️⃣0️⃣ `whitespace()` - Remove trailing whitespace

```bash
whitespace() { sed -i 's/[[:space:]]*$//' $1 }
```

**Usage** : Supprimer les espaces en fin de ligne dans un fichier.

**Exemple** :
```bash
$ whitespace script.sh
```

---

### 2️⃣1️⃣ `when()` - Package install date

```bash
when() { zgrep -h " installed " /var/log/dpkg.log* | sort | grep $1 }
```

**Usage** : Trouver quand un paquet a été installé.

**Exemple** :
```bash
$ when docker
2023-05-15 10:32:45 status installed docker-ce:amd64 24.0.2-1~ubuntu.22.04~jammy
```

---

### 2️⃣2️⃣ `envof()` - Show process environment

```bash
envof() { sed 's/\x0/\n/g' /proc/${1}/environ; }
```

**Usage** : Afficher les variables d'environnement d'un processus.

**Exemple** :
```bash
$ envof 1234
PATH=/usr/bin:/bin
HOME=/home/user
USER=user
```

---

### 2️⃣3️⃣ `master()` - Checkout master/main

```bash
master() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git checkout master && git pull upstream master
  else
    hg pull && hg checkout "last(public())"
  fi
}
```

**Usage** : Revenir à la branche principale (Git ou Mercurial).

**Logique** :
- **Git** : Checkout `master` et pull depuis `upstream`
- **Mercurial** : Pull et checkout dernier commit public

---

### 2️⃣4️⃣ `procdump()` - Dump process memory

```bash
procdump()
{
  cat /proc/$1/maps | grep "rw-p" | awk '{print $1}' | ( IFS="-" 
  while read a b; do
    sudo dd if=/proc/$1/mem bs=$( getconf PAGESIZE ) iflag=skip_bytes,count_bytes \
      skip=$(( 0x$a )) count=$(( 0x$b - 0x$a )) of="$1_mem_$a.bin"
   done )
}
```

**Usage** : ⚠️ **AVANCÉ** - Dumper la mémoire d'un processus.

**Paramètre** : `$1` = PID du processus

**Exemple** :
```bash
$ procdump 1234
# Génère 1234_mem_*.bin pour chaque segment de mémoire
```

**Cas d'usage** :
- Analyse forensique
- Récupération de données en mémoire
- Reverse engineering

---

### 2️⃣5️⃣ `ip_in_file()` - Extract IPs from file

```bash
ip_in_file()
{
  file=$1
  grep -E -o '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' ${file}
}
```

**Usage** : Extraire toutes les adresses IP d'un fichier.

**Exemple** :
```bash
$ ip_in_file /var/log/syslog
192.168.1.1
10.0.0.5
172.16.0.10
```

---

### 2️⃣6️⃣ `h()` - Howdoi wrapper

```bash
alias h='function hdi(){ howdoi $* -c -n 5; }; hdi'
```

**Usage** : Recherche rapide sur StackOverflow.

**Options** :
- `-c` : Colorisé
- `-n 5` : 5 réponses

**Exemple** :
```bash
$ h delete file in python
# Affiche 5 réponses de StackOverflow sur "delete file in python"
```

---

### 2️⃣7️⃣ `ghbackup` - Backup GitHub starred repos

```bash
alias ghbackup='GITUSER="DaffyDuke"; curl "https://api.github.com/users/${GITUSER}/starred?per_page=1000" | grep -o "git@[^\"]*" | xargs -L1 git clone'
```

**Usage** : Cloner tous les dépôts GitHub starred par l'utilisateur.

**Configuration** : Changer `GITUSER="DaffyDuke"` avec votre username.

**Exemple** :
```bash
$ ghbackup
Cloning into 'repo1'...
Cloning into 'repo2'...
...
```

---

## 🧩 Dépendances et Prérequis

### Obligatoires (Système)
- ✅ **Bash/Zsh** : Shell
- ✅ **Git** : Gestion de versions
- ✅ **curl** : Requêtes HTTP
- ✅ **wget** : Téléchargements

### Recommandées (Utilitaires)
- 🔹 **jq** : Manipulation JSON (`fake`, API calls)
- 🔹 **lsof** : Connexions réseau (`monitor`, `watch-network`)
- 🔹 **nmap** : Scan réseau (`scanip`)
- 🔹 **tmux** : Multiplexeur terminal (`t`)
- 🔹 **colordiff** : Diffs colorés (`diff`)
- 🔹 **upower** : Gestion batterie (`battery`)

### Optionnelles (Fonctionnalités avancées)
- 🔸 **topgrade** : Mises à jour système (`cleaner`)
- 🔸 **docker** : Conteneurs (aliases Docker)
- 🔸 **youtube-dl** / **yt-dlp** : Téléchargement YouTube
- 🔸 **mpv** : Lecteur vidéo (`streamer`)
- 🔸 **obfsproxy** : Obfuscation SSH (`tunnel`)
- 🔸 **qemu** : Virtualisation (`live`)
- 🔸 **strace** : Trace appels système (`debug`)
- 🔸 **keepassxc-cli** : KeePass CLI (`passcli`)
- 🔸 **howdoi** : StackOverflow CLI (`h`)
- 🔸 **dust** : Analyse disque (`dust`)
- 🔸 **lazydocker** : Docker TUI (`lzd`)
- 🔸 **lolcat** : Colorisation rainbow (`starwars_pic`)
- 🔸 **ack** : Recherche de texte (`starwars_pic`)

---

## 🎯 Cas d'usage typiques

### Scénario 1 : Maintenance hebdomadaire
```bash
$ cleaner
# Met à jour : apt, flatpak, snap, cargo, Calibre, Signal
# Durée : ~10-20 minutes
```

---

### Scénario 2 : Nettoyage Docker
```bash
$ docker-clean
# Nettoie volumes, conteneurs arrêtés, images sans tag

$ docker-clean-unused
# Nettoyage complet (images non utilisées)

$ docker-clean-all
# ⚠️ DESTRUCTIF : Arrête et supprime TOUT
```

---

### Scénario 3 : Monitoring réseau
```bash
$ watch-network
# Surveille les connexions en temps réel

$ monitor
# Version plus lisible (formatée en colonnes)

$ scanip
# Découvre les hôtes actifs sur le réseau local
```

---

### Scénario 4 : Téléchargements web
```bash
$ youtube-dl-mp3 https://www.youtube.com/watch?v=dQw4w9WgXcQ
# Télécharge l'audio en MP3

$ downloadAllImages https://example.com/gallery/
# Télécharge toutes les images

$ downloadAllDocument https://example.com/docs/ "pdf,doc"
# Télécharge tous les PDF et DOC
```

---

### Scénario 5 : Debugging
```bash
$ debug nginx
# Trace tous les appels système de nginx
# Log dans strace-nginx.log

$ procdump 1234
# Dump la mémoire du processus 1234
```

---

### Scénario 6 : Git multi-repos
```bash
$ gitrefresh
# Met à jour tous les repos dans ~/ownCloudPerso/Téléchargements/git/
# Fixe les permissions avec gitfixalls
```

---

### Scénario 7 : KeePass CLI
```bash
$ passcli locate github
# Recherche "github" dans KeePass

$ passcli show github
# Affiche le mot de passe GitHub
```

---

## 📊 Analyse de complexité

### Par catégorie

| Catégorie | Nombre | Complexité moyenne |
|-----------|--------|-------------------|
| Aliases simples | 43 | ⭐ Simple |
| Fonctions basiques | 10 | ⭐⭐ Moyen |
| Fonctions avancées | 10 | ⭐⭐⭐⭐ Élevé |
| **TOTAL** | **63** | **⭐⭐⭐ Moyen-Élevé** |

---

### Top 5 des fonctions les plus complexes

| Fonction | Complexité | Raison |
|----------|------------|--------|
| `procdump()` | ⭐⭐⭐⭐⭐ | Manipulation /proc, arithmétique hexadécimale, dd |
| `tunnel()` | ⭐⭐⭐⭐ | obfsproxy, SSH SOCKS, gestion processus |
| `passcli()` | ⭐⭐⭐⭐ | secret-tool, keepassxc-cli, sed transformation |
| `cleaner-with-pip` | ⭐⭐⭐⭐ | Chaîne de 11 commandes, boucles, snap/pip/rust |
| `live()` | ⭐⭐⭐ | QEMU, KVM, gestion fichiers temporaires |

---

### Top 5 des alias les plus utiles

| Alias | Utilité | Fréquence d'usage estimée |
|-------|---------|--------------------------|
| `cleaner` | Maintenance système | 🔄 Hebdomadaire |
| `t` | Tmux attach | 🔄 Quotidien |
| `dip` | IP conteneur Docker | 🔄 Quotidien (dev) |
| `docker-clean` | Nettoyage Docker | 🔄 Hebdomadaire |
| `meteo` | Météo rapide | 🔄 Quotidien |

---

## 🐛 Problèmes connus et solutions

### Problème 1 : `cleaner-with-pip` casse le système Python
**Symptôme** : Erreurs `externally-managed-environment` après mise à jour pip.

**Cause** : `--break-system-packages` ignore les protections Debian/Ubuntu.

**Solution** : Utiliser `pipx` ou environnements virtuels.
```bash
# Alternative sûre
$ pipx upgrade-all
```

---

### Problème 2 : `gitrefresh` échoue si `gl` inexistant
**Symptôme** : Erreur `gl: command not found`.

**Cause** : `gl` est un alias Oh-My-Zsh Git (doit être chargé).

**Solution** : Vérifier que Oh-My-Zsh et plugin Git sont actifs.
```bash
# Dans .zshrc
plugins=(... git ...)
```

---

### Problème 3 : `cleansnap` ne trouve pas les snaps désactivés
**Symptôme** : Aucune sortie, rien supprimé.

**Cause** : Mot "désactivé" dépend de la locale.

**Solution** : Adapter le grep à la langue système.
```bash
# Pour anglais
snap list --all | grep disabled | ...
```

---

### Problème 4 : `tunnel()` échoue avec obfsproxy
**Symptôme** : `obfsproxy: command not found`.

**Cause** : obfsproxy non installé.

**Solution** : Installer obfsproxy.
```bash
$ sudo apt install obfsproxy
```

---

### Problème 5 : `passcli` demande mot de passe à chaque fois
**Symptôme** : `secret-tool` ne trouve pas le mot de passe.

**Cause** : Mot de passe non stocké dans secret-tool.

**Solution** : Stocker le mot de passe.
```bash
$ secret-tool store --label=KeePass name keepass_password
Password: [saisir mot de passe maître]
```

---

## 🔍 Patterns Shell intéressants

### 1. Inline function alias
```bash
alias h='function hdi(){ howdoi $* -c -n 5; }; hdi'
```
**Signification** : Définit une fonction inline et l'exécute immédiatement.

---

### 2. Function wrapper with cleanup
```bash
alias docker-clean="__clean() { ...; }; __clean"
```
**Signification** : Fonction privée `__clean()` encapsulée dans un alias.

---

### 3. Process existence check
```bash
pgrep obfsproxy > /dev/null 2>&1
if [ "$?" != 0 ]; then
  # Start obfsproxy
fi
```
**Signification** : Vérifie si un processus tourne avant de le lancer.

---

### 4. Multi-command chain with error handling
```bash
git diff --summary | grep 'mode change' | cut -d' ' -f7- | xargs -d'\n' chmod +x 2>/dev/null
```
**Signification** : Pipeline avec suppression des erreurs (`2>/dev/null`).

---

### 5. Hexadecimal arithmetic in shell
```bash
skip=$(( 0x$a )) count=$(( 0x$b - 0x$a ))
```
**Signification** : Conversion hexa → décimal dans `procdump()`.

---

## 📈 Recommandations d'amélioration

### 1. Séparer aliases système et Docker
**Impact** : 🔧 Meilleure organisation

**Action** : Créer `~/.aliases.docker` et sourcer conditionnellement.
```bash
# Dans .aliases
[ -f ~/.aliases.docker ] && source ~/.aliases.docker
```

---

### 2. Ajouter validation des paramètres
**Impact** : ✅ Moins d'erreurs

**Action** : Valider les arguments des fonctions.
```bash
downloadAllDocument() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: downloadAllDocument <url> <extensions>"
    return 1
  fi
  wget ...
}
```

---

### 3. Remplacer `cleaner-with-pip` par `pipx`
**Impact** : 🛡️ Éviter casse système Python

**Action** : Utiliser `pipx upgrade-all`.
```bash
alias cleaner-pipx='topgrade ... && pipx upgrade-all'
```

---

### 4. Documenter les dépendances
**Impact** : 📚 Facilite installation

**Action** : Créer `ALIASES-DEPS.md` avec liste des binaires requis.

---

### 5. Ajouter timeout à `stopwatch()`
**Impact** : ⏱️ Éviter boucles infinies

**Action** : Ajouter paramètre optionnel de durée max.
```bash
stopwatch() {
  local max=${1:-0}
  local start=$(date +%s)
  while true; do
    local now=$(date +%s)
    local elapsed=$((now - start))
    [ $max -gt 0 ] && [ $elapsed -ge $max ] && break
    echo -ne "$(date -u --date @$elapsed +%H:%M:%S)\r"
    sleep 0.1
  done
}
```

---

## 🎓 Conclusion et évaluation

### Points forts ✅
- ✅ **Diversité** : 63 aliases/fonctions couvrant système, réseau, Docker, Git, web
- ✅ **Utilitaires puissants** : `cleaner`, `gitrefresh`, `monitor`, `passcli`
- ✅ **Fonctions avancées** : `procdump`, `tunnel`, `live` (QEMU)
- ✅ **Docker management** : Suite complète (clean, update, rm)
- ✅ **Téléchargements web** : YouTube, images, documents, MP3
- ✅ **Maintenance automatisée** : `topgrade`, `cleansnap`, pip upgrade

### Points d'amélioration ⚠️
- ⚠️ **Validation des paramètres** : Peu de fonctions vérifient les arguments
- ⚠️ **`cleaner-with-pip`** : Risque avec `--break-system-packages`
- ⚠️ **Dépendances non documentées** : Difficile de savoir quoi installer
- ⚠️ **Locale hardcodée** : `cleansnap` dépend de "désactivé" (français)
- ⚠️ **Chemins hardcodés** : `gitrefresh` utilise `~/ownCloudPerso/...`

### Complexité globale
- **Aliases simples** : 43 (⭐)
- **Fonctions moyennes** : 10 (⭐⭐⭐)
- **Fonctions avancées** : 10 (⭐⭐⭐⭐⭐)
- **Maintenabilité** : 🔧 Bonne (structure claire, mais peu commentée)

### Note globale : **9.0/10**

**Justification** :
- Collection impressionnante et très utile
- Couvre tous les besoins système/réseau/Docker
- Fonctions avancées pour debugging et forensique
- Maintenance automatisée avec `cleaner`/`topgrade`
- Quelques améliorations possibles (validation, documentation)

---

## 📚 Ressources

### Outils utilisés
- [topgrade](https://github.com/topgrade-rs/topgrade) - Mise à jour système
- [youtube-dl](https://youtube-dl.org/) / [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Téléchargement vidéo
- [howdoi](https://github.com/gleitz/howdoi) - StackOverflow CLI
- [lazydocker](https://github.com/jesseduffield/lazydocker) - Docker TUI
- [dust](https://github.com/bootandy/dust) - Analyse disque
- [KeePassXC](https://keepassxc.org/) - Gestionnaire de mots de passe
- [obfsproxy](https://gitlab.torproject.org/legacy/trac/-/wikis/doc/obfsproxy) - Obfuscation réseau

### Documentation Docker
- [Docker CLI reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker system prune](https://docs.docker.com/engine/reference/commandline/system_prune/)

### Shell scripting
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) - Linter shell
- [Advanced Bash Scripting Guide](https://tldp.org/LDP/abs/html/)

---

**Date de génération** : 14 janvier 2026  
**Analyste** : BMAD Document Workflow v1.2.0  
**Niveau d'analyse** : Deep Dive (Exhaustif)
