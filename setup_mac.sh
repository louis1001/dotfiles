#!/bin/bash
set -e # Exit on error

# 1. Setup Variables
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "🚀 Starting Migration..."

# 2. Check Dependencies
if ! command -v stow &>/dev/null; then
  echo "📦 Installing Stow..."
  brew install stow
fi

# 3. Create Repo Structure
echo "qb Creating directories..."
# We use the structure: package/.config/name to stow correctly to home
mkdir -p "$DOTFILES_DIR/zsh/.zsh"
mkdir -p "$DOTFILES_DIR/nvim/.config"
mkdir -p "$DOTFILES_DIR/zellij/.config"
mkdir -p "$DOTFILES_DIR/mise/.config"
mkdir -p "$DOTFILES_DIR/custom_scripts/.config"

# 4. Helper Function to Move
move_to_dotfiles() {
  local src="$1"
  local dest_parent="$2" # The folder inside dotfiles (e.g., nvim/.config)
  local dest_name="$3"   # The final folder name (e.g., nvim)

  if [ -e "$src" ]; then
    echo "   Moving $src -> $dest_parent/$dest_name"
    mkdir -p "$dest_parent"
    mv "$src" "$dest_parent/$dest_name"
  else
    echo "   ⚠️  Source $src not found, skipping."
  fi
}

# 5. Execute Moves
# Move Zshrc
if [ -f "$HOME/.zshrc" ]; then
  mv "$HOME/.zshrc" "$DOTFILES_DIR/zsh/.zshrc_backup" # Backup original, we will use a new generated one
  echo "   Backed up original .zshrc"
fi

# Move Config Folders
move_to_dotfiles "$HOME/.config/nvim" "$DOTFILES_DIR/nvim/.config" "nvim"
move_to_dotfiles "$HOME/.config/zellij" "$DOTFILES_DIR/zellij/.config" "zellij"
move_to_dotfiles "$HOME/.config/mise" "$DOTFILES_DIR/mise/.config" "mise"
move_to_dotfiles "$HOME/.config/louis1001" "$DOTFILES_DIR/custom_scripts/.config" "louis1001"

# 6. Generate New Modular Zsh Configs
echo "📝 Generating new Zsh configuration..."

# --- 6a. Main .zshrc ---
cat >"$DOTFILES_DIR/zsh/.zshrc" <<'EOF'
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
EOF

# --- 6b. Exports & Paths (Cleaned up) ---
cat >"$DOTFILES_DIR/zsh/.zsh/exports.zsh" <<'EOF'
# Environment & Paths
export GEM_HOME="$HOME/.gem"
export EDITOR='nvim'

# NPM
export NPM_PACKAGES="$HOME/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

# Dotnet
export PATH="$PATH:$HOME/.dotnet/tools"

# Cargo
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Tool Managers (Mise & ASDF)
# Prefer Mise, fallback to ASDF if needed
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
elif [ -f "$HOME/.local/bin/mise" ]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi

if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
  . "$HOME/.asdf/completions/asdf.bash"
fi
EOF

# --- 6c. Aliases ---
cat >"$DOTFILES_DIR/zsh/.zsh/aliases.zsh" <<'EOF'
# Navigation
alias job="cd ~/Documents/projects/applaudo/volaris_ios"

# iOS / Tuist
alias tg="tuist generate"
EOF

# --- 6d. MacOS Specifics ---
cat >"$DOTFILES_DIR/zsh/.zsh/macos.zsh" <<'EOF'
# Herd Lite (PHP)
export PATH="/Users/louis1001/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/Users/louis1001/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# Maestro
export PATH=$PATH:$HOME/.maestro/bin
EOF

# --- 6e. Linux Placeholder ---
touch "$DOTFILES_DIR/zsh/.zsh/linux.zsh"

# 7. Stow Everything
echo "🔗 Linking files..."
cd "$DOTFILES_DIR"
stow -v -R zsh
stow -v -R nvim
stow -v -R zellij
stow -v -R mise
stow -v -R gemini
stow -v -R custom_scripts

echo "🎉 Migration Complete!"
echo "   New config location: ~/dotfiles"
echo "   Restart your terminal."
