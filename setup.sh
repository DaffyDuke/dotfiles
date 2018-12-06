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
}

PPA()
{
  # this tool aims to be ran from Ubuntu
  # install additionnal repositories
  for ppa in ppa:djcj/hybrid \
    ppa:geary-team/releases \
    ppa:gezakovacs/ppa \
    ppa:hollywood/ppa \
    ppa:pbek/qownnotes \
    ppa:peek-developers/stable \
    ppa:peterlevi/ppa \
    ppa:teejee2008/ppa \
    ppa:unit193/encryption \
    ppa:vincent-vandevyvre/vvv \
    ppa:webupd8team/indicator-kdeconnect \
    ppa:webupd8team/y-ppa-manager \
    ppa:twodopeshaggy/jarun \
    ppa:yubico/stable \
    ppa:libreoffice/ppa \
    ppa:yannubuntu/boot-repair \
    ppa:dyatlov-igor/la-capitaine \
    ppa:peterlevi/ppa
  do
    sudo apt-add-repository -n --yes ${ppa}
  done
  sudo apt-get update
  sudo apt install -y hollywood qownnotes peek variety timeshift veracrypt oqapy indicator-kdeconnect y-ppa-manager ddgr software-properties-common boot-repair la-capitaine-icon-theme variety variety-slideshow
}

