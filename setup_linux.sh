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
    fzf

# 2. Modern Unix Tools (Manual Installs for freshness)

# --- Neovim (AppImage for latest version) ---
if ! command -v nvim &> /dev/null; then
    echo "📦 Installing Neovim (AppImage)..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
fi

# --- Zellij (Binary) ---
if ! command -v zellij &> /dev/null; then
    echo "📦 Installing Zellij..."
    curl -L https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz | tar xz
    chmod +x zellij
    sudo mv zellij /usr/local/bin/
fi

# --- Lazygit ---
if ! command -v lazygit &> /dev/null; then
    echo "📦 Installing Lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

# --- Zoxide (Better cd) ---
if ! command -v zoxide &> /dev/null; then
    echo "📦 Installing Zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# --- Eza (Better ls) ---
if ! command -v eza &> /dev/null; then
    echo "📦 Installing Eza (via gpg)..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

# 3. Handle Dotfiles
echo "🔗 Linking Configs with Stow..."
mkdir -p "$DOTFILES_DIR/zsh/.zsh"
mkdir -p "$DOTFILES_DIR/nvim/.config"
mkdir -p "$DOTFILES_DIR/zellij/.config"

# Backup existing
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$BACKUP_DIR/"
fi

cd "$DOTFILES_DIR"
stow -v -R zsh
stow -v -R nvim
stow -v -R zellij
# stow -v -R qutebrowser # Uncomment if you install qutebrowser on linux

# 4. Change Shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🐚 Changing default shell to Zsh..."
    chsh -s $(which zsh)
fi

echo "🎉 Linux Setup Complete! Restart your terminal."