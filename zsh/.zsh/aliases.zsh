# Navigation
alias job="cd ~/Documents/projects/applaudo/volaris_ios"

# iOS / Tuist
alias tg="tuist generate"

# Seamless Navigation: Zsh -> Zellij -> Vim
# NOTE: Ctrl+J is often 'Enter' in terminals. Be careful overriding it.
# Ctrl+L is usually 'Clear Screen'.

# Function to move zellij focus
function zellij_move() {
  zellij action move-focus $1
}

# Bind keys (Using ZLE - Zsh Line Editor)
# These only work when the command line is active (not running a process like top)

# Ctrl+h (Left)
bindkey -s '^h' 'zellij_move left^M'
# Ctrl+l (Right) - WARNING: Overrides Clear Screen
bindkey -s '^l' 'zellij_move right^M'
# Ctrl+k (Up)
bindkey -s '^k' 'zellij_move up^M'
# Ctrl+j (Down) - WARNING: Often conflicts with Enter (Accept Line)
# Most users skip Ctrl+j or map it carefully.
# bindkey -s '^j' 'zellij_move down^M'
