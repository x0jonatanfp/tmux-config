#!/usr/bin/env bash
# Pruebas de tmux-config sin tocar la configuración real: usan un HOME temporal y un
# servidor tmux aislado (-L). shellcheck, si está instalado, también se ejecuta.
set -uo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
sock=tmux-config-test-$$
fails=0
trap 'tmux -L "$sock" kill-server 2>/dev/null; rm -rf "$tmp"' EXIT

check() { # check <descripción> <comando...>
  local desc=$1
  shift
  if "$@" >/dev/null 2>&1; then echo "ok    $desc"; else echo "FALLO $desc"; fails=$((fails + 1)); fi
}

# 1. Sintaxis de todos los scripts
for f in "$repo"/bin/* "$repo"/install.sh "$repo"/tests/test.sh; do
  check "bash -n $(basename "$f")" bash -n "$f"
done
if command -v shellcheck >/dev/null; then
  check "shellcheck" shellcheck "$repo"/bin/* "$repo"/install.sh
else
  echo "omit  shellcheck no está instalado"
fi

# 2. La configuración carga sin errores y fija las opciones esperadas.
# new-session -d mantiene vivo el servidor aislado; los errores de parseo salen por stderr.
mkdir -p "$tmp/home"
export HOME=$tmp/home XDG_RUNTIME_DIR=$tmp
errors=$(tmux -L "$sock" -f "$repo/tmux.conf" new-session -d 2>&1)
check "tmux.conf carga sin errores" test -z "$errors"
check "detach-on-destroy off" test "$(tmux -L "$sock" show -gv detach-on-destroy)" = off
check "history-limit 50000" test "$(tmux -L "$sock" show -gv history-limit)" = 50000
check "monitor-activity off" test "$(tmux -L "$sock" show -wgv monitor-activity)" = off
check "monitor-silence 0" test "$(tmux -L "$sock" show -wgv monitor-silence)" = 0
check "terminal-features con RGB" grep -q 'RGB' <<<"$(tmux -L "$sock" show -s terminal-features)"
check "paleta fucsia sin restos del rosa antiguo" bash -c '! grep -qiE "#ff6fb5|#ffa6d2|#ff79c6|#9d2c6b" "$0" "$1" "$2"' "$repo/tmux.conf" "$repo/bin/tmux-git" "$repo/bin/tmux-switch"
# Los iconos son glifos Nerd Font invisibles al editar: se comprueban por sus bytes UTF-8
# (sesión, teclado del prefijo y reloj) para que no se pierdan al reescribir la barra.
check "barra: iconos de sesión, prefijo y reloj" bash -c 'for g in "\xef\x92\x89" "\xef\x84\x9c" "\xef\x80\x97"; do grep -q "$(printf "$g")" "$0" || exit 1; done' "$repo/tmux.conf"
check "barra: marca de paneles sincronizados" grep -q "pane_synchronized" "$repo/tmux.conf"
check "plugins de persistencia sin run-shell -b" bash -c '! grep -qE "^run-shell -b .*(resurrect|continuum)" "$0"' "$repo/tmux.conf"
check "claude se restaura con --continue" grep -q 'claude->claude --continue' <<<"$(tmux -L "$sock" show -gv @resurrect-processes)"
check "freebuff se restaura con --continue" grep -q 'freebuff->freebuff --continue' <<<"$(tmux -L "$sock" show -gv @resurrect-processes)"
check "ruta actual en bind c" grep -q 'pane_current_path' <<<"$(tmux -L "$sock" list-keys -T prefix c)"
tmux -L "$sock" kill-server 2>/dev/null

# 3. install.sh: enlaza, respeta lo existente con copia y es idempotente
echo "fichero real" >"$HOME/.tmux.conf"
check "install.sh --no-plugins" "$repo/install.sh" --no-plugins
check "~/.tmux.conf es un enlace al repo" test "$(readlink "$HOME/.tmux.conf")" = "$repo/tmux.conf"
check "copia de seguridad del fichero previo" bash -c 'grep -q "fichero real" "$HOME"/.tmux.conf.bak-*'
check "scripts enlazados" test "$(readlink "$HOME/.local/bin/tmux-git")" = "$repo/bin/tmux-git"
check "unidad de systemd enlazada" test "$(readlink "$HOME/.config/systemd/user/tmux.service")" = "$repo/systemd/tmux.service"
check "segunda ejecución sin cambios" bash -c '! "$0" --no-plugins | grep -qE "^(enlazado|copia)"' "$repo/install.sh"

# 3b. La unidad de systemd es válida (si systemd-analyze está disponible)
if command -v systemd-analyze >/dev/null; then
  # ExecStop apunta al plugin (%h); en el HOME temporal no está clonado, así que se simula.
  mkdir -p "$HOME/.tmux/plugins/tmux-resurrect/scripts"
  printf '#!/bin/sh\n' >"$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  chmod +x "$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
  check "systemd-analyze verify tmux.service" systemd-analyze --user verify "$repo/systemd/tmux.service"
else
  echo "omit  systemd-analyze no está instalado"
fi

# 4. Scripts de la barra
check "tmux-working ignora un panel inválido" bash -c 'test -z "$("$0" x)"' "$repo/bin/tmux-working"
# Pantallas reales de cada agente, trabajando y parado (capturadas con cada uno en marcha).
# Un panel que solo imprime el texto sirve: el script lee el contenido, no el proceso.
tw_check() { # tw_check <nombre> <si|no> <texto>
  local out
  tmux -L "$sock" new-session -d -s "tw$$" "printf '%b' '$3'; sleep 30"
  sleep 0.4
  out=$(TMUX="$(tmux -L "$sock" display -p '#{socket_path},0,0')" "$repo/bin/tmux-working" "$(tmux -L "$sock" display -p -t "tw$$" '#{pane_id}')")
  tmux -L "$sock" kill-session -t "tw$$" 2>/dev/null
  if [[ $2 = si ]]; then check "tmux-working: $1" test -n "$out"; else check "tmux-working: $1" test -z "$out"; fi
}
tw_check "claude trabajando" si '* Actualizing... (4s)\n  esc to interrupt\n'
tw_check "claude parado" no '  ? for shortcuts\n'
tw_check "opencode trabajando" si '   ■■■⬝⬝⬝⬝⬝ esc interrupt\n'
tw_check "opencode parado" no '  Build · Big Pickle OpenCode\n'
tw_check "pi trabajando" si '── ⠧ Working ───────\n'
tw_check "pi parado" no '🧠 probe · ready\n'
tw_check "freebuff trabajando" si ' working...\n│  ▍Add to the current task (/ for commands)\n'
tw_check "freebuff parado con cuenta atrás" no ' 3:24 left · 42.9K (4%)\n│  Enter a coding task or / for commands\n'
tw_check "panel sin agente" no 'cultofskaro@void:~$ \n'
check "tmux-working ignora un panel inválido" bash -c 'test -z "$("$0" x)"' "$repo/bin/tmux-working"
check "tmux-sysstat imprime CPU, RAM y disco" bash -c '"$0" >/dev/null; test "$("$0" | grep -o "│" | wc -l)" = 2' "$repo/bin/tmux-sysstat"
git init -q "$tmp/repo" && git -C "$tmp/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
check "tmux-git en repo limpio muestra ✓" bash -c '"$0" "$1" | grep -q "✓"' "$repo/bin/tmux-git" "$tmp/repo"
touch "$tmp/repo/nuevo"
check "tmux-git marca ficheros sin seguimiento" bash -c '"$0" "$1" | grep -q "?1"' "$repo/bin/tmux-git" "$tmp/repo"
check "tmux-git fuera de repo no imprime nada" test -z "$("$repo/bin/tmux-git" "$tmp")"

echo
if ((fails)); then echo "$fails fallo(s)"; exit 1; fi
echo "Todo correcto"
