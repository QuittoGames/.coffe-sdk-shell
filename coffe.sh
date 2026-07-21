#!/usr/bin/env bash
# ======================================
# Coffee SDK — Entry Point
# ======================================

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}"

# UI Layer
source "$COFFE_SDK_ROOT/ui/icons.sh"
source "$COFFE_SDK_ROOT/ui/theme/coffe_theme.sh"
source "$COFFE_SDK_ROOT/ui/fzf.sh"
source "$COFFE_SDK_ROOT/ui/dialogs.sh"

# Modules (usam apenas ui::*, nunca fzf diretamente)
source "$COFFE_SDK_ROOT/modules/search.sh"
source "$COFFE_SDK_ROOT/modules/env.sh"
source "$COFFE_SDK_ROOT/modules/git.sh"
source "$COFFE_SDK_ROOT/modules/docker.sh"

version() {
    local data_file="${COFFE_SDK_ROOT}/data/data.json"

    # Trava de segurança caso o arquivo não exista
    if [[ ! -f "$data_file" ]]; then
        echo -e "\033[31m${ICON_WARNING:-!} Erro: Arquivo de dados não encontrado em $data_file\033[0m" >&2
        return 1
    fi

    # Leitura dos dados do JSON
    local name version author
    read -r name version author < <(
        jq -r '[.name, .version, .author] | @tsv' "$data_file" 2>/dev/null
    )

    # Cores ANSI
    local c_reset="\033[0m"
    local c_bold="\033[1m"
    local c_dim="\033[2m"
    local c_cyan="\033[36m"
    local c_green="\033[32m"
    local c_yellow="\033[33m"

    # Ícones aproveitando a sua tabela icons.sh (com fallbacks)
    local icon_app="${COFFE_SDK_ICON:-☕}"
    local icon_version="${ICON_TAG:-🏷️}"
    local icon_author="${ICON_USER:-👤}"

    # Saída formatada estilo Card CLI
    echo -e ""
    echo -e "  ${c_cyan}${c_bold}${icon_app}  ${name}${c_reset}"
    echo -e "  ${c_dim}──────────────────────────────${c_reset}"
    echo -e "   ${c_green}${icon_version}${c_reset}  ${c_bold}Versão:${c_reset}  ${c_yellow}v${version}${c_reset}"
    echo -e "   ${c_cyan}${icon_author}${c_reset}  ${c_bold}Autor:${c_reset}   ${author:-Desconhecido}"
    echo -e "  ${c_dim}──────────────────────────────${c_reset}"
    echo -e ""
}

# Debug
if [[ "$DEBUG" == "true" ]]; then
    echo " Coffee SDK"
    echo "   󰍉 FZF Theme"
    echo "   󰣇 Modules: search env git docker"
fi
