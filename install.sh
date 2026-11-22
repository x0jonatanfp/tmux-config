#!/usr/bin/env bash
# Instala la configuración de tmux con enlaces simbólicos al repo y clona los plugins de
# persistencia (versiones fijadas). Idempotente: se puede ejecutar las veces que haga falta.
# Si ya hay un fichero real en el destino, lo mueve a <destino>.bak-<fecha> antes de enlazar.
#   ./install.sh            instala
#   ./install.sh --no-plugins  enlaza sin clonar los plugins (sin red)
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
stamp=$(date +%Y%m%d-%H%M%S)

RESURRECT_REF=v4.0.0
CONTINUUM_REF=v3.1.0

link() {
  local src=$1 dest=$2
  mkdir -p "$(dirname "$dest")"
  if [[ -L $dest && $(readlink "$dest") == "$src" ]]; then
    echo "ok       $dest"
    return
  fi
  if [[ -e $dest || -L $dest ]]; then
    mv "$dest" "$dest.bak-$stamp"
    echo "copia    $dest.bak-$stamp"
  fi
  ln -s "$src" "$dest"
  echo "enlazado $dest -> $src"
}

# Clona el plugin en la versión fijada; si ya existe, solo comprueba que está en esa versión.
plugin() {
  local name=$1 ref=$2 dir=$HOME/.tmux/plugins/$1
  if [[ ! -d $dir ]]; then
    git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ref" "https://github.com/tmux-plugins/$name.git" "$dir"
    echo "clonado  $dir ($ref)"
  else
    echo "ok       $dir ($(git -C "$dir" describe --tags --always 2>/dev/null))"
  fi
}

link "$repo/tmux.conf" "$HOME/.tmux.conf"
for script in "$repo"/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

if [[ ${1:-} != --no-plugins ]]; then
  plugin tmux-resurrect "$RESURRECT_REF"
  plugin tmux-continuum "$CONTINUUM_REF"
fi

echo "Listo. Dentro de tmux, recarga con prefix + r."
