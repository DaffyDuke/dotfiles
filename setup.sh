# Install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp .vimrc ~/
vim +BundleInstall
vim +GoInstallBinaries
# Install tmux
cp .tmux.conf ~/
#  Install oh-my-szh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
cp .zshrc ~/
# INstall eslint for syntastic
sudo npm install -g eslint
sudo npm install -g babel-eslint
sudo npm install -g eslint-plugin-react
apt-get Install thefuck
