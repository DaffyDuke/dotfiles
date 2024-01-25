# Setup fzf
# ---------
if [[ ! "$PATH" == */home/daffy/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/daffy/.fzf/bin"
fi

# Auto-completion
# ---------------
source "/home/daffy/.fzf/shell/completion.bash"

# Key bindings
# ------------
source "/home/daffy/.fzf/shell/key-bindings.bash"
