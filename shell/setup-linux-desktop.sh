#!/usr/bin/env bash
# Install Alacritty's launcher or switch GNOME's terminal shortcut.
set -euo pipefail

python3 - "$@" <<'PY'
import ast
import os
from pathlib import Path
import subprocess
import sys

mode = sys.argv[1] if len(sys.argv) == 2 else 'install'
if len(sys.argv) > 2 or mode not in ('install', 'alacritty', 'default'):
    raise SystemExit('Usage: setup-linux-desktop.sh [alacritty|default]')

home = Path.home()
binary = home / '.cargo/bin/alacritty'
if mode != 'default' and not os.access(binary, os.X_OK):
    raise SystemExit(f'Alacritty executable not found: {binary}')

# Desktop Exec values have their own quoting rules, not shell quoting.
executable = str(binary).replace('%', '%%')
for char in ('\\', '"', '$', '`'):
    executable = executable.replace(char, '\\' + char)
command = f'"{executable}"'

if mode == 'install':
    data_home = Path(os.environ.get('XDG_DATA_HOME') or home / '.local/share')
    launcher = data_home / 'applications/Alacritty.desktop'
    launcher.parent.mkdir(parents=True, exist_ok=True)
    marker = '# Managed by aleeper-config\n'
    if launcher.exists() and not launcher.read_text().startswith(marker):
        print(f'  Leaving existing application launcher unchanged: {launcher}')
    else:
        launcher.write_text(marker + '[Desktop Entry]\nType=Application\nName=Alacritty\n'
                            f'Exec={command}\nIcon=utilities-terminal\nTerminal=false\n'
                            'Categories=System;TerminalEmulator;\n')
        print(f'  Installed application launcher: {launcher}')

if 'gnome' not in os.environ.get('XDG_CURRENT_DESKTOP', '').lower().split(':'):
    if mode == 'install':
        print('  Not a GNOME session; skipping keyboard shortcut.')
        raise SystemExit(0)
    raise SystemExit('Terminal shortcut switching requires a GNOME session.')

base = 'org.gnome.settings-daemon.plugins.media-keys'
prefix = '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/'


def get(schema, key):
    value = subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()
    return ast.literal_eval(value.removeprefix('@as '))


def set_value(schema, key, value):
    subprocess.run(['gsettings', 'set', schema, key, value], check=True)


paths = get(base, 'custom-keybindings')
selected = None
conflict = False
for path in paths:
    schema = f'{base}.custom-keybinding:{path}'
    if get(schema, 'name') == 'Alacritty' and selected is None:
        selected = path
    elif get(schema, 'binding').lower() in ('<primary><alt>t', '<control><alt>t'):
        conflict = True

if mode == 'default':
    if selected:
        set_value(f'{base}.custom-keybinding:{selected}', 'binding', '')
    subprocess.run(['gsettings', 'reset', base, 'terminal'], check=True)
    raise SystemExit(0)

if conflict:
    raise SystemExit('Ctrl+Alt+T is already used by another custom shortcut; remove that binding first.')

if selected is None:
    index = 0
    while f'{prefix}custom{index}/' in paths:
        index += 1
    selected = f'{prefix}custom{index}/'
    paths.append(selected)
    set_value(base, 'custom-keybindings', repr(paths))

schema = f'{base}.custom-keybinding:{selected}'
set_value(schema, 'name', 'Alacritty')
set_value(schema, 'command', repr(command))
terminal_bindings = get(base, 'terminal')
remaining = [binding for binding in terminal_bindings
             if binding.lower() not in ('<primary><alt>t', '<control><alt>t')]
if remaining != terminal_bindings:
    set_value(base, 'terminal', repr(remaining))
set_value(schema, 'binding', '<Primary><Alt>t')
if mode == 'install':
    print('  Ctrl+Alt+T → Alacritty')
PY
