# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="powerlevel9k/powerlevel9k"
# ZSH_THEME="robbyrussell"
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"
LESSHISTFILE=/dev/null

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(aws bundler debian docker git gitignore golang kitchen kubectl rake ruby keychain terraform thefuck tmuxinator ubuntu ugit zsh-wakatime z zsh-autosuggestions)
# plugins=(aws bundler debian docker git gitignore golang kitchen kubectl rake ruby gpg-ssh-smartcard-yubikey-keybase terraform thefuck tmuxinator ubuntu )

# User configuration

export PATH=$HOME/bin:${KREW_ROOT:-$HOME/.krew}/bin:/usr/local/bin:/usr/share/bcc/tools/:$PATH
if [ -f /etc/debian_version ]; then
export PY_USER_BIN=$(python -c 'import site; print(site.USER_BASE + "/bin")')
else
export PY_USER_BIN=$(/opt/homebrew/opt/python/libexec/bin/python -c 'import site; print(site.USER_BASE + "/bin")')
fi
export RUST_USER_BIN=$HOME/.cargo/bin
# export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"
eval `keychain --eval --agents ssh id_rsa`
if [ -f ~/.ssh/id_ecdsa ]; then
eval `keychain --eval --agents ssh ~/.ssh/id_ecdsa`
fi

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
source $HOME/.aliases
[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases

export TERM=xterm-256color

export GOROOT=$HOME/go-dist
export GOPATH=~/GOPROJECTS
export PATH=$RUST_USER_BIN:$PY_USER_BIN:$GOROOT/bin:$PATH
export PATH=$PATH:$GOPATH/bin
export EDITOR=vim
export SHELLCHECK_OPTS="-e SC2086 -e SC2043"
export GPG_TTY=`tty`

#export PS1="${ret_status}%{$fg_bold[green]%}%m/linux %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}"
ssh() {
        tmux rename-window "$(echo $@ | awk '{print $NF}' | cut -d . -f 1)"
            command ssh "$@"
                tmux set-window-option automatic-rename "on" 1>/dev/null
}

export PS1='${ret_status}%{$fg_bold[green]%}%m %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C $HOME/bin/vault vault

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $HOME/.oh-my-zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
if [ -f /etc/debian_version ]
then
. $HOME/.asdf/asdf.sh
else
. /opt/homebrew/opt/asdf/libexec/asdf.sh
fi

# Howdoi
# https://github.com/gleitz/howdoi
export  HOWDOI_COLORIZE=1
export  HOWDOI_DISABLE_CACHE=1
# export  HOWDOI_DISABLE_SSL=1
# export  HOWDOI_SEARCH_ENGINE=google
# export  HOWDOI_URL=serverfault.com

# https://starship.rs/guide/#%F0%9F%9A%80-installation
# The minimal, blazing-fast, and infinitely customizable prompt for any shell!
eval "$(starship init zsh)"

# https://github.com/denisidoro/navi/blob/master/docs/installation.md#installing-the-shell-widget
# An interactive cheatsheet tool for the command-line.
eval "$(navi widget zsh)"

if [ -f /etc/debian_version ]
then
alias fix='eval $(acli --script fixCmd "$(fc -nl -1)" $?)'
howto() { h="$@"; eval $(acli --script howCmd "$h") ; }

# ARA vars for ansible
export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"

# fx.wtf
source <(fx --comp zsh)
else

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
alias vim=/opt/homebrew/bin/vim

# Homebrew: Python
export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"

# pyenv
export PATH="$HOME/.pyenv:$PATH"
eval "$(pyenv init -)"

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
fpath=($HOME/.oh-my-zsh/custom/completions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions $HOME/.oh-my-zsh/plugins/z $HOME/.oh-my-zsh/custom/plugins/zsh-wakatime $HOME/.oh-my-zsh/plugins/ubuntu $HOME/.oh-my-zsh/plugins/tmuxinator $HOME/.oh-my-zsh/plugins/thefuck $HOME/.oh-my-zsh/plugins/terraform $HOME/.oh-my-zsh/plugins/keychain $HOME/.oh-my-zsh/plugins/ruby $HOME/.oh-my-zsh/plugins/rake $HOME/.oh-my-zsh/plugins/kubectl $HOME/.oh-my-zsh/plugins/kitchen $HOME/.oh-my-zsh/plugins/golang $HOME/.oh-my-zsh/plugins/gitignore $HOME/.oh-my-zsh/plugins/git $HOME/.oh-my-zsh/plugins/docker $HOME/.oh-my-zsh/plugins/debian $HOME/.oh-my-zsh/plugins/bundler $HOME/.oh-my-zsh/plugins/aws $HOME/.oh-my-zsh/functions $HOME/.oh-my-zsh/completions $HOME/.oh-my-zsh/cache/completions /usr/local/share/zsh/site-functions /usr/share/zsh/site-functions /usr/share/zsh/5.9/functions)

# Add krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# https://github.com/lensapp/lens/issues/6563
export USE_GKE_GCLOUD_AUTH_PLUGIN=False

# https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke?hl=en
export USE_GKE_GCLOUD_AUTH_PLUGIN=True


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
eval "$($HOME/.local/bin/mise activate zsh)"

fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

if [ ! -f /etc/debian_version ]; then
# JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
