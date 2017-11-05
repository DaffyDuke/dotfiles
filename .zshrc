# Path to your oh-my-zsh installation.
<<<<<<< HEAD
export ZSH=/home/daffy/.oh-my-zsh
=======
export ZSH=$HOME/.oh-my-zsh
>>>>>>> b496d4db7e0d22616c9261082458438a132de200

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"
<<<<<<< HEAD
=======
#ZSH_THEME="wulve"
>>>>>>> b496d4db7e0d22616c9261082458438a132de200

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

<<<<<<< HEAD
# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

=======
>>>>>>> b496d4db7e0d22616c9261082458438a132de200
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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
<<<<<<< HEAD
plugins=(git aws colored-man-pages command-not-found docker go golang history rsync systemd tmux ubuntu)

# User configuration

  export PATH="/home/daffy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
=======
plugins=(git bundler golang rake ruby ssh-agent tmuxinator)

# User configuration

export PATH=$HOME/bin:/usr/local/bin:$PATH
>>>>>>> b496d4db7e0d22616c9261082458438a132de200
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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

<<<<<<< HEAD
if [[ $TILIX_ID ]]; then
    source /etc/profile.d/vte.sh
fi

=======

export TERM=xterm-256color

export GOROOT=$HOME/go-dist
export GOPATH=~/GOPROJECTS
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$GOPATH/bin
export EDITOR=vim
export PATH=$PATH:~/bin
#export PS1="${ret_status}%{$fg_bold[green]%}%m/linux %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}"
ssh() {
        tmux rename-window "$(echo $@ | awk '{print $NF}' | cut -d . -f 1)"
            command ssh "$@"
                tmux set-window-option automatic-rename "on" 1>/dev/null
}

export PS1='${ret_status}%{$fg_bold[green]%}%m %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(git_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'
>>>>>>> b496d4db7e0d22616c9261082458438a132de200
