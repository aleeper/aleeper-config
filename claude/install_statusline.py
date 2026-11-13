#!/usr/bin/env python3
"""Install the shared Claude Code status line without replacing other settings."""
import json
import os
from pathlib import Path
import shlex
import stat
import sys
import tempfile


def install():
    source = Path(__file__).resolve().parent / 'statusline-command.sh'
    if not source.is_file():
        raise ValueError(f'missing status-line script: {source}')

    claude_dir = Path.home() / '.claude'
    settings_link = claude_dir / 'settings.json'
    if settings_link.is_symlink() and not settings_link.exists():
        raise ValueError(f'{settings_link}: broken settings symlink')
    settings_path = settings_link.resolve()
    if settings_path.exists():
        try:
            with settings_path.open(encoding='utf-8') as stream:
                settings = json.load(stream)
        except json.JSONDecodeError as exc:
            raise ValueError(f'{settings_link}: invalid JSON ({exc})') from exc
        if not isinstance(settings, dict):
            raise ValueError(f'{settings_link}: settings must be a JSON object')
        mode = stat.S_IMODE(settings_path.stat().st_mode)
    else:
        settings = {}
        mode = 0o600

    target = claude_dir / 'statusline-command.sh'
    previous = settings.get('statusLine')
    statusline = dict(previous) if isinstance(previous, dict) else {}
    statusline.update(type='command', command=f'bash {shlex.quote(str(target))}')
    needs_settings_write = settings.get('statusLine') != statusline
    settings['statusLine'] = statusline

    claude_dir.mkdir(parents=True, exist_ok=True)
    if not (target.is_symlink() and target.resolve() == source):
        if os.path.lexists(target):
            backup = target.with_name(target.name + '.bak')
            n = 1
            while os.path.lexists(backup):
                backup = target.with_name(target.name + f'.bak.{n}')
                n += 1
            target.rename(backup)
            print(f'  Backed up status line: {backup}')
        target.symlink_to(source)
        print(f'  Linked status line: {target} -> {source}')
    else:
        print(f'  Status line already linked: {target}')

    if needs_settings_write:
        fd, temporary = tempfile.mkstemp(prefix='.settings-', dir=settings_path.parent)
        try:
            with os.fdopen(fd, 'w', encoding='utf-8') as stream:
                json.dump(settings, stream, indent=2, ensure_ascii=False)
                stream.write('\n')
            os.chmod(temporary, mode)
            os.replace(temporary, settings_path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        print(f'  Configured status line in: {settings_link}')
    else:
        print(f'  Status line already configured in: {settings_link}')


if __name__ == '__main__':
    try:
        install()
    except (OSError, ValueError) as exc:
        print(f'Cannot configure Claude status line: {exc}', file=sys.stderr)
        sys.exit(1)
