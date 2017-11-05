#!/bin/bash

# Things to do after installing Ubuntu 17.10
# https://itsfoss.com/things-installing-ubuntu-17-10/
sudo apt update && sudo apt upgrade
sudo apt install tlp tlp-rdw
sudo tlp start

# this tool aims to be ran from Ubuntu
# install additionnal repositories
for ppa in ppa:djcj/hybrid \
  ppa:eviltwin1/feedreader-stable \
  ppa:geary-team/releases \
  ppa:gezakovacs/ppa \
  ppa:hollywood/ppa \
  ppa:mariospr/frogr \
  ppa:pbek/qownnotes \
  ppa:peek-developers/stable \
  ppa:peterlevi/ppa \
  ppa:teejee2008/ppa \
  ppa:unit193/encryption \
  ppa:uroni/urbackup \
  ppa:vincent-vandevyvre/vvv \
  ppa:webupd8team/atom \
  ppa:webupd8team/indicator-kdeconnect \
  ppa:webupd8team/tor-browser \
  ppa:webupd8team/y-ppa-manager
do
  sudo apt-add-repository --yes ${ppa}
done
sudo apt-get update
sudo apt install -y cool-retro-term hollywood frogr qownnotes peek variety timeshift veracrypt urbackup oqapy atom indicator-kdeconnect tor-browser y-ppa-manager 
sudo apt install -y git zsh

# Install some packages
sudo apt install -f gnome-tweak-tool ubuntu-restricted-extras tilix alien awscli bc bluegriffon corkscrew darktable default-jre deluge-gtk dnstracer easytag ethstatus ethtool fastboot fortunes-fr freemind ftp gcompris gcompris-sound-fr gcstar geary glances gnupg2 google-cloud-sdk guake handbrake harmony heimdall-flash-frontend hugin hugo icedtea-plugin iftop iotop iptstate jxplorer kerneloops klavaro language-pack-fr libreoffice-gnome lightworks lsof lynx mc meld ncdu netcat-openbsd nmap nmon ogmrip openconnect openssh-client openssh-server openvpn owncloud-client p7zip parcellite parted pass patch pgtop pssh pwgen qarte qemu-kvm qtpass rdesktop remmina repo rpm rsync s3cmf scribus seahorse shellcheck shotwell simple-scan sshpass strace synaptic tcpdump testssl.sh thefuck tilix traceroute tshark tuxmath unetbootin unrar vagrant vim-gnome vim-youcompleteme virt-manager vlc weboob-qt whois wireshark xauth youtube-dlg zenmap

# Dropbox
# https://www.dropbox.com/install-linux
wget -o /tmp/dropbox_2015.10.28_amd64.deb -O https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb
sudo dpkg -i /tmp/dropbox_2015.10.28_amd64.deb

# VirtualBox
# https://www.virtualbox.org/wiki/Linux_Downloads
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
echo "deb http://download.virtualbox.org/virtualbox/debian yakkety contrib" | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
sudo apt-get update
sudo apt-get install virtualbox-5.2

# Keybase
# https://keybase.io/docs/the_app/install_linux
curl -o /tmp/keybase_amd64.deb -O https://prerelease.keybase.io/keybase_amd64.deb
sudo dpkg -i /tmp/keybase_amd64.deb
sudo apt-get install -f

# Spotify
# https://doc.ubuntu-fr.org/spotify
sudo sh -c 'echo "deb http://repository.spotify.com stable non-free" >> /etc/apt/sources.list.d/spotify.list'
udo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D2C19886
sudo apt-get update
sudo apt-get install spotify-client

# Slack
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
sudo dpkg -i puppet-release-xenial.deb
sudo apt-get update

# Docker
# https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce

# Install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp .vimrc ~/
vim +BundleInstall
vim +GoInstallBinaries
# Install tmux
#  Install oh-my-szh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
# INstall eslint for syntastic
sudo npm install -g eslint
sudo npm install -g babel-eslint
sudo npm install -g eslint-plugin-react

# XAuth
# https://superuser.com/questions/806637/xauth-not-creating-xauthority-file/941244#941244
 rm .Xauthority
 # xauth with complain unless ~/.Xauthority exists
 touch ~/.Xauthority
 # only this one key is needed for X11 over SSH 
 xauth generate :0 . trusted 
 # generate our own key, xauth requires 128 bit hex encoding
 xauth add ${HOST}:0 . $(xxd -l 16 -p /dev/urandom)
 # To view a listing of the .Xauthority file, enter the following 
 xauth list 

 # Install Tilix Theme
 mkdir -p ~/.config/tilix/schemes/
 wget -qO $HOME"/.config/tilix/schemes/desert.json" https://raw.githubusercontent.com/storm119/Tilix-Themes/master/Themes/desert.json

# Fix ttf-mscorefonts-installer
# http://www.asso-linux.org/forum/viewtopic.php?f=4&t=196
wget -o /tmp/ttf-mscorefonts-installer_3.6_all.deb -O http://ftp.fr.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb
sudo dpkg -i /tmp/ttf-mscorefonts-installer_3.6_all.deb
sudo apt install -f

