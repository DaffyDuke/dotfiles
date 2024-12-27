# Credits
Forked from https://github.com/owulveryck/dotfiles
Adapted with https://lord.re/posts/62-dotfiles-home-git/
Lots of fun from https://catonmat.net/linux-and-vim-notes

# prerequisite
alias
```
alias config='git --git-dir=$HOME/dotfiles --work-tree=$HOME'
```
# sample of command
```
config commit -m 'tuning zshrc' .zshrc
```
please use commitizen 
```
config cz commit
```
