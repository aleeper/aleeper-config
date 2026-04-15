#!/usr/bin/env sh
# Personal shell functions — sourced by both bash and zsh

_ALEEPER_CONFIG_DIR="${ALEEPER_CONFIG_DIR:-$HOME/aleeper-config}"

# ── Build alerts ──────────────────────────────────────────────────────────────
if command -v aplay &>/dev/null; then _APLAY=aplay; fi
if command -v afplay &>/dev/null; then _APLAY=afplay; fi

# Wrap make to play a sound on success or failure
make() {
  /usr/bin/time -f "User: %U, System: %S, Real: %e" /usr/bin/make "$@"
  local ret=$?
  if [ $ret -eq 0 ]; then
    ${_APLAY} "$_ALEEPER_CONFIG_DIR/sounds/scifi002-trim.wav" 2>/dev/null &
  else
    ${_APLAY} "$_ALEEPER_CONFIG_DIR/sounds/banana-peel.wav" 2>/dev/null &
  fi
  return $ret
}

# ── Utilities ─────────────────────────────────────────────────────────────────

whichshell() {
  if [ -n "$ZSH_VERSION" ]; then
    echo "zsh $ZSH_VERSION"
  elif [ -n "$BASH_VERSION" ]; then
    echo "bash $BASH_VERSION"
  else
    echo "unknown ($SHELL)"
  fi
}

# Serve current directory over HTTP
serve() { python3 -m http.server "${1:-8000}"; }

# Open gitk in background
gkl() { (gitk --all "$@" &); }

# Backup a file (foo → foo.bak)
backup() { cp "$1" "$1.bak"; }

# Print resolved full path(s)
pfp() { for i in "$@"; do readlink -e "$(pwd)/$i"; done; }

# ── Worktree navigation ───────────────────────────────────────────────────────

# Fuzzy cd to a project worktree under $PROJ_ROOT/projects/<project>/<name>
# Depends on: fzf, fd (or fdfind on Ubuntu)
pcdf() {
  local fd_cmd
  fd_cmd=$(command -v fdfind || command -v fd) || { echo "fd not found"; return 1; }
  local dest
  dest=$(
    "$fd_cmd" --min-depth 2 --max-depth 2 --type d --exclude '.*' \
      . "$PROJ_ROOT/projects" \
      | sed "s|$PROJ_ROOT/projects/||" \
      | fzf -1 -0 -q "${1:-}"
  ) || return
  cd "$PROJ_ROOT/projects/$dest"
}

# Create a git worktree as a sibling of the current repo directory.
# Branch: $USER/<name>   Worktree: ../<name>
# Usage: wtnew <name>
wtnew() {
  local name="${1:?Usage: wtnew <name>}"
  local dest
  dest="$(git rev-parse --show-toplevel 2>/dev/null)/../${name}"
  git worktree add "$dest" -b "${USER:-adam}/${name}" && \
    echo "Worktree: $(realpath "$dest")"
}
