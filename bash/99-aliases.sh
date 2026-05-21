# ─── ALIASES & FUNCIONES VARIAS ─────────────────────────────────────────────
# Espacio reservado para funciones futuras: gco, pkillf, fkill, fdocker, etc.
# (Se va llenando cuando agreguemos cada herramienta)

# ─── TMUX ───────────────────────────────────────────────────────────────────
# Sessionizer: en tmux moderno está como popup en 'prefix + C-j',
# pero en servers con tmux <3.2 (Ubuntu 20.04, CentOS 7) ese binding no existe.
# El alias da acceso universal: tipear 'ts' funciona en cualquier versión.
alias ts='~/bin/tmux-sessionizer'
