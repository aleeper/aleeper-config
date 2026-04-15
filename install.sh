#!/usr/bin/env bash
# install.sh — set up aleeper-config as the source of truth.
# Supports Linux (apt) and macOS (Homebrew).
# Safe to re-run: backs up existing real files before symlinking.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="$(uname -s)"
echo "Installing from: $REPO (platform: $PLATFORM)"

# ── Helpers ───────────────────────────────────────────────────────────────────

symlink() {
  local src="$REPO/$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    echo "  Backing up: $dst -> $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  Linked: $dst -> $src"
}

clone_plugin() {
  local repo="$1" dest="$2"
  if [[ ! -d "$dest" ]]; then
    echo "  Cloning $repo → $dest"
    git clone --depth=1 "$repo" "$dest"
  else
    echo "  Already installed: $dest"
  fi
}

# ── System packages ───────────────────────────────────────────────────────────
echo ""
echo "── Installing packages ──────────────────────────────────────"
if [[ "$PLATFORM" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "  Homebrew is required. Install it from https://brew.sh then re-run."
    exit 1
  fi
  brew install \
    bat \
    eza \
    fd \
    fzf \
    git-delta \
    ncdu \
    neovim \
    ripgrep \
    zoxide \
    zsh-autosuggestions \
    zsh-syntax-highlighting
  brew install --cask alacritty
else
  sudo apt-get install -y \
    bat \
    cmake \
    eza \
    fd-find \
    fzf \
    git-delta \
    libfontconfig-dev \
    libfreetype-dev \
    libxcb-xfixes0-dev \
    libxkbcommon-dev \
    ncdu \
    pkg-config \
    ripgrep \
    zoxide \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting
fi
echo "  Done."

# ── Nerd Font (JetBrainsMono — required for p10k and nvim icons) ──────────────
echo ""
echo "── Nerd Font ────────────────────────────────────────────────"
if [[ "$PLATFORM" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
else
  FONT_DIR="$HOME/.local/share/fonts"
fi
if [[ -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
  echo "  Already installed: JetBrainsMono Nerd Font"
else
  echo "  Installing JetBrainsMono Nerd Font..."
  mkdir -p "$FONT_DIR"
  TMP="$(mktemp -d)"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    -o "$TMP/JetBrainsMono.tar.xz"
  tar xf "$TMP/JetBrainsMono.tar.xz" -C "$FONT_DIR"
  rm -rf "$TMP"
  fc-cache -fv >/dev/null 2>&1 || true
  echo "  Installed. Set terminal font to: JetBrainsMono Nerd Font Mono"
fi

# ── External plugins (cloned to ~/.personal-plugins, not git submodules) ──────
echo ""
echo "── Cloning external plugins ─────────────────────────────────"
clone_plugin https://github.com/romkatv/powerlevel10k.git \
  "$HOME/.config/zsh/plugins/powerlevel10k"
clone_plugin https://github.com/projekt0n/github-theme-contrib.git \
  "$HOME/.personal-plugins/github-theme-contrib"

# ── Symlinks ──────────────────────────────────────────────────────────────────
echo ""
echo "── Creating symlinks ────────────────────────────────────────"
symlink alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml
if [[ "$PLATFORM" == "Darwin" ]]; then
  symlink alacritty/macos.toml ~/.config/alacritty/platform.toml
else
  symlink alacritty/linux.toml ~/.config/alacritty/platform.toml
fi

symlink bash/bashrc           ~/.bashrc
symlink zsh/zshrc             ~/.zshrc
symlink zsh/p10k.zsh          ~/.p10k.zsh
symlink git/gitconfig         ~/.gitconfig
symlink vim/vimrc             ~/.vimrc
symlink nvim                  ~/.config/nvim
symlink tmux/tmux.conf        ~/.tmux.conf
symlink tmux/insert_window.sh ~/.tmux/insert_window.sh

# Cursor and VSCode share the same settings format
symlink cursor/settings.json    ~/.config/Cursor/User/settings.json
symlink cursor/keybindings.json ~/.config/Cursor/User/keybindings.json
symlink cursor/settings.json    ~/.config/Code/User/settings.json
symlink cursor/keybindings.json ~/.config/Code/User/keybindings.json

# ── Stub files (not in repo — add your secrets here) ─────────────────────────
echo ""
echo "── Stub files ───────────────────────────────────────────────"

mkdir -p "$HOME/.shell.d"
echo "  ~/.shell.d/ ready (drop *.sh files here to auto-source them)"
if [[ ! -f "$HOME/.shell.d/work.sh" ]]; then
  cat > "$HOME/.shell.d/work.sh" <<'EOF'
#!/usr/bin/env sh
# ~/.shell.d/work.sh — machine/work-specific config (not in aleeper-config repo)
# Sourced automatically by ~/.bashrc and ~/.zshrc. Keep POSIX-compatible.
EOF
  echo "  Created: ~/.shell.d/work.sh (stub)"
else
  echo "  Already exists: ~/.shell.d/work.sh"
fi

if [[ ! -f ~/.gitconfig.work ]]; then
  cat > ~/.gitconfig.work <<'EOF'
[user]
  email = adam@applied.co
EOF
  echo "  Created: ~/.gitconfig.work"
else
  echo "  Already exists: ~/.gitconfig.work"
fi

# ── Set zsh as default shell ──────────────────────────────────────────────────
echo ""
echo "── Default shell ────────────────────────────────────────────"
if [[ "$PLATFORM" == "Darwin" ]]; then
  _configured_shell="$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')"
else
  _configured_shell="$(getent passwd "$USER" | cut -d: -f7)"
fi
if [[ "$_configured_shell" == "$(which zsh)" ]]; then
  echo "  Already using zsh ($_configured_shell)"
else
  echo "  Switching default shell to zsh (will prompt for password)..."
  chsh -s "$(which zsh)"
fi
unset _configured_shell

# ── Rust (required for cargo install alacritty) ───────────────────────────────
if [[ "$PLATFORM" != "Darwin" ]]; then
  echo ""
  echo "── Rust ─────────────────────────────────────────────────────"
  if command -v cargo >/dev/null 2>&1 || [[ -f "$HOME/.cargo/bin/cargo" ]]; then
    echo "  Already installed: $(cargo --version 2>/dev/null || $HOME/.cargo/bin/cargo --version)"
  else
    echo "  Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    echo "  Installed: $("$HOME/.cargo/bin/cargo" --version)"
  fi
  source "$HOME/.cargo/env"
fi

# ── Alacritty (Linux — build from source via cargo for latest version) ────────
if [[ "$PLATFORM" != "Darwin" ]]; then
  echo ""
  echo "── Alacritty ────────────────────────────────────────────────"
  if [[ -f "$HOME/.cargo/bin/alacritty" ]]; then
    echo "  Already installed: $("$HOME/.cargo/bin/alacritty" --version)"
  else
    echo "  Building Alacritty via cargo (this takes a few minutes)..."
    cargo install alacritty --locked
    echo "  Installed: $(alacritty --version)"
  fi
fi

# ── Neovim (Linux only — macOS gets it via brew above) ───────────────────────
if [[ "$PLATFORM" != "Darwin" ]]; then
  echo ""
  echo "── Neovim ───────────────────────────────────────────────────"
  # grep -oP is Linux-only; use sed for portability
  NVIM_MINOR="$(nvim --version 2>/dev/null | head -1 | sed 's/.*v[0-9]*\.\([0-9]*\).*/\1/')"
  if [[ -z "$NVIM_MINOR" ]] || [[ "$NVIM_MINOR" -lt 11 ]]; then
    echo "  nvim minor ${NVIM_MINOR:-?} is too old (need 0.11+), installing latest..."
    TMP="$(mktemp -d)"
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
      -o "$TMP/nvim.tar.gz"
    tar xzf "$TMP/nvim.tar.gz" -C "$TMP"
    sudo mv "$TMP/nvim-linux-x86_64" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -rf "$TMP"
    echo "  Installed: $(nvim --version | head -1)"
  else
    echo "  nvim 0.$NVIM_MINOR is recent enough, skipping."
  fi
fi

# ── GNOME keyboard shortcut for Alacritty (Linux only) ───────────────────────
if [[ "$PLATFORM" != "Darwin" ]] && command -v gsettings >/dev/null 2>&1; then
  echo ""
  echo "── GNOME shortcut (Ctrl+Alt+T → Alacritty) ──────────────────"
  _kb_base="org.gnome.settings-daemon.plugins.media-keys"
  _kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
  # Clear the built-in terminal binding so it doesn't compete
  gsettings set "$_kb_base" terminal '[]'
  # Register Alacritty as a custom shortcut
  gsettings set "$_kb_base" custom-keybindings "['$_kb_path']"
  gsettings set "${_kb_base}.custom-keybinding:${_kb_path}" name    'Alacritty'
  gsettings set "${_kb_base}.custom-keybinding:${_kb_path}" command 'alacritty'
  gsettings set "${_kb_base}.custom-keybinding:${_kb_path}" binding '<Primary><Alt>t'
  unset _kb_base _kb_path
  echo "  Ctrl+Alt+T → alacritty"
fi

# ── Post-install notes ────────────────────────────────────────────────────────
echo ""
echo "── Done! Next steps: ────────────────────────────────────────"
echo "  1. exec zsh                   (start zsh session)"
echo "  2. p10k configure             (set up prompt, saves to ~/.p10k.zsh)"
echo "  3. nvim                       (triggers lazy.nvim plugin bootstrap)"
echo "  4. Fill in ~/.shell.d/work.sh (tokens, docker helpers, company PATH)"
echo ""
