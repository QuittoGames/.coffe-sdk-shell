#!/usr/bin/env bash
# shell=bash
#
# coffe_theme.sh — Tema do Coffee SDK (arrays, presets, key bindings).
# Nada aqui é exportado como string plana (sem FZF_DEFAULT_OPTS).
# Use `fzf::run` em fzf.sh para aplicar os arrays corretamente.

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}"

source "$COFFE_SDK_ROOT/ui/icons.sh"
source "$COFFE_SDK_ROOT/ui/colors/ansi_colors.sh"

# --------------------------------------
# Data
# --------------------------------------

DATA_FILE="$COFFE_SDK_ROOT/data/data.json"
if command -v jq >/dev/null 2>&1 && [[ -f "$DATA_FILE" ]]; then
    DEBUG=$(jq -r '.config.debug' "$DATA_FILE")
else
    DEBUG=false
fi

# --------------------------------------
# Default Commands
# --------------------------------------

export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'

# --------------------------------------
# Base options
# --------------------------------------

_FZF_OPTS=(
    --height=82%
    --layout=reverse
    --border=rounded
    --padding=1
    --margin=1
    --cycle
    --ansi
    --multi
    --info=inline-right
    --tabstop=4
    --prompt="${ICON_SEARCH} Search > "
    --pointer=󰜴
    --marker=${ICON_CHECK}
    --separator=─
    --scrollbar=▐▌
    --preview-window=right:60%:border-left:wrap
    --preview='if [[ -d {} ]]; then eza --icons --tree --level=3 --git --color=always {}; else bat --style=numbers --color=always --line-range=:500 {}; fi'
)

# PALETA TRANSPARENTE COM AZUL DOMINANTE
_FZF_COLORS=(
    --color=bg:-1                   # Fundo transparente do terminal
    --color=bg+:-1                  # Linha ativa transparente
    --color=fg:$HEX_CREAM           # Texto regular em tom Latte suave
    --color=fg+:$HEX_WHITE          # Texto selecionado em Branco puro
    --color=hl:$HEX_SKY_BLUE        # Match de busca em Cyan elétrico
    --color=hl+:$HEX_ICE_BLUE       # Match de busca na linha ativa
    --color=prompt:$HEX_BLUE        # Prompt do FZF em Azul moderno
    --color=pointer:$HEX_SKY_BLUE   # Ponteiro `󰜴` em Azul Cyan marcante
    --color=marker:$HEX_GREEN       # Items selecionados em Verde Matcha
    --color=spinner:$HEX_ORANGE     # Spinner em Canela
    --color=info:$HEX_LIGHT_BLUE    # Informações da busca em Azul brilhante
    --color=border:$HEX_BLUE        # Bordas em Azul moderno
    --color=header:$HEX_LIGHT_BLUE  # Títulos em Azul suave
    --color=query:$HEX_WHITE        # Texto digitado em Branco puro
    --color=gutter:-1               # Margem transparente
)

_FZF_BINDS=(
    --bind=ctrl-j:down
    --bind=ctrl-k:up
    --bind=alt-j:down
    --bind=alt-k:up
    --bind=ctrl-u:preview-half-page-up
    --bind=ctrl-d:preview-half-page-down
    --bind=ctrl-b:preview-page-up
    --bind=ctrl-f:preview-page-down
    --bind=pgup:preview-page-up
    --bind=pgdn:preview-page-down
    --bind=home:first
    --bind=end:last
    --bind=ctrl-r:toggle-preview
    --bind=ctrl-space:toggle
    --bind=ctrl-a:select-all
    --bind=ctrl-x:deselect-all
    --bind='ctrl-y:execute-silent(echo -n {} | wl-copy)+abort'
    --bind='ctrl-o:execute(code {})+abort'
    --bind='ctrl-e:execute(code {})+abort'
    --bind=?:toggle-preview
)

# --------------------------------------
# Presets (usados por fzf::*)
# --------------------------------------

FZF_FILES_OPTS=(
    --prompt="${ICON_FILE} Files > "
    --header="${ICON_FILE} Search files"
    --preview-label="${ICON_EYE} Preview"
)

FZF_GREP_OPTS=(
    --delimiter=:
    --prompt="${ICON_SEARCH} Grep > "
    --header="${ICON_FILE} Search text"
    --preview-label="${ICON_EYE} Preview"
    --preview="bat --style=numbers --color=always --highlight-line {2} {1}"
)

FZF_DIRS_OPTS=(
    --prompt="${ICON_FOLDER} Directories > "
    --header="${ICON_FOLDER} Browse directories"
    --preview-label="${ICON_EYE} Tree"
    --preview="eza --icons --tree --level=3 --git --color=always {}"
)

FZF_HISTORY_OPTS=(
    --prompt="${ICON_HISTORY} History > "
    --header="${ICON_HISTORY} Shell history"
)

FZF_GIT_OPTS=(
    --prompt="${ICON_GIT} Git > "
)

FZF_DOCKER_OPTS=(
    --prompt="${ICON_DOCKER} Docker > "
)

# --------------------------------------
# Key bindings (Ctrl+T / Ctrl+R / Alt+C)
# --------------------------------------

export FZF_CTRL_T_OPTS="
--prompt='${ICON_FILE} Files >'
--pointer=󰜴
--preview='if [[ -d {} ]]; then eza --icons --tree --level=2 --git --color=always {}; else bat --style=numbers --color=always {}; fi'
"

export FZF_CTRL_R_OPTS="
--layout=reverse
--border=rounded
--prompt='${ICON_HISTORY} History >'
--pointer=󰜴
--preview='echo {}'
"

export FZF_ALT_C_OPTS="
--prompt='${ICON_FOLDER} Directories >'
--pointer=󰜴
--preview='eza --icons --tree --level=3 --git --color=always {}'
"

# --------------------------------------
# bat
# --------------------------------------

export BAT_THEME="Visual Studio Dark (C/C++)"

# --------------------------------------
# Debug
# --------------------------------------

if [[ "$DEBUG" == "true" ]]; then
    echo -e "${CLR_BLUE}${ICON_CHECK} Coffee SDK — Theme loaded (Modern Blue Focus)${CLR_RESET}"
fi
