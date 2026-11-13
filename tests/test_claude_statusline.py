#!/usr/bin/env python3
"""Exercise Claude status-line setup without modifying the real home directory."""
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
INSTALLER = REPO / 'claude' / 'install_statusline.py'
SOURCE = REPO / 'claude' / 'statusline-command.sh'


class ClaudeStatusLineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="claude home's ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.claude = self.home / '.claude'
        self.settings = self.claude / 'settings.json'
        self.statusline = self.claude / 'statusline-command.sh'
        self.env = os.environ.copy()
        self.env['HOME'] = str(self.home)

    def install(self):
        return subprocess.run(['python3', str(INSTALLER)], env=self.env,
                              text=True, capture_output=True)

    def test_fresh_install_creates_private_settings_and_working_status_line(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.statusline.is_symlink())
        self.assertEqual(self.statusline.resolve(), SOURCE)
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o600)
        settings = json.loads(self.settings.read_text())
        self.assertEqual(settings['statusLine']['type'], 'command')
        command = shlex.split(settings['statusLine']['command'])
        self.assertEqual(command, ['bash', str(self.statusline)])
        status = subprocess.run(command, env=self.env, text=True, capture_output=True,
                                input=json.dumps({'context_window': {'used_percentage': 53}}))
        self.assertEqual(status.returncode, 0, status.stderr)
        self.assertEqual(status.stderr, '')
        self.assertIn('ctx 53%', status.stdout)
        self.assertIn('session', status.stdout)

    def test_existing_settings_and_backups_survive_repeated_installs(self):
        self.claude.mkdir()
        existing = {'env': {'PERSONAL_SETTING': 'keep'}, 'statusLine': {
            'type': 'command', 'command': 'old command', 'padding': 3}}
        self.settings.write_text(json.dumps(existing))
        self.settings.chmod(0o640)
        self.statusline.write_text('my previous script\n')
        prior_backup = self.claude / 'statusline-command.sh.bak'
        prior_backup.write_text('older backup\n')
        for _ in range(2):
            result = self.install()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        settings = json.loads(self.settings.read_text())
        self.assertEqual(settings['env'], existing['env'])
        self.assertEqual(settings['statusLine']['padding'], 3)
        self.assertEqual(shlex.split(settings['statusLine']['command']),
                         ['bash', str(self.statusline)])
        self.assertEqual(self.settings.stat().st_mode & 0o777, 0o640)
        self.assertEqual(prior_backup.read_text(), 'older backup\n')
        self.assertEqual((self.claude / 'statusline-command.sh.bak.1').read_text(),
                         'my previous script\n')
        self.assertFalse((self.claude / 'statusline-command.sh.bak.2').exists())

    def test_invalid_settings_fail_without_touching_files(self):
        for bad in ('not json', '[]'):
            with self.subTest(bad=bad):
                self.claude.mkdir(exist_ok=True)
                self.settings.write_text(bad)
                self.statusline.write_text('my original script\n')
                result = self.install()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('settings.json', result.stderr)
                self.assertEqual(self.settings.read_text(), bad)
                self.assertEqual(self.statusline.read_text(), 'my original script\n')
                self.assertFalse((self.claude / 'statusline-command.sh.bak').exists())

    def test_symlinked_settings_remain_a_symlink(self):
        self.claude.mkdir()
        target = self.home / 'custom-settings.json'
        target.write_text('{"other": true}')
        self.settings.symlink_to(target)
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.settings.is_symlink())
        self.assertTrue(json.loads(target.read_text())['other'])
        self.assertIn('statusLine', json.loads(target.read_text()))

    def test_status_line_handles_missing_context_data(self):
        result = subprocess.run(['bash', str(SOURCE)], env=self.env, text=True,
                                capture_output=True, input='{}')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        self.assertNotIn('ctx ', result.stdout)
        self.assertIn('session', result.stdout)


class LinuxInstallTests(unittest.TestCase):
    def test_linux_installer_sets_up_claude_without_running_system_commands(self):
        with tempfile.TemporaryDirectory(prefix='linux install ') as tmp:
            root = Path(tmp)
            repo = root / 'repo'
            repo.mkdir()
            shutil.copyfile(REPO / 'install.sh', repo / 'install.sh')
            shutil.copytree(REPO / 'claude', repo / 'claude', ignore=shutil.ignore_patterns('__pycache__'))
            (repo / 'shell').mkdir()
            (repo / 'shell/setup-linux-desktop.sh').write_text('exit 0\n')
            home = root / 'home'
            for directory in ('.local/share/fonts', '.config/zsh/plugins/powerlevel10k',
                              '.personal-plugins/github-theme-contrib', '.tmux/plugins/tpm',
                              '.cargo/bin'):
                (home / directory).mkdir(parents=True)
            (home / '.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf').touch()
            (home / '.cargo/env').write_text('# test environment\n')
            alacritty = home / '.cargo/bin/alacritty'
            alacritty.write_text('#!/bin/sh\nprintf "alacritty test\\n"\n')
            alacritty.chmod(0o755)
            bin_dir = root / 'bin'
            bin_dir.mkdir()
            for name, body in {
                'uname': "printf 'Linux\\n'\n",
                'sudo': 'printf "%s\\n" "$*" >> "$HOME/sudo.log"\n',
                'cargo': "printf 'cargo test\\n'\n",
                'git-branchless': "printf 'git-branchless test\\n'\n",
                'nvim': "printf 'NVIM v0.11.0\\n'\n",
                'zsh': 'exit 0\n',
                'getent': 'printf "test:x:1:1::%s:%s\\n" "$HOME" "$(command -v zsh)"\n',
            }.items():
                path = bin_dir / name
                path.write_text('#!/bin/sh\n' + body)
                path.chmod(0o755)
            env = os.environ.copy()
            env.update(HOME=str(home), PATH=f'{bin_dir}:/usr/bin:/bin', USER='testuser')
            result = subprocess.run(['bash', str(repo / 'install.sh')], env=env,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('python3', (home / 'sudo.log').read_text())
            installed = home / '.claude/statusline-command.sh'
            self.assertTrue(installed.is_symlink())
            self.assertEqual(installed.resolve(), repo / 'claude/statusline-command.sh')
            self.assertTrue((home / '.claude/settings.json').is_file())


if __name__ == '__main__':
    unittest.main()
