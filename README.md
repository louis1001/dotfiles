# 🚀 dotfiles

Personal configuration files managed with **GNU Stow**.

## 📦 Structure

- `nvim/`: Neovim configuration (LazyVim based)
- `zsh/`: Zsh configuration (Modular: aliases, exports, OS-specific)
- `zellij/`: Terminal multiplexer config
- `mise/`: Tool manager configuration
- `custom_scripts/`: Personal utility scripts

## 🛠️ First-Time Setup

### macOS
```bash
./setup_mac.sh
```

### Linux (Ubuntu/Debian)
```bash
./setup_linux.sh
```

## 🔄 Syncing Changes

After pushing changes from one machine, run this on your other machines to pull and re-link:

```bash
./sync.sh
```

This script will:
1. Pull the latest changes from Git.
2. Re-run `stow` to ensure all symlinks are up to date.
