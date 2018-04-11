# Some tips on windows
## Be compliant with Linux
Apply WindowsTimeFixUTC.reg

## Install Babun
# https://babun.github.io/
Fix environment dirs

```
echo "daffyduke:x:197609:197608:Olivier Duquesne:/home/daffyduke:/bin/zsh" > /etc/passwd
echo "daffyduke::13064:0:99999:7::::" > /etc/shadow
echo "daffyduke:x:197609:daffyduke" > /etc/group
ssh-keygen
chmod 600 /home/daffyduke/.ssh/id_rsa
```
Update dir

```
babun update
babun shell /bin/zsh
```

## Install Go
# https://golang.org/dl/
##Change .gitconfig to dosable ssl check
```
go get golang.org/x/tools/cmd/godoc
go get golang.org/x/tools/cmd/goimports
go get -u github.com/golang/lint/golint
go get 4d63.com/tldr

```
Some Go and Vim tools ...

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +BundleInstall
vim +GoInstallBinaries

```
## Fix Putty directory
```
mv /usr/bin/awk /usr/bin/awk-KO
ln -s /usr/bin/gawk /usr/bin/awk
pact install tmux sudo httpie 
pact remove libcrypt0
pact update perl
pact install make
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"

```
### Install Docker
https://store.docker.com/editions/community/docker-ce-desktop-windows

```
bin/docker-machine create --driver virtualbox --virtualbox-cpu-count 1 --virtualbox-disk-size "20000" --virtualbox-memory "2048"  --virtualbox-ui-type "headless" DockerMachine
bin/docker-machine.exe env DockerMachine

```

### Install Keybase
https://keybase.io/docs/the_app/install_windows

### Install Windows 10 SDK
https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk
