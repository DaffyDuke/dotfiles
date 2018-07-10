# Setup fzf
# ---------
if [[ ! "$PATH" == */home/daffy/.fzf/bin* ]]; then
  export PATH="$PATH:/home/daffy/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/daffy/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/home/daffy/.fzf/shell/key-bindings.bash"

