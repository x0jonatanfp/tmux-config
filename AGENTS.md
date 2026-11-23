# AGENTS.md

tmux configuration (`tmux.conf`), its scripts (`bin/`) and the symlink installer (`install.sh`). Public repo. Docs are bilingual: `README.md` (English) and `README.es.md` (Spanish) must stay equivalent; code comments are in Spanish and explain the why.

## Commands

- Install: `./install.sh` (or `./install.sh --no-plugins`).
- Test: `tests/test.sh`. It uses a temporary `HOME` and an isolated tmux server (`-L`); it never touches the real configuration.
- Release: `make release` (needs a clean tree). The version lives in `VERSION` and is computed from the commit types by `commit-and-tag-version`; never edit it by hand.
- Reload in a live session: `tmux source-file ~/.tmux.conf` (or `prefix r`).

## Conventions

- Scripts are bash with `set -u`/`pipefail`, with no hardcoded paths or user names (no `/home/<user>`).
- `~/.tmux.conf` and `~/.local/bin/tmux-*` are **links** to this repo. Edit here, never the target.
- Plugins are pinned to a version in `install.sh` (`RESURRECT_REF`, `CONTINUUM_REF`). To update, change the version and rerun the install on a clean machine.
- A behavior change comes with its case in `tests/test.sh` and updates both READMEs in the same change.
- Nothing private in the repo: no real paths, user names, hosts, IPs or secrets. Run `gitleaks dir . --redact --no-banner` before pushing.

## Gotchas

- The bar uses `#rrggbb` colors: they depend on `terminal-features ",xterm-256color:RGB"`. If the emulator's `TERM` changes, adjust that pattern.
- Each window's icon is chosen by **name** (`claude*`, `*vim*`, `ssh*`): if something renames windows, the icon is lost.
- `monitor-activity` is on because the bar's `●` dot depends on it.
- Persistence restores layout and paths, plus only the processes listed in `@resurrect-processes` (`claude` and `freebuff`, relaunched with `--continue`); the panes' `sudo su` is deliberately not restored. Resurrect only relaunches a pane if its index exists, so the `base-index`/`pane-base-index` settings must match the saved layout. With `@continuum-restore on` it only restores when the server starts, which `systemd/tmux.service` (user unit, enabled by `install.sh`) does at login; there is no lingering, so it does not start before the first login. The plugins' `run-shell` lines must not use `-b`: loaded in the background, continuum sees the session that `new -s` already created, assumes the server is not new and skips the restore.
- `bind c`, `%` and `"` are redefined with `-c "#{pane_current_path}"`; any other `split-window` or `new-window` binding must carry it too.
- `VERSION` has no trailing newline on purpose: `commit-and-tag-version` reads it raw and a newline ends up in the tag name, which git rejects. Don't let an editor add one.
