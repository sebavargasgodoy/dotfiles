# ─── SSH HELPERS ────────────────────────────────────────────────────────────

# sshl: lista servers de ~/.ssh/config con fuzzy finder
# Muestra el alias + descripción del comentario "# --- ... ---" si existe
sshl() {
    local selection
    selection=$(awk '
        /^# ---/ {
            desc = $0
            gsub(/^# *--* */, "", desc)
            gsub(/ *--*$/, "", desc)
            next
        }
        /^Host / && $2 !~ /\*/ {
            printf "%-25s  %s\n", $2, desc
            desc = ""
        }
    ' ~/.ssh/config 2>/dev/null | \
        fzf --prompt="  SSH > " \
            --height=50% \
            --reverse \
            --border \
            --header="Enter: conectar | Esc: cancelar")

    local host
    host=$(echo "$selection" | awk '{print $1}')

    if [ -n "$host" ]; then
        echo "→ Conectando a $host..."
        ssh "$host"
    fi
}

# Tab completion para ssh: autocompleta nombres del ~/.ssh/config
_ssh_complete_hosts() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local hosts
    hosts=$(grep '^Host ' ~/.ssh/config 2>/dev/null | awk '{print $2}' | grep -v '\*')
    COMPREPLY=($(compgen -W "$hosts" -- "$cur"))
}
complete -F _ssh_complete_hosts ssh
