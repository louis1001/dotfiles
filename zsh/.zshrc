# =============================================================================
# CORE CONFIGURATION
# =============================================================================

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell" # Restored RobbyRussell theme
plugins=(git zsh-syntax-highlighting z)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source $ZSH/oh-my-zsh.sh
fi

# =============================================================================
# THEME & VISUALS (Dracula)
# =============================================================================

# 1. Apply Base16 Shell Colors (Dracula)
# This ensures Linux terminals match the Mac iTerm colors
if [ -f "$HOME/.zsh/themes/dracula.sh" ]; then
    source "$HOME/.zsh/themes/dracula.sh"
fi

# 2. Starship Prompt (Disabled to prioritize RobbyRussell)
# if command -v starship &> /dev/null; then
#     eval "$(starship init zsh)"
# fi

# =============================================================================
# MODULAR SOURCING
# =============================================================================

if [ -f "$HOME/.zsh/exports.zsh" ]; then source "$HOME/.zsh/exports.zsh"; fi
if [ -f "$HOME/.zsh/aliases.zsh" ]; then source "$HOME/.zsh/aliases.zsh"; fi

case "$OSTYPE" in
  darwin*)
    [ -f "$HOME/.zsh/macos.zsh" ] && source "$HOME/.zsh/macos.zsh"
    if [ -f "/opt/homebrew/bin/brew" ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    ;;
  linux*)
    [ -f "$HOME/.zsh/linux.zsh" ] && source "$HOME/.zsh/linux.zsh"
    ;;
esac

# Zoxide (Better cd)
if command -v zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi
