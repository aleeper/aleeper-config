aleeper-config
==============

bash and other setup scripts

## Claude Code status line

`./install.sh` installs the shared status-line script on macOS and Linux, and merges its command into
`~/.claude/settings.json` without replacing other settings. It saves any existing status-line script as
`~/.claude/statusline-command.sh.bak` (or a numbered backup if that name already exists). Re-running
installation keeps the link and settings in place. Python 3 is installed with the other dependencies.

The status line shows context usage and session, daily and monthly costs; the local cost totals live in
`~/.claude/cost-tracking/`.