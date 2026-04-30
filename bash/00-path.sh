# ─── PATH ───────────────────────────────────────────────────────────────────
# Agregar ~/bin al PATH (donde vive tmux-sessionizer y otros scripts personales)
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi
