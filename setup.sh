#!/bin/bash

# Things to do after installing Ubuntu 17.10
sudo timedatectl set-local-rtc 1

# https://itsfoss.com/things-installing-ubuntu-17-10/
sudo apt update && sudo apt upgrade -y
sudo apt install -y tlp tlp-rdw
sudo tlp start

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
  ppa:yannubuntu/boot-repair
do
  sudo apt-add-repository -n --yes ${ppa}
done
sudo apt-get update
sudo apt install -y hollywood qownnotes peek variety timeshift veracrypt oqapy indicator-kdeconnect y-ppa-manager ddgr software-properties-common boot-repair # frogr urbackup cool-retro-term bluegriffon bcc-tools freemind harmony lightworks youtube-dlg
sudo apt install -y git zsh expect

# Install some packages
sudo apt install -y \
  alien androidsdk-ddms ansible ansible-lint apt-file atop awscli \
  baobab bc build-essential bundler \
  ca-certificates checkinstall clipit corkscrew cowsay cpuid curl \
  darktable debian-goodies default-jre deluge-gtk dfc dnstracer dos2unix \
  easytag ethstatus ethtool ettercap-graphical evince \
  fastboot filezilla fortunes-fr ftp \
  gcompris gcstar geary glances gnome-tweak-tool gnome-usage gnupg2 gnupg-agent google-cloud-sdk graphviz guake guake-indicator \
  handbrake heimdall-flash-frontend htop httpcode httperf httpie hugin hugo \
  icedtea-plugin iftop ioping iotop iproute2 iptraf iputils-arping iptstate \
  jq junior-programming jxplorer \
  keepass2 kerneloops klavaro \
  language-pack-fr ldap-utils lftp libpam-yubico libreoffice-gnome lolcat lsof ltrace lynx \
  mat mc meld ncdu mono-complete \
  netcat-openbsd nethogs nmap nmon npm numatop \
  ogmrip openconnect openssh-client openssh-server openvpn owncloud-client \
  p7zip parted pass patch pcp perf-tools-unstable pgtop pinentry-curses pidcat postgresql-client pssh putty-tools python pwgen \
  qarte qemu qtpass \
  rdesktop remmina repo rpm rsync \
  s3cmd scribus seahorse scdaemon shellcheck shotwell simple-scan sosreport spectre-meltdown-checker sshfs sshpass strace stunnel4 synaptic sysstat \
  tcpdump testssl.sh thefuck tilix toilet torbrowser-launcher traceroute tshark tuxmath \
  ubuntu-restricted-extras unetbootin unrar \
  vagrant vim-gnome vim-youcompleteme virt-manager vlc \
  weboob-qt whois wireshark \
  xauth xscreensaver \
  yamllint yubikey-manager-qt \
  zenmap
sudo apt remove gnome-screensaver
mkdir -p ~/.config/systemd/user/
systemctl --user enable xscreensaver
# when you need to add users to junior-programming
# sudo dpkg-reconfigure --force junior-config

# Atom
curl -L https://packagecloud.io/AtomEditor/atom/gpgkey | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main" > /etc/apt/sources.list.d/atom.list'
sudo apt-get update
sudo apt-get install -y atom

# Dropbox
# https://www.dropbox.com/install-linux
wget -O /tmp/dropbox_2015.10.28_amd64.deb https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb
sudo dpkg -i /tmp/dropbox_2015.10.28_amd64.deb
sudo apt --fix-broken install

# VirtualBox
# https://www.virtualbox.org/wiki/Linux_Downloads
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo rm /etc/apt/sources.list.d/virtualbox.list
echo "deb http://download.virtualbox.org/virtualbox/debian bionic contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
sudo apt-get update
sudo apt-get install virtualbox-5.2

# Keybase
# https://keybase.io/docs/the_app/install_linux
curl -o /tmp/keybase_amd64.deb -O https://prerelease.keybase.io/keybase_amd64.deb
sudo dpkg -i /tmp/keybase_amd64.deb
sudo apt-get install -f

# Spotify
# https://doc.ubuntu-fr.org/spotify
sudo rm /etc/apt/sources.list.d/spotify.list
sudo sh -c 'echo "deb http://repository.spotify.com stable non-free" >> /etc/apt/sources.list.d/spotify.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2C19886
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EFDC8610341D9410
sudo apt-get update
sudo apt-get install spotify-client

# FIXME Slack
# https://slack.com/intl/fr-fr/downloads/Linux
curl -s https://packagecloud.io/install/repositories/slacktechnologies/slack/script.deb.sh | sudo bash

# Chrome
# https://doc.ubuntu-fr.org/google_chrome
# https://www.google.com/chrome/browser/desktop/index.html
sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo apt-get update
sudo apt-get install google-chrome-stable

# Puppet
# https://docs.puppet.com/puppet/4.5/install_linux.html#installing-release-packages-on-apt-based-systems
wget http://apt.puppetlabs.com/puppet-release-xenial.deb;
sudo dpkg -i puppet-release-xenial.deb && rm -f puppet-release-xenial.deb

# FIXME Docker
# https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-compose
cd /tmp || exit
wget https://github.com/DockStation/dockstation/releases/download/v1.3.0/dockstation_1.3.0_amd64.deb
sudo dpkg -i /tmp/dockstation_1.3.0_amd64.deb && rm /tmp/dockstation_1.3.0_amd64.deb

# TLDR
go get 4d63.com/tldr

# Install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +BundleInstall
vim +GoInstallBinaries

# Install oh-my-szh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# XAuth
# https://superuser.com/questions/806637/xauth-not-creating-xauthority-file/941244#941244
 rm -f .Xauthority
 # xauth with complain unless ~/.Xauthority exists
 touch ~/.Xauthority
 # only this one key is needed for X11 over SSH 
 xauth generate :0 . trusted 
 # generate our own key, xauth requires 128 bit hex encoding
 xauth add "${HOST}":0 . $(xxd -l 16 -p /dev/urandom)
 # To view a listing of the .Xauthority file, enter the following 
 xauth list 

 # Install Tilix Theme
 mkdir -p ~/.config/tilix/schemes/
 wget -qO "${HOME}"/.config/tilix/schemes/desert.json https://raw.githubusercontent.com/storm119/Tilix-Themes/master/Themes/desert.json
 gsettings set org.gnome.desktop.default-applications.terminal exec 'terminal'

# Fixed in bionic ttf-mscorefonts-installer
# http://www.asso-linux.org/forum/viewtopic.php?f=4&t=196
# wget -o /tmp/ttf-mscorefonts-installer_3.6_all.deb -O http://ftp.fr.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
# sudo dpkg -i /tmp/ttf-mscorefonts-installer_3.6_all.deb
# sudo apt install -f

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

# Misc Gnome configurations
# Some help : https://askubuntu.com/questions/971067/how-can-i-script-the-settings-made-by-gnome-tweak-tool
# dconf watch / is your friend !
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-last-coordinates '(50.633000000000003, 3.0586000000000002)'
gsettings set org.gnome.desktop.wm.preferences theme 'Radiance'
gsettings set org.gnome.desktop.interface gtk-theme 'Radiance'
gsettings set org.gnome.desktop.interface cursor-theme 'DMZ-White'
gsettings set org.gnome.eog.plugins.pythonconsole font 'Monospace 10'
gsettings set org.gnome.desktop.interface icon-theme 'ubuntu-mono-dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 9'
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 12'
gsettings set org.gnome.gedit.plugins.pythonconsole font 'Monospace 10'
gsettings set com.canonical.unity-greeter icon-theme-name 'ubuntu-mono-dark'
gsettings set org.gnome.meld custom-font 'monospace, 14'
gsettings set org.gnome.gedit.plugins.externaltools font 'Monospace 10'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set com.canonical.indicator.datetime show-day true
gsettings set com.canonical.indicator.datetime show-date true
gsettings set com.canonical.indicator.datetime show-week-numbers true
gsettings set com.canonical.indicator.datetime show-calendar true
gsettings set com.canonical.indicator.datetime show-events true
gsettings set com.canonical.indicator.datetime show-clock true
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.mutter workspaces-only-on-primary true
gsettings set org.gnome.shell favorite-apps ['firefox.desktop', 'google-chrome.desktop', 'rhythmbox.desktop', 'shotwell.desktop', 'libreoffice-writer.desktop', 'org.gnome.Nautilus.desktop', 'youtube-dlg.desktop', 'cacher.desktop', 'spotify.desktop', 'atom.desktop', 'keepass2.desktop', 'com.gexperts.Tilix.desktop', 'QOwnNotes.desktop']
gsettings set org.gnome.shell.window-switcher current-workspace-only false
gsettings set org.gnome.desktop.screensaver lock-delay 120
gsettings set org.gnome.desktop.privacy report-technical-problems true
gsettings set org.gnome.desktop.screensaver picture-options 'zoom'
gsettings set org.gnome.desktop.screensaver primary-color '#ffffff'
gsettings set org.gnome.desktop.screensaver secondary-color '#000000'
gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/backgrounds/gnome/Bokeh_Tails.jpg'

# Kubernetes
# https://github.com/kubernetes/minikube
cd ~/bin/ || exit
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl
export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir "$HOME"/.kube || true
touch "$HOME"/.kube/config
export KUBECONFIG="$HOME"/.kube/config
sudo -E ./minikube start
# this for loop waits until kubectl can access the api server that Minikube has created
for i in {1..150}; do # timeout for 5 minutes
  ./kubectl get po &> /dev/null
  if [ $? -ne 1 ]; then
    break
  fi
  sleep 2
