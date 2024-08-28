#!/bin/bash

Setup()
{
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
  test -f  ~/.config/systemd/user/geoclue-agent.service && systemctl --user enable --now geoclue-agent.service
  # Add CDROM Roles
  sudo usermod -a -G cdrom daffy
}

WIFI()
{
  # Wifi do not refresh after suspend
  # power on wifi card
  # https://askubuntu.com/questions/452826/wireless-networking-not-working-after-resume-in-ubuntu-14-04?noredirect=1&lq=1
  (cat << 10_resume_wifi
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
  (cat << wifi-resume.service
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
}

PPA()
{
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
    ppa:flexiondotorg/quickemu
  do
    sudo apt-add-repository -n --yes ${ppa}
  done
  sudo apt-get update
  sudo apt install -y hollywood qownnotes peek variety timeshift veracrypt \
    ddgr software-properties-common boot-repair variety \
    grub-customizer bashtop piper gh nautilus-nextcloud appimagelauncher \
    quickgui quickemu
  # can not install on focal (dependancy problems) sudo apt install -y oqapy
}

Packages()
{
  # Install some packages
  sudo apt install -y \
    acct alot asciidoc aide aide-common alien apt-file apt-cacher aria2 asciidoctor aspell-fr atop awscli auditd \
    baobab barrier bc blueman brasero build-essential bundler \
    ca-certificates cargo checkinstall cheese chrome-gnome-shell cifs-utils clipit checksecurity cloc cmake colord-gtk-utils colordiff corkscrew cowsay cpuid curl \
    darktable debian-goodies default-jre debsecan debsums deluge-gtk deluged dfc dkms digikam dnstracer dos2unix \
    easytag ethstatus ethtool ettercap-graphical evince evolution evolution-ews extrace exuberant-ctags \
    fail2ban fastboot fdupes ffmpegthumbnailer filezilla flameshot fonts-powerline fortunes fonts-radisnoir fpart ftp \
    gajim geary geogebra-gnome gimp  git-extras gnome-tweaks gnome-usage gnupg2 gnupg-agent gparted graphviz gromit-mpx gron gthumb guake guake-indicator \
    handbrake hashcat heimdall-flash-frontend hey htop httpcode httperf httpie httping hugin hugo hunspell-fr hunspell-fr-comprehensive hwloc libhwloc-contrib-plugins \
    i2c-tools: iftop inkscape innoextract ioping iotop ipcalc iproute2 iptraf-ng iputils-arping iptstate \
    josm josm-l10n jq jxplorer \
    kdenlive kdocker keepassxc keychain kigo klavaro kodi krita krita-l10n \
    ldap-utils lftp libeatmydata1 libimage-exiftool-perl libpam-tmpdir libpam-yubico libreoffice-calc libreoffice-draw libreoffice-help-fr libreoffice-impress libreoffice-math libreoffice-nlpsolver libreoffice-voikko libreoffice-writer libreoffice-writer2latex libreoffice-gnome libva-glx2 lm-sensors libsecret-tools lnav lolcat lsof ltrace lxc python3-lxc lynx \
    mc meld mgitstatus miller mono-complete mumble mutt \
    nautilus-image-converter ncal ncdu needrestart nemo-gtkhash netcat-openbsd neomutt nethogs network-manager-openvpn-gnome nextcloud-desktop nmap nmon notmuch numatop npm \
    ocrfeeder offlineimap ooo-thumbnailer openboard openconnect openshot-qt openssh-client openssh-server openvpn \
    p7zip pandoc parallel parted pass patch pavucontrol pcp pdfgrep perf-tools-unstable perl-doc pgtop photocollage pinentry-curses pinentry-tty pitivi pm-utils postgresql-client progress psensor pssh putty-tools python3 python3-dev python3-pycurl python3-virtualenv pwgen pydf python3-gpg python-is-python3 \
    qalc qemu-system-gui qtpass \
    rclone rdesktop redshift-gtk remmina rename ripgrep rpm rsync \
    s3cmd screen screenkey scribus seahorse scdaemon shotwell ssh-import-id sshuttle simple-scan simplescreenrecorder smartmontools sound-juicer sosreport source-highlight spectre-meltdown-checker speedtest-cli sshfs sshpass sslscan socat software-properties-common stopmotion strace stunnel4 synaptic synfigstudio sysstat \
    tcpdump tellico termshark testssl.sh thefuck thunderbird tig tilix toilet torbrowser-launcher traceroute trash-cli tshark \
    unison-gtk unrar urlview \
    vagrant vifm vim-fugitive vim-nox vim-python-jedi vim-youcompleteme virt-manager virtualenv vlc \
    whois winbind wireshark wkhtmltopdf \
    xauth xdg-utils xournalpp xscreensaver xsane \
    yamllint \
    zmap

  sudo apt-get install -y libquazip5-1 libqrencode4
  sudo ln -s /usr/lib/x86_64-linux-gnu/libqrencode.so.4 /usr/lib/x86_64-linux-gnu/libqrencode.so.3

  # Python alternatives
  # sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
  # sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 2
  sudo update-alternatives  --set python /usr/bin/python3.11

}

SNAP()
{
  # for snap in androidsdk chromium czkawka code github-desktop gnome-system-monitor hub hugo ipfs-desktop \
  for snap in chromium czkawka code codium github-desktop gnome-system-monitor hub hugo ipfs-desktop \
    keepassxc magnus mailspring onlyoffice-desktopeditors procs pycharm-community \
    rambox shellcheck slack spotify strawberry telegram-desktop whatsdesk yakyak yq
  do
    snap install --classic ${snap}
  done
  sudo snap connect czkawka:removable-media
}

Python()
{
  # Python
  snap install pycharm-community --classic

  # Try alphago .....
  # cd /tmp
  # git clone https://github.com/maxpumperla/betago
  # cd betago
  # python run_demo.py

  # Install some other pip cool stuff
  for pkg in bcc bpytop betago configobj docopt git-pull-request grip howdoi icdiff jsonnet kapitan litecli mycli search-that-hash shodan spotify-cli-linux tenserflow terminaltables virtualenv yt-dlp
  do
    pip install "${pkg}" --upgrade --break-system-packages
  done
}

GO()
{
  # GO
  # https://golang.org/dl/
  mkdir -p "$GOROOT" "$GOPATH"
  cd "$GOROOT" || exit
  wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz
  tar xvfz go1.9.2.linux-amd64.tar.gz
  rm go1.9.2.linux-amd64.tar.gz
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


  # tips cross compilation
  # CGO_ENABLED=yes go build
  go get github.com/claudiodangelis/qrcp
  # cd /tmp || exit
  git clone https://github.com/rs/curlie.git
  cd curlie
  go build .
  go install .
}

Crontab()
{
  # Install Usefull local crontabs
  cd /tmp || exit
  cat > crontab << \EOF
16 02 * * * /home/daffy/bin/get_screensavers.py /home/daffy/Dropbox/Screensavers
@reboot cd /home/daffy/Documents/Code/git/github/noisy && /usr/bin/docker run -it noisy --config config.json
EOF
  crontab crontab && rm crontab
}

Android()
{
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

Ansible()
{
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

Argbash()
{
  # Argbash : https://github.com/matejak/argbash/
  cd /tmp || exit 1
  wget https://github.com/matejak/argbash/archive/2.8.0.zip
  unzip 2.8.0.zip
  cd argbash-2.8.0 || exit 1
  cd resources || exit 1
  make install PREFIX=$HOME/.local
}

Atom()
{
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
    terraform-fmt
  do 
    apm install "${module}"
  done
  echo "apm complete"
}

Bat()
{
  # Bat
  # https://twitter.com/fdevillamil/status/1095785002791550977?s=09
  cd /tmp || exit 1
  wget https://github.com/sharkdp/bat/releases/download/v0.10.0/bat_0.10.0_amd64.deb
  sudo dpkg -i bat_0.10.0_amd64.deb
}

Delta()
{
  cd /tmp || exit 1
  wget https://github.com/barnumbirr/delta-debian/releases/download/v0.1.1-1/delta_0.1.1-1_amd64_debian_buster.deb
  sudo dpkg -i delta_0.1.1-1_amd64_debian_buster.deb
}

bcctools()
{
  # bcc-tools
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D4284CDD
  echo "deb [trusted=yes] https://repo.iovisor.org/apt/bionic bionic-nightly main" | sudo tee /etc/apt/sources.list.d/iovisor.list
  sudo apt-get update
  sudo apt-get install -y bcc-tools libbcc-examples linux-headers-"$(uname -r)" python3-bcc
}

bluegriffon()
{
  #- FIXME bluegriffon
  cd /tmp || exit
  wget http://bluegriffon.org/freshmeat/3.0.1/bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
  sudo dpkg -i bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb && rm bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
}

browsh()
{
  # browsh Text Web browser
  # Needs Firefox
  cd /tmp || exit
  wget https://github.com/browsh-org/browsh/releases/download/v1.6.4/browsh_1.6.4_linux_amd64.deb
  sudo dpkg -i browsh_1.6.4_linux_amd64.deb
}

Calibre()
{
  # Install Calibre
  sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
}

Chaos()
{
  # Chaos toolkit : https://medium.com/chaos-toolkit/announcing-chaos-discover-and-chaos-init-ff2bf02c5a85
  docker pull chaostoolkit/chaostoolkit
  docker run -it chaostoolkit/chaostoolkit discover chaostoolkit-kubernetes
}

ChatGPT()
{
  # Install a chatgpt commandline
  curl -sS https://raw.githubusercontent.com/0xacx/chatGPT-shell-cli/main/install.sh | sudo -E bash
}

Children()
{
  # Add some games
  sudo apt install -y \
    brainparty briquolo cgoban colobot connectagram \
    extremetuxracer fretsonfire-songs-muldjord frozen-bubble gbrainy gcompris-qt grhino \
    junior-config junior-programming khangman lutris mu-cade opencity pingus supertuxkart tomatoes tuxmath tuxtype

  # when you need to add users to junior-programming
  sudo dpkg-reconfigure --force junior-config
}

Chrome()
{
  # Chrome
  # https://doc.ubuntu-fr.org/google_chrome
  # https://www.google.com/chrome/browser/desktop/index.html
  sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y google-chrome-stable
}

chromeIPass()
{
  # chromeIPass : https://github.com/pfn/passifox/
  sudo wget https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx -O /usr/lib/keepass2/KeePassHttp.plgx
}

CLOUD()
{
  # some cloud tools
  # Packer
  # https://www.packer.io/downloads.html
  cd ~/bin || exit
  wget https://releases.hashicorp.com/packer/1.1.1/packer_1.1.1_linux_amd64.zip
  unzip -f packer_1.1.1_linux_amd64.zip
  rm packer_1.1.1_linux_amd64.zip
  
  # terraform
  # https://www.terraform.io/downloads.html
  cd ~/bin || exit
  wget https://releases.hashicorp.com/terraform/1.2.9/terraform_1.2.9_linux_amd64.zip
  unzip -f terraform_1.2.9_linux_amd64.zip
  rm -f terraform_1.2.9_linux_amd64.zip getTerraformProviders.sh
  wget https://gist.githubusercontent.com/jnahelou/63947831a8154daf6bc3573cc27ed373/raw/e7c685d8ae80e3c6b17238703a870cab00edc7b0/getTerraformProviders.sh
  sudo mkdir -p /usr/local/terraform/toolbox/providers/
  sudo bash ~/bin/getTerraformProviders.sh
  cd "$HOME" || exit
  terraform init -plugin-dir=/usr/local/terraform/toolbox/providers/
  # terraform graph | dot -Tpng > terraform-graph.png
  
  # rancher
  # https://github.com/rancher/cli/release
  cd ~/bin || exit
  wget https://github.com/rancher/cli/releases/download/v0.6.5-rc4/rancher-linux-amd64-v0.6.5-rc4.tar.gz
  tar xvfz rancher-linux-amd64-v0.6.5-rc4.tar.gz
  rm rancher-linux-amd64-v0.6.5-rc4.tar.gz
  # https://github.com/rancher/rancher-compose/releases
  cd ~/bin || exit
  wget https://github.com/rancher/rancher-compose/releases/download/v0.12.5/rancher-compose-linux-amd64-v0.12.5.tar.gz
  tar xvfz rancher-compose-linux-amd64-v0.12.5.tar.gz
  rm rancher-compose-linux-amd64-v0.12.5.tar.gz
  
  # ack-grep
  # https://beyondgrep.com/install/
  curl https://beyondgrep.com/ack-2.22-single-file > ~/bin/ack && chmod 0755 ~/bin/ack

  # CloudConvert
  sudo npm install -g cloudconvert-cli
  export CLOUDCONVERT_API_KEY=changeme

  # Gandi Client
  cd /tmp || exit
  sudo apt-get install -y python-nose python3-nose python-ipy
  git clone https://github.com/Gandi/gandi.cli.git
  cd gandi.cli  || exit
  ln -sf packages/debian debian && debuild -us -uc -b && sudo dpkg -i ../python-gandicli_1.0_all.deb

  # Vault
  wget https://releases.hashicorp.com/vault/0.9.3/vault_0.9.3_linux_amd64.zip -O ~/bin/vault_0.9.3_linux_amd64.zip
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

  # AZURE
  # Install prerequisite packages: 
  sudo apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y
  # Modify your sources list:
  AZ_REPO=$(lsb_release -cs)
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
  sudo tee /etc/apt/sources.list.d/azure-cli.list
  # Get the Microsoft signing key:
  sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
    --keyserver packages.microsoft.com \
    --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF
  # Install the CLI:
  sudo apt-get update
  sudo apt-get install azure-cli
  # Install Azure Functions Core Tools
  cd /tmp || exit
  wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  sudo apt-get update
  sudo apt-get install -y azure-functions-core-tools

  # ASDF
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
  # already in this git repo here
  # echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
  # echo ". $HOME/.asdf/asdf.sh" >> ~/.zshrc
}

coolretroterm()
{
  # FIXME cool-retro-term
  cd /tmp || exit
  sudo apt -y install build-essential qml-module-qtgraphicaleffects qml-module-qt-labs-folderlistmodel qml-module-qt-labs-settings qml-module-qtquick-controls qml-module-qtquick-dialogs qmlscene qt5-default qt5-qmake qtdeclarative5-dev qtdeclarative5-localstorage-plugin qtdeclarative5-qtquick2-plugin qtdeclarative5-window-plugin
  git clone --recursive https://github.com/Swordfish90/cool-retro-term.git
  cd cool-retro-term || exit
  qmake && make
  sudo make install
}

CozyDrive()
{
  # CozyDrive
  mkdir -p ~/Applications
  wget -O ~/Applications/CozyDrive-3.6.0-x86_64.AppImage https://nuts.cozycloud.cc/download/channel/stable/64
  chmod +x ~/Applications/CozyDrive-3.6.0-x86_64.AppImage
  GnomeExtensions
  gnomeshell-extension-manage --install --extension-id 1031
}

Ctop()
{
  # Top-like interface for container metrics https://ctop.sh
  sudo wget https://github.com/bcicen/ctop/releases/download/v0.7/ctop-0.7-linux-amd64 -O /usr/local/bin/ctop
  sudo chmod +x /usr/local/bin/ctop
}

Docker()
{
  # FIXME Docker
  # https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
  sudo apt-get install linux-image-extra-"$(uname -r)" linux-image-extra-virtual
  sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install docker-ce docker-compose
  cd /tmp || exit
  wget https://github.com/DockStation/dockstation/releases/download/v1.3.0/dockstation_1.3.0_amd64.deb
  sudo dpkg -i /tmp/dockstation_1.3.0_amd64.deb && rm /tmp/dockstation_1.3.0_amd64.deb
  sudo gpasswd -a $USER docker
  # https://github.com/jesseduffield/lazydocker#installation
  go get github.com/jesseduffield/lazydocker
}

Douane()
{
# Douane Firewal
# Following doc : https://github.com/Douane/Douane
sudo apt install liblog4cxx-dev libdbus-c++-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libgtkmm-3.0-dev
}

DroidCAM()
{
  # DroiCAM : use smartphone as webcam on computer
  # https://www.dev47apps.com/droidcam/linux/
  cd /tmp/ || exit 1
  wget https://files.dev47apps.net/linux/droidcam_latest.zip
  unzip droidcam_latest.zip -d droidcam
  cd droidcam && sudo ./install-client
  sudo apt install linux-headers-`uname -r` gcc make
  sudo ./install-video
  sudo ./install-sound
}

Dropbox()
{
  # Dropbox
  # https://www.dropbox.com/install-linux
  cd /tmp || exit 1
  wget -O dropbox_2020.03.04_amd64.deb https://www.dropbox.com/download?dl=packages/debian/dropbox_2020.03.04_amd64.deb
  sudo dpkg -i dropbox_2020.03.04_amd64.deb
  sudo apt --fix-broken install
  echo fs.inotify.max_user_watches=100000 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p
}

DVD()
{
  # Encrypted DVD
  sudo apt install -y libdvd-pkg
  sudo dpkg-reconfigure libdvd-pkg
}

Element()
{
  # Element : a Matrix client
  sudo apt install -y wget apt-transport-https
  sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
  sudo apt update
  sudo apt install -y element-desktop
}

FlatPackages()
{
  # misc softwares available with flatpack command
  FlatPack
  for pkg in ch.openboard.OpenBoard com.getpostman.Postman com.github.xournalpp.xournalpp com.valvesoftware.Steam \
    org.geogebra.GeoGebra org.gnome.Cheese org.gnome.FeedReader org.jamovi.jamovi org.jdownloader.JDownloader \
    org.kde.krita org.openshot.OpenShot org.openstreetmap.josm org.pitivi.Pitivi io.github.Bavarder.Bavarder
  do
    flatpak install flathub "${pkg}"
  done
}

FlatPack()
{
  # New Package system
  sudo apt install -y flatpak
  sudo apt install -y gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

Fuzzy()
{
  # fzf: Fuzzy Finder
  cd /tmp || exit
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
}

GCStar()
{
  # gcstar : collection software
  sudo apt install -y libogg-vorbis-header-pureperl-perl libnet-freedb-perl libmp3-tag-perl libgd-graph3d-perl libdatetime-format-strptime-perl libtest-mocktime-datecalc-perl libgtk3-simplelist-perl libxml-simple-perl
  cd /tmp || exit
  wget https://gitlab.com/GCstar/GCstar/-/archive/v1.7.3/GCstar-v1.7.3.tar.gz
  tar xvfz GCstar-v1.7.3.tar.gz
  cd /tmp/GCstar-v1.7.3/gcstar && sudo ./install
  rm /tmp/GCstar-v1.7.3.tar.gz*
}

Github()
{
  # Github
  snap install --edge github-desktop
  snap install hub --classic
}

GnomeExtensions()
{
  # Install Gnome-extensions
  # https://wiki.gnome.org/Projects/GnomeShell/Extensions#Enabling_extensions
  # https://github.com/cyberalex4life/gnome-shell-extension-cl/blob/master/gnome-shell-extension-cl
  # sound-output-device-chooser@kgshank.net                           - enabled    
  gnomeshell-extension-manage --install --extension-id 906
  # alternate-tab@gnome-shell-extensions.gcampax.github.com           - enabled    
  gnomeshell-extension-manage --install --extension-id 15
  # drive-menu@gnome-shell-extensions.gcampax.github.com              - enabled    
  gnomeshell-extension-manage --install --extension-id 7
  # windowsNavigator@gnome-shell-extensions.gcampax.github.com        - enabled    
  gnomeshell-extension-manage --install --extension-id 10
  # refresh-wifi@kgshank.net                                          - enabled    
  gnomeshell-extension-manage --install --extension-id 905
  # extensions@abteil.org                                             - enabled    
  gnomeshell-extension-manage --install --extension-id 1036
  # auto-move-windows@gnome-shell-extensions.gcampax.github.com       - enabled    
  gnomeshell-extension-manage --install --extension-id 16
  # workspace-switch-wraparound@theychx.org                           - enabled    
  gnomeshell-extension-manage --install --extension-id 1116
  # panel-osd@berend.de.schouwer.gmail.com
  gnomeshell-extension-manage --install --extension-id 708
  # cast-to-tv@rafostar.github.com                                    - enabled    
  gnomeshell-extension-manage --install --extension-id 1544
  # todolist@tomMoral.org                                             - enabled    
  gnomeshell-extension-manage --install --extension-id 1104                 
  # CoverflowAltTab@palatis.blogspot.com                              - enabled    
  gnomeshell-extension-manage --install --extension-id 97
  cd ~/.local/share/gnome-shell/extensions/cast-to-tv@rafostar.github.com || exit
  npm install

  # other params
  dconf write /org/gnome/shell/extensions/panel-osd/y-pos 5.0
  dconf write /org/gnome/shell/extensions/panel-osd/x-pos 90.0
}

GnomeConfigurations()
{
  # Misc Gnome configurations
  # Some help : https://askubuntu.com/questions/971067/how-can-i-script-the-settings-made-by-gnome-tweak-tool
  # dconf watch / is your friend !
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-last-coordinates '(50.633000000000003, 3.0586000000000002)'
  gsettings set org.gnome.desktop.wm.preferences theme 'Radiance'
  gsettings set org.gnome.desktop.interface gtk-theme 'Radiance'
  gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'
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
}

GrafTCP()
{
  # GraphTCP : https://github.com/hmgle/graftcp
  cd /tmp && git clone https://github.com/hmgle/graftcp.git
  cd graftcp && make
}

GRAPH()
{
  # dgraph
  curl https://get.dgraph.io -sSf | bash
}

Infrakit()
{
  # Infrakit : A toolkit for creating and managing declarative, self-healing infrastructure.
  mkdir -p $GOPATH/src/github.com/docker || true
  cd $GOPATH/src/github.com/docker || exit
  git clone git@github.com:docker/infrakit.git
  cd infrakit && make get-tools & make ci && make binaries
  cp build/* ~/bin/
}

IssueHelper()
{
  # Issue-helper
  sudo apt remove cargo rustc
  curl https://sh.rustup.rs -sSf | sh
  source "${HOME}"/.cargo/env
  cargo install gli
}

Keybase()
{
  # Keybase
  # https://keybase.io/docs/the_app/install_linux
  curl -o /tmp/keybase_amd64.deb -O https://prerelease.keybase.io/keybase_amd64.deb
  sudo dpkg -i /tmp/keybase_amd64.deb
  sudo apt-get install -f
}

Kubernetes()
{
  # Kubernetes
  # https://github.com/kubernetes/minikube
  cd ~/bin/ || exit
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl && chmod +x kubectl
  curl -Lo karto https://github.com/Zenika/karto/releases/download/v1.1.0/karto && chmod +x karto
  export MINIKUBE_WANTUPDATENOTIFICATION=false
  export MINIKUBE_WANTREPORTERRORPROMPT=false
  export MINIKUBE_HOME=$HOME
  export CHANGE_MINIKUBE_NONE_USER=true
  mkdir "$HOME"/.kube || true
  touch "$HOME"/.kube/config
  export KUBECONFIG="$HOME"/.kube/config
  minikube start
  # this for loop waits until kubectl can access the api server that Minikube has created
  for i in {1..150}; do # timeout for 5 minutes
    echo "$i\c"
    kubectl get po &> /dev/null
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
  wget https://github.com/garethr/kubeval/releases/download/0.7.3/kubeval-linux-amd64.tar.gz
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
  set -x; cd "$(mktemp -d)" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" && "$KREW" install krew
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  kubectl krew update
  for plugin in debug rbac-lookup who-can flame
  do 
    kubectl krew install ${plugin}
  done

  # Popeye - A Kubernetes Cluster Sanitizer
  git clone https://github.com/derailed/popeye
  cd popeye
  # Build and install
  go install
  # Run
  # popeye
}

Lightworks()
{
  # FIXME Lightworks
  cd /tmp || exit
  wget -O lightworks.deb "https://www.lwks.com/index.php?option=com_docman&task=doc_download&gid=194"
  sudo dpkg -i lightworks.deb && rm lightworks.deb
  sudo apt --fix-broken install -y
}

lutris()
{
  # Lutris Game Platform
  echo "deb [signed-by=/etc/apt/keyrings/lutris.gpg] https://download.opensuse.org/repositories/home:/strycore/Debian_12/ ./" | sudo tee /etc/apt/sources.list.d/lutris.list > /dev/null
  wget -q -O- https://download.opensuse.org/repositories/home:/strycore/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/keyrings/lutris.gpg > /dev/null
  sudo apt update
  sudo apt install -y lutris
}

lynis()
{
  # lynis update is really major from ubuntu packages
  sudo apt install -y apt-transport-https
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F
  echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
  echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
  sudo apt update
  sudo apt install -y lynis
}

lynishardening()
{
  # some suggestions afer lynis report
  grep -q "*  hard  core  0" /etc/security/limits.conf || \
    echo "*  hard  core  0" | sudo tee -a /etc/security/limits.conf
  grep -q "fs.suid_dumpable = 0" /etc/sysctl.conf || \
    echo "fs.suid_dumpable = 0" | sudo tee -a /etc/sysctl.conf
  grep -q "ulimit -S -c 0" /etc/profile || \
    echo "ulimit -S -c 0 > /dev/null 2>&1" | sudo tee -a /etc/profile
  sudo sysctl -p
  sudo postconf -e smtpd_banner=mycomputer
  sudo postconf -e disable_vrfy_command=yes 
  grep -q "AllowTcpForwarding=no" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "AllowTcpForwarding=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "ClientAliveCountMax=2" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "ClientAliveCountMax=2" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "Compression=no" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "Compression=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "LogLevel=VERBOSE" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "LogLevel=VERBOSE" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "MaxAuthTries=3" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "MaxAuthTries=3" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "MaxSessions=2" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "MaxSessions=2" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  grep -q "TCPKeepAlive=no" /etc/ssh/sshd_config.d/lynis.conf || \
    echo "TCPKeepAlive=no" | sudo tee -a /etc/ssh/sshd_config.d/lynis.conf
  sudo apt install acct sysstat
  sudo sed -i -e 's+ENABLED="false"+ENABLED="true"+g+' /etc/default/sysstat
  sudo systemctl enable sysstat
  sudo systemctl restart sysstat
  sudo systemctl restart ssh
}

Minishift()
{
  # Minishift
  # https://github.com/MiniShift/minishift#getting-started
  cd /tmp || exit
  wget https://github.com/minishift/minishift/releases/download/v1.25.0/minishift-1.25.0-linux-amd64.tgz
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

mkcert()
{
  # mkcert : create a valid local CA & certs
  sudo apt install libnss3-tools
  curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
  chmod +x mkcert-v*-linux-amd64
  sudo cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
}

MultiBootUSB()
{
  # MultiBootUSB
  cd /tmp || exit
  sudo apt install python3-pyudev
  wget -O python3-multibootusb_9.2.0-1_all.deb https://github.com/mbusb/multibootusb/releases/download/v9.2.0/python3-multibootusb_9.2.0-1_all.deb 
  sudo dpkg -i python3-multibootusb_9.2.0-1_all.deb && rm python3-multibootusb_9.2.0-1_all.deb
}

Multisystem()
{
  # Multisystem
  sudo apt-add-repository 'deb http://liveusb.info/multisystem/depot all main'
  wget -q http://liveusb.info/multisystem/depot/multisystem.asc -O- | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y multisystem
  sudo usermod -a -G adm ${USER}
}

Music()
{
  # Music Software
  sudo apt install -y guitarix mixxx rosegarden
}

NeoVim()
{
  VIM
  Python
  GO
  # NeoVIM
  pip3 install --upgrade --break-system-packages neovim
  go get -u github.com/nsf/gocode
}

nicotine()
{
  # Nicotine+ is a graphical client for the Soulseek peer-to-peer network.
  sudo apt install software-properties-common
  sudo add-apt-repository ppa:nicotine-team/stable
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6CEB6050A30E5769
  sudo apt update
  sudo apt install -y nicotine
}

npmfx()
{
  # FX json parser
  # https://www.youtube.com/watch?v=LMIeaIpZnJI&feature=em-uploademail
  sudo npm install -g fx
}

OfflineImap()
{
  # Install last OfflineImap lines
  mkdir -p ~/.config/systemd/user
  cd /tmp && git clone https://github.com/OfflineIMAP/offlineimap.git
  cp offlineimap/contrib/systemd/* ~/.config/systemd/user/
  systemctl --user start offlineimap.service
  systemctl --user enable offlineimap-oneshot.timer
}

OneDrive()
{
  # OneDrive : https://github.com/abraunegg/onedrive
  sudo apt install -i build-essential
  sudo apt install -i libcurl4-openssl-dev
  sudo apt install -i libsqlite3-dev
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

OSQuery()
{
  # OSQuery : https://itnext.io/auditing-containers-with-osquery-389636f8c420
  export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY
  sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
  sudo apt-get update
  sudo apt-get install osquery
}

PlayOnLinux()
{
  # PlayOnLinux
  wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
  sudo add-apt-repository http://deb.playonlinux.com/
  sudo apt -V install playonlinux wine
}

Powershell()
{
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
  wget -O https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.9/powershell_6.0.0-beta.9-1.ubuntu.17.04_amd64.deb
  sudo dpkg -i powershell_6.0.0-beta.9-1.ubuntu.17.04_amd64.deb
}

Puppet()
{
  # Puppet
  # https://docs.puppet.com/puppet/4.5/install_linux.html#installing-release-packages-on-apt-based-systems
  wget http://apt.puppetlabs.com/puppet-release-xenial.deb;
  sudo dpkg -i puppet-release-xenial.deb && rm -f puppet-release-xenial.deb
}

ProtonBridge()
{
  # ProtonBridge to download mails and use it from mutt
  cd /tmp || exit
  version=3.8.2
  wget https://proton.me/download/bridge/protonmail-bridge_${version}-1_amd64.deb
  sudo dpkg -i protonmail-bridge_${version}-1_amd64.deb
  rm protonmail-bridge_${version}-1_amd64.deb
}

ProtonVPN()
{
  # ProtonVPN : https://protonvpn.com/support/linux-ubuntu-vpn-setup/
  version=1.0.3-3
  cd /tmp || exit
  wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_${version}_all.deb
  echo "c68a0b8dad58ab75080eed7cb989e5634fc88fca051703139c025352a6ee19ad protonvpn-stable-release_${version}_all.deb" | sha256sum --check -
  sudo apt-get update
  sudo dpkg -i protonvpn-stable-release_${version}_all.deb
  sudo apt install -y protonvpn
  sudo apt install -y libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator
}

rapidphotodownloader()
{
  # rapid-photo-downloader : http://www.damonlynch.net/rapid/downloads.html
  cd /tmp || exit
  wget https://launchpad.net/rapid/pyqt/0.9.9/+download/install.py
  python3 install.py
}

RocketChat()
{
  # RocketChat
  sudo apt-get install libpurple-dev libjson-glib-dev libglib2.0-dev mercurial make libmarkdown2-dev;
  cd /tmp || exit
  hg clone https://bitbucket.org/EionRobb/purple-rocketchat/ && cd purple-rocketchat || exit
  make && sudo make install
}

Rust()
{
  # Install rust and other cargo tools
  # First remove debian packages
  sudo apt remove cargo rustc
  curl https://sh.rustup.rs -sSf | sh

  # Initiate Cargo cache
  rustup install stable
  rustup default stable

  for rustpkg in bat delta-git dog dust dutree erdtree fd-find gping just kubie mdcat navi ripgrep spotify-tui trippy viu
  do
    cargo install "${rustpkg}"
  done
}

s3benchmark()
{
  # s3benchmark : Measure Amazon S3's performance from any location.
  cd ~/bin && curl -OL https://github.com/dvassallo/s3-benchmark/raw/master/build/linux-amd64/s3-benchmark
  chmod +x ~/bin/s3-benchmark
}

Screensavers()
{
  # Screensavers
  sudo apt remove gnome-screensaver
  sudo add-apt-repository ppa:mc3man/mpv-tests
  sudo apt install -y mpv
  cat > /tmp/crons << EOF
16 02 * * * /home/daffy/bin/get_screensavers.py /home/daffy/Dropbox/Screensavers
@reboot cd /home/daffy/ownCloudPerso/Code/git/github/noisy && /usr/bin/docker run -it noisy --config config.json
EOF
  crontab /tmp/crons
  mkdir -p ~/.config/systemd/user/
  systemctl --user enable xscreensaver
}

Signal()
{
  # NOTE: These instructions only work for 64 bit Debian-based
  # Linux distributions such as Ubuntu, Mint etc.
  
  # 1. Install our official public software signing key
  wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
  cat signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
  rm signal-desktop-keyring.gpg
  
  # 2. Add our repository to your list of repositories
  echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" |\
    sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
  
  # 3. Update your package database and install signal
  # sudo apt update && sudo apt install signal-desktop
  sudo apt install apt-transport-https && sudo apt update && sudo apt install signal-desktop
}

Slack()
{
  # Slack
  # https://slack.com/intl/fr-fr/downloads/Linux
  sudo snap install slack --classic
}

Spip-Cli()
{
  # Spip in commandline https://contrib.spip.net/SPIP-Cli#Installation
  sudo git clone https://git.spip.net/spip-contrib-outils/spip-cli.git /opt/spip-cli
  cd /opt/spip-cli
  sudo composer install

  cd /opt/spip-cli/bin
  # Commande 'spip'
  sudo ln -s $(pwd)/spip /usr/local/bin/
  # Commande 'spipmu' pour site mutualisé
  sudo ln -s $(pwd)/spipmu /usr/local/bin/
  # Autocompletion (Linux)
  sudo ln -s $(pwd)/spip_console_autocomplete /etc/bash_completion.d/spip
  # Autocompletion (MacOs)
  # sudo ln -s $(pwd)/spip_console_autocomplete /usr/local/etc/bash_completion.d/spip
}

Spotify()
{
  # Spotify
  # https://doc.ubuntu-fr.org/spotify
  curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt-get update && sudo apt-get install spotify-client
  # sudo snap install spotify
  # sudo ln -s /var/lib/snapd/desktop/applications/spotify_spotify.desktop /usr/share/applications/spotify.desktop
  pip install spotify-cli-linux
  pip install lyricwikia
}

Stacer()
{
  # Stacer : Ubuntu System Cleaner Stacer Scores a Spring Update
  cd /tmp || exit
  wget https://github.com/oguzhaninan/Stacer/releases/download/v1.0.9/stacer_1.0.9_amd64.deb
  sudo dpkg -i stacer_1.0.9_amd64.deb
}

Students()
{
  # Add some scientific Tools
  sudo apt install -y \
    avogadro fritzing geogebra geogebra-gnome kalzium kgeography marble marble-plugins pyacidobasic python3-mecavideo qalculate-gtk step tkgate verbiste-gnome zegrapher

  cd /tmp || exit 1
  wget https://www.lernsoftware-filius.de/downloads/Setup/filius_2.5.1_all.deb
  sudo dpkg -i filius_2.5.1_all.deb
  # Logiciels PlayOnLinux
  # Sine Qua Non : http://patrice-rabiller.fr/SineQuaNon/menusqn.htm
  # Filius : https://www.lernsoftware-filius.de/Herunterladen
  # Regressi : http://regressi.fr/WordPress/download/
}

STui()
{
  # S-Tui : https://www.cyberciti.biz/python-tutorials/monitor-linux-cpu-temperature-frequency-power-in-a-graphical-way/
  sudo apt install -y python-pip stress
  pip install s-tui --break-system-packages
  # sudo s-tui
}

Taskfile()
{
  # Taskfile : Task is a task runner / build tool that aims to be simpler and easier to use than, for example, GNU Make.
  # https://taskfile.org/#/
  go get -u -v github.com/go-task/task/cmd/task
}

Terminal()
{
  # Install Tilix Theme
  mkdir -p ~/.config/tilix/schemes/
  wget -qO "${HOME}"/.config/tilix/schemes/desert.json https://raw.githubusercontent.com/storm119/Tilix-Themes/master/Themes/desert.json
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

TLDR()
{
  # TLDR
  go get 4d63.com/tldr
}

Trello()
{
  # Trello Client
  # git clone https://github.com/mheap/trello-cli.git # best but badly installed
  # https://github.com/qcam/3llo
  sudo em install 3llo
  export TRELLO_USER=your_username
  export TRELLO_KEY=your_key
  export TRELLO_TOKEN=your_token
}

ttfmscorefontsinstaller()
{
# Fixed in bionic ttf-mscorefonts-installer
# http://www.asso-linux.org/forum/viewtopic.php?f=4&t=196
# wget -o /tmp/ttf-mscorefonts-installer_3.6_all.deb -O http://ftp.fr.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
# sudo dpkg -i /tmp/ttf-mscorefonts-installer_3.6_all.deb
  sudo apt install -f
}

urbackup()
{
  # urbackup
  TF=$(mktemp) && wget "https://hndl.urbackup.org/Client/2.2.5/UrBackup%20Client%20Linux%202.2.5.sh" -O $TF && sudo sh $TF; rm $TF
}

Ventoy()
{
  # Ventoy : multisystem alternative
  cd /tmp/ && wget https://github.com/ventoy/Ventoy/releases/download/v1.0.61/ventoy-1.0.61-linux.tar.gz
  cd ~/bin && tar xvfz /tmp/ventoy-1.0.61-linux.tar.gz
}

VIM()
{
  # Add Ruby Support to vim
  sudo update-alternatives --set vim /usr/bin/vim.nox
  # Install vundle
  pip install flake8
  pip install wakatime
  pip install pidcat-pip
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +BundleInstall
  vim +GoInstallBinaries
  cd ~/.vim/plugged/YouCompleteMe && python install.py

  # vim-instant-markdown
  sudo npm -g install instant-markdown-d
  cd /tmp || exit
  git clone git@github.com:suan/vim-instant-markdown.git
  mkdir -p ~/.vim/after/ftplugin/markdown/
  cd vim-instant-markdown || exit
  cp after/ftplugin/markdown/instant-markdown.vim ~/.vim/after/ftplugin/markdown/

  # vim-fugitive
  mkdir -p ~/.vim/pack/tpope/start
  cd ~/.vim/pack/tpope/start
  git clone https://tpope.io/vim/fugitive.git
  vim -u NONE -c "helptags fugitive/doc" -c q

  # vim-terraform
  git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
}

VirtualBox()
{
  # VirtualBox
  # https://www.virtualbox.org/wiki/Linux_Downloads
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
  sudo rm /etc/apt/sources.list.d/virtualbox.list
  echo "deb http://download.virtualbox.org/virtualbox/debian eoan contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
  sudo apt-get update
  sudo apt-get install -y virtualbox
  sudo usermod -G vboxusers -a $USER
  version=$(VBoxManage --version|cut -dr -f1|cut -d'_' -f1) && wget -c http://download.virtualbox.org/virtualb … ox-extpack
  VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack
}

Vivaldi()
{
  # Vivaldi web browser
  cd /tmp || exit
  wget https://downloads.vivaldi.com/stable/vivaldi-stable_6.5.3206.48-1_amd64.deb
  sudo dpkg -i vivaldi-stable_6.5.3206.48-1_amd64.deb
  rm vivaldi-stable_6.5.3206.48-1_amd64.deb
}

VSCodium()
{
  # VSCodium : libre version of Microsoft VSCode
  # SNAP
  cd /tmp || exit
  wget https://github.com/VSCodium/vscodium/releases/download/1.85.1.23348/codium_1.85.1.23348_amd64.deb
  sudo dpkg -i codium_1.85.1.23348_amd64.deb
  rm codium_1.85.1.23348_amd64.deb
  # Extensions
  for extension in \
    abusaidm.html-snippets \
    AlanWalk.markdown-toc \
    ban.spellright \
    be5invis.toml \
    bierner.markdown-preview-github-styles \
    bung87.vscode-gemfile \
    bmarkovic.haproxy \
    CoenraadS.bracket-pair-colorizer-2 \
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
    HookyQR.beautify \
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
    zkirkland.vscode-firstupper

    do
      codium --install-extension ${extension}
    done
}

WakeMeOps()
{
  # WakeMeOps : WakeMeOps est un référentiel Debian pour les applications portables.
  curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
  sudo apt-get update
  sudo apt install gping choose bottom himalaya xh
}

WSS()
{
  # WSS by Netflix
  # https://github.com/brendangregg/wss.git
  echo ""
}

WTF()
{
  # WTF
  GO
  go get -u github.com/senorprogrammer/wtf
  cd $GOPATH/src/github.com/senorprogrammer/wtf || exit
  make install
}

XAuth()
{
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

YakYak()
{
  # YakYak : https://www.omgubuntu.co.uk/2017/10/yakyak-opensource-google-hangouts-desktop-app
  sudo snap install yakyak
}

youtube()
{
  # youtube-dlg
  sudo add-apt-repository -n -y ppa:nilarimogard/webupd8
  sudo sed -i -e "s+bionic+xenial+g" /etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8-bionic.list
  sudo apt update
  sudo apt install -y youtube-dlg
}

YunoHost()
{
  # YunoHost : add SSL CA
  sudo cp ~/coincoin.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
}

zquests()
{
    # Search commandline tool : https://blog.shevarezo.fr/post/2018/10/31/faire-recherches-internet-ligne-de-commande
    go get -v github.com/zquestz/s
}

ZSH()
{
  # Install oh-my-szh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  cd ~/.oh-my-zsh && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  cd /tmp || exit
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
  cd nerd-fonts || exit
  ./install.sh "FiraCode"
  snap install starship --edge
}

Annexes()
{
  # OOo extension
  echo https://github.com/seanyeh/vibreoffice
}

Main()
{
#  Setup
#  WIFI
#  PPA
  Packages
#  Python
#  GO
#  Android
#  Ansible
#  Argbash
#  Atom
#  Bat
#  bcctools
#  bluegriffon
#  browsh
#  Chaos
  ChatGPT
  Children
#  Chrome
#  chromeIPass
#  CLOUD
#  coolretroterm
#  CozyDrive
#  Crontab
#  Ctop
  Delta
#  Docker
#  Douane
  Dropbox
#  DroidCAM
  DVD
#  Element
  FlatPack
#  Feedreader
  Fuzzy
#  GCStar
#  Github
  GnomeConfigurations
  GnomeExtensions
#  GrafTCP
#  GRAPH
#  Infrakit
#  IssueHelper
  Keybase
  Kubernetes
#  Lightworks
  lutris
  lynis
#  lynishardening
  Minishift
  mkcert
#  MultiBootUSB
#  Multisystem
  Music
  NeoVim
  nicotine
#  npmfx
  OfflineImap
#  OneDrive
#  OSQuery
  PlayOnLinux
  Powershell
  ProtonBridge
  ProtonVPN
  Puppet
#  rapidphotodownloader
#  RocketChat
  Rust   
#  s3benchmark
  Screensavers
  Signal
  Slack
  SNAP
#  Spip-Cli
  Spotify
  Stacer
  Students
#  STui
#  Taskfile
  Terminal
  TLDR
#  Trello
  ttfmscorefontsinstaller
  urbackup
  Ventoy
  VIM
  VirtualBox
  Vivaldi
  VSCodium
  WakeMeOps
  WSS
  WTF
  XAuth
  YakYak
  youtube
#  YunoHost
  ZSH
#  zquests
}


if [ ! -z $1 ] 
then
  $1
else
  Main
fi
