#!/usr/bin/env bash
# ============================================================================
#  install.sh — instalador de dotfiles
#
#  Uso:
#    ./install.sh                  # modo server (default)
#    ./install.sh --server         # explícito: server (instala todo)
#    ./install.sh --workstation    # PC local: NO instala tmux ni tmux-sessionizer
#    ./install.sh --dry-run        # solo muestra qué haría, sin tocar nada
#    ./install.sh --help
#
#  Idempotente: corrérelo varias veces no rompe nada.
#  Si encuentra config previa, hace backup con timestamp antes de pisarla.
# ============================================================================

set -euo pipefail

# ─── COLORES ────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_RED='\033[31m'
    C_GREEN='\033[32m'
    C_YELLOW='\033[33m'
    C_BLUE='\033[34m'
    C_DIM='\033[2m'
else
    C_RESET='' C_BOLD='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_DIM=''
fi

log()   { echo -e "${C_BLUE}▸${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}✓${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
err()   { echo -e "${C_RED}✗${C_RESET} $*" >&2; }
info()  { echo -e "${C_DIM}  $*${C_RESET}"; }

# ─── VARIABLES ──────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_SUFFIX=".bak.${TIMESTAMP}"

MODE="server"   # default
DRY_RUN=0

# ─── PARSEO DE ARGUMENTOS ───────────────────────────────────────────────────
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Opciones:
  --server         Modo server (default): instala bash + tmux + tmux-sessionizer
  --workstation    Modo PC local: instala solo bash (sshl, fzf, PATH)
  --dry-run        Muestra qué haría sin tocar nada
  -h, --help       Muestra esta ayuda

Ejemplos:
  $0                       # corre como server (default)
  $0 --workstation         # corre como PC personal
  $0 --workstation --dry-run
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --server)      MODE="server"; shift ;;
        --workstation) MODE="workstation"; shift ;;
        --dry-run)     DRY_RUN=1; shift ;;
        -h|--help)     show_help; exit 0 ;;
        *)             err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

# ─── DETECCIÓN DE OS ────────────────────────────────────────────────────────
detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)            echo "debian" ;;
            rhel|centos|rocky|almalinux|fedora) echo "rhel" ;;
            *)                        echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

OS_FAMILY="$(detect_os)"
PKG_INSTALL_CMD=""
case "$OS_FAMILY" in
    debian) PKG_INSTALL_CMD="sudo apt update && sudo apt install -y" ;;
    rhel)
        # CentOS 7 usa yum; CentOS/RHEL/Rocky/Alma 8+ y Fedora usan dnf
        if command -v dnf >/dev/null 2>&1; then
            PKG_INSTALL_CMD="sudo dnf install -y"
        else
            PKG_INSTALL_CMD="sudo yum install -y"
        fi
        ;;
    *)      PKG_INSTALL_CMD="" ;;
esac

# ─── HEADER ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${C_BOLD}━━━ dotfiles installer ━━━${C_RESET}"
echo ""
info "Hostname:      $(hostname)"
info "Usuario:       $(whoami)"
info "OS detectado:  $OS_FAMILY"
info "Modo:          $MODE"
info "Repo:          $DOTFILES_DIR"
[ "$DRY_RUN" -eq 1 ] && warn "DRY-RUN: no se va a modificar ningún archivo"
echo ""

# ─── HELPERS DE INSTALACIÓN ─────────────────────────────────────────────────

# Crea un symlink idempotente, haciendo backup si existe algo distinto al destino esperado
link_file() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        err "Source no existe: $source"
        return 1
    fi

    # Caso 1: el target ya es el symlink correcto → no hacer nada
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
        ok "$target ya apunta correctamente"
        return 0
    fi

    # Caso 2: existe algo distinto (archivo regular u otro symlink)
    if [ -e "$target" ] || [ -L "$target" ]; then
        local backup="${target}${BACKUP_SUFFIX}"
        warn "$target ya existe → backup en $backup"
        if [ "$DRY_RUN" -eq 0 ]; then
            mv "$target" "$backup"
        fi
    fi

    # Caso 3: crear el symlink
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$target")"
        ln -s "$source" "$target"
    fi
    ok "Symlink: $target → $source"
}

