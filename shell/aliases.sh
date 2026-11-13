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
# tmn [name] — new session; auto-numbered if no name given
unalias tmn 2>/dev/null || :
tmn() { if [ $# -gt 0 ]; then tmux new -s "$@"; else tmux new; fi; }

# Editor / shell reload
alias editsh='${VISUAL:-${EDITOR:-vim}} ~/.zshrc'
alias resh='source ~/.zshrc'
alias editbash='${VISUAL:-${EDITOR:-vim}} ~/.bashrc'
alias rebash='source ~/.bashrc'

# Swap left Windows key and left Ctrl (Mac-style keyboard on Linux).
# GNOME owns the keymap on Wayland; setxkbmap only affects Xwayland there.
_keyboard_apply() {
  if [ "$(uname -s)" = Darwin ]; then
    printf '%s\n' 'Keyboard switching is for Linux; use macOS keyboard settings instead.' >&2
    return 1
  fi
  case ":${XDG_CURRENT_DESKTOP:-}:" in
    *:GNOME:*|*:gnome:*)
      _keyboard_options=$(gsettings get org.gnome.desktop.input-sources xkb-options) || return
      _keyboard_options=$(python3 -c '
import ast, sys
options = ast.literal_eval(sys.argv[1].removeprefix("@as "))
options = [option for option in options if option != "ctrl:swap_lwin_lctl"]
if sys.argv[2] == "mac":
    options.append("ctrl:swap_lwin_lctl")
print(options)
' "$_keyboard_options" "$1") || return
      gsettings set org.gnome.desktop.input-sources xkb-options "$_keyboard_options"
      ;;
    *)
      if [ "${XDG_SESSION_TYPE:-}" = wayland ]; then
        printf '%s\n' 'Keyboard switching on Wayland requires GNOME.' >&2
        return 1
      fi
      if [ -z "${DISPLAY:-}" ]; then
        printf '%s\n' 'No graphical session available for keyboard switching.' >&2
        return 1
      fi
      if [ "$1" = mac ]; then
        setxkbmap -option ctrl:swap_lwin_lctl
      else
        setxkbmap -option ""
      fi
      ;;
  esac
}

_keyboard_set() {
  _keyboard_apply "$1" || return
  mkdir -p "$HOME/.config"
  if [ "$1" = mac ]; then
    rm -f "$HOME/.config/pc-keyboard"
  else
    touch "$HOME/.config/pc-keyboard"
  fi
}

if [ -f "$HOME/.config/pc-keyboard" ]; then
  _keyboard_apply pc >/dev/null 2>&1 || :
else
  _keyboard_apply mac >/dev/null 2>&1 || :
fi
alias mac-kbd='_keyboard_set mac'
alias pc-kbd='_keyboard_set pc'

# Ctrl+Alt+T terminal (GNOME). Persists across logins via dconf.
# `alacritty-term` → Alacritty; `default-term` → stock GNOME Terminal.
if command -v gsettings >/dev/null 2>&1; then
  alias alacritty-term='bash "$HOME/aleeper-config/shell/setup-linux-desktop.sh" alacritty'
  alias default-term='bash "$HOME/aleeper-config/shell/setup-linux-desktop.sh" default'
fi

# Login shell (prompts for password; applies to new terminal windows).
# Affects GNOME Terminal and SSH only — Alacritty and tmux are pinned to zsh.
alias zsh-shell='chsh -s "$(command -v zsh)" && echo "Login shell → zsh (new terminals)"'
alias bash-shell='chsh -s "$(command -v bash)" && echo "Login shell → bash (new terminals)"'

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

# bat (Ubuntu installs as 'batcat' due to naming conflict)
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi

# ncdu → du (interactive disk usage)
# (no alias needed — ncdu is its own command)

# rg is already on PATH — no alias, just use it directly
# fd/fdfind is already on PATH — used in pcdf/wtnew
