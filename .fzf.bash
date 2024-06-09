# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/mac-Z09ODUQU/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/Users/mac-Z09ODUQU/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/mac-Z09ODUQU/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/mac-Z09ODUQU/.fzf/shell/key-bindings.bash"
