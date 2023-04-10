# Setup fzf
# ---------
if [[ ! "$PATH" == */home/daffy/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/daffy/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/daffy/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/daffy/.fzf/shell/key-bindings.zsh"
