# ─── SSH HELPERS ────────────────────────────────────────────────────────────

# sshl: lista servers de ~/.ssh/config con fuzzy finder
#
# Parsea cualquier comentario que esté inmediatamente antes de un bloque Host
# y lo usa como descripción. Soporta múltiples formatos:
#   # --- Data Warehouse ---       (formato vargas-sistemas)
#   # - Data Warehouse -            (variante con guion simple)
#   # 🏛️ UNCUYO - SUDOCU / PROD   (formato Wolfindia con emojis)
#   ##### Bloque #####              (separadores con ##)
#   # ============================  (separadores con =)
#
# La heurística: limpia separadores (-, =, #, _) repetidos en medio y
# sueltos al inicio/final del texto. Mantiene guiones internos (ej: "PROD - DB").
# Los emojis se conservan porque agregan contexto visual.
sshl() {
    local selection
    selection=$(awk '
        # Cualquier comentario es candidato a ser descripción del próximo Host
        /^# / {
            desc = $0
            sub(/^# */, "", desc)
            # Limpiar separadores repetidos en cualquier parte del texto
            gsub(/[-=#_]{2,}/, "", desc)
            # Limpiar separadores sueltos al inicio o al final
            sub(/^[-=#_]+ */, "", desc)
            sub(/ *[-=#_]+$/, "", desc)
            # Colapsar espacios y trim
            gsub(/  +/, " ", desc)
            sub(/^ +/, "", desc)
            sub(/ +$/, "", desc)
            if (length(desc) > 0) last_desc = desc
            next
        }
        /^Host / && $2 !~ /\*/ {
            printf "%-30s  %s\n", $2, last_desc
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
