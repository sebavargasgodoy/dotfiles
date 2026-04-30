# dotfiles

Configuración personal replicable de **Sebastián Vargas** (sysadmin @ UNCUYO).

Setup centrado en `tmux` + `fzf` + `bash`, optimizado para administrar múltiples
servers vía SSH desde 3 máquinas locales (PCs trabajo, casa y notebook personal).

## Qué hay acá

```
dotfiles/
├── install.sh                  # Instalador con detección OS + flags
├── bash/                       # Fragmentos del shell (cargados desde ~/.bashrc)
│   ├── init.sh                 # Entry point — sourcea todos los fragmentos
│   ├── 00-path.sh              # Agrega ~/bin al PATH
│   ├── 10-fzf.sh               # Integraciones fzf (Ctrl+R, Ctrl+T, Alt+C)
│   ├── 20-ssh.sh               # sshl + tab completion para ssh
│   └── 99-aliases.sh           # Funciones varias (placeholder)
├── tmux/
│   └── tmux.conf               # Config tmux (solo se instala en servers)
└── bin/
    └── tmux-sessionizer        # Session switcher con fzf (prefix + C-j)
```

## Instalación

```bash
git clone https://github.com/sebavargasgodoy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### En un server (default)

```bash
./install.sh
```

Instala: bash fragments + tmux.conf + tmux-sessionizer + TPM.

### En PC local (workstation)

```bash
./install.sh --workstation
```

Instala: solo bash fragments. Sin tmux (en local se usa kitty + tabs).

### Modo dry-run (no toca nada, solo muestra)

```bash
./install.sh --dry-run
./install.sh --workstation --dry-run
```

## Cómo funciona

- El instalador crea **symlinks** desde `~/.tmux.conf`, `~/bin/tmux-sessionizer`,
  etc. al repo. Editás una vez en el repo, `git pull` en otra máquina, listo.
- El `~/.bashrc` no se reemplaza: se le agrega **una sola línea** que sourcea
  `bash/init.sh`. Idempotente — corrérelo varias veces no rompe nada.
- Si encuentra config previa que no es nuestra, hace **backup con timestamp**
  (`~/.tmux.conf.bak.20260430-1430`) antes de pisar.

## Dependencias

- `bash` (4+)
- `fzf` (Ctrl+R/T, Alt+C, sshl, tmux-sessionizer)
- `tmux` (3.0+) — solo en servers
- `git`

Si faltan, el instalador te avisa con el comando de tu distro:

| Distro | Instalación |
|---|---|
| Ubuntu/Debian | `sudo apt install fzf tmux git` |
| RHEL/CentOS | `sudo dnf install fzf tmux git` |

## Atajos clave

### Bash (en cualquier máquina)
| Atajo | Acción |
|---|---|
| `Ctrl+R` | Búsqueda fuzzy en historial |
| `Ctrl+T` | Búsqueda fuzzy de archivos |
| `Alt+C` | `cd` con búsqueda fuzzy |
| `sshl` | Conectar a server con fuzzy del `~/.ssh/config` |
| `ssh <Tab><Tab>` | Autocomplete de hosts |

### Tmux (solo servers)
| Atajo | Acción |
|---|---|
| `Ctrl+Space` | Prefix |
| `prefix \|` / `prefix -` | Split horizontal/vertical |
| `prefix h/j/k/l` | Navegar panes |
| `prefix S` | Toggle sync panes |
| `prefix C-j` | Session switcher con fzf |
| `prefix Enter` | Entrar a copy mode (vi-style) |
| `prefix r` | Recargar config |

## Pendiente / Roadmap

- [ ] Indicador prod/test en barra tmux (color por hostname)
- [ ] Función `ta` (tmux attach con fzf desde fuera de tmux)
- [ ] Configuración de `kitten ssh` (terminfo + clipboard remoto)
- [ ] Funciones fzf adicionales: `pkillf`, `gco`, `fkill`, `fdocker`, `frg`, `fpkg`
- [ ] Config de `kitty.conf` replicable (PCs locales)
