# ─── FZF INTEGRATIONS ───────────────────────────────────────────────────────
# Activa Ctrl+R (historial), Ctrl+T (archivos), Alt+C (directorios)
# Los paths varían según distro:
#   Ubuntu/Debian: /usr/share/doc/fzf/examples/
#   RHEL/CentOS:   /usr/share/fzf/shell/
#   fzf moderno:   /usr/share/fzf/
#   Install manual:  /usr/local/share/fzf/   ← CentOS 7 sin paquete fzf

_load_fzf_integration() {
    local candidates_keybindings=(
        "/usr/share/doc/fzf/examples/key-bindings.bash"
        "/usr/share/fzf/shell/key-bindings.bash"
        "/usr/share/fzf/key-bindings.bash"
        "/usr/local/share/fzf/key-bindings.bash"
    )
    local candidates_completion=(
        "/usr/share/doc/fzf/examples/completion.bash"
        "/usr/share/fzf/shell/completion.bash"
        "/usr/share/fzf/completion.bash"
        "/usr/local/share/fzf/completion.bash"
    )

    local f
    for f in "${candidates_keybindings[@]}"; do
        [ -f "$f" ] && source "$f" && break
    done

    for f in "${candidates_completion[@]}"; do
        [ -f "$f" ] && source "$f" 2>/dev/null && break
    done
}

# Solo cargar si fzf está instalado
command -v fzf >/dev/null 2>&1 && _load_fzf_integration
unset -f _load_fzf_integration
