# tmux-config

[Read in English](README.md)

Configuración de tmux y sus scripts auxiliares, versionada y desplegada con enlaces simbólicos. Barra de estado con métricas (CPU, RAM, disco), rama y estado de git, selector de sesiones con fzf y persistencia de sesiones tras reiniciar.

## Contenido

| Ruta | Qué es |
| --- | --- |
| `tmux.conf` | Configuración completa (se enlaza como `~/.tmux.conf`). |
| `bin/tmux-sysstat` | Segmento de la barra: CPU, RAM y disco con color por carga. |
| `bin/tmux-git` | Segmento de la barra: rama y estado git de la ruta del panel. |
| `bin/tmux-switch` | Selector de sesiones con fzf en popup (`prefix s` / `prefix f`). |
| `install.sh` | Crea los enlaces, clona los plugins de persistencia y habilita el servicio de systemd de usuario. |
| `systemd/tmux.service` | Servicio de usuario que arranca el servidor de tmux al iniciar sesión y restaura las sesiones guardadas. |
| `tests/test.sh` | Pruebas sin tocar la configuración real. |

## Requisitos

- tmux 3.4 o superior (probado en 3.6).
- Una fuente Nerd Font en el emulador de terminal (los iconos de la barra).
- `fzf` para el selector de sesiones.
- `git` para la barra y para clonar los plugins.

## Instalación

```bash
./install.sh
```

Enlaza `~/.tmux.conf` y los scripts de `bin/` en `~/.local/bin/` (que debe estar en el `PATH`). Si ya había un fichero real, lo guarda como `<destino>.bak-<fecha>`. Con `--no-plugins` no clona los plugins. Dentro de tmux, recarga con `prefix r`.

## Uso

Teclas propias (el prefijo es el de siempre, `Ctrl-b`):

| Tecla | Acción |
| --- | --- |
| `prefix s` / `prefix f` | Selector de sesiones con fzf y vista previa. |
| `prefix S` | Árbol clásico de sesiones. |
| `prefix w` | Árbol de ventanas. |
| `prefix r` | Recarga la configuración. |

`prefix c`, `prefix %` y `prefix "` no cambian, pero ahora abren la ventana o el panel en la ruta del panel actual.

## Persistencia

`tmux-resurrect` y `tmux-continuum` (versiones fijadas en `install.sh`) guardan las sesiones cada 15 minutos y las restauran cuando arranca el servidor de tmux. Se recuperan sesiones, ventanas, paneles y rutas. **Los procesos no vuelven**: un agente o un servidor que estuviera corriendo hay que relanzarlo.

`install.sh` habilita un servicio de systemd de usuario (`tmux.service`) que arranca el servidor al iniciar sesión y restaura las sesiones, así que no hace falta abrir tmux a mano antes. Parar el servicio guarda el estado y después cierra el servidor. Donde no haya systemd de usuario, la instalación omite este paso y avisa; entonces se habilita el servicio a mano.

## Versiones

Las releases se sacan con `make release`: la versión de `VERSION` y el `CHANGELOG.md` salen de los tipos de commit (Conventional Commits).

## Pruebas

```bash
tests/test.sh
```

Comprueba la sintaxis de los scripts, que la configuración carga sin errores y fija las opciones esperadas, que `install.sh` enlaza, hace copia y es idempotente, y que los segmentos de la barra imprimen lo esperado. Ejecuta además `shellcheck` si está instalado.

## Arquitectura

Todo es configuración y bash. Los segmentos de la barra imprimen estilos `#[...]` de tmux y se invocan con `#()` cada `status-interval`; `tmux-sysstat` guarda la lectura previa de `/proc/stat` en `XDG_RUNTIME_DIR` para calcular la CPU como delta. Los plugins se cargan con `run-shell` desde `~/.tmux/plugins`.

## Licencia

[MIT](LICENSE)
