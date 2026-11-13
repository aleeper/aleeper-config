#!/usr/bin/env python3
"""Integration tests against an isolated GNOME settings database."""
import ast
import os
import pathlib
import shlex
import shutil
import subprocess
import tempfile
import unittest

REPO = pathlib.Path(__file__).resolve().parents[1]


def has_gnome_test_dependencies():
    if not shutil.which('dbus-run-session') or not shutil.which('gsettings'):
        return False
    result = subprocess.run(['gsettings', 'list-schemas'], text=True, capture_output=True)
    return result.returncode == 0 and {
        'org.gnome.desktop.input-sources',
        'org.gnome.settings-daemon.plugins.media-keys',
    }.issubset(result.stdout.splitlines())


@unittest.skipUnless(has_gnome_test_dependencies(), 'GNOME settings and D-Bus are required')
class LinuxDesktopTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='desktop test ')
        self.addCleanup(self.temp.cleanup)
        self.home = pathlib.Path(self.temp.name)
        (self.home / '.config').mkdir()
        (self.home / '.local' / 'share').mkdir(parents=True)
        (self.home / 'aleeper-config').symlink_to(REPO)
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_DATA_HOME=str(self.home / '.local' / 'share'),
                        XDG_RUNTIME_DIR=str(self.home), XDG_SESSION_TYPE='wayland',
                        XDG_CURRENT_DESKTOP='ubuntu:GNOME', DISPLAY='')

    def run_session(self, script):
        return subprocess.run(['dbus-run-session', '--', 'bash', '-e', '-c', script],
                              env=self.env, text=True, capture_output=True)

    @unittest.skipUnless(shutil.which('zsh'), 'zsh is required')
    def test_keyboard_aliases_work_in_zsh(self):
        result = subprocess.run(['dbus-run-session', '--', 'zsh', '-c', f'''
            gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
            source "{REPO}/shell/aliases.sh"
            pc-kbd
            mac-kbd
            gsettings get org.gnome.desktop.input-sources xkb-options
        '''], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("'caps:escape'", result.stdout)
        self.assertIn("'ctrl:swap_lwin_lctl'", result.stdout)
        self.assertFalse((self.home / '.config/pc-keyboard').exists())

    def test_keyboard_switching_on_x11_uses_setxkbmap(self):
        bin_dir = self.home / 'bin'
        bin_dir.mkdir()
        command = bin_dir / 'setxkbmap'
        command.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$HOME/xkb-log"\n')
        command.chmod(0o755)
        self.env.update(PATH=f'{bin_dir}:/usr/bin:/bin', XDG_SESSION_TYPE='x11',
                        XDG_CURRENT_DESKTOP='XFCE', DISPLAY=':1')
        result = self.run_session(f'''
            shopt -s expand_aliases
            . "{REPO}/shell/aliases.sh"
            pc-kbd
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home / 'xkb-log').read_text().splitlines(),
                         ['-option ctrl:swap_lwin_lctl', '-option '])
        self.assertTrue((self.home / '.config/pc-keyboard').exists())

    def test_mac_keyboard_on_wayland_preserves_other_options(self):
        result = self.run_session(f'''
            touch "$HOME/.config/pc-keyboard"
            gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"
            shopt -s expand_aliases
            . "{REPO}/shell/aliases.sh"
            mac-kbd
            gsettings get org.gnome.desktop.input-sources xkb-options
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("'caps:escape'", result.stdout)
        self.assertIn("'ctrl:swap_lwin_lctl'", result.stdout)
        self.assertFalse((self.home / '.config' / 'pc-keyboard').exists())

    def test_pc_keyboard_on_wayland_preserves_other_options(self):
        result = self.run_session(f'''
            gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape', 'ctrl:swap_lwin_lctl']"
            shopt -s expand_aliases
            . "{REPO}/shell/aliases.sh"
            pc-kbd
            gsettings get org.gnome.desktop.input-sources xkb-options
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("'caps:escape'", result.stdout)
        self.assertNotIn("'ctrl:swap_lwin_lctl'", result.stdout)
        self.assertTrue((self.home / '.config' / 'pc-keyboard').exists())

    def test_desktop_install_registers_launcher_and_resolvable_shortcut(self):
        executable = self.home / '.cargo' / 'bin' / 'alacritty'
        executable.parent.mkdir(parents=True)
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)
        result = self.run_session(f'''
            bash "{REPO}/shell/setup-linux-desktop.sh"
            gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(executable), result.stdout)
        command = ast.literal_eval(result.stdout.strip().splitlines()[-1])
        self.assertEqual(shlex.split(command), [str(executable)])
        desktop = self.home / '.local/share/applications/Alacritty.desktop'
        self.assertTrue(desktop.exists())
        self.assertIn(str(executable), desktop.read_text())

    def test_terminal_toggles_target_alacritty_not_an_existing_shortcut(self):
        executable = self.home / '.cargo/bin/alacritty'
        executable.parent.mkdir(parents=True)
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)
        result = self.run_session(f'''
            base=org.gnome.settings-daemon.plugins.media-keys
            prefix=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
            other="$base.custom-keybinding:$prefix/custom0/"
            alacritty="$base.custom-keybinding:$prefix/custom1/"
            gsettings set "$base" custom-keybindings "['$prefix/custom0/']"
            gsettings set "$other" name 'Other'
            gsettings set "$other" binding '<Super>k'
            bash "{REPO}/shell/setup-linux-desktop.sh"
            shopt -s expand_aliases
            . "{REPO}/shell/aliases.sh"
            default-term
            gsettings get "$alacritty" binding
            gsettings get "$base" terminal
            alacritty-term
            gsettings get "$alacritty" binding
            gsettings get "$base" terminal
            gsettings get "$other" binding
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        before, restored, after, disabled, other = result.stdout.strip().splitlines()[-5:]
        self.assertEqual(ast.literal_eval(before), '')
        self.assertIn('<primary><alt>t', [s.lower() for s in ast.literal_eval(restored)])
        self.assertEqual(ast.literal_eval(after), '<Primary><Alt>t')
        self.assertNotIn('<primary><alt>t',
                         [s.lower() for s in ast.literal_eval(disabled.removeprefix('@as '))])
        self.assertEqual(ast.literal_eval(other), '<Super>k')

    def test_installer_reports_conflicting_custom_shortcut(self):
        executable = self.home / '.cargo/bin/alacritty'
        executable.parent.mkdir(parents=True)
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)
        result = self.run_session(f'''
            base=org.gnome.settings-daemon.plugins.media-keys
            path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
            schema="$base.custom-keybinding:$path"
            gsettings set "$base" custom-keybindings "['$path']"
            gsettings set "$schema" name 'Other'
            gsettings set "$schema" binding '<Primary><Alt>t'
            if bash "{REPO}/shell/setup-linux-desktop.sh"; then
                printf 'unexpected-success\\n'
            else
                printf 'conflict-reported\\n'
            fi
            gsettings get "$base" custom-keybindings
            gsettings get "$schema" binding
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        status, paths, binding = result.stdout.strip().splitlines()[-3:]
        self.assertEqual(status, 'conflict-reported')
        self.assertEqual(len(ast.literal_eval(paths)), 1)
        self.assertEqual(ast.literal_eval(binding), '<Primary><Alt>t')

    def test_desktop_install_preserves_existing_shortcuts_and_is_idempotent(self):
        executable = self.home / '.cargo/bin/alacritty'
        executable.parent.mkdir(parents=True)
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)
        result = self.run_session(f'''
            base=org.gnome.settings-daemon.plugins.media-keys
            path=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
            schema="$base.custom-keybinding:$path"
            gsettings set "$base" custom-keybindings "['$path']"
            gsettings set "$schema" name 'Other'
            gsettings set "$schema" binding '<Super>k'
            bash "{REPO}/shell/setup-linux-desktop.sh"
            bash "{REPO}/shell/setup-linux-desktop.sh"
            gsettings get "$base" custom-keybindings
            gsettings get "$schema" name
            gsettings get "$schema" binding
        ''')
        self.assertEqual(result.returncode, 0, result.stderr)
        paths, name, binding = result.stdout.strip().splitlines()[-3:]
        self.assertEqual(len(ast.literal_eval(paths)), 2)
        self.assertEqual(ast.literal_eval(name), 'Other')
        self.assertEqual(ast.literal_eval(binding), '<Super>k')


if __name__ == '__main__':
    unittest.main()