# Asegura que ~/.bashrc sourcea bash/init.sh (línea idempotente)
ensure_bashrc_source() {
    local bashrc="$HOME/.bashrc"
    local marker="# >>> dotfiles bash init >>>"
    local line="[ -f \"$DOTFILES_DIR/bash/init.sh\" ] && source \"$DOTFILES_DIR/bash/init.sh\""
    local end_marker="# <<< dotfiles bash init <<<"

    if [ ! -f "$bashrc" ]; then
        warn "$bashrc no existe, lo creo"
        [ "$DRY_RUN" -eq 0 ] && touch "$bashrc"
    fi

    if grep -qF "$marker" "$bashrc" 2>/dev/null; then
        ok "$bashrc ya sourcea los dotfiles"
        return 0
    fi

    log "Agregando bloque dotfiles a $bashrc"
    if [ "$DRY_RUN" -eq 0 ]; then
        # Backup del .bashrc original antes de modificar
        cp "$bashrc" "${bashrc}${BACKUP_SUFFIX}"
        info "Backup de .bashrc: ${bashrc}${BACKUP_SUFFIX}"

        cat >> "$bashrc" <<EOF

$marker
$line
$end_marker
EOF
    fi
    ok "Bloque agregado a $bashrc"
}

# Verifica dependencias y avisa cuáles faltan
check_dependencies() {
    local deps=("$@")
    local missing=()
    local d
    for d in "${deps[@]}"; do
        if ! command -v "$d" >/dev/null 2>&1; then
            missing+=("$d")
        fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
        ok "Todas las dependencias están instaladas: ${deps[*]}"
        return 0
    fi

    warn "Faltan dependencias: ${missing[*]}"
    if [ -n "$PKG_INSTALL_CMD" ]; then
        info "Instalalas con:  $PKG_INSTALL_CMD ${missing[*]}"
    else
        info "Instalá manualmente: ${missing[*]}"
    fi
    return 1
}

# ─── INSTALACIÓN ────────────────────────────────────────────────────────────

log "Verificando dependencias..."
case "$MODE" in
    workstation) check_dependencies fzf git || true ;;
    server)      check_dependencies fzf git tmux || true ;;
esac
echo ""

log "Instalando fragmentos de bash..."
ensure_bashrc_source
echo ""

log "Instalando ~/bin/..."
mkdir -p "$HOME/bin"
link_file "$DOTFILES_DIR/bin/tmux-sessionizer" "$HOME/bin/tmux-sessionizer"
[ "$DRY_RUN" -eq 0 ] && chmod +x "$DOTFILES_DIR/bin/tmux-sessionizer"
echo ""

if [ "$MODE" = "server" ]; then
    log "Instalando configuración de tmux..."
    link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
    echo ""

    # TPM (tmux plugin manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        log "Instalando TPM (tmux plugin manager)..."
        if [ "$DRY_RUN" -eq 0 ]; then
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
            ok "TPM instalado en ~/.tmux/plugins/tpm"
            info "Después de iniciar tmux, apretá: prefix + I  para instalar plugins"
        else
            info "DRY-RUN: clonaría tpm en ~/.tmux/plugins/tpm"
        fi
    else
        ok "TPM ya está instalado"
    fi
    echo ""
else
    info "Modo workstation: saltando tmux.conf (no se usa tmux en PC local)"
    echo ""
fi

# ─── RESUMEN FINAL ──────────────────────────────────────────────────────────
echo -e "${C_BOLD}━━━ instalación completa ━━━${C_RESET}"
echo ""
ok "Modo: $MODE"
info "Próximos pasos:"
echo "    1. Recargá tu shell:    source ~/.bashrc"
if [ "$MODE" = "server" ]; then
    echo "    2. Iniciá tmux:         tmux"
    echo "    3. Instalá plugins:     prefix + I  (Ctrl+Space + I)"
fi
echo ""

if [ "$DRY_RUN" -eq 1 ]; then
    warn "DRY-RUN: ningún archivo fue modificado realmente"
fi
