# Environment & Paths
export GEM_HOME="$HOME/.gem"
export EDITOR='nvim'

# Dotfiles custom scripts
export PATH="$PATH:$HOME/dotfiles/custom_scripts"

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
