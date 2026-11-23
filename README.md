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
| `install.sh` | Creates the links and clones the persistence plugins. |
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

`tmux-resurrect` and `tmux-continuum` (versions pinned in `install.sh`) save your sessions every 15 minutes and restore them when the tmux server starts. Sessions, windows, panes and paths come back. **Processes do not**: an agent or a server that was running has to be started again.

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
