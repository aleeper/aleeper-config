#!/usr/bin/env sh
# Personal (non-secret) environment variables and PATH additions.
# Machine/work-specific vars belong in ~/.shell.d/ (not in repo).

export ALEEPER_CONFIG_DIR="$HOME/aleeper-config"

# Root for git project/worktree collections.
# Override in ~/.shell.d/ for machine-specific paths (e.g. /media/drive2).
export PROJ_ROOT="${PROJ_ROOT:-$HOME/projects}"

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$ALEEPER_CONFIG_DIR/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
