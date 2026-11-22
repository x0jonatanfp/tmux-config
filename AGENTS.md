# AGENTS.md

Configuración de tmux (`tmux.conf`), sus scripts (`bin/`) y el instalador por enlaces simbólicos (`install.sh`). Repo privado, en español.

## Comandos

- Instalar: `./install.sh` (o `./install.sh --no-plugins`).
- Probar: `tests/test.sh`. Usa un `HOME` temporal y un servidor tmux aislado (`-L`); no toca la configuración real.
- Recargar en una sesión viva: `tmux source-file ~/.tmux.conf` (o `prefix r`).

## Convenciones

- Los scripts son bash con `set -u`/`pipefail`, comentarios en español que explican el porqué y sin rutas ni nombres de usuario fijos (nada de `/home/<usuario>`).
- `~/.tmux.conf` y los scripts de `~/.local/bin/tmux-*` son **enlaces** a este repo. Se edita aquí, nunca el destino.
- Los plugins van fijados a una versión en `install.sh` (`RESURRECT_REF`, `CONTINUUM_REF`). Para actualizar, cambia la versión y vuelve a ejecutar la instalación en una máquina limpia.
- Un cambio de comportamiento lleva su caso en `tests/test.sh` y actualiza el README en el mismo cambio.

## Trampas

- La barra usa colores `#rrggbb`: dependen de `terminal-features ",xterm-256color:RGB"`. Si cambia el `TERM` del emulador, ajusta ese patrón.
- El icono de cada ventana se elige por el **nombre** (`claude*`, `*vim*`, `ssh*`): si algo renombra las ventanas, el icono se pierde.
- `monitor-activity` está activado porque el punto `●` de la barra depende de él.
- La persistencia restaura el layout y las rutas, no los procesos. Con `@continuum-restore on` solo restaura cuando arranca el servidor; no hay unidad de arranque.
- `bind c`, `%` y `"` se redefinen con `-c "#{pane_current_path}"`; si se añaden otros `split-window` o `new-window`, deben llevarlo también.

## Estado

Privado de momento; la idea es publicarlo y enlazarlo desde la web (ficha en el Laboratorio). Al publicarlo, README en inglés y español, `AGENTS.md` en inglés y revisión de fugas.
