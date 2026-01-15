# Main Zshrc
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-syntax-highlighting)

# Load Oh-My-Zsh
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source $ZSH/oh-my-zsh.sh
fi

# Modular Sourcing
source "$HOME/.zsh/exports.zsh"
source "$HOME/.zsh/aliases.zsh"

# OS Specifics
if [[ "$OSTYPE" == "darwin"* ]]; then
    [ -f "$HOME/.zsh/macos.zsh" ] && source "$HOME/.zsh/macos.zsh"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    [ -f "$HOME/.zsh/linux.zsh" ] && source "$HOME/.zsh/linux.zsh"
fi

# Custom Session Scripts
[ -f "$HOME/.config/louis1001/setup_session.sh" ] && source "$HOME/.config/louis1001/setup_session.sh"
