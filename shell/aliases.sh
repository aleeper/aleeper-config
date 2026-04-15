#!/usr/bin/env sh
# Personal shell aliases — sourced by both bash and zsh

# Directory navigation
alias kk='cd -'
alias up='cd ..'
alias upp='cd ../..'
alias uppp='cd ../../..'
alias upppp='cd ../../../..'
alias uppppp='cd ../../../../..'
alias lsdir='for i in $(ls -d */); do echo ${i%%/}; done'

# tmux shortcuts
alias tmls='tmux ls'
alias tma='tmux attach -t'
alias tmr='tmux rename-session -t'
alias tmn='tmux new -s'

# Editor / shell reload
alias editsh='${VISUAL:-${EDITOR:-vim}} ~/.zshrc'
alias resh='source ~/.zshrc'
alias editbash='${VISUAL:-${EDITOR:-vim}} ~/.bashrc'
alias rebash='source ~/.bashrc'

# Swap left Windows key and left Ctrl (personal keyboard preference)
[ -n "$DISPLAY" ] && setxkbmap -option ctrl:swap_lwin_lctl 2>/dev/null

# ── Modern tool replacements (fall back gracefully if not installed) ───────────

# eza → ls (keep ll/la/l consistent)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -alh'
  alias la='eza -a'
  alias l='eza'
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi

# bat → cat (Ubuntu installs as 'batcat')
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
fi

# ncdu → du (interactive disk usage)
# (no alias needed — ncdu is its own command)

# rg is already on PATH — no alias, just use it directly
# fd/fdfind is already on PATH — used in pcdf/wtnew