Packages()
{
  # Install some packages
  sudo apt install -y \
    asciidoc alien androidsdk-ddms ansible ansible-lint apt-file aria2 aspell-fr atop awscli \
    baobab bc build-essential bundler \
    ca-certificates calibre checkinstall chrome-gnome-shell clipit chromium-browser chromium-browser-l10n checksecurity cmake corkscrew cowsay cpuid curl \
    darktable debian-goodies default-jre deluge-gtk deluged dfc dkms dnstracer dos2unix \
    easytag ethstatus ethtool ettercap-graphical evince evolution exuberant-ctags \
    fastboot fdupes filezilla fonts-powerline fortunes-fr fslint ftp \
    gcstar geary gimp glances gnome-tweak-tool gnome-usage gnupg2 gnupg-agent gparted graphviz gthumb guake guake-indicator \
    handbrake hddtemp heimdall-flash-frontend htop httpcode httperf httpie hugin hugo hunspell-fr hunspell-fr-comprehensive \
    i2c-tools: icedtea-plugin iftop ioping iotop iproute2 iptraf iputils-arping iptstate \
    jq jxplorer \
    keepass2 kerneloops kigo klavaro \
    language-pack-fr ldap-utils lftp libpam-yubico libreoffice libreoffice-calc libreoffice-draw libreoffice-help-fr libreoffice-impress libreoffice-math libreoffice-nlpsolver libreoffice-pdfimport libreoffice-voikko libreoffice-writer libreoffice-templates libreoffice-writer2latex libreoffice-gnome lm-sensors lolcat lsof ltrace lynx \
    mat mc meld ncdu mono-complete mutt \
    netcat-openbsd nethogs network-manager-openvpn-gnome nmap nmon npm numatop \
    ogmrip openclipart-libreoffice openconnect openssh-client openssh-server openvpn owncloud-client \
    p7zip pandoc parted pass patch pcp perf-tools-unstable perl-doc pgtop photocollage pidgin pidgin-skype pidgin-encryption pidgin-openpgp pidgin-gnome-keyring pinentry-curses pinentry-tty pidcat planfacile playonlinux pm-utils postgresql-client psensor pssh putty-tools python python3 python-pip python3-dev python3-virtualenv pwgen pydf \
    qarte qemu qtpass \
    rclone rdesktop redshift-gtk remmina repo rpm rsync \
    s3cmd scribus seahorse scdaemon shellcheck shotwell shutter simple-scan smartmontools sosreport spectre-meltdown-checker sshfs sshpass strace stunnel4 synaptic sysstat \
    tcpdump tellico testssl.sh thefuck thunderbird tilix toilet torbrowser-launcher traceroute tshark \
    ubuntu-restricted-extras ukuu unetbootin unrar urlview \
    vagrant vim-gnome vim-python-jedi vim-youcompleteme virt-manager virtualenv vlc \
    weboob-qt whois winbind wireshark \
    xauth xdg-utils xscreensaver xsane \
    yamllint yubikey-manager-qt \
    zenmap
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

DVD()
{
  # Encrypted DVD
  sudo apt install -y libdvd-pkg
  sudo dpkg-reconfigure libdvd-pkg
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

Dropbox()
{
  # Dropbox
  # https://www.dropbox.com/install-linux
  wget -O /tmp/dropbox_2015.10.28_amd64.deb https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb
  sudo dpkg -i /tmp/dropbox_2015.10.28_amd64.deb
  sudo apt --fix-broken install
  echo fs.inotify.max_user_watches=100000 | sudo tee -a /etc/sysctl.conf; sudo sysctl -p
}

VirtualBox()
{
  # VirtualBox
  # https://www.virtualbox.org/wiki/Linux_Downloads
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
  sudo rm /etc/apt/sources.list.d/virtualbox.list
  echo "deb http://download.virtualbox.org/virtualbox/debian bionic contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
  sudo apt-get update
  sudo apt-get install -y virtualbox-5.2
  sudo usermod -G vboxusers -a $USER
  version=$(VBoxManage --version|cut -dr -f1|cut -d'_' -f1) && wget -c http://download.virtualbox.org/virtualb … ox-extpack
  VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-$version.vbox-extpack
}

Keybase()
{
  # Keybase
  # https://keybase.io/docs/the_app/install_linux
  curl -o /tmp/keybase_amd64.deb -O https://prerelease.keybase.io/keybase_amd64.deb
  sudo dpkg -i /tmp/keybase_amd64.deb
  sudo apt-get install -f
}

Spotify()
{
  # Spotify
  # https://doc.ubuntu-fr.org/spotify
  # sudo rm /etc/apt/sources.list.d/spotify.list
  # sudo sh -c 'echo "deb http://repository.spotify.com stable non-free" >> /etc/apt/sources.list.d/spotify.list'
  # sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2C19886
  # sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EFDC8610341D9410
  # sudo apt-get update
  # sudo apt-get install -y spotify-client
  sudo snap install spotify
  sudo ln -s /var/lib/snapd/desktop/applications/spotify_spotify.desktop /usr/share/applications/spotify.desktop
}

Slack()
{
  # Slack
  # https://slack.com/intl/fr-fr/downloads/Linux
  sudo snap install slack --classic
}

Chrome()
{
  # Chrome
  # https://doc.ubuntu-fr.org/google_chrome
  # https://www.google.com/chrome/browser/desktop/index.html
  sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y google-chrome-unstable
}

Puppet()
{
  # Puppet
  # https://docs.puppet.com/puppet/4.5/install_linux.html#installing-release-packages-on-apt-based-systems
  wget http://apt.puppetlabs.com/puppet-release-xenial.deb;
  sudo dpkg -i puppet-release-xenial.deb && rm -f puppet-release-xenial.deb
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
}

TLDR()
{
  # TLDR
  go get 4d63.com/tldr
}

VIM()
{
  # Install vundle
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
}

ZSH()
{
  # Install oh-my-szh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
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

Terminal()
{
  # Install Tilix Theme
  mkdir -p ~/.config/tilix/schemes/
  wget -qO "${HOME}"/.config/tilix/schemes/desert.json https://raw.githubusercontent.com/storm119/Tilix-Themes/master/Themes/desert.json
  gsettings set org.gnome.desktop.default-applications.terminal exec 'terminal'
  default=$(gsettings get com.gexperts.Tilix.ProfilesList default)
  dconf write /com/gexperts/Tilix/profiles/${default}/login-shell true
  dconf write /com/gexperts/Tilix/warn-vte-config-issue false
  dconf write /com/gexperts/Tilix/profiles/${default}/use-theme-colors false
  dconf write /com/gexperts/Tilix/profiles/${default}/foreground-color \'#FFFFFF\'
  dconf write /com/gexperts/Tilix/profiles/${default}/background-color \'#333333\'
  dconf write /com/gexperts/Tilix/profiles/${default}/bold-color-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/badge-color-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/highlight-colors-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/cursor-colors-set false
  dconf write /com/gexperts/Tilix/profiles/${default}/palette "['#4D4D4D', '#FF2B2B', '#98FB98', '#F0E68C', '#CD853F', '#FFDEAD', '#FFA0A0', '#F5DEB3', '#555555', '#FF5555', '#55FF55', '#FFFF55', '#87CEFF', '#FF55FF', '#FFD700', '#FFFFFF']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal ""
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 name unset
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 command unset
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 binding '<Primary><Alt>t'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 name 'Terminal'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings.custom0 command '/usr/bin/tilix'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings ['/org/gnome/settings/daemon/plugins/media-keys/custom-keybindings/custom0/']
}

ttfmscorefontsinstaller()
{
# Fixed in bionic ttf-mscorefonts-installer
# http://www.asso-linux.org/forum/viewtopic.php?f=4&t=196
# wget -o /tmp/ttf-mscorefonts-installer_3.6_all.deb -O http://ftp.fr.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
# sudo dpkg -i /tmp/ttf-mscorefonts-installer_3.6_all.deb
 sudo apt install -f
}

GnomeExtensions()
{
  # Install Gnome-extensions
  # https://wiki.gnome.org/Projects/GnomeShell/Extensions#Enabling_extensions
  # https://github.com/cyberalex4life/gnome-shell-extension-cl/blob/master/gnome-shell-extension-cl
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
  dconf write /org/gnome/shell/extensions/panel-osd/y-pos 5.0
  dconf write /org/gnome/shell/extensions/panel-osd/x-pos 90.0
}

GnomeConfigurations()
{
  # Misc Gnome configurations
  # Some help : https://askubuntu.com/questions/971067/how-can-i-script-the-settings-made-by-gnome-tweak-tool
  # dconf watch / is your friend !
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false
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
}

Kubernetes()
{
  # Kubernetes
  # https://github.com/kubernetes/minikube
  cd ~/bin/ || exit
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl && chmod +x kubectl
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
  kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
  kubectl expose deployment hello-minikube --type=NodePort
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

  # Some other tools
  # https://github.com/appscode/kubed
  # https://github.com/heptio/ark
  # https://github.com/cloudnativelabs/kube-router
  # https://github.com/GoogleCloudPlatform/kube-metacontroller
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
  eval $(minishift oc-env)
  oc new-app https://github.com/sclorg/nodejs-ex -l name=myapp
  oc logs -f bc/nodejs-ex
  oc expose svc/nodejs-ex
  minishift openshift service nodejs-ex --in-browser
  minishift stop
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
  wget https://releases.hashicorp.com/terraform/0.10.8/terraform_0.10.8_linux_amd64.zip
  unzip -f terraform_0.10.8_linux_amd64.zip
  rm -f terraform_0.10.8_linux_amd64.zip getTerraformProviders.sh
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
  # tips cross compilation
  # CGO_ENABLED=yes go build
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

Speedtest()
{
  # Fast speedtest by Netflix commandline
  curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
  sudo apt-get install -y nodejs
  # sudo npm install --global fast-cli  # needs to understand why installation fail
  # INstall eslint for syntastic
  sudo npm install -g eslint
  sudo npm install -g babel-eslint
  sudo npm install -g eslint-plugin-react
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

Python()
{
  # Python
  snap install pycharm-community --classic
  pip3 install virtualenv
  pip3 install docopt
  pip3 install configobj
  pip3 install terminaltables

  # Try alphago .....
  pip install tenserflow
  pip install betago
  # cd /tmp
  # git clone https://github.com/maxpumperla/betago
  # cd betago
  # python run_demo.py
}

WSS()
{
  # WSS by Netflix
  # https://github.com/brendangregg/wss.git
  echo ""
}

GRAPH()
{
  # dgraph
  curl https://get.dgraph.io -sSf | bash
}

Chaos()
{
  # Chaos toolkit : https://medium.com/chaos-toolkit/announcing-chaos-discover-and-chaos-init-ff2bf02c5a85
  docker pull chaostoolkit/chaostoolkit
  docker run -it chaostoolkit/chaostoolkit discover chaostoolkit-kubernetes
}

Ctop()
{
  # Top-like interface for container metrics https://ctop.sh
  sudo wget https://github.com/bcicen/ctop/releases/download/v0.7/ctop-0.7-linux-amd64 -O /usr/local/bin/ctop
  sudo chmod +x /usr/local/bin/ctop
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

Ansible()
{
  # molecule : https://blog.octo.com/en/the-wizard-ansible-molecule-and-test-driven-development/
  sudo pip install molecule
  cd /tmp || exit
  git clone https://github.com/metacloud/molecule
  cd /tmp/molecule/test/scenarios/driver/docker || exit
  molecule test
}

chromeIPass()
{
  # chromeIPass : https://github.com/pfn/passifox/
  sudo wget https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx -O /usr/lib/keepass2/KeePassHttp.plgx
}

IssueHelper()
{
  # Issue-helper
  sudo apt remove cargo rustc
  curl https://sh.rustup.rs -sSf | sh
  source "${HOME}"/.cargo/env
  cargo install gli
}

Feedreader()
{
  # Feedreader
  sudo apt install -y libgumbo-dev
  curl https://raw.githubusercontent.com/jangernert/FeedReader/master/scripts/install_ubuntu.sh | bash
}

urbackup()
{
  # urbackup
  TF=$(mktemp) && wget "https://hndl.urbackup.org/Client/2.2.5/UrBackup%20Client%20Linux%202.2.5.sh" -O $TF && sudo sh $TF; rm $TF
}

lnav()
{
  # lnav
  cd ~/bin || exit
  wget https://github.com/tstack/lnav/releases/download/v0.8.3/lnav-0.8.3-linux-64bit.zip -O ~/bin/lnav-0.8.3-linux-64bit.zip
  unzip ~/bin/lnav-0.8.3-linux-64bit.zip && rm ~/bin/lnav-0.8.3-linux-64bit.zip
}

youtube()
{
  # youtube-dlg
  sudo add-apt-repository -n -y ppa:nilarimogard/webupd8
  sudo sed -i -e "s+bionic+xenial+g" /etc/apt/sources.list.d/nilarimogard-ubuntu-webupd8-bionic.list
  sudo apt update
  sudo apt install -y youtube-dlg
}

Lightworks()
{
  # FIXME Lightworks
  cd /tmp || exit
  wget -O lightworks.deb "https://www.lwks.com/index.php?option=com_docman&task=doc_download&gid=194"
  sudo dpkg -i lightworks.deb && rm lightworks.deb
  sudo apt --fix-broken install -y
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

bcctools()
{
  # bcc-tools
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D4284CDD
  echo "deb [trusted=yes] https://repo.iovisor.org/apt/bionic bionic-nightly main" | sudo tee /etc/apt/sources.list.d/iovisor.list
  sudo apt-get update
  sudo apt-get install y bcc-tools libbcc-examples linux-headers-$(uname -r)
}

bluegriffon()
{
  #- FIXME bluegriffon
  cd /tmp || exit
  wget http://bluegriffon.org/freshmeat/3.0.1/bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
  sudo dpkg -i bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb && rm bluegriffon-3.0.1.Ubuntu16.04-x86_64.deb
}

NeoVim()
{
  VIM
  Python
  GO
  # NeoVIM
  pip3 install --upgrade neovim
  go get -u github.com/nsf/gocode
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

Douane()
{
# Douane Firewal
# Following doc : https://github.com/Douane/Douane
sudo apt install liblog4cxx-dev libdbus-c++-dev libboost-filesystem-dev libboost-regex-dev libboost-signals-dev libgtkmm-3.0-dev
}

MultiBootUSB()
{
  # MultiBootUSB
  cd /tmp || exit
  sudo apt install python3-pyudev
  wget -O python3-multibootusb_9.2.0-1_all.deb https://github.com/mbusb/multibootusb/releases/download/v9.2.0/python3-multibootusb_9.2.0-1_all.deb 
  sudo dpkg -i python3-multibootusb_9.2.0-1_all.deb && rm python3-multibootusb_9.2.0-1_all.deb
}

RocketChat()
{
  # RocketChat
  sudo apt-get install libpurple-dev libjson-glib-dev libglib2.0-dev mercurial make libmarkdown2-dev;
  cd /tmp || exit
  hg clone https://bitbucket.org/EionRobb/purple-rocketchat/ && cd purple-rocketchat || exit
  make && sudo make install
}

WTF()
{
  # WTF
  GO
  go get -u github.com/senorprogrammer/wtf
  cd $GOPATH/src/github.com/senorprogrammer/wtf || exit
  make install
}

Fuzzy()
{
  # fzf: Fuzzy Finder
  cd /tmp || exit
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
}

Stacer()
{
  # Stacer : Ubuntu System Cleaner Stacer Scores a Spring Update
  cd /tmp || exit
  wget https://github.com/oguzhaninan/Stacer/releases/download/v1.0.9/stacer_1.0.9_amd64.deb
  sudo dpkg -i stacer_1.0.9_amd64.deb
}

rapidphotodownloader()
{
  # rapid-photo-downloader : http://www.damonlynch.net/rapid/downloads.html
  cd /tmp || exit
  wget https://launchpad.net/rapid/pyqt/0.9.9/+download/install.py
  python3 install.py
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

Multisystem()
{
  # Multisystem
  sudo apt-add-repository 'deb http://liveusb.info/multisystem/depot all main'
  wget -q http://liveusb.info/multisystem/depot/multisystem.asc -O- | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y multisystem
  sudo usermod -a -G adm ${USER}
}

PlayOnLinux()
{
  # PlayOnLinux
  wget -q "http://deb.playonlinux.com/public.gpg" -O- | sudo apt-key add -
  sudo add-apt-repository http://deb.playonlinux.com/
  sudo apt -V install playonlinux wine-stable
}

Children()
{
  # Add some games
  sudo apt install -y \
    brainparty briquolo cgoban childsplay childsplay-alphabet-sounds-fr colobot connectagram \
    extremetuxracer fgo fretsonfire frozen-bubble gbrainy gcompris grhino \
    junior-programming opencity pingus pysycache steam supertuxkart tomatoes tuxmath tuxtype

  # when you need to add users to junior-programming
  # sudo dpkg-reconfigure --force junior-config
}

YunoHost()
{
  # YunoHost : add SSL CA
  sudo cp ~/coincoin.crt /usr/local/share/ca-certificates
  sudo update-ca-certificates
}

Github()
{
  # Github
  snap install --edge github-desktop
}

GrafTCP()
{
  # GraphTCP : https://github.com/hmgle/graftcp
  cd /tmp || git clone https://github.com/hmgle/graftcp.git
  cd graftcp || make
}

STui()
{
  # S-Tui : https://www.cyberciti.biz/python-tutorials/monitor-linux-cpu-temperature-frequency-power-in-a-graphical-way/
  sudo apt install -y python-pip stress
  sudo pip install s-tui
  # sudo s-tui
}

YakYak()
{
  # YakYak : https://www.omgubuntu.co.uk/2017/10/yakyak-opensource-google-hangouts-desktop-app
  sudo snap install yakyak
}

zquests()
{
    # Search commandline tool : https://blog.shevarezo.fr/post/2018/10/31/faire-recherches-internet-ligne-de-commande
    go get -v github.com/zquestz/s
}

Main()
{
#  Setup
#  PPA
  Packages
#  Python
#  GO
#  Android
#  Ansible
#  Atom
#  bcctools
#  bluegriffon
#  Chaos
#  Children
#  Chrome
#  chromeIPass
#  CLOUD
#  coolretroterm
#  CozyDrive
#  Ctop
#  Docker
#  Douane
#  Dropbox
#  DVD
#  Feedreader
#  Fuzzy
#  GnomeConfigurations
#  GnomeExtensions
#  GRAPH
#  Github
#  GrafTCP
#  Infrakit
#  IssueHelper
#  Keybase
#  Kubernetes
#  Lightworks
#  lnav
#  Minishift
#  MultiBootUSB
#  Multisystem
#  NeoVim
#  OneDrive
#  PlayOnLinux
#  Powershell
#  Puppet
#  rapidphotodownloader
#  RocketChat
#  Screensavers
#  Slack
#  Speedtest
#  Spotify
#  Stacer
#  STui
#  Terminal
#  TLDR
#  Trello
#  ttfmscorefontsinstaller
#  urbackup
#  VIM
#  VirtualBox
#  WSS
#  WTF
#  XAuth
#  YakYak
#  youtube
#  YunoHost
#  ZSH
#  zquests
}

Main
