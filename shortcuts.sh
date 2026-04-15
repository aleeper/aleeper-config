#!/usr/bin/env sh
# Backward-compatibility shim — sourced by the old ~/.bashrc entry.
# After running install.sh and switching to zsh, this file is no longer needed.
# New canonical locations: shell/aliases.sh, shell/functions.sh, shell/env.sh

_cfg="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

source "$_cfg/shell/env.sh"
source "$_cfg/shell/aliases.sh"
source "$_cfg/shell/functions.sh"
