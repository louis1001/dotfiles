#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "🐧 Starting Linux (Ubuntu/Debian) Setup..."

# 1. System Update & Essentials
echo "📦 Updating system and installing base dependencies..."
sudo apt update && sudo apt install -y \
  git \
  curl \
  wget \
  zsh \
  stow \
  build-essential \
  unzip \
  ripgrep \
  jq \
  python3-venv \
  fzf \
  lldb

# 2. Shell Setup (Oh My Zsh & Plugins)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "📦 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "📦 Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 3. Modern Unix Tools
# --- Neovim ---
if ! command -v nvim &>/dev/null; then
  echo "📦 Installing Neovim (AppImage)..."
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  sudo mv nvim.appimage /usr/local/bin/nvim
fi

# --- Zellij ---
if ! command -v zellij &>/dev/null; then
  echo "📦 Installing Zellij..."
  curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
  chmod +x zellij
  sudo mv zellij /usr/local/bin/
fi

# --- Lazygit ---
if ! command -v lazygit &>/dev/null; then
  echo "📦 Installing Lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
fi

# --- Zoxide ---
if ! command -v zoxide &>/dev/null; then
  echo "📦 Installing Zoxide..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# --- Eza ---
if ! command -v eza &>/dev/null; then
  echo "📦 Installing Eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi

# 4. Cleanup & Prepare Dotfiles
echo "🧹 Cleaning up conflicts..."
mkdir -p "$BACKUP_DIR"

# If the backup file exists INSIDE the repo (from Mac setup), move it out to avoid stow errors
if [ -f "$DOTFILES_DIR/zsh/.zshrc_backup" ]; then
  echo "   Moving internal backup file out of stow package..."
  mv "$DOTFILES_DIR/zsh/.zshrc_backup" "$BACKUP_DIR/zshrc_from_mac_migration"
fi

# 5. Backup Local Configs
# We must backup .zsh directory if it exists, otherwise stow cannot link the directory
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "   ⚠️  Existing config found at $target. Moving to $BACKUP_DIR..."
    mv "$target" "$BACKUP_DIR/"
  fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.zsh"          # <--- Critical: remove local .zsh dir to allow symlink
backup_if_exists "$HOME/.zshrc_backup" # <--- Critical: remove local backup file
backup_if_exists "$HOME/.config/nvim"
backup_if_exists "$HOME/.config/zellij"

# 6. Configure Linux Specifics
# Ensure .local/bin is in PATH for zoxide/mise
mkdir -p "$DOTFILES_DIR/zsh/.zsh"
cat >"$DOTFILES_DIR/zsh/.zsh/linux.zsh" <<EOF
# Linux Specific Settings
export PATH="\$HOME/.local/bin:\$PATH"
# Fix delete key in some terminals
bindkey "^[[3~" delete-char
EOF

# 7. Stow
echo "🔗 Linking Configs with Stow..."
mkdir -p "$DOTFILES_DIR/zsh/.zsh"
mkdir -p "$DOTFILES_DIR/nvim/.config"
mkdir -p "$DOTFILES_DIR/zellij/.config"
mkdir -p "$DOTFILES_DIR/mise/.config"
mkdir -p "$DOTFILES_DIR/gemini"

cd "$DOTFILES_DIR"
stow -v -R zsh
stow -v -R nvim
stow -v -R zellij
stow -v -R mise
stow -v -R gemini
stow -v -R custom_scripts

# 8. Change Shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "🐚 Changing default shell to Zsh..."
  chsh -s $(which zsh)
fi

echo "🎉 Linux Setup Complete! Restart your terminal."
