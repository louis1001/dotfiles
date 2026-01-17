# Linux Specific Settings (Sourced by .zshrc)

# 1. Custom Binaries
export PATH="$HOME/.local/bin:$PATH"

# 2. Fix delete key in some terminals (e.g. VS Code terminal, Zellij)
bindkey "^[[3~" delete-char

# 3. Initialize NVM (Node Version Manager)
# This ensures Neovim sees the correct Node version (e.g., v22) selected by nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
