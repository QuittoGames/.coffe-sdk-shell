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

DATA_FILE="$COFFE_SDK_ROOT/data/info.json"
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
    --prompt="${COFFE_SDK_ICON} ${ICON_SEARCH} > "
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
    --bind='ctrl-p:execute($SHELL -c "source ${COFFE_SDK_ROOT}/ui/theme/coffe_theme.sh && coffe::keybinds")'
)

# --------------------------------------
# Keybinds display (Ctrl+P)
# --------------------------------------

coffe::keybinds() {
    local keybinds_text="
${CLR_BOLD}${CLR_CARAMEL}Navigation${CLR_RESET}
  ${CLR_SKY_BLUE}ctrl-j / alt-j${CLR_RESET}    Down
  ${CLR_SKY_BLUE}ctrl-k / alt-k${CLR_RESET}    Up
  ${CLR_SKY_BLUE}home${CLR_RESET}              First item
  ${CLR_SKY_BLUE}end${CLR_RESET}               Last item

${CLR_BOLD}${CLR_CARAMEL}Preview${CLR_RESET}
  ${CLR_SKY_BLUE}ctrl-u${CLR_RESET}            Preview half-page up
  ${CLR_SKY_BLUE}ctrl-d${CLR_RESET}            Preview half-page down
  ${CLR_SKY_BLUE}ctrl-b${CLR_RESET}            Preview page up
  ${CLR_SKY_BLUE}ctrl-f${CLR_RESET}            Preview page down
  ${CLR_SKY_BLUE}ctrl-r / ?${CLR_RESET}        Toggle preview

${CLR_BOLD}${CLR_CARAMEL}Selection${CLR_RESET}
  ${CLR_SKY_BLUE}ctrl-space${CLR_RESET}        Toggle selection
  ${CLR_SKY_BLUE}ctrl-a${CLR_RESET}            Select all
  ${CLR_SKY_BLUE}ctrl-x${CLR_RESET}            Deselect all

${CLR_BOLD}${CLR_CARAMEL}Actions${CLR_RESET}
  ${CLR_SKY_BLUE}ctrl-y${CLR_RESET}            Copy to clipboard
  ${CLR_SKY_BLUE}ctrl-o / ctrl-e${CLR_RESET}   Open in VS Code
  ${CLR_SKY_BLUE}ctrl-p${CLR_RESET}            This help
"

    # Se estiver rodando dentro do tmux, abre em um popup flutuante
    if [[ -n "$TMUX" ]]; then
        tmux display-popup -E -w 60% -h 65% -b rounded -T " Coffee SDK — Keybinds " \
            "$SHELL -c 'echo -e \"$keybinds_text\" | fzf --ansi --no-input --no-info --header=\"Pressione ESC ou ENTER para fechar\" --color=bg:-1 >/dev/null'"
    else
        # Fallback fora do tmux: fzf secundário ou lesse/cat simples
        echo -e "$keybinds_text" | fzf \
            --ansi \
            --height=60% \
            --border=rounded \
            --border-label=" Coffee SDK — Keybinds " \
            --header="Pressione ESC ou ENTER para fechar" \
            --no-input \
            --no-info >/dev/null
    fi
}
export -f coffe::keybinds

# --------------------------------------
# Presets (usados por fzf::*)
# --------------------------------------

FZF_FILES_OPTS=(
    --prompt="${ICON_SHELL} ${ICON_FILE} > "
    --header="${ICON_FILE} Search files"
    --header="${ICON_KEYBOARD} Ctrl+P: Keybinds"
    --preview-label="${ICON_EYE} Preview"
)

FZF_GREP_OPTS=(
    --delimiter=:
    --prompt="${ICON_SHELL} ${ICON_SEARCH} > "
    --header="${ICON_FILE} Search text"
    --header="${ICON_KEYBOARD} Ctrl+P: Keybinds"
    --preview-label="${ICON_EYE} Preview"
    --preview="bat --style=numbers --color=always --highlight-line {2} {1}"
)

FZF_DIRS_OPTS=(
    --prompt="${ICON_SHELL} ${ICON_FOLDER} > "
    --header="${ICON_FOLDER} Browse directories"
    --preview-label="${ICON_EYE} Tree"
    --preview="eza --icons --tree --level=3 --git --color=always {}"
)

FZF_HISTORY_OPTS=(
    --prompt="${ICON_SHELL} ${ICON_HISTORY} > "
    --header="${ICON_HISTORY} Shell history"
)

FZF_GIT_OPTS=(
    --prompt="${ICON_SHELL} ${ICON_GIT} > "
)

FZF_DOCKER_OPTS=(
    --prompt="${ICON_SHELL} ${ICON_DOCKER} > "
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

export BAT_THEME="cpptools_dark_vs"

# --------------------------------------
# Debug
# --------------------------------------

if [[ "$DEBUG" == "true" ]]; then
    echo -e "${CLR_BLUE}${ICON_CHECK} Coffee SDK — Theme loaded (Modern Blue Focus)${CLR_RESET}"
fi
