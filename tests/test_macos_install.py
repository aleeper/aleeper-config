#!/usr/bin/env python3
"""Exercise the macOS installer branch without installing system packages."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class MacOSInstallTests(unittest.TestCase):
    def test_mac_keyboard_command_does_not_change_xquartz_keymap(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            bin_dir = home / 'bin'
            bin_dir.mkdir()
            for name, body in {
                'uname': "printf 'Darwin\\n'\n",
                'setxkbmap': 'touch "$HOME/changed-xquartz"\n',
            }.items():
                path = bin_dir / name
                path.write_text('#!/bin/sh\n' + body)
                path.chmod(0o755)
            env = os.environ.copy()
            env.update(HOME=str(home), PATH=f'{bin_dir}:/usr/bin:/bin', DISPLAY=':0',
                       XDG_SESSION_TYPE='', XDG_CURRENT_DESKTOP='')
            result = subprocess.run(['bash', '-c', f'. "{REPO}/shell/aliases.sh"; _keyboard_set mac'],
                                    env=env, text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((home / 'changed-xquartz').exists())

    def test_macos_uses_homebrew_and_skips_linux_desktop_setup(self):
        with tempfile.TemporaryDirectory(prefix='mac install ') as tmp:
            root = Path(tmp)
            repo = root / 'repo'
            repo.mkdir()
            shutil.copyfile(REPO / 'install.sh', repo / 'install.sh')
            (repo / 'shell').mkdir()
            (repo / 'shell/setup-linux-desktop.sh').write_text('exit 99\n')
            home = root / 'home'
            for directory in ('Library/Fonts', '.config/zsh/plugins/powerlevel10k',
                              '.personal-plugins/github-theme-contrib', '.tmux/plugins/tpm'):
                (home / directory).mkdir(parents=True)
            (home / 'Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf').touch()
            bin_dir = root / 'bin'
            bin_dir.mkdir()
            scripts = {
                'uname': "printf 'Darwin\\n'\n",
                'brew': 'printf "%s\\n" "$*" >> "$BREW_LOG"\n',
                'dscl': 'printf "UserShell: %s\\n" "$CURRENT_SHELL"\n',
            }
            for name, body in scripts.items():
                path = bin_dir / name
                path.write_text('#!/bin/sh\n' + body)
                path.chmod(0o755)
            env = os.environ.copy()
            env.update(HOME=str(home), PATH=f'{bin_dir}:/usr/bin:/bin', USER='testuser',
                       BREW_LOG=str(root / 'brew.log'), CURRENT_SHELL='/usr/bin/zsh')
            result = subprocess.run(['bash', str(repo / 'install.sh')], env=env,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('install --cask alacritty', (root / 'brew.log').read_text())
            self.assertEqual(os.readlink(home / '.config/alacritty/platform.toml'),
                             str(repo / 'alacritty/macos.toml'))
            self.assertNotIn('Alacritty desktop integration', result.stdout)


if __name__ == '__main__':
    unittest.main()