done
sudo kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080
sudo kubectl expose deployment hello-minikube --type=NodePort
curl $(minikube service hello-minikube --url)
# sudo minikube dashboard
sudo minikube stop
cd /tmp || exit
git clone git clone https://github.com/ahmetb/kubectx.git
cp -v kubectx/{kubectx,kubens,utils.bash} ~/bin/ 
# Some other tools
# https://github.com/appscode/kubed
# https://github.com/heptio/ark
# https://github.com/cloudnativelabs/kube-router
# https://github.com/GoogleCloudPlatform/kube-metacontroller

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

# CloudConvert
sudo npm install -g cloudconvert-cli
export CLOUDCONVERT_API_KEY=changeme

# Fast speedtest by Netflix commandline
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
sudo apt-get install -y nodejs
# sudo npm install --global fast-cli  # needs to understand why installation fail
# INstall eslint for syntastic
sudo npm install -g eslint
sudo npm install -g babel-eslint
sudo npm install -g eslint-plugin-react

# Gandi Client
cd /tmp || exit
sudo apt-get install -y python-nose python3-nose python-ipy
git clone https://github.com/Gandi/gandi.cli.git
cd gandi.cli  || exit
ln -sf packages/debian debian && debuild -us -uc -b && sudo dpkg -i ../python-gandicli_1.0_all.deb

# Android Rules
cd /tmp || exit
git clone git@github.com:M0Rf30/android-udev-rules.git
sudo cp android-udev-rules/51-android.rules /etc/udev/rules.d/ 
sudo chmod a+r /etc/udev/rules.d/51-android.rules
sudo groupadd adbusers
sudo usermod -a -G adbusers $(whoami)
sudo udevadm control --reload-rules
sudo service udev restart

# Trello Client
# git clone https://github.com/mheap/trello-cli.git # best but badly installed
# https://github.com/qcam/3llo
sudo em install 3llo
export TRELLO_USER=your_username
export TRELLO_KEY=your_key
export TRELLO_TOKEN=your_token

# Try alphago .....
pip install tenserflow
pip install betago
# cd /tmp
# git clone https://github.com/maxpumperla/betago
# cd betago
# python run_demo.py

# WSS by Netflix
# https://github.com/brendangregg/wss.git

# dgraph
curl https://get.dgraph.io -sSf | bash

# Chaos toolkit : https://medium.com/chaos-toolkit/announcing-chaos-discover-and-chaos-init-ff2bf02c5a85
docker pull chaostoolkit/chaostoolkit
docker run -it chaostoolkit/chaostoolkit discover chaostoolkit-kubernetes

# Top-like interface for container metrics https://ctop.sh
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7/ctop-0.7-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop

# Infrakit : A toolkit for creating and managing declarative, self-healing infrastructure.
mkdir -p $GOPATH/src/github.com/docker || true
cd $GOPATH/src/github.com/docker || exit
git clone git@github.com:docker/infrakit.git
cd infrakit && make get-tools & make ci && make binaries
cp build/* ~/bin/

# molecule : https://blog.octo.com/en/the-wizard-ansible-molecule-and-test-driven-development/
sudo pip install molecule
cd /tmp || exit
git clone https://github.com/metacloud/molecule
cd /tmp/molecule/test/scenarios/driver/docker || exit
molecule test

# chromeIPass : https://github.com/pfn/passifox/
sudo wget https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx -O /usr/lib/keepass2/KeePassHttp.plgx

# Vault
wget https://releases.hashicorp.com/vault/0.9.3/vault_0.9.3_linux_amd64.zip -O ~/bin/vault_0.9.3_linux_amd64.zip
unzip ~/bin/vault_0.9.3_linux_amd64.zip && rm ~/bin/vault_0.9.3_linux_amd64.zip
vault -autocomplete-install
export VAULT_ADDR='http://127.0.0.1:8200'
# setup https://github.com/Caiyeon/goldfish/wiki/Production-Deployment

# Issue-helper
sudo apt remove cargo rustc
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
cargo install gli

# Feedreader
curl https://raw.githubusercontent.com/jangernert/FeedReader/master/scripts/install_ubuntu.sh | bash

# urbackup
TF=$(mktemp) && wget "https://hndl.urbackup.org/Client/2.2.5/UrBackup%20Client%20Linux%202.2.5.sh" -O $TF && sudo sh $TF; rm $TF

# lnav
cd ~/bin || exit
wget https://github.com/tstack/lnav/releases/download/v0.8.3/lnav-0.8.3-linux-64bit.zip -O ~/bin/lnav-0.8.3-linux-64bit.zip
unzip ~/bin/lnav-0.8.3-linux-64bit.zip && rm ~/bin/lnav-0.8.3-linux-64bit.zip
