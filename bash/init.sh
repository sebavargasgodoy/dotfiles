# ─── DOTFILES ENTRY POINT ───────────────────────────────────────────────────
# Este archivo lo sourcea ~/.bashrc y carga todos los fragmentos del repo.
# Para agregar nuevas funciones: poner un nuevo fragmento bash/NN-nombre.sh

# Detectar el directorio donde vive este script (resuelve symlinks)
DOTFILES_BASH_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

# Sourcear todos los fragmentos en orden alfabético, excluyendo init.sh
for fragment in "$DOTFILES_BASH_DIR"/[0-9]*.sh; do
    [ -r "$fragment" ] && source "$fragment"
done
unset fragment DOTFILES_BASH_DIR
