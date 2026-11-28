# tmux-config

[Leer en español](README.es.md)

A tmux configuration and its helper scripts, versioned and installed through symlinks. Status bar with system metrics (CPU, RAM, disk), git branch and status, an fzf session picker, and session persistence across reboots.

## Contents

| Path | What it is |
| --- | --- |
| `tmux.conf` | The full configuration (linked as `~/.tmux.conf`). |
| `bin/tmux-sysstat` | Status bar segment: CPU, RAM and disk, colored by load. |
| `bin/tmux-git` | Status bar segment: branch and git status of the pane's path. |
| `bin/tmux-switch` | fzf session picker in a popup (`prefix s` / `prefix f`). |
| `bin/tmux-working` | Status bar segment: pink `●` on a window whose agent is working (Claude Code, opencode, pi or freebuff). |
| `install.sh` | Creates the links, clones the persistence plugins and enables the systemd user service. |
| `systemd/tmux.service` | User service that starts the tmux server at login and restores the saved sessions. |
| `tests/test.sh` | Tests that do not touch your real configuration. |

## Requirements

- tmux 3.4 or newer (tested on 3.6).
- A Nerd Font in your terminal emulator (the status bar icons).
- `fzf` for the session picker.
- `git` for the status bar and to clone the plugins.

## Installation

```bash
./install.sh
```

Links `~/.tmux.conf` and the scripts in `bin/` into `~/.local/bin/` (which must be in your `PATH`). If a real file was already there, it is kept as `<target>.bak-<date>`. With `--no-plugins` the plugins are not cloned. Inside tmux, reload with `prefix r`.

## Usage

Custom keys (the prefix is the default one, `Ctrl-b`):

| Key | Action |
| --- | --- |
| `prefix s` / `prefix f` | fzf session picker with preview. |
| `prefix S` | Classic session tree. |
| `prefix w` | Window tree. |
| `prefix r` | Reload the configuration. |

`prefix c`, `prefix %` and `prefix "` keep their meaning, but now open the window or pane in the current pane's path.

## Persistence

`tmux-resurrect` and `tmux-continuum` (versions pinned in `install.sh`) save your sessions every 15 minutes and restore them when the tmux server starts. Sessions, windows, panes and paths come back. **Processes do not come back**, except the agents: `claude` and `freebuff` are relaunched with `--continue` in the pane's path, so they pick up their last conversation. Anything else that was running has to be started again.

`install.sh` enables a systemd user service (`tmux.service`) that starts the server when you log in and restores the sessions, so you never have to start tmux by hand first. Stopping the service saves the state and then closes the server. Where there is no user systemd the install skips this step and prints a notice; enable the service by hand then.

## Versioning

Releases are cut with `make release`: the version in `VERSION` and the `CHANGELOG.md` come from the commit types (Conventional Commits).

## Tests

```bash
tests/test.sh
```

It checks the scripts' syntax, that the configuration loads without errors and sets the expected options, that `install.sh` links, backs up and is idempotent, and that the status bar segments print what they should. It also runs `shellcheck` if it is installed.

## Architecture

It is all configuration and bash. The status bar segments print tmux `#[...]` styles and are called with `#()` every `status-interval`; `tmux-sysstat` keeps the previous `/proc/stat` reading in `XDG_RUNTIME_DIR` to compute CPU as a delta. The plugins are loaded with `run-shell` from `~/.tmux/plugins`.

## License

[MIT](LICENSE)
