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
packages=(zsh nvim zellij mise gemini custom_scripts)

for pkg in "${packages[@]}"; do
    if [ -d "$pkg" ]; then
        echo "   Restowing $pkg..."
        # Use --adopt to link even if files exist, but we should be careful.
        # Better: check for conflicts and move them to backup if they aren't links.
        stow -v -R "$pkg" 2>&1 | while read -r line; do
            if [[ "$line" == *"existing target is neither a link nor a directory"* ]]; then
                conflict_file=$(echo "$line" | awk -F': ' '{print $2}')
                echo "   ⚠️  Conflict found: $conflict_file. Moving to backup..."
                mkdir -p "$DOTFILES_DIR/backups"
                mv "$HOME/$conflict_file" "$DOTFILES_DIR/backups/$(basename "$conflict_file").bak_$(date +%s)"
                stow -v -R "$pkg"
            else
                echo "      $line"
            fi
        done
    fi
done

echo "✅ Sync complete! Restart your shell or run 'source ~/.zshrc' if Zsh config changed."
