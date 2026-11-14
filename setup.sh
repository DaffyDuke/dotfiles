#!/bin/bash

Setup() {
  # Prerequisite for our .tmuxrc
  rm -rf /tmp/tmux-1000/* && touch /tmp/tmux-1000/default

  # Things to do after installing Ubuntu 17.10
  sudo timedatectl set-local-rtc 1
  sudo apt install -y language-pack-gnome-fr-base

  # https://itsfoss.com/things-installing-ubuntu-17-10/
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y tlp tlp-rdw i8kutils
  sudo tlp start
  sudo apt install -y git zsh expect
  # Git help tips now in .gitconfig : https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration
  # Laptop mode : https://www.linuxtricks.fr/wiki/optimiser-linux-pour-un-pc-portable
  sudo bash -c 'cat << EOF > /etc/sysctl.d/98-laptop.conf
vm.laptop_mode=5
vm.swappiness=10
EOF'
  # Redshift Geoloc
  test -f ~/.config/systemd/user/geoclue-agent.service && systemctl --user enable --now geoclue-agent.service
  # Add CDROM Roles
  sudo usermod -a -G cdrom "${SUDO_USER:-$USER}"
  sudo bash -c 'cat << EOF > /etc/stubby/stubby.yml
  - address_data: 80.67.169.12
    tls_auth_name: "ns0.fdn.fr"
  - address_data: 2001:910:800::12
    tls_auth_name: "ns0.fdn.fr"
  - address_data: 80.67.169.40
    tls_auth_name: "ns1.fdn.fr"
  - address_data: 2001:910:800::40
    tls_auth_name: "ns1.fdn.fr"
EOF'
}

Disable_Heavy_Services() {
  echo "==> Désactivation des services lourds ou inutiles au démarrage pour optimiser le temps de boot et les I/O SSD..."

  # Services non pertinents ou en échec (matériel absent ou incompatible)
  sudo systemctl disable --now nvidia-persistenced.service 2>/dev/null
  sudo systemctl disable --now xfs_healer_start.service xfs_healer@-.service 2>/dev/null
  sudo systemctl disable vboxdrv.service 2>/dev/null
  sudo systemctl disable --now luanti-server.service 2>/dev/null

  # Conteneurs et virtualisation (à lancer manuellement au besoin pour éviter la saturation du SSD au boot)
  sudo systemctl disable docker.service containerd.service 2>/dev/null
  sudo systemctl disable lxc.service lxc-net.service libvirtd.service 2>/dev/null

  # Démons d'audit / monitoring intensifs
  sudo systemctl disable --now auditd.service acct.service atop.service 2>/dev/null

  # Réinitialise les états en échec
  sudo systemctl reset-failed 2>/dev/null

  echo "[✓] Services désactivés."
}

WIFI_Intel2230_Fix() {
  echo "==> Configuration de la stabilité Wi-Fi (Intel Centrino Wireless-N 2230)..."

  # 1. Configuration du module iwlwifi (/etc/modprobe.d/iwlwifi.conf)
  sudo tee /etc/modprobe.d/iwlwifi.conf <<'EOF'
# Désactive l'agrégation TX instable en 802.11n sur Centrino 2230 tout en conservant le débit
options iwlwifi 11n_disable=8
# Chiffrement logiciel pour éviter les blocages de reconnexion/renégociation WPA2
options iwlwifi swcrypto=1
# Désactive la mise en veille agressive du chipset Wi-Fi
options iwlwifi power_save=0
options iwldvm force_cam=0
EOF

  # 2. Désactivation de l'économie d'énergie Wi-Fi dans NetworkManager
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf <<'EOF'
[connection]
wifi.powersave = 2
EOF

  echo "[✓] Fichiers /etc/modprobe.d/iwlwifi.conf et /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf créés."
}

WIFI() {
  # Wifi do not refresh after suspend
  # power on wifi card
  # https://askubuntu.com/questions/452826/wireless-networking-not-working-after-resume-in-ubuntu-14-04?noredirect=1&lq=1
  (
    cat <<10_resume_wifi
 #!/bin/sh

case "${1}" in
  resume|thaw)
    nmcli r wifi off && nmcli r wifi on ;;
esac
10_resume_wifi
  ) | sudo tee -e /etc/pm/sleep.d/10_resume_wifi
  chmod 755 /etc/pm/sleep.d/10_resume_wifi

  # Restart Network after suspend
  # https://www.malachisoord.com/2017/02/18/ubuntu-fix-wifi-after-suspend/
  (
    cat <<wifi-resume.service
[Unit]
Description=Restart NetworkManager at resume
After=suspend.target
After=hibernate.target
After=hybrid-sleep.target

[Service]
ExecStart=/bin/systemctl --no-block restart network-manager.service

[Install]
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=hybrid-sleep.target
wifi-resume.service
  ) | sudo tee -a /etc/systemd/system/wifi-resume.service
  sudo systemctl enable wifi-resume.service

  # Move shitty iwlwifi file
  # https://askubuntu.com/questions/524088/is-this-a-bad-wireless-card
  sudo mv /etc/modprobe.d/iwlwifi.conf /etc/modprobe.d/iwlwifi.conf-dist
  echo "options iwlwifi wd_disable=1 bt_coex_active=0 11n_disable=1" | sudo tee -a /etc/modprobe.d/iwlwifi.conf

  # Take care to suspend module
  # http://www.webupd8.org/2013/01/fix-wireless-or-wired-network-not.html
  echo "SUSPEND_MODULES=\"\$SUSPEND_MODULES iwldvm iwlwifi\"" | sudo tee -a /etc/pm/config.d/unload_modules

  # Discover
  sudo apt install -y bettercap build-essential ruby-dev libpcap-dev
  sudo gem install bettercap
  sudo bettercap
}

PPA() {
  # Add keys
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
  # this tool aims to be ran from Ubuntu
  # install additionnal repositories
  for ppa in \
    ppa:pbek/qownnotes \
    ppa:peterlevi/ppa \
    ppa:teejee2008/ppa \
    ppa:unit193/encryption \
    ppa:vincent-vandevyvre/vvv \
    ppa:yubico/stable \
    ppa:libreoffice/ppa \
    ppa:yannubuntu/boot-repair \
    ppa:peterlevi/ppa \
    ppa:danielrichter2007/grub-customizer \
    ppa:bashtop-monitor/bashtop \
    ppa:libratbag-piper/piper-libratbag-git \
    ppa:nextcloud-devs/client \
    ppa:appimagelauncher-team/stable \
    ppa:yannick-mauray/quickgui \
    ppa:flexiondotorg/quickemu; do
    sudo apt-add-repository -n --yes ${ppa}
  done
  sudo apt-get update
  sudo apt install -y hollywood qownnotes peek variety timeshift veracrypt \
    ddgr software-properties-common boot-repair variety \
    grub-customizer bashtop piper gh nautilus-nextcloud appimagelauncher \
    quickgui quickemu
  # can not install on focal (dependancy problems) sudo apt install -y oqapy
  # install some github cli extensions
  for extension in dlvhdr/gh-dash seachicken/gh-poi AaronMoat/gh-pulls fundor333/gh-bofh meiji163/gh-notify linnea-bakshi/gh-doctor; do
    gh extension install "${extension}"
  done
}

Packages() {
  # Firmware et microcode matériel
  sudo apt install -y \
    firmware-amd-graphics \
    firmware-linux-free \
    firmware-linux-nonfree \
    firmware-iwlwifi \
    intel-microcode

  # Install some packages
  sudo apt install -y \
    acct alot asciidoc aide aide-common alien apt-file apt-cacher aria2 ardour asciidoctor aspell-fr atop awscli auditd \
    baobab barrier bc bleachbit blueman brasero build-essential bundler \
    ca-certificates cargo checkinstall chrome-gnome-shell cifs-utils clipit checksecurity cloc cmake colord-gtk-utils colordiff corkscrew cowsay cpuid curl \
    darktable ddgr debian-goodies default-jre debsecan debsums deluge-gtk deluged dfc dkms digikam direnv dnsperf dnstracer dos2unix duf \
    easytag eatmydata ethstatus ethtool ettercap-graphical evince evolution evolution-ews extrace exuberant-ctags \
    fail2ban fastboot fastfetch fdupes ffmpegthumbnailer filezilla fonts-powerline fortunes fonts-radisnoir fpart ftp \
    gajim geary geogebra-gnome gimp git-extras gnome-screenshot gnome-tweaks gnome-usage gnupg2 gnupg-agent googler gparted graphviz gromit-mpx gron gthumb guake guake-indicator \
    handbrake hashcat heimdall-flash-frontend hey htop httpcode httperf httpie httping httrack httraqt hugin hugo hunspell-fr hunspell-fr-comprehensive hurl hwloc libhwloc-contrib-plugins \
    i2c-tools iftop inkscape innoextract ioping iotop ipcalc iproute2 iptraf-ng iputils-arping iptstate isync \
    josm josm-l10n jq jxplorer \
    kdenlive kdocker keepassxc keychain kid3 kid3-cli kigo klavaro kodi krita krita-l10n \
    lazygit ldap-utils lftp libeatmydata1 libimage-exiftool-perl libpam-tmpdir libpam-yubico libreoffice-calc libreoffice-draw libreoffice-help-fr libreoffice-impress libreoffice-math libreoffice-nlpsolver libreoffice-voikko libreoffice-writer libreoffice-writer2latex libreoffice-gnome libva-glx2 lm-sensors libsecret-tools lmms lnav lolcat lsof ltrace lxc python3-lxc lynx \
    mc mediawiki2latexguipyqt meld mgitstatus miller molly-guard mono-complete mosh mp3splt mp3splt-gtk multitail mumble mutt \
    nautilus-image-converter ncal ncdu needrestart nemo-gtkhash netcat-openbsd neomutt neovim nethogs network-manager-openvpn-gnome nextcloud-desktop nmap nmon notmuch numatop npm \
    ocrfeeder offlineimap ooo-thumbnailer openboard openconnect openshot-qt openssh-client openssh-server openvpn \
    p7zip pandoc parallel parted pass patch pavucontrol pcp pdfgrep perf-tools-unstable perl-doc pgtop photocollage pinentry-curses pinentry-tty pitivi pm-utils pre-commit postgresql-client power-profiles-daemon pre-commit progress psensor pssh putty-tools python3 python3-dev python3-pycurl python3-virtualenv pwgen pydf python3-gpg python-is-python3 \
    qalc qemu-system-gui qtpass qtractor \
    rclone rdesktop redshift-gtk refind remmina rename ripgrep rpm rsync \
    s3cmd screen screenkey scribus seahorse scdaemon shc shotwell ssh-import-id sshuttle simple-scan simplescreenrecorder smartmontools sound-juicer sosreport source-highlight spectre-meltdown-checker speedtest-cli sshfs sshpass sslscan socat software-properties-common stopmotion strace stubby stunnel4 synaptic sysstat \
    tcpdump tellico termshark testssl.sh thefuck thunderbird tig tilix toilet torbrowser-launcher traceroute trash-cli tshark \
    unison-gtk unrar urlview \
    vifm vim-fugitive vim-gtk3 vim-nox vim-python-jedi vim-youcompleteme virt-manager virtualenv vlc \
    whois winbind wireshark \
    xauth xdg-utils xournalpp xscreensaver xsane \
    yamllint \
    zmap

  sudo apt-get install -y libquazip5-1 libqrencode4
  sudo ln -s /usr/lib/x86_64-linux-gnu/libqrencode.so.4 /usr/lib/x86_64-linux-gnu/libqrencode.so.3

  # Python alternatives
  # sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
  # sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2
  # sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.14 3
  if update-alternatives --list python >/dev/null 2>&1; then
    sudo update-alternatives --set python /usr/bin/python3.14 2>/dev/null || true
  fi

}

SNAP() {
  # for snap in androidsdk chromium czkawka code github-desktop gnome-system-monitor hub hugo ipfs-desktop \
  for snap in chromium czkawka code codium github-desktop gnome-system-monitor hub hugo ipfs-desktop \
    keepassxc magnus mailspring onlyoffice-desktopeditors popeye procs pycharm-community qobuz-linux \
    rambox shellcheck slack spotify strawberry telegram-desktop whatsdesk yakyak; do
    snap install --classic ${snap}
  done
  sudo snap connect czkawka:removable-media
}

Python() {
  # Python
  snap install pycharm-community --classic

  # Try alphago .....
  # cd /tmp
  # git clone https://github.com/maxpumperla/betago
  # cd betago
  # python run_demo.py

  # Install some other pip cool stuff
  for pkg in aranet4 bcc brotab bpytop betago commitizen configobj cookiecutter cz-conventional-gitmoji deface docopt git-pull-request gradio grip howdoi icdiff jsonnet kapitan litecli mycli pynvim pypandoc search-that-hash sentencepiece shodan spotdl spotify-cli-linux tenserflow terminaltables topgrade transformers uv virtualenv yt-dlp; do
    pip install "${pkg}" --upgrade --break-system-packages
  done
  # Nettoyage d'anciens plugins cz incompatibles (qui bloquent le chargement global de commitizen)
  pip uninstall -y cz-github-jira-conventional cz-emoji --break-system-packages 2>/dev/null || true
  # uv An extremely fast Python package and project manager, written in Rust.
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

GO() {
  # GO
  # https://golang.org/dl/
  # mkdir -p "$GOROOT" "$GOPATH"
  # cd "$GOROOT" || exit
  # wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz
  # tar xvfz go1.9.2.linux-amd64.tar.gz
  # rm go1.9.2.linux-amd64.tar.gz
  sudo apt install -y golang
  go get golang.org/x/tools/cmd/godoc
  go get golang.org/x/tools/cmd/goimports
  go get -u github.com/golang/lint/golint
  # Accept URLs on stdin, replace all query string values with a user-supplied valu
  go get -u github.com/tomnomnom/qsreplace
  # gau Fetch known URLs from AlienVault's Open Threat Exchange, the Wayback Machine, and Common Crawl.
  go install github.com/lc/gau/v2/cmd/gau@latest
  # https://github.com/lc/gau/issues/8
  sed -i -e "s+alias gau='git add --update'+\#alias gau='git add --update'+g" ~/.oh-my-zsh/plugins/git/git.plugin.zsh
  # qf : GF Paterns For (ssrf,RCE,Lfi,sqli,ssti,idor,url redirection,debug_logic, interesting Subs) parameters grep
  go get -u github.com/tomnomnom/waybackurls
  go get -u github.com/tomnomnom/gf
  # assetfinder : Find domains and subdomains related to a given domain
  go get -u github.com/tomnomnom/assetfinder
  # ffuf – Fast Web Fuzzer Linux Tool Written in Go
  go get -u github.com/ffuf/ffuf
  # pdfcpu: a Go PDF processor and CLI
  go install github.com/pdfcpu/pdfcpu/cmd/pdfcpu@latest

  # tips cross compilation
  # CGO_ENABLED=yes go build
  go install github.com/claudiodangelis/qrcp@latest 2>/dev/null || true
  go install github.com/rs/curlie@latest 2>/dev/null || true
}

Crontab() {
  # Install Usefull local crontabs
  cd /tmp || exit
  cat >crontab <<EOF
16 02 * * * ${HOME}/bin/get_screensavers.py ${HOME}/Dropbox/Screensavers
EOF
  crontab crontab && rm crontab
}

# Installation d'applications AppImage
install_appimages() {
  DESKTOP_DIR="$HOME/.local/share/applications"
  mkdir -p "$DESKTOP_DIR"
  APPIMAGE_DIR="$HOME/AppImages"
  mkdir -p "$APPIMAGE_DIR"

  # Table associative : nom du fichier => URL d'origine
  declare -a APPIMAGES_URLS=(
    ["cables.appimage"]="https://github.com/cables-gl/cables/releases/latest/download/cables.appimage"
    ["chataigne.appimage"]="https://github.com/benkuper/Chataigne/releases/latest/download/Chataigne-x86_64.AppImage"
    ["cozy_drive.appimage"]="https://github.com/cozy/cozy-drive/releases/latest/download/Cozy-Drive-x86_64.AppImage"
    ["flightgear.appimage"]="https://github.com/FlightGear/flightgear/releases/latest/download/FlightGear-x86_64.AppImage"
    ["heron_animation_beta.appimage"]="https://github.com/heronanimation/heron-animation-beta/releases/latest/download/HeronAnimation-x86_64.AppImage"
    ["lmms.appimage"]="https://github.com/LMMS/lmms/releases/latest/download/lmms-x86_64.AppImage"
    ["mednum_offline_player.appimage"]="https://github.com/mednum-offline-player/mednum-offline-player/releases/latest/download/mednum-offline-player-x86_64.AppImage"
    ["pia.appimage"]="https://github.com/pia-foss/pia-app/releases/latest/download/pia-x86_64.AppImage"
    ["plingstore.appimage"]="https://github.com/blingstore/PlingStore/releases/latest/download/PlingStore-x86_64.AppImage"
    ["prusaslicer.appimage"]="https://github.com/prusa3d/PrusaSlicer/releases/latest/download/PrusaSlicer-x86_64.AppImage"
    ["siril.appimage"]="https://github.com/Free-astro/siril/releases/latest/download/siril-x86_64.AppImage"
    ["synfig_studio.appimage"]="https://github.com/synfig/synfig/releases/latest/download/SynfigStudio-x86_64.AppImage"
    ["webcamoid.appimage"]="https://github.com/webcamoid/webcamoid/releases/latest/download/Webcamoid-x86_64.AppImage"
    ["freelens.appimage"]="https://github.com/freelens/freelens/releases/latest/download/freelens-x86_64.AppImage"
    ["worldmonitor.appimage"]="https://www.worldmonitor.app/api/download?platform=linux-appimage"
  )

  for filename in "${!APPIMAGES_URLS[@]}"; do
    dest="$APPIMAGE_DIR/$filename"
    url="${APPIMAGES_URLS[$filename]}"
    if [ ! -f "$dest" ]; then
      echo "Téléchargement de $filename depuis $url ..."
      curl -L "$url" -o "$dest"
    fi
    if [ -f "$dest" ]; then
      chmod +x "$dest"
      echo "AppImage prêt : $dest"

      # Création du raccourci .desktop
      appname="${filename%.appimage}"
      desktopfile="$DESKTOP_DIR/${appname}.desktop"
      cat >"$desktopfile" <<EOF
[Desktop Entry]
Type=Application
Name=${appname^}
Exec="$dest"
Icon=$APPIMAGE_DIR/${appname}.png
Comment=AppImage $appname
Terminal=false
Categories=Utility;
EOF
      # Optionnel : extraire l'icône si possible
      if command -v bsdtar >/dev/null 2>&1; then
        bsdtar -xf "$dest" '*.png' -O 2>/dev/null | head -c 1000000 >"$APPIMAGE_DIR/${appname}.png" || true
      fi
      update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    else
      echo "Erreur de téléchargement : $filename"
    fi
  done
  echo "AppImages traités dans $APPIMAGE_DIR"
}

Albert() {
  # MacOS Launcher
  curl https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
  echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
  sudo wget -c -nv https://download.opensuse.org/repositories/home:manuelschneid3r/Debian_12/Release.key -O "/etc/apt/trusted.gpg.d/home:manuelschneid3r.asc"
  sudo apt update
  sudo apt install -y albert
}

Android() {
  # Android Rules
  cd /tmp || exit
  git clone git@github.com:M0Rf30/android-udev-rules.git
  sudo cp android-udev-rules/51-android.rules /etc/udev/rules.d/
  sudo chmod a+r /etc/udev/rules.d/51-android.rules
  sudo groupadd adbusers
  sudo usermod -a -G adbusers "$(whoami)"
  sudo udevadm control --reload-rules
  sudo service udev restart
}

Ansible() {
  # ansible & ARA
  python3 -m pip install --user ansible "ara[server]" --break-system-packages
  # molecule : https://blog.octo.com/en/the-wizard-ansible-molecule-and-test-driven-development/
  python3 -m pip install --user molecule --break-system-packages
  cd /tmp || exit
  git clone https://github.com/metacloud/molecule
  cd /tmp/molecule/tests/fixtures/integration/test_command/molecule/docker || exit
  molecule test
  # Run ansible playbooks in parallel.
  python3 -m pip install ansible-parallel --break-system-packages
}

Argbash() {
  # Argbash : https://github.com/matejak/argbash/
  cd /tmp || exit 1
  wget -c https://github.com/matejak/argbash/archive/2.8.0.zip
  unzip 2.8.0.zip
  cd argbash-2.8.0 || exit 1
  cd resources || exit 1
  make install PREFIX=$HOME/.local
}

Atom() {
  # Atom
  curl -L https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
  sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
  sudo apt-get update
  sudo apt-get install -y atom

  # Install atom modules
  # http://flight-manual.atom.io/using-atom/sections/atom-packages/
  for module in git-plus \
    go-plus \
    intentions \
    hugofy \
    language-hugo \
    language-powershell \
    language-puppet \
    language-terraform \
    linter \
    linter-docker \
    linter-golinter \
    linter-packer-validate \
    linter-puppet-lint \
    linter-shellcheck \
    linter-terraform-syntax \
    linter-ui-default \
    pandoc-convert \
    teletype \
    terraform-fmt; do
    apm install "${module}"
  done
  echo "apm complete"
}

Bat() {
  # Bat
  # https://twitter.com/fdevillamil/status/1095785002791550977?s=09
  cd /tmp || exit 1
  wget -c https://github.com/sharkdp/bat/releases/download/v0.10.0/bat_0.10.0_amd64.deb
  sudo dpkg -i bat_0.10.0_amd64.deb
}

BootRepair() {
  # BootRepair
  # https://wiki.debian.org/Boot-Repair
  sudo install -m 0755 -d /etc/apt/keyrings
  # Récupération de la clé RSA 4096 moderne du PPA (la vieille clé RSA 1024 de SourceForge est rejetée par Ubuntu 24+)
  curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x308901CC3AD15B3AB64CC0EF3E687364D2EDDB5F" 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /etc/apt/keyrings/boot-repair.gpg >/dev/null || true
  echo 'deb [signed-by=/etc/apt/keyrings/boot-repair.gpg] https://ppa.launchpadcontent.net/yannubuntu/boot-repair/ubuntu noble main' | sudo tee /etc/apt/sources.list.d/boot-repair.list >/dev/null
  sudo apt update && sudo apt install -y boot-repair
}

Delta() {
  cd /tmp || exit 1
  wget -c https://github.com/barnumbirr/delta-debian/releases/download/v0.1.1-1/delta_0.1.1-1_amd64_debian_buster.deb
  sudo dpkg -i delta_0.1.1-1_amd64_debian_buster.deb
  sudo apt-mark hold delta
}

bcctools() {
  # bcc-tools
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D4284CDD
  echo "deb [trusted=yes] https://repo.iovisor.org/apt/bionic bionic-nightly main" | sudo tee /etc/apt/sources.list.d/iovisor.list
  sudo apt-get update
  sudo apt-get install -y bcc-tools libbcc-examples linux-headers-"$(uname -r)" python3-bcc
}

bluegriffon() {
  #- FIXME bluegriffon
  cd /tmp || exit
  wget -c http://bluegriffon.org/freshmeat/3.0.1/bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
  sudo dpkg -i bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb && rm bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
}

Brew() {
  if [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
    # Try Brew on Linux
    sudo apt-get -y install build-essential procps curl file git
    if ! command -v brew >/dev/null 2>&1 && [ ! -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Load brew environment for current session
    if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # Run brew bundle if Brewfile-debian exists
    if [ -f "Brewfile-debian" ]; then
      echo "Installation du bundle Homebrew Debian..."
      brew bundle --file Brewfile-debian
    elif [ -f "$HOME/Brewfile-debian" ]; then
      echo "Installation du bundle Homebrew Debian..."
      brew bundle --file "$HOME/Brewfile-debian"
    fi
  else
    # Use brew to install softwares on macOS
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew bundle
  fi
}

browsh() {
  # browsh Text Web browser
  # Needs Firefox
  cd /tmp || exit
  wget -c https://github.com/browsh-org/browsh/releases/download/v1.6.4/browsh_1.6.4_linux_amd64.deb
  sudo dpkg -i browsh_1.6.4_linux_amd64.deb
}

Calibre() {
  # Install Calibre
  sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
}

Chaos() {
  # Chaos toolkit : https://medium.com/chaos-toolkit/announcing-chaos-discover-and-chaos-init-ff2bf02c5a85
  docker pull chaostoolkit/chaostoolkit
  docker run -it chaostoolkit/chaostoolkit discover chaostoolkit-kubernetes
}

ChatGPT() {
  # Install a chatgpt commandline
  curl -sS https://raw.githubusercontent.com/0xacx/chatGPT-shell-cli/main/install.sh | sudo -E bash
}

Children() {
  # Add some games
  sudo apt install -y \
    brainparty briquolo cgoban colobot connectagram \
    extremetuxracer fretsonfire-songs-muldjord frozen-bubble gbrainy gcompris-qt grhino \
    junior-config junior-programming khangman lutris mu-cade opencity pingus supertuxkart tomatoes tuxmath tuxtype

  # when you need to add users to junior-programming
  sudo dpkg-reconfigure --force junior-config
}

Chrome() {
  # Chrome
  # https://doc.ubuntu-fr.org/google_chrome
  # https://www.google.com/chrome/browser/desktop/index.html
  sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y google-chrome-stable
}

chromeIPass() {
  # chromeIPass : https://github.com/pfn/passifox/
  sudo wget -c https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx -O /usr/lib/keepass2/KeePassHttp.plgx
}

CLOUD() {
  # some cloud tools
  # Packer
  # https://www.packer.io/downloads.html
  cd ~/bin || exit
  wget -c https://releases.hashicorp.com/packer/1.1.1/packer_1.1.1_linux_amd64.zip
  unzip -f packer_1.1.1_linux_amd64.zip
  rm packer_1.1.1_linux_amd64.zip

  # terraform
  # https://www.terraform.io/downloads.html
  cd ~/bin || exit
  wget -c https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_linux_amd64.zip
  unzip -f terraform_1.2.9_linux_amd64.zip
  rm -f terraform_1.2.9_linux_amd64.zip getTerraformProviders.sh
  wget -c https://gist.githubusercontent.com/jnahelou/63947831a8154daf6bc3573cc27ed373/raw/e7c685d8ae80e3c6b17238703a870cab00edc7b0/getTerraformProviders.sh
  sudo mkdir -p /usr/local/terraform/toolbox/providers/
  sudo bash ~/bin/getTerraformProviders.sh
  cd "$HOME" || exit
  terraform init -plugin-dir=/usr/local/terraform/toolbox/providers/
  # terraform graph | dot -Tpng > terraform-graph.png

  # rancher
  # https://github.com/rancher/cli/release
  cd ~/bin || exit
  wget -c https://github.com/rancher/cli/releases/download/v0.6.5-rc4/rancher-linux-amd64-v0.6.5-rc4.tar.gz
  tar xvfz rancher-linux-amd64-v0.6.5-rc4.tar.gz
  rm rancher-linux-amd64-v0.6.5-rc4.tar.gz
  # https://github.com/rancher/rancher-compose/releases
  cd ~/bin || exit
  wget -c https://github.com/rancher/rancher-compose/releases/download/v0.12.5/rancher-compose-linux-amd64-v0.12.5.tar.gz
  tar xvfz rancher-compose-linux-amd64-v0.12.5.tar.gz
  rm rancher-compose-linux-amd64-v0.12.5.tar.gz

  # ack-grep
  # https://beyondgrep.com/install/
  curl https://beyondgrep.com/ack-2.22-single-file >~/bin/ack && chmod 0755 ~/bin/ack

  # CloudConvert
  sudo npm install -g cloudconvert-cli
  export CLOUDCONVERT_API_KEY=changeme

  # Gandi Client
  cd /tmp || exit
  sudo apt-get install -y python-nose python3-nose python-ipy
  git clone https://github.com/Gandi/gandi.cli.git
  cd gandi.cli || exit
  ln -sf packages/debian debian && debuild -us -uc -b && sudo dpkg -i ../python-gandicli_1.0_all.deb

  # Vault
  wget -c https://releases.hashicorp.com/vault/0.9.3/vault_0.9.3_linux_amd64.zip -O ~/bin/vault_0.9.3_linux_amd64.zip
  unzip ~/bin/vault_0.9.3_linux_amd64.zip && rm ~/bin/vault_0.9.3_linux_amd64.zip
  vault -autocomplete-install
  export VAULT_ADDR='http://127.0.0.1:8200'
  # setup https://github.com/Caiyeon/goldfish/wiki/Production-Deployment

  # GCP
  # Create environment variable for correct distribution
  export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
  # Add the Cloud SDK distribution URI as a package source
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  # Import the Google Cloud Platform public key
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  # Update the package list and install the Cloud SDK
  sudo apt-get update && sudo apt-get install -y google-cloud-sdk
  # Install components
  gcloud components install gke-gcloud-auth-plugin

  # AZURE
  # Install prerequisite packages:
  sudo apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y
  # Modify your sources list:
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list
  # Get the Microsoft signing key:
  sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
    --keyserver packages.microsoft.com \
    --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
  # Install the CLI:
  sudo apt-get update
  sudo apt-get install -y azure-cli
  # Install Azure Functions Core Tools
  cd /tmp || exit
  wget -c -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y azure-functions-core-tools

  # ASDF
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
  # already in this git repo here
  # echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
  # echo ". $HOME/.asdf/asdf.sh" >> ~/.zshrc

  # MISE
  #
  apt update -y && apt install -y gpg sudo wget curl
  sudo install -dm 755 /etc/apt/keyrings
  wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
  sudo apt update
  sudo apt install -y mise
}

coolretroterm() {
  # FIXME cool-retro-term
  cd /tmp || exit
  sudo apt -y install build-essential qml-module-qtgraphicaleffects qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qtquick-controls qml-module-qtquick-dialogs qmlscene qt5-default qt5-qmake qtdeclarative5-dev qtdeclarative5-localstorage-plugin qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin
  git clone --recursive https://github.com/Swordfish90/cool-retro-term.git
  cd cool-retro-term || exit
  qmake && make
  sudo make install
}

CozyDrive() {
  # CozyDrive
  mkdir -p ~/Applications
  wget -c -O ~/Applications/CozyDrive-3.6.0-x86_64.AppImage https://nuts.cozycloud.cc/download/channel/stable/64
  chmod +x ~/Applications/CozyDrive-3.6.0-x86_64.AppImage
  GnomeExtensions
  gnomeshell-extension-manage --install --extension-id 1031
}

CrowdSec() {
  # CrowdSec : https://github.com/crowdsecurity/crowdsec?tab=readme-ov-file
  curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
  sudo apt-get update
  sudo apt install -y crowdsec
  sudo apt install -y crowdsec-firewall-bouncer-iptables
  sudo crowdsec -t && sudo systemctl restart crowdsec
}

Ctop() {
  # Top-like interface for container metrics https://ctop.sh
  sudo wget -c https://github.com/bcicen/ctop/releases/download/v0.7/ctop-0.7-linux-amd64 -O /usr/local/bin/ctop
  sudo chmod +x /usr/local/bin/ctop
}

Docker() {
  # Docker CE
  # https://docs.docker.com/engine/install/ubuntu/
  sudo apt-get install -y ca-certificates curl

  local codename
  codename="$(lsb_release -cs 2>/dev/null || echo "resolute")"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg 2>/dev/null | sudo tee /etc/apt/keyrings/docker.asc >/dev/null || true
  sudo chmod a+r /etc/apt/keyrings/docker.asc 2>/dev/null || true

  local docker_list="/etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-${codename}.list"
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" | sudo tee "$docker_list" >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
  sudo usermod -aG docker "$USER"
  # https://github.com/jesseduffield/lazydocker#installation
  if command -v go >/dev/null 2>&1; then
    go install github.com/jesseduffield/lazydocker@latest 2>/dev/null || true
  fi
  # Dive https://github.com/wagoodman/dive
  cd /tmp || exit
  DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  if [ -n "$DIVE_VERSION" ]; then
    wget -c "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb"
    sudo apt install -y "./dive_${DIVE_VERSION}_linux_amd64.deb"
    rm -f "./dive_${DIVE_VERSION}_linux_amd64.deb"
  fi
}

Douane() {
  # Douane Firewal
  # Following doc : https://github.com/Douane/Douane
  sudo apt install -y liblog4cxx-dev libdbus-c++-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libgtkmm-3.0-dev
}

DroidCAM() {
  # DroiCAM : use smartphone as webcam on computer
  # https://www.dev47apps.com/droidcam/linux/
  cd /tmp/ || exit 1
  wget -c https://files.dev47apps.net/linux/droidcam_latest.zip
  unzip droidcam_latest.zip -d droidcam
  cd droidcam && sudo ./install-client
  sudo apt install -y linux-headers-$(uname -r) gcc make
  sudo ./install-video
  sudo ./install-sound
}

Dropbox() {
  # Dropbox
  # https://www.dropbox.com/install-linux
  cd /tmp || exit 1
  echo fs.inotify.max_user_watches=500000 | sudo tee -a /etc/sysctl.conf
  sudo sysctl -p
  sudo apt install nautilus-dropbox -y && cd ~ && sudo wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf - && dropbox start -i
}

DVD() {
  # Encrypted DVD
  sudo apt install -y libdvd-pkg
  sudo dpkg-reconfigure libdvd-pkg
}

Element() {
  # Element : a Matrix client
  sudo apt install -y wget apt-transport-https
  sudo wget -c -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
  sudo apt update
  sudo apt install -y element-desktop
}

FlatPackages() {
  # misc softwares available with flatpack command
  FlatPack
  for pkg in ch.openboard.OpenBoard com.github.tchx84.Flatseal com.getpostman.Postman com.github.xournalpp.xournalpp com.valvesoftware.Steam \
    io.github.qwersyk.Newelle org.geogebra.GeoGebra org.gnome.Cheese org.gnome.FeedReader org.jamovi.jamovi org.jdownloader.JDownloader \
    org.kde.krita org.openshot.OpenShot org.openstreetmap.josm org.pitivi.Pitivi io.github.Bavarder.Bavarder app.drey.Dialect it.mijorus.gearlever \
    app.zen_browser.zen com.brave.Browser io.github.tobagin.karere net.lutris.Lutris; do
    flatpak install -y flathub "${pkg}"
  done
}

FlatPack() {
  # New Package system
  sudo apt install -y flatpak
  sudo apt install -y gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

Fuzzy() {
  # fzf: Fuzzy Finder
  if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  else
    (cd "$HOME/.fzf" && git pull 2>/dev/null || true)
  fi
  # Installation automatisée non interactive (répond oui à tout)
  "$HOME/.fzf/install" --all --no-fish --no-nushell
  # Remplacement des chemins absolus générés par $HOME pour la portabilité
  sed -i "s|$HOME|\$HOME|g" "$HOME/.fzf.bash" 2>/dev/null || true
  sed -i "s|$HOME|\$HOME|g" "$HOME/.fzf.zsh" 2>/dev/null || true
}

GCStar() {
  # gcstar : collection software
  sudo apt install -y libogg-vorbis-header-pureperl-perl libnet-freedb-perl libmp3-tag-perl libgd-graph3d-perl libdatetime-format-strptime-perl libtest-mocktime-datecalc-perl libgtk3-simplelist-perl libxml-simple-perl
  cd /tmp || exit
  wget -c https://gitlab.com/GCstar/GCstar/-/archive/v1.7.3/GCstar-v1.7.3.tar.gz
  tar xvfz GCstar-v1.7.3.tar.gz
  cd /tmp/GCstar-v1.7.3/gcstar && sudo ./install
  rm /tmp/GCstar-v1.7.3.tar.gz*
}

Github() {
  # Github
  snap install --edge github-desktop
  snap install hub --classic
}

GnomeExtensions() {
  # Install Gnome-extensions
  # Vérification de l'outil d'installation
  if ! command -v gnomeshell-extension-manage >/dev/null 2>&1 && [ ! -x "$HOME/bin/gnomeshell-extension-manage" ]; then
    echo "gnomeshell-extension-manage introuvable, étape ignorée."
    return 0
  fi

  local gmanage
  gmanage="$(command -v gnomeshell-extension-manage 2>/dev/null || echo "$HOME/bin/gnomeshell-extension-manage")"

  # Extensions actives et compatibles avec les versions récentes de GNOME Shell :
  # Removable Drive Menu (GNOME 50+)
  "$gmanage" --install --extension-id 7 || true
  # Window Navigator (GNOME 50+)
  "$gmanage" --install --extension-id 10 || true
  # Auto Move Windows (GNOME 50+)
  "$gmanage" --install --extension-id 16 || true
  # Coverflow Alt-Tab (GNOME 50+)
  "$gmanage" --install --extension-id 97 || true
  # Burn My Windows (GNOME 50+)
  "$gmanage" --install --extension-id 4679 || true
  # Vitals (GNOME 50+)
  "$gmanage" --install --extension-id 1460 || true
  # Frippery Move Clock (GNOME 50+)
  "$gmanage" --install --extension-id 2 || true
  # Compiz windows effect (GNOME 50+)
  "$gmanage" --install --extension-id 3210 || true

  # Extensions obsolètes / incompatibles avec GNOME 45+ désactivées :
  # - 906 (Sound Device Chooser - intégré nativement dans GNOME Shell)
  # - 15 (AlternateTab - intégré nativement)
  # - 905 (Refresh Wifi - max GNOME 42)
  # - 1036 (Extensions - max GNOME 3.34, remplacé par l'app Extensions native)
  # - 1116 (Workspace Switch Wraparound - max GNOME 45)
  # - 708 (Panel OSD - max GNOME 40)
  # - 1544 (Cast to TV - max GNOME 3.36)
  # - 1104 (Section Todo List - max GNOME 43)
  # - 1162 (Emoji Selector - max GNOME 43)
  # - 1011 (Dynamic Panel Transparency - max GNOME 43)

  # Configuration dconf
  dconf write /org/gnome/desktop/wm/preferences/button-layout 'close:appmenu' 2>/dev/null || true
}

GnomeConfigurations() {
  # Misc Gnome configurations
  # Some help : https://askubuntu.com/questions/971067/how-can-i-script-the-settings-made-by-gnome-tweak-tool
  # dconf watch / is your friend !
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-last-coordinates '(50.633000000000003, 3.0586000000000002)'
  gsettings set org.gnome.desktop.wm.preferences theme 'Radiance'
  gsettings set org.gnome.desktop.interface gtk-theme 'Radiance'
  gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'
  gsettings set org.gnome.desktop.interface cursor-size 24
  gsettings set org.gnome.desktop.interface icon-theme 'ubuntu-mono-dark'
  gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
  gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
  gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
  gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
  gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
  gsettings set org.gnome.gedit.plugins.pythonconsole font 'Monospace 10'
  gsettings set org.gnome.meld custom-font 'monospace, 14'
  gsettings set org.gnome.gedit.plugins.externaltools font 'Monospace 10'
  gsettings set org.gnome.desktop.interface clock-show-date true
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.mutter workspaces-only-on-primary true
  gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'google-chrome.desktop', 'rhythmbox.desktop', 'shotwell.desktop', 'libreoffice-writer.desktop', 'org.gnome.Nautilus.desktop', 'youtube-dlg.desktop', 'cacher.desktop', 'spotify.desktop', 'atom.desktop', 'keepass2.desktop', 'com.gexperts.Tilix.desktop', 'QOwnNotes.desktop', 'thunderbird.desktop']"
  gsettings set org.gnome.shell.window-switcher current-workspace-only false
  gsettings set org.gnome.desktop.screensaver lock-delay 120
  gsettings set org.gnome.desktop.privacy report-technical-problems true
  gsettings set org.gnome.desktop.screensaver picture-options 'zoom'
  gsettings set org.gnome.desktop.screensaver primary-color '#ffffff'
  gsettings set org.gnome.desktop.screensaver secondary-color '#000000'
  gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'
  gsettings set org.gnome.desktop.interface icon-theme 'La-Capitaine'
  gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'
  sudo bash -c 'cat << EOF > /usr/share/thumbnailers/ffmpeg.thumbnailer
[Thumbnailer Entry]
TryExec=/usr/bin/ffmpegthumbnailer
Exec=/usr/bin/ffmpegthumbnailer -s %s -i %i -o %o -c png -f -t 10
MimeType=video/flv;video/webm;video/mkv;video/mp4;video/mpeg;video/avi;video/ogg;video/quicktime;video/x-avi;video/x-flv;video/x-mp4;video/x-mpeg;video/x-webm;video/x-mkv;application/x-extension-webm;video/x-matroska;video/x-ms-wmv;video/x-msvideo;video/x-msvideo/avi;video/x-theora/ogg;video/x-theora/ogv;video/x-ms-asf;video/x-m4v;
EOF'
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
  gsettings set org.gnome.mutter check-alive-timeout 30000
  #  Newelle - Your Ultimate Virtual Assistant (commenté pour éviter le blocage d'exécution)
  # /bin/bash -c 'flatpak run --command=gsettings io.github.qwersyk.Newelle set io.github.qwersyk.Newelle startup-mode "mini" && flatpak run io.github.qwersyk.Newelle'
  gsettings set org.gnome.mutter center-new-windows true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 binding 'Print'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 command '/bin/gnome-screenshot --interactive'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 name "Capture d'Ecran"
}

GrafTCP() {
  # GraphTCP : https://github.com/hmgle/graftcp
  cd /tmp && git clone https://github.com/hmgle/graftcp.git
  cd graftcp && make
}

GRAPH() {
  # dgraph
  curl https://get.dgraph.io -sSf | bash
}

Infrakit() {
  # Infrakit : A toolkit for creating and managing declarative, self-healing infrastructure.
  mkdir -p $GOPATH/src/github.com/docker || true
  cd $GOPATH/src/github.com/docker || exit
  git clone git@github.com:docker/infrakit.git
  cd infrakit && make get-tools &
  make ci && make binaries
  cp build/* ~/bin/
}

IssueHelper() {
  # Issue-helper
  sudo apt remove -y cargo rustc
  if ! command -v rustup >/dev/null 2>&1 && [ ! -x "$HOME/.cargo/bin/rustup" ]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi
  [ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"
  cargo install gli
}

Hurl() {
  # Hurl
  # Hurl is a command line tool that runs HTTP requests defined in a simple plain text format.
  VERSION=6.0.0
  cd /tmp || exit 1
  curl --location --remote-name https://github.com/Orange-OpenSource/hurl/releases/download/$VERSION/hurl_${VERSION}_amd64.deb
  sudo apt update && sudo apt-get install -y ./hurl_${VERSION}_amd64.deb
}

Keybase() {
  # Keybase
  # https://keybase.io/docs/the_app/install_linux
  curl -o /tmp/keybase_amd64.deb -O https://prerelease.keybase.io/keybase_amd64.deb
  sudo dpkg -i /tmp/keybase_amd64.deb
  sudo apt-get install -y -f
}

K3S() {
  # Kubernetes Light
  curl -sfL https://get.k3s.io | sh -
  # Check for Ready node, takes ~30 seconds
  sudo k3s kubectl get node
  sudo k3s server &
  # Kubeconfig is written to /etc/rancher/k3s/k3s.yaml
  sudo k3s kubectl get node

  # On a different node run the below command.
  # NODE_TOKEN comes from /var/lib/rancher/k3s/server/node-token on your server
  # sudo k3s agent --server https://myserver:6443 --token ${NODE_TOKEN}
}

Kubernetes() {
  # Kubernetes
  sudo apt install -y k9s qemu-system libvirt-daemon-system virt-manager ovmf
  # Liens pour le pilote qemu2 de minikube
  if [ -f /usr/share/OVMF/OVMF_CODE_4M.fd ] && [ ! -f /usr/share/OVMF/OVMF_CODE.fd ]; then
    sudo ln -s /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd 2>/dev/null || true
  fi

  # Ajout de l'utilisateur aux groupes nécessaires
  sudo usermod -aG docker,kvm,libvirt "${SUDO_USER:-$USER}"

  # https://github.com/kubernetes/minikube
  cd ~/bin/ || exit
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl && chmod +x kubectl
  curl -Lo karto https://github.com/Zenika/karto/releases/download/v1.1.0/karto && chmod +x karto
  export MINIKUBE_WANTUPDATENOTIFICATION=false
  export MINIKUBE_WANTREPORTERRORPROMPT=false
  export MINIKUBE_HOME=$HOME
  export CHANGE_MINIKUBE_NONE_USER=true
  mkdir -p "$HOME"/.kube
  touch "$HOME"/.kube/config
  export KUBECONFIG="$HOME"/.kube/config

  # Lancer minikube avec le contexte de groupe actif (docker) pour éviter DRV_NOT_HEALTHY
  if groups | grep -q "\bdocker\b"; then
    minikube start --driver=docker
  else
    sg docker -c "minikube start --driver=docker"
  fi
  # this for loop waits until kubectl can access the api server that Minikube has created
  for i in {1..150}; do # timeout for 5 minutes
    echo "$i\c"
    kubectl get po &>/dev/null
    if [ $? -ne 1 ]; then
      break
    fi
    sleep 2
  done
  kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.10
  kubectl expose deployment hello-minikube --type=NodePort --port=8080
  kubectl get pod
  minikube service hello-minikube --url
  curl "$(minikube service hello-minikube --url)"
  # sudo minikube dashboard
  minikube stop
  cd /tmp || exit
  git clone https://github.com/ahmetb/kubectx.git
  cp -v kubectx/{kubectx,kubens} ~/bin/
  mkdir -p ~/.oh-my-zsh/completions
  chmod -R 755 ~/.oh-my-zsh/completions
  cp kubectx/completion/kubectx.zsh ~/.oh-my-zsh/completions/_kubectx.zsh
  cp kubectx/completion/kubens.zsh ~/.oh-my-zsh/completions/_kubens.zsh

  # kubeval : Validate your Kubernetes configuration files, supports multiple Kubernetes versions
  cd /tmp || exit
  wget -c https://github.com/garethr/kubeval/releases/download/0.7.3/kubeval-linux-amd64.tar.gz
  tar xvfz kubeval-linux-amd64.tar.gz
  mv kubeval ~/bin/
  rm kubeval-linux-amd64.tar.gz

  # Some other tools
  # https://github.com/appscode/kubed
  # https://github.com/heptio/ark
  # https://github.com/cloudnativelabs/kube-router
  # https://github.com/GoogleCloudPlatform/kube-metacontroller

  # kustomizer
  curl -s https://kustomizer.dev/install/kustomizer.sh | sudo bash

  # Install kubectl plugins krew
  set -x
  cd "$(mktemp -d)" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
    tar zxvf krew.tar.gz &&
    KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" && "$KREW" install krew
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  kubectl krew update
  for plugin in debug rbac-lookup who-can flame; do
    kubectl krew install ${plugin}
  done

  # Popeye - A Kubernetes Cluster Sanitizer
  cd /tmp || exit
  git clone https://github.com/derailed/popeye
  cd popeye || exit
  # Build and install
  go install
  # Run
  # popeye
  #
  # Kubevious Healthcheck & syntax
  curl https://get.kubevious.io/cli.sh -o install-kubevious.sh && chmod +x install-kubevious.sh && sudo ./install-kubevious.sh && rm install-kubevious.sh
}

Lightworks() {
  # FIXME Lightworks
  cd /tmp || exit
  wget -c -O lightworks.deb "https://www.lwks.com/index.php?option=com_docman&task=doc_download&gid=194"
  sudo dpkg -i lightworks.deb && rm lightworks.deb
  sudo apt --fix-broken install -y
}

lutris() {
  # Lutris Game Platform
  echo "deb [signed-by=/etc/apt/keyrings/lutris.gpg] https://download.opensuse.org/repositories/home:/strycore/Debian_12/ ./" | sudo tee /etc/apt/sources.list.d/lutris.list >/dev/null
  wget -q -O- https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/keyrings/lutris.gpg >/dev/null
  sudo apt update
  sudo apt install -y lutris
}

lynis() {
  # lynis update is really major from ubuntu packages
  sudo apt install -y apt-transport-https
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
  echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
  echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
  sudo apt update
  sudo apt install -y lynis
}

lynishardening() {
  # some suggestions afer lynis report
  grep -q "*  hard  core  0" /etc/security/limits.conf ||
    echo "*  hard  core  0" | sudo tee -a /etc/security/limits.conf
  grep -q "fs.suid_dumpable = 0" /etc/sysctl.conf ||
    echo "fs.suid_dumpable = 0" | sudo tee -a /etc/sysctl.conf
  grep -q "ulimit -S -c 0" /etc/profile ||
    echo "ulimit -S -c 0 > /dev/null 2>&1" | sudo tee -a /etc/profile
  sudo sysctl -p
  sudo postconf -e smtpd_banner=mycomputer
  sudo postconf -e disable_vrfy_command=yes
  grep -q "AllowTcpForwarding=no" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "AllowTcpForwarding=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "ClientAliveCountMax=2" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "ClientAliveCountMax=2" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "Compression=no" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "Compression=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "LogLevel=VERBOSE" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "LogLevel=VERBOSE" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "MaxAuthTries=3" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "MaxAuthTries=3" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "MaxSessions=2" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "MaxSessions=2" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "TCPKeepAlive=no" /etc/ssh/sshd_config.d/lynis.conf ||
    echo "TCPKeepAlive=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  sudo apt install -y acct sysstat
  sudo sed -i -e 's+ENABLED="false"+ENABLED="true"+g+' /etc/default/sysstat
  sudo systemctl enable sysstat
  sudo systemctl restart sysstat
  sudo systemctl restart ssh
}

MammouthCode() {
  # MammouthCode
  # https://info.mammouth.ai/fr/docs/mammouth-code/
  cd /tmp || exit
  curl -fsSL "https://code.mammouth.ai/install.sh" | bash
}

Minishift() {
  # Minishift
  # https://github.com/MiniShift/minishift#getting-started
  cd /tmp || exit
  wget -c https://github.com/minishift/minishift/releases/download/v1.25.0/minishift-1.25.0-linux-amd64.tgz
  tar xvfz minishift-1.25.0-linux-amd64.tgz
  mv minishift-1.25.0-linux-amd64/minishift ~/bin
  minishift config set vm-driver virtualbox
  minishift start
  minishift oc-env
  eval "$(minishift oc-env)"
  oc new-app https://github.com/sclorg/nodejs-ex -l name=myapp
  oc logs -f bc/nodejs-ex
  oc expose svc/nodejs-ex
  minishift openshift service nodejs-ex --in-browser
  minishift stop
}

mkcert() {
  # mkcert : create a valid local CA & certs
  sudo apt install -y libnss3-tools
  curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
  chmod +x mkcert-v*-linux-amd64
  sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
}

MultiOSUSB() {
  # MultiOSUSB : multisystem alternative
  cd /tmp/ && wget -c -O MultiBootUSB.tar.gz https://github.com/Mexit/MultiOS-USB/releases/download/v0.9.9/MultiOS-USB_linux_v0.9.9.tar.gz
  cd ~/bin && tar xvfz /tmp/MultiBootUSB.tar.gz
}

Multisystem() {
  # Multisystem
  sudo apt-add-repository 'deb http://liveusb.info/multisystem/depot all main'
  wget -q http://liveusb.info/multisystem/depot/multisystem.asc -O- | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y multisystem
  sudo usermod -a -G adm ${USER}
}

Mullvad() {
  # Mullvad VPN anonymous as possible
  # Télécharger la clé de signature Mullvad
  sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc

  # Ajouter le serveur de dépôt Mullvad à apt
  echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$(dpkg --print-architecture)] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list

  # Installer le pack
  sudo apt update
  sudo apt install -y mullvad-vpn
}

Music() {
  # Music Software
  sudo apt install -y audacity easyeffects giada guitarix hydrogen kluppe mixxx muse qwinff rosegarden seq24 soundconverter tk707 tuxguitar yoshimi zytrax
}

NeoVim() {
  # NeoVim
  sudo apt install -y neovim

  # Configuration LazyVim uniquement si non existante
  if [ ! -d "$HOME/.config/nvim" ] || [ ! -f "$HOME/.config/nvim/init.lua" ]; then
    echo "Initialisation de la configuration LazyVim..."
    [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim"{,.bak}
    [ -d "$HOME/.local/share/nvim" ] && mv "$HOME/.local/share/nvim"{,.bak}
    [ -d "$HOME/.local/state/nvim" ] && mv "$HOME/.local/state/nvim"{,.bak}
    [ -d "$HOME/.cache/nvim" ] && mv "$HOME/.cache/nvim"{,.bak}
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
  else
    echo "Configuration NeoVim existante détectée, conservation."
  fi

  # Synchronisation et installation automatique des plugins et extras LazyVim en mode non-interactif
  if command -v nvim >/dev/null 2>&1; then
    echo "Synchronisation et installation des plugins LazyVim..."
    nvim --headless "+Lazy! restore" +qa 2>/dev/null || true
  fi

  # Configuration des alternatives système (vi, vim, view, ex, vimdiff -> nvim)
  local nvim_bin
  nvim_bin="$(command -v nvim 2>/dev/null || echo "/usr/bin/nvim")"
  if [ -x "$nvim_bin" ]; then
    echo "Configuration des alternatives système pour NeoVim ($nvim_bin)..."
    sudo update-alternatives --install /usr/bin/ex ex "$nvim_bin" 110 2>/dev/null || true
    sudo update-alternatives --install /usr/bin/vi vi "$nvim_bin" 110 2>/dev/null || true
    sudo update-alternatives --install /usr/bin/view view "$nvim_bin" 110 2>/dev/null || true
    sudo update-alternatives --install /usr/bin/vim vim "$nvim_bin" 110 2>/dev/null || true
    sudo update-alternatives --install /usr/bin/vimdiff vimdiff "$nvim_bin" 110 2>/dev/null || true
    sudo update-alternatives --set ex "$nvim_bin" 2>/dev/null || true
    sudo update-alternatives --set vi "$nvim_bin" 2>/dev/null || true
    sudo update-alternatives --set view "$nvim_bin" 2>/dev/null || true
    sudo update-alternatives --set vim "$nvim_bin" 2>/dev/null || true
    sudo update-alternatives --set vimdiff "$nvim_bin" 2>/dev/null || true
  fi
}

nicotine() {
  # Nicotine+ is a graphical client for the Soulseek peer-to-peer network.
  sudo apt install -y software-properties-common
  sudo add-apt-repository -y ppa:nicotine-team/stable
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6CEB6050A30E5769
  sudo apt update
  sudo apt install -y nicotine
}

nix() {
  # Nix https://nix.dev/manual/nix/2.32/installation/multi-user.html?highlight=%22nix-users%22#restricting-access
  sudo chgrp nix-users /nix/var/nix/daemon-socket
  sudo chmod ug=rwx,o= /nix/var/nix/daemon-socket
  sudo usermod -aG nix-users "${SUDO_USER:-$USER}"
}

npmfx() {
  # FX json parser
  # https://www.youtube.com/watch?v=LMIeaIpZnJI&feature=em-uploademail
  sudo npm install -g fx
}

OfflineImap() {
  # Install last OfflineImap lines
  mkdir -p ~/.config/systemd/user
  cd /tmp && git clone https://github.com/OfflineIMAP/offlineimap.git
  cp offlineimap/contrib/systemd/* ~/.config/systemd/user/
  systemctl --user start offlineimap.service
  systemctl --user enable offlineimap-oneshot.timer
}

OneDrive() {
  # OneDrive : https://github.com/abraunegg/onedrive
  sudo apt install -y -i build-essential
  sudo apt install -y -i libcurl4-openssl-dev
  sudo apt install -y -i libsqlite3-dev
  curl -fsS https://dlang.org/install.sh | bash -s dmd
  source "${HOME}/dlang/dmd-2.081.2/activate"
  cd /tmp || exit
  git clone https://github.com/abraunegg/onedrive.git
  cd onedrive || exit
  make
  sudo make install
  onedrive --synchronize
  systemctl --user enable onedrive
  systemctl --user start onedrive
}

orionbrowser() {
  # orionbrowser : https://orionbrowser.com/platforms/linux/install
  flatpak remote-add --if-not-exists orion-beta https://flatpak.orionbrowser.com/orion-beta.flatpakrepo
  flatpak install orion-beta com.kagi.Orion
}

OSQuery() {
  # OSQuery : https://itnext.io/auditing-containers-with-osquery-389636f8c420
  export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY
  sudo add-apt-repository -y 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
  sudo apt-get update
  sudo apt-get install -y osquery
}

PlayOnLinux() {
  # PlayOnLinux
  wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
  sudo add-apt-repository -y http://deb.playonlinux.com/
  sudo apt -V install playonlinux wine
}

Powershell() {
  # Powershell
  # https://github.com/PowerShell/PowerShell/blob/master/docs/installation/linux.md
  # Import the public repository GPG keys
  curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
  # Register the Microsoft Ubuntu repository
  curl https://packages.microsoft.com/config/ubuntu/17.10/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
  # Update the list of products
  sudo apt-get update
  # Install PowerShell
  sudo apt-get install -y powershell
  # as repo is not available for the moment ....
  cd /tmp || exit
  wget -c -O https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.9/powershell_6.0.0-beta.9-1.ubuntu.17.04_amd64.deb
  sudo dpkg -i powershell_6.0.0-beta.9-1.ubuntu.17.04_amd64.deb
}

Puppet() {
  # Puppet
  # https://docs.puppet.com/puppet/4.5/install_linux.html#installing-release-packages-on-apt-based-systems
  wget -c http://apt.puppetlabs.com/puppet-release-xenial.deb
  sudo dpkg -i puppet-release-xenial.deb && rm -f puppet-release-xenial.deb
}

ProtonBridge() {
  # ProtonBridge to download mails and use it from mutt
  cd /tmp || exit
  version=3.8.2
  wget -c https://proton.me/download/bridge/protonmail-bridge_${version}-1_amd64.deb
  sudo dpkg -i protonmail-bridge_${version}-1_amd64.deb
  rm protonmail-bridge_${version}-1_amd64.deb
}

ProtonVPN() {
  # ProtonVPN : https://protonvpn.com/support/linux-ubuntu-vpn-setup/
  version=1.0.8
  cd /tmp || exit
  wget -c https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_${version}_all.deb
  echo "0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180 protonvpn-stable-release_${version}_all.deb" | sha256sum --check -
  sudo apt-get update
  sudo dpkg -i protonvpn-stable-release_${version}_all.deb
  sudo apt install -y proton-vpn-gnome-desktop
  sudo apt install -y libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator
}

rapidphotodownloader() {
  # rapid-photo-downloader : http://www.damonlynch.net/rapid/downloads.html
  cd /tmp || exit
  wget -c https://launchpad.net/rapid/pyqt/0.9.9/+download/install.py
  python3 install.py
}

RocketChat() {
  # RocketChat
  sudo apt-get install -y libpurple-dev libjson-glib-dev libglib2.0-dev mercurial make libmarkdown2-dev
  cd /tmp || exit
  hg clone https://bitbucket.org/EionRobb/purple-rocketchat/ && cd purple-rocketchat || exit
  make && sudo make install
}

Rust() {
  # Install rust and other cargo tools
  # First remove debian packages
  sudo apt remove -y cargo rustc
  if ! command -v rustup >/dev/null 2>&1 && [ ! -x "$HOME/.cargo/bin/rustup" ]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi
  [ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"

  # Initiate Cargo cache
  if command -v rustup >/dev/null 2>&1; then
    rustup install stable
    rustup default stable
  fi

  for rustpkg in bat cargo-update delta-git dog dust dutree erdtree fd-find gping just himalaya htmlq kubie lurk-cli mdcat multigit navi ripgrep spotify-tui trippy viu; do
    cargo install "${rustpkg}" || true
  done
}

s3benchmark() {
  # s3benchmark : Measure Amazon S3's performance from any location.
  cd ~/bin && curl -OL https://github.com/dvassallo/s3-benchmark/raw/master/build/linux-amd64/s3-benchmark
  chmod +x ~/bin/s3-benchmark
}

scrcpy() {
  # scrcpy: Display and control your Android device
  # for Debian/Ubuntu
  sudo apt install -y ffmpeg libsdl2-2.0-0 adb wget \
    gcc git pkg-config meson ninja-build libsdl2-dev \
    libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
    libswresample-dev libusb-1.0-0 libusb-1.0-0-dev
  cd /tmp || exit 1
  git clone https://github.com/Genymobile/scrcpy
  cd scrcpy || exit
  ./install_release.sh
  # Uninstall
  # sudo ninja -Cbuild-auto uninstall
}

Screensavers() {
  # Screensavers
  sudo apt remove -y gnome-screensaver
  sudo add-apt-repository -y ppa:mc3man/mpv-tests
  sudo apt install -y mpv
  cat >/tmp/crons <<EOF
16 02 * * * ${HOME}/bin/get_screensavers.py ${HOME}/Dropbox/Screensavers
@reboot cd ${HOME}/ownCloudPerso/Code/git/github/noisy && /usr/bin/docker run -it noisy --config config.json
EOF
  crontab /tmp/crons
  mkdir -p ~/.config/systemd/user/
  systemctl --user enable xscreensaver
}

Signal() {
  # NOTE: These instructions only work for 64 bit Debian-based
  # Linux distributions such as Ubuntu, Mint etc.

  # 1. Install our official public software signing key
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor >signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null
  rm signal-desktop-keyring.gpg

  # 2. Add our repository to your list of repositories
  echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" |
    sudo tee -a /etc/apt/sources.list.d/signal-xenial.list

  # 3. Update your package database and install signal
  # sudo apt update && sudo apt install signal-desktop
  sudo apt install -y apt-transport-https && sudo apt update && sudo apt install -y signal-desktop

  # 4. Send icon to systray
  sudo sed -i '/^Exec/ {/--use-tray-icon/ !s/$/ --use-tray-icon/}' /usr/share/applications/signal-desktop.desktop
}

Slack() {
  # Slack
  # https://slack.com/intl/fr-fr/downloads/Linux
  sudo snap install slack --classic
}

Spip-Cli() {
  # Spip in commandline https://contrib.spip.net/SPIP-Cli#Installation
  sudo git clone https://git.spip.net/spip-contrib-outils/spip-cli.git /opt/spip-cli
  cd /opt/spip-cli || exit
  sudo composer install

  cd /opt/spip-cli/bin || exit
  # Commande 'spip'
  sudo ln -s $(pwd)/spip /usr/local/bin/
  # Commande 'spipmu' pour site mutualisé
  sudo ln -s $(pwd)/spipmu /usr/local/bin/
  # Autocompletion (Linux)
  sudo ln -s $(pwd)/spip_console_autocomplete /etc/bash_completion.d/spip
  # Autocompletion (MacOs)
  # sudo ln -s $(pwd)/spip_console_autocomplete /usr/local/etc/bash_completion.d/spip
}

Spotify() {
  # Spotify
  # https://doc.ubuntu-fr.org/spotify
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt-get update && sudo apt-get install -y spotify-client
  # sudo snap install spotify
  # sudo ln -s /var/lib/snapd/desktop/applications/spotify_spotify.desktop /usr/share/applications/spotify.desktop
  pip install spotify-cli-linux
  pip install lyricwikia
}

Stacer() {
  # Stacer : Ubuntu System Cleaner Stacer Scores a Spring Update
  cd /tmp || exit
  wget -c https://github.com/oguzhaninan/Stacer/releases/download/v1.0.9/stacer_1.0.9_amd64.deb
  sudo dpkg -i stacer_1.0.9_amd64.deb
}

Students() {
  # Add some scientific Tools
  sudo apt install -y \
    avogadro filius fritzing geogebra geogebra-gnome kalzium kgeography marble marble-plugins pyacidobasic python3-mecavideo qalculate-gtk step tkgate verbiste-gnome zegrapher

  # Logiciels PlayOnLinux
  # Sine Qua Non : http://patrice-rabiller.fr/SineQuaNon/menusqn.htm
  # Regressi : http://regressi.fr/WordPress/download/
}

STui() {
  # S-Tui : https://www.cyberciti.biz/python-tutorials/monitor-linux-cpu-temperature-frequency-power-in-a-graphical-way/
  sudo apt install -y python-pip stress
  pip install s-tui --break-system-packages
  # sudo s-tui
}

Taskfile() {
  # Taskfile : Task is a task runner / build tool that aims to be simpler and easier to use than, for example, GNU Make.
  # https://taskfile.org/#/
  go get -u -v github.com/go-task/task/cmd/task
}

Teams() {
  # Teams for Linux: Unofficial Microsoft Teams for Linux client
  # https://github.com/IsmaelMartinez/teams-for-linux
  sudo mkdir -p /etc/apt/keyrings
  sudo wget -c -qO /etc/apt/keyrings/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc
  echo "deb [signed-by=/etc/apt/keyrings/teams-for-linux.asc arch=$(dpkg --print-architecture)] https://repo.teamsforlinux.de/debian/ stable main" | sudo tee /etc/apt/sources.list.d/teams-for-linux-packages.list
  sudo apt update
  sudo apt install -y teams-for-linux
}

Terminal() {
  # Install Tilix Theme
  mkdir -p ~/.config/tilix/schemes/
  wget -c -qO "${HOME}"/.config/tilix/schemes/desert.json https://raw.githubusercontent.com/storm119/Tilix-Themes/master/Themes/desert.json
  gsettings set org.gnome.desktop.default-applications.terminal exec 'terminal'
  default=$(gsettings get com.gexperts.Tilix.ProfilesList default | tr -d \')
  dconf write /com/gexperts/Tilix/profiles/${default}/login-shell true
  dconf write /com/gexperts/Tilix/warn-vte-config-issue false
  dconf write /com/gexperts/Tilix/control-scroll-zoom true
  dconf write /com/gexperts/Tilix/profiles/${default}/use-theme-colors false
  dconf write /com/gexperts/Tilix/profiles/${default}/foreground-color \'#FFFFFF\'
  dconf write /com/gexperts/Tilix/profiles/${default}/background-color \'#333333\'
  dconf write /com/gexperts/Tilix/profiles/${default}/bold-color-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/badge-color-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/highlight-colors-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/cursor-colors-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/default-size-columns '200'
  dconf write /com/gexperts/Tilix/profiles/${default}/default-size-rows '50'
  dconf write /com/gexperts/Tilix/profiles/${default}/font 'MesloLGS NF 12'
  dconf write /com/gexperts/Tilix/profiles/${default}/palette "['#4D4D4D', '#FF2B2B', '#98FB98', '#F0E68C', '#CD853F', '#FFDEAD', '#FFA0A0', '#F5DEB3', '#555555', '#FF5555', '#55FF55', '#FFFF55', '#87CEFF', '#FF55FF', '#FFD700', '#FFFFFF']"
  dconf write /com/gexperts/Tilix/copy-on-select true
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal ""
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 name unset
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 command unset
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 binding '<Primary><Alt>t'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 name 'Terminal'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 command '/usr/bin/tilix'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings ['/org/gnome/settings/daemon/plugins/media-keys/custom-keybindings/custom0/']
  gsettings set org.gnome.desktop.interface enable-animations true
  # Tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

TLDR() {
  # TLDR
  # go get 4d63.com/tldr
  sudo apt -y install tldr-py
  git clone git@github.com:tldr-pages/tldr.git ~/.tldr
  tldr init
  tldr reindex
  tldr update
}

Trello() {
  # Trello Client
  # git clone https://github.com/mheap/trello-cli.git # best but badly installed
  # https://github.com/qcam/3llo
  sudo em install 3llo
  export TRELLO_USER=your_username
  export TRELLO_KEY=your_key
  export TRELLO_TOKEN=your_token
}

ttfmscorefontsinstaller() {
  # Fixed in bionic ttf-mscorefonts-installer
  # http://www.asso-linux.org/forum/viewtopic.php?f=4&t=196
  # wget -o /tmp/ttf-mscorefonts-installer_3.6_all.deb -O http://ftp.fr.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
  # sudo dpkg -i /tmp/ttf-mscorefonts-installer_3.6_all.deb
  sudo apt install -y -f
}

urbackup() {
  # urbackup
  TF=$(mktemp) && wget -c "https://hndl.urbackup.org/Client/2.2.5/UrBackup%20Client%20Linux%202.2.5.sh" -O $TF && sudo sh $TF
  rm $TF
}

VIM() {
  if [ -f /etc/debian_version ]; then
    # Add Ruby Support to vim
    sudo update-alternatives --set vim /usr/bin/vim.nox
  fi
  # Install vundle
  pip3 install flake8 --break-system-packages
  pip3 install wakatime --break-system-packages
  pip3 install pidcat-pip --break-system-packages
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +BundleInstall
  vim +GoInstallBinaries
  vim +PluginInstall
  # cd ~/.vim/plugged/YouCompleteMe && python install.py

  # vim-instant-markdown
  sudo npm -g install instant-markdown-d
  cd /tmp || exit
  git clone https://github.com/instant-markdown/vim-instant-markdown.git
  mkdir -p ~/.vim/after/ftplugin/markdown/
  cd vim-instant-markdown || exit
  cp after/ftplugin/markdown/instant-markdown.vim ~/.vim/after/ftplugin/markdown/

  # vim-fugitive
  mkdir -p ~/.vim/pack/tpope/start
  cd ~/.vim/pack/tpope/start || exit
  git clone https://tpope.io/vim/fugitive.git
  vim -u NONE -c "helptags fugitive/doc" -c q

  # vim-terraform
  git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform

  # vim-kitty
  git clone https://github.com/fladson/vim-kitty.git /tmp/vim-kitty
  mkdir -p ~/.vim/after/syntax/
  mv /tmp/vim-kitty/syntax/* ~/.vim/after/syntax/
  rm -rf /tmp/vim-kitty

  # govim
  go get -u github.com/nsf/gocode
}

VirtualBox() {
  # VirtualBox
  # https://www.virtualbox.org/wiki/Linux_Downloads
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
  sudo rm /etc/apt/sources.list.d/virtualbox.list
  echo "deb http://download.virtualbox.org/virtualbox/debian eoan contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
  sudo apt-get update
  sudo apt-get install -y virtualbox
  sudo usermod -G vboxusers -a $USER
  version=$(VBoxManage --version | cut -dr -f1 | cut -d'_' -f1) && wget -c http://download.virtualbox.org/virtualb … ox-extpack
  VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack
}

Vivaldi() {
  # Vivaldi web browser
  cd /tmp || exit
  wget -c https://downloads.vivaldi.com/stable/vivaldi-stable_6.5.3206.48-1_amd64.deb
  sudo dpkg -i vivaldi-stable_6.5.3206.48-1_amd64.deb
  rm vivaldi-stable_6.5.3206.48-1_amd64.deb
}

VSCodium() {
  # VSCodium / VSCode
  local editor_bin
  if command -v codium >/dev/null 2>&1; then
    editor_bin="codium"
  elif command -v code >/dev/null 2>&1; then
    editor_bin="code"
  else
    cd /tmp || exit
    wget -c https://github.com/VSCodium/vscodium/releases/download/1.85.1.23348/codium_1.85.1.23348_amd64.deb
    sudo dpkg -i codium_1.85.1.23348_amd64.deb
    rm -f codium_1.85.1.23348_amd64.deb
    editor_bin="codium"
  fi

  # Extensions
  for extension in \
    abusaidm.html-snippets \
    AlanWalk.markdown-toc \
    ban.spellright \
    be5invis.toml \
    bierner.markdown-preview-github-styles \
    bung87.vscode-gemfile \
    bmarkovic.haproxy \
    coolbear.systemd-unit-file \
    CraigMaslowski.erb \
    DavidAnson.vscode-markdownlint \
    DavidWang.ini-for-vscode \
    dracula-theme.theme-dracula \
    eamodio.gitlens \
    Equinusocio.vsc-material-theme \
    esbenp.prettier-vscode \
    espresso3389.unicode-normalizer \
    fabianlauer.vs-code-xml-format \
    fimars.github-plus-theme-elixir-adapted \
    foxundermoon.shell-format \
    gera2ld.markmap-vscode \
    gistart.theme-desert-dawn \
    GrapeCity.gc-excelviewer \
    Gruntfuggly.todo-tree \
    hangxingliu.vscode-nginx-conf-hint \
    heptio.jsonnet \
    joaompinto.asciidoctor-vscode \
    jpogran.puppet-vscode \
    kenhowardpdx.vscode-gist \
    kirozen.wordcounter \
    kisstkondoros.typelens \
    mauve.terraform \
    mechatroner.rainbow-csv \
    medo64.render-crlf \
    neilding.language-liquid \
    mikestead.dotenv \
    mjmcloug.vscode-elixir \
    mohsen1.prettify-json \
    mrorz.language-gettext \
    ms-mssql.mssql \
    ms-python.python \
    ms-vscode.Go \
    ms-vscode.powershell \
    ms-vsliveshare.vsliveshare \
    mycelo.oracle-plsql \
    oderwat.indent-rainbow \
    PeterJausovec.vscode-docker \
    PKief.material-icon-theme \
    pomdtr.excalidraw-editor \
    Prisma.vscode-graphql \
    redhat.vscode-yaml \
    ryu1kn.partial-diff \
    shanoor.vscode-nginx \
    samuelcolvin.jinjahtml \
    shakram02.bash-beautify \
    slevesque.vscode-autohotkey \
    sleistner.vscode-fileutils \
    streetsidesoftware.code-spell-checker \
    timonwong.shellcheck \
    vscodevim.vim \
    vscoss.vscode-ansible \
    wdhongtw.gpg-indicator \
    wholroyd.jinja \
    xlab-steampunk.steampunk-spotter \
    zkirkland.vscode-firstupper; do
    "$editor_bin" --install-extension "${extension}" --force 2>/dev/null || true
  done
}

AntigravityIDE() {
  # Antigravity CLI installation if missing
  if ! command -v agy >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/agy" ]; then
    echo "Installation du CLI Google Antigravity (agy)..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || true
  fi

  # Antigravity IDE shortcut creation
  local desktop_dir="$HOME/.local/share/applications"
  local icons_dir="$HOME/.local/share/icons"
  local ide_dir="/opt/Antigravity IDE"
  local ide_bin="$ide_dir/antigravity-ide"
  local source_icon="$ide_dir/resources/app/out/vs/platform/browserOnboarding/static/antigravity.svg"

  if [ -d "$ide_dir" ]; then
    echo "Configuring desktop shortcuts for Antigravity IDE..."
    mkdir -p "$desktop_dir"
    mkdir -p "$icons_dir"

    # Copy icon if available
    if [ -f "$source_icon" ]; then
      cp "$source_icon" "$icons_dir/antigravity-ide.svg"
      icon_path="antigravity-ide"
    else
      icon_path="$ide_dir/resources/app/resources/linux/code.png"
    fi

    # Create .desktop content
    local desktop_content="[Desktop Entry]
Name=Antigravity IDE
Comment=AI-powered IDE by Google DeepMind
GenericName=Text Editor
Exec=\"$ide_bin\" %F
Icon=$icon_path
Type=Application
StartupNotify=true
StartupWMClass=antigravity-ide
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;
Actions=new-empty-window;
Keywords=antigravity;ide;gemini;ai;

[Desktop Action new-empty-window]
Name=New Empty Window
Name[fr]=Nouvelle fenêtre vide
Exec=\"$ide_bin\" --new-window %F
Icon=$icon_path"

    # Write to local applications menu
    echo "$desktop_content" >"$desktop_dir/antigravity-ide.desktop"
    chmod +x "$desktop_dir/antigravity-ide.desktop"

    # Write to Bureau (Desktop) if exists
    if [ -d "$HOME/Bureau" ]; then
      echo "$desktop_content" >"$HOME/Bureau/antigravity-ide.desktop"
      chmod +x "$HOME/Bureau/antigravity-ide.desktop"
    fi

    # Write to Desktop if exists (just in case)
    if [ -d "$HOME/Desktop" ]; then
      echo "$desktop_content" >"$HOME/Desktop/antigravity-ide.desktop"
      chmod +x "$HOME/Desktop/antigravity-ide.desktop"
    fi

    # Update desktop database
    update-desktop-database "$desktop_dir" 2>/dev/null || true
    echo "Antigravity IDE desktop shortcuts successfully created/updated."
  else
    echo "Antigravity IDE is not installed in $ide_dir. Skipping shortcut creation."
  fi
}

WakeMeOps() {
  # WakeMeOps : WakeMeOps est un référentiel Debian pour les applications portables.
  curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
  sudo apt-get update
  sudo apt install -y bottom choose gping himalaya hugo k9s openlens procs rclone ripgrep trivy xh yq
}

WSS() {
  # WSS by Netflix
  # https://github.com/brendangregg/wss.git
  echo ""
}

WTF() {
  # WTF
  if ! command -v wtfutil >/dev/null 2>&1; then
    go install github.com/wtfutil/wtf@latest 2>/dev/null || true
  fi
}

XAuth() {
  # XAuth
  # https://superuser.com/questions/806637/xauth-not-creating-xauthority-file/941244#941244
  rm -f .Xauthority
  # xauth with complain unless ~/.Xauthority exists
  touch ~/.Xauthority
  # only this one key is needed for X11 over SSH
  xauth generate :0 . trusted
  # generate our own key, xauth requires 128 bit hex encoding
  xauth add "${HOST}":0 . "$(xxd -l 16 -p /dev/urandom)"
  # To view a listing of the .Xauthority file, enter the following
  xauth list
}

YakYak() {
  # YakYak : https://www.omgubuntu.co.uk/2017/10/yakyak-opensource-google-hangouts-desktop-app
  sudo snap install yakyak
}

youtube() {
  # youtube-dlg / yt-dlp
  # Le PPA WebUpd8 est obsolète et n'a pas de release pour Ubuntu 24/26.
  # yt-dlp est déjà installé via pip / pipx / uv dans ~/.local/bin/yt-dlp
  echo "yt-dlp est le remplaçant moderne de youtube-dl."
}

YunoHost() {
  # YunoHost : add SSL CA
  sudo cp ~/coincoin.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
}

zquests() {
  # Search commandline tool : https://blog.shevarezo.fr/post/2018/10/31/faire-recherches-internet-ligne-de-commande
  go get -v github.com/zquestz/s
}

ZSH() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

  # Install oh-my-zsh if missing
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended || true
  fi

  # Themes
  if [ ! -d "$zsh_custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$zsh_custom/themes/powerlevel10k" 2>/dev/null || true
  fi

  # Plugins custom
  # 1. zsh-syntax-highlighting (installé dans custom/plugins)
  if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
  fi

  # 2. zsh-autosuggestions
  if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions" 2>/dev/null || true
  fi

  # 3. ugit
  if ! command -v ugit >/dev/null 2>&1 && [ ! -x "/home/linuxbrew/.linuxbrew/bin/ugit" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Bhupesh-V/ugit/master/install)" || true
  fi
  if [ ! -d "$zsh_custom/plugins/ugit" ]; then
    git clone https://github.com/Bhupesh-V/ugit.git "$zsh_custom/plugins/ugit" 2>/dev/null || true
  fi

  # 4. zsh-wakatime
  if [ ! -d "$zsh_custom/plugins/zsh-wakatime" ]; then
    git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "$zsh_custom/plugins/zsh-wakatime" 2>/dev/null || true
    if [ -f "$zsh_custom/plugins/zsh-wakatime/wakatime.plugin.zsh" ]; then
      cp "$zsh_custom/plugins/zsh-wakatime/wakatime.plugin.zsh" "$zsh_custom/plugins/zsh-wakatime/zsh-wakatime.plugin.zsh"
    fi
  fi

  # CLI & Fonts
  if [ ! -d "$HOME/.local/share/fonts/NerdFonts" ]; then
    cd /tmp || exit
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git 2>/dev/null || true
    if [ -d "nerd-fonts" ]; then
      cd nerd-fonts && ./install.sh "FiraCode" 2>/dev/null || true
    fi
  fi
  snap install starship --edge 2>/dev/null || true
  curl -fsSL https://fx.wtf/install.sh | sudo sh 2>/dev/null || true
}

Annexes() {
  # OOo extension
  echo https://github.com/seanyeh/vibreoffice
}

FixAptRepositories() {
  echo "=== Réparation et modernisation des dépôts et clés APT ==="

  # Assurer la présence des répertoires de keyrings
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo install -m 0755 -d /usr/share/keyrings

  local codename
  codename="$(lsb_release -cs 2>/dev/null || echo "resolute")"

  # 1. Signal Desktop : téléchargement propre de la clé et configuration du dépôt unique signed-by
  echo "-> Modernisation du dépôt Signal Desktop..."
  curl -fsSL https://updates.signal.org/desktop/apt/keys.asc 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null || true
  if [ -f /usr/share/keyrings/signal-desktop-keyring.gpg ]; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal-xenial.list >/dev/null
  fi

  # 2. Google Cloud SDK : suite générique cloud-sdk (résolution de l'erreur 404 sur resolute) + clé
  echo "-> Modernisation du dépôt Google Cloud SDK..."
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /usr/share/keyrings/cloud.google.gpg >/dev/null || true
  if [ -f /usr/share/keyrings/cloud.google.gpg ]; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
  fi

  # 3. Docker CE : clé moderne dans /etc/apt/keyrings et configuration du repo
  echo "-> Modernisation du dépôt Docker CE ($codename)..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg 2>/dev/null | sudo tee /etc/apt/keyrings/docker.asc >/dev/null || true
  sudo chmod a+r /etc/apt/keyrings/docker.asc 2>/dev/null || true
  if [ -f /etc/apt/keyrings/docker.asc ]; then
    local docker_list="/etc/apt/sources.list.d/archive_uri-https_download_docker_com_linux_ubuntu-${codename}.list"
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" | sudo tee "$docker_list" >/dev/null
  fi

  # 4. Azure CLI : installation de la clé Microsoft officielle dans /etc/apt/keyrings et signed-by
  echo "-> Modernisation du dépôt Azure CLI..."
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null || true
  if [ -f /etc/apt/keyrings/microsoft.gpg ]; then
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ ${codename} main" | sudo tee /etc/apt/sources.list.d/azure-cli.list >/dev/null
  fi

  # 5. Nettoyage des anciens dépôts obsolètes ou doublons
  if [ -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    echo "-> Suppression de l'ancien dépôt obsolète microsoft-prod.list..."
    sudo rm -f /etc/apt/sources.list.d/microsoft-prod.list
  fi
  # PPA webupd8 (incompatible / 404 sur resolute)
  if ls /etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8* >/dev/null 2>&1; then
    echo "-> Suppression du PPA webupd8 obsolète (404 sur resolute)..."
    sudo rm -f /etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8*
  fi

  # 6. Lynis (Cisofy) : migration vers /etc/apt/keyrings/cisofy.gpg avec signed-by
  echo "-> Modernisation du dépôt Lynis (Cisofy)..."
  curl -fsSL https://packages.cisofy.com/keys/cisofy-software-public.key 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /etc/apt/keyrings/cisofy.gpg >/dev/null || true
  if [ -f /etc/apt/keyrings/cisofy.gpg ]; then
    echo "deb [signed-by=/etc/apt/keyrings/cisofy.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list >/dev/null
  fi

  # 7. Lutris : utilisation de la clé moderne si le dépôt tierce est maintenu
  if [ -f /etc/apt/sources.list.d/lutris.list ]; then
    echo "-> Modernisation de la clé Lutris..."
    curl -fsSL https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /etc/apt/keyrings/lutris.gpg >/dev/null || true
  fi

  # 8. Boot-Repair : mise à niveau de la clé PPA vers RSA 4096 (rejet RSA 1024)
  if [ -f /etc/apt/sources.list.d/boot-repair.list ]; then
    echo "-> Modernisation de la clé Boot-Repair (RSA 4096)..."
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x308901CC3AD15B3AB64CC0EF3E687364D2EDDB5F" 2>/dev/null | gpg --dearmor 2>/dev/null | sudo tee /etc/apt/keyrings/boot-repair.gpg >/dev/null || true
  fi

  # 9. Mise à jour de la base APT
  echo "-> Rafraîchissement des dépôts APT..."
  sudo apt-get update || true
  echo "[✓] Configuration des dépôts et clés APT corrigée et modernisée."
}

Main() {
  FixAptRepositories
  Setup
  ZSH
  #  WIFI
  #  PPA
  Packages
  Python
  GO
  # install_appimages
  #  Albert
  #  Android
  #  Ansible
  #  Argbash
  #  Atom
  #  Bat
  BootRepair
  #  bcctools
  #  bluegriffon
  Brew
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
  #  Delta
  Docker
  #  Douane
  # Dropbox
  #  DroidCAM
  DVD
  #  Element
  FlatPack
  #  Feedreader
  Fuzzy
  #  GCStar
  #  Github
  GnomeExtensions
  GnomeConfigurations
  #  GrafTCP
  #  GRAPH
  #  Infrakit
  #  IssueHelper
  Hurl
  #  Keybase
  K3S
  Kubernetes
  #  Lightworks
  lutris
  lynis
  #  lynishardening
  MammouthCode
  Minishift
  mkcert
  #  MultiOSUSB
  #  Multisystem
  Mullvad
  Music
  #  nicotine
  # nix
  # npmfx
  # OfflineImap
  # OneDrive
  # orionbrowser
  #  OSQuery
  # PlayOnLinux
  # Powershell
  # ProtonBridge
  #  ProtonVPN
  # Puppet
  #  rapidphotodownloader
  #  RocketChat
  Rust
  #  s3benchmark
  # scrcpy
  # Screensavers
  Signal
  Slack
  # SNAP
  #  Spip-Cli
  # Spotify
  Stacer
  # Students
  # STui
  # Taskfile
  # Teams
  Terminal
  # TLDR
  # Trello
  ttfmscorefontsinstaller
  # urbackup
  VIM
  NeoVim
  # VirtualBox
  # Vivaldi
  # VSCodium
  AntigravityIDE
  WakeMeOps
  # WSS
  WTF
  # XAuth
  # YakYak
  youtube
  # YunoHost
  SetupAISkillsMCP
  SetupRTK
  SetupYubiKey
}

SetupAISkillsMCP() {
  echo "=== Configuration des Skills et MCP IA ==="
  local central_skills="$HOME/.local/share/ai-skills"
  mkdir -p "$central_skills"

  # Liens symboliques pour centraliser les skills entre tous les outils
  local targets=(
    "$HOME/.config/opencode/skills"
    "$HOME/.gemini/config/skills"
    "$HOME/.copilot/skills"
    "$HOME/.config/mammouth/skills"
  )

  for target in "${targets[@]}"; do
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
      if [ "$(readlink "$target")" != "$central_skills" ]; then
        rm -f "$target"
        ln -s "$central_skills" "$target"
      fi
    else
      [ -d "$target" ] && cp -r "$target"/* "$central_skills"/ 2>/dev/null
      rm -rf "$target"
      ln -s "$central_skills" "$target"
    fi
    echo "[✓] Lien symbolique créé : $target -> $central_skills"
  done

  # Compilation et installation de l'outil sync-ai-tools en Go si disponible
  if [ -d "$HOME/bin/src/sync-ai-tools" ] && command -v go >/dev/null 2>&1; then
    echo "Compilation de sync-ai-tools..."
    (cd "$HOME/bin/src/sync-ai-tools" && make install)
  fi
}

SetupRTK() {
  echo "=== Installation et configuration de RTK (Token Compressor) ==="

  # 1. Vérification et installation du binaire rtk
  if ! command -v rtk >/dev/null 2>&1; then
    if [ -x "/home/linuxbrew/.linuxbrew/bin/rtk" ]; then
      export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    elif command -v brew >/dev/null 2>&1; then
      echo "Installation de rtk via Homebrew..."
      brew install rtk
    else
      echo "Installation de rtk via script officiel..."
      curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/main/install.sh | bash 2>/dev/null || true
    fi
  fi

  if ! command -v rtk >/dev/null 2>&1 && [ ! -x "/home/linuxbrew/.linuxbrew/bin/rtk" ]; then
    echo "[!] Attention : Le binaire rtk est introuvable. Veuillez l'installer au préalable."
    return 1
  fi

  local rtk_bin
  rtk_bin="$(command -v rtk 2>/dev/null || echo "/home/linuxbrew/.linuxbrew/bin/rtk")"

  # 2. Configuration pour Google Antigravity
  echo "-> Configuration de RTK pour Antigravity..."
  "$rtk_bin" init -g --agent antigravity --auto-patch </dev/null 2>/dev/null || true

  # 3. Configuration pour OpenCode
  echo "-> Configuration de RTK pour OpenCode..."
  "$rtk_bin" init -g --opencode --auto-patch </dev/null 2>/dev/null || true

  # 4. Configuration pour GitHub Copilot CLI / VS Code Copilot
  echo "-> Configuration de RTK pour GitHub Copilot..."
  "$rtk_bin" init -g --copilot --auto-patch </dev/null 2>/dev/null || true

  # 5. Configuration pour Mammouth Code (partage du plugin OpenCode)
  echo "-> Configuration de RTK pour Mammouth Code..."
  local opencode_plugin="$HOME/.config/opencode/plugins/rtk.ts"
  local mammouth_plugins_dir="$HOME/.config/mammouth/plugins"
  mkdir -p "$mammouth_plugins_dir"

  if [ -f "$opencode_plugin" ]; then
    ln -sf "$opencode_plugin" "$mammouth_plugins_dir/rtk.ts"
    echo "[✓] Lien symbolique créé : $mammouth_plugins_dir/rtk.ts -> $opencode_plugin"
  fi

  echo "[✓] Configuration de RTK terminée avec succès."
}

SetupYubiKey() {
  echo "=== Configuration YubiKey (Authentification PAM & Verrouillage automatique) ==="

  local setup_script="$HOME/bin/setup_yubikey.sh"
  local autolock_script="$HOME/bin/enable_yubikey_autolock.sh"

  # 1. Vérification des paquets requis
  sudo apt install -y libpam-u2f pamu2fcfg udev

  # 2. Configuration du verrouillage automatique au retrait de la YubiKey
  if [ -f "$autolock_script" ]; then
    echo "-> Configuration du verrouillage automatique au retrait de la YubiKey..."
    sudo bash "$autolock_script" || echo "[!] Attention : Échec de l'activation du verrouillage YubiKey"
  fi

  # 3. Configuration de l'authentification PAM (login / sudo / screenlock)
  if [ -f "$setup_script" ]; then
    local u2f_keys="$HOME/.config/Yubico/u2f_keys"
    if [ -f "$u2f_keys" ] && [ -s "$u2f_keys" ]; then
      echo "-> Clé YubiKey déjà enregistrée dans $u2f_keys. Application des modules PAM..."
      sudo bash "$setup_script" || echo "[!] Attention : Erreur lors de l'application de la config PAM YubiKey"
    else
      echo "-> Première configuration YubiKey détectée :"
      echo "   Veuillez brancher votre clé YubiKey et la toucher lorsqu'elle clignote."
      sudo bash "$setup_script" || echo "[!] Attention : Enregistrement de la clé YubiKey ignoré ou annulé"
    fi
  fi
}

# Appel automatique ou manuel de la fonction d'installation AppImage
# Décommentez la ligne suivante pour installer les AppImages lors du setup principal :
# install_appimages

if [ -n "$1" ]; then
  $1
else
  Main
fi
