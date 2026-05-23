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
        # Comentario: candidato a descripción del próximo Host
        /^# / {
            desc = $0
            sub(/^# */, "", desc)
            gsub(/[-=#_]{2,}/, "", desc)
            sub(/^[-=#_]+ */, "", desc)
            sub(/ *[-=#_]+$/, "", desc)
            gsub(/  +/, " ", desc)
            sub(/^ +/, "", desc)
            sub(/ +$/, "", desc)
            if (length(desc) > 0) pending_desc = desc
            next
        }
        # Inicio de bloque Host
        /^Host / {
            # Si veníamos juntando un bloque previo y tenía HostName, lo imprimimos
            if (current_host != "" && current_ip != "") {
                printf "%-28s  %-16s  %s\n", current_host, current_ip, current_desc
            }
            current_host = ""
            current_ip = ""
            current_desc = pending_desc

            # Tomamos el primer nombre del bloque (sin wildcards)
            if ($2 !~ /\*/) {
                current_host = $2
            }
            next
        }
        # HostName dentro del bloque actual
        /^[[:space:]]*HostName / {
            if (current_host != "") {
                current_ip = $2
            }
            next
        }
        END {
            # Cerrar el último bloque
            if (current_host != "" && current_ip != "") {
                printf "%-28s  %-16s  %s\n", current_host, current_ip, current_desc
            }
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
