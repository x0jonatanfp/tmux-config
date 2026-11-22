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
check "monitor-activity on" test "$(tmux -L "$sock" show -wgv monitor-activity)" = on
check "terminal-features con RGB" grep -q 'RGB' <<<"$(tmux -L "$sock" show -s terminal-features)"
check "ruta actual en bind c" grep -q 'pane_current_path' <<<"$(tmux -L "$sock" list-keys -T prefix c)"
tmux -L "$sock" kill-server 2>/dev/null

# 3. install.sh: enlaza, respeta lo existente con copia y es idempotente
echo "fichero real" >"$HOME/.tmux.conf"
check "install.sh --no-plugins" "$repo/install.sh" --no-plugins
check "~/.tmux.conf es un enlace al repo" test "$(readlink "$HOME/.tmux.conf")" = "$repo/tmux.conf"
check "copia de seguridad del fichero previo" bash -c 'grep -q "fichero real" "$HOME"/.tmux.conf.bak-*'
check "scripts enlazados" test "$(readlink "$HOME/.local/bin/tmux-git")" = "$repo/bin/tmux-git"
check "segunda ejecución sin cambios" bash -c '! "$0" --no-plugins | grep -qE "^(enlazado|copia)"' "$repo/install.sh"

# 4. Scripts de la barra
check "tmux-sysstat imprime CPU, RAM y disco" bash -c '"$0" >/dev/null; test "$("$0" | grep -o "│" | wc -l)" = 2' "$repo/bin/tmux-sysstat"
git init -q "$tmp/repo" && git -C "$tmp/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
check "tmux-git en repo limpio muestra ✓" bash -c '"$0" "$1" | grep -q "✓"' "$repo/bin/tmux-git" "$tmp/repo"
touch "$tmp/repo/nuevo"
check "tmux-git marca ficheros sin seguimiento" bash -c '"$0" "$1" | grep -q "?1"' "$repo/bin/tmux-git" "$tmp/repo"
check "tmux-git fuera de repo no imprime nada" test -z "$("$repo/bin/tmux-git" "$tmp")"

echo
if ((fails)); then echo "$fails fallo(s)"; exit 1; fi
echo "Todo correcto"
