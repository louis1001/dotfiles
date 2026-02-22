#!/bin/bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "🔄 Syncing dotfiles..."

if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo "❌ Error: $DOTFILES_DIR is not a git repository."
    exit 1
fi

cd "$DOTFILES_DIR"

# 1. Pull latest changes
echo "📥 Pulling latest changes from git..."
git pull origin main --rebase || git pull origin master --rebase

# 2. Re-stow all packages
echo "🔗 Re-linking packages with Stow..."
packages=(zsh nvim zellij mise custom_scripts)

for pkg in "${packages[@]}"; do
    if [ -d "$pkg" ]; then
        echo "   Restowing $pkg..."
        stow -v -R "$pkg"
    fi
done

echo "✅ Sync complete! Restart your shell or run 'source ~/.zshrc' if Zsh config changed."
