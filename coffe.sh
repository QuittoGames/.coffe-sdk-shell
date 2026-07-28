#!/usr/bin/env bash
# ======================================
# Coffee SDK — Entry Point
# ======================================

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk-shell}"

# Config
source "$COFFE_SDK_ROOT/config/packages.sh"

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
source "$COFFE_SDK_ROOT/modules/ssh.sh"

export DEBUG=$(jq -r '.config.debug' "$COFFE_SDK_ROOT/data/info.json")

version() {
    local data_file="${COFFE_SDK_ROOT}/data/info.json"

    if [[ ! -f "$data_file" ]]; then
        echo -e "${CLR_RED:-${CLR_RESET}}${ICON_WARNING:-!} Erro: Arquivo de dados não encontrado em $data_file${CLR_RESET}" >&2
        return 1
    fi

    local name version author
    IFS=$'\t' read -r name version author < <(
        jq -r '[.name, .version, .createdBy] | @tsv' "$data_file" 2>/dev/null
    )

    local icon_app="${COFFE_SDK_ICON:-☕}"
    local icon_distro="${ICON_FEDORA:-}"
    local icon_shell="${ICON_BASH:-}"
    local icon_version="${ICON_TAG:-🏷️}"
    local icon_author="${ICON_USER:-👤}"

    echo -e ""
    echo -e "  ${CLR_BLUE}${CLR_BOLD}${icon_app}  ${name}${CLR_RESET}"
    echo -e "  ${CLR_DIM}${ICON_COFFE}${CLR_RESET}${CLR_DIM}────────────────────────────────────${CLR_RESET}"
    echo -e "   ${CLR_GREEN}${icon_version}${CLR_RESET}  ${CLR_BOLD}Versão:${CLR_RESET}  ${CLR_CARAMEL}v${version}${CLR_RESET}"
    echo -e "   ${CLR_SKY_BLUE}${icon_author}${CLR_RESET}  ${CLR_BOLD}Autor:${CLR_RESET}   ${CLR_CREAM}${author:-Quitto}${CLR_RESET}"
    echo -e "   ${LOGO_OS}  ${CLR_BROWN}│${CLR_RESET}  ${icon_distro} ${CLR_DIM}Fedora${CLR_RESET}  ${CLR_BROWN}│${CLR_RESET}  ${icon_shell} ${CLR_DIM}Bash${CLR_RESET}"
    echo -e "  ${CLR_DIM}${ICON_COFFE}────────────────────────────────────${CLR_RESET}"
        echo -e ""
}

# Auto-install dependencies
coffe::packages::install

# Config Bat
BAT_THEMES_DIR="$COFFE_SDK_ROOT/config/bat/themes"

if [ ! -d "$BAT_THEMES_DIR" ]; then
    echo "Bat themes directory not found. Creating..."
    mkdir -p "$BAT_THEMES_DIR"
fi

# Debug
if [[ "$DEBUG" == "true" ]]; then
    echo "${CLR_BLUE}${COFFE_SDK_ICON} ${CLR_BOLD}Coffee SDK${CLR_RESET} ${CLR_DIM}loaded${CLR_RESET}"
    echo "  ${ICON_SHELL}  ${CLR_DIM}Shell:${CLR_RESET}  search env git docker"
    echo "  ${ICON_PYTHON}  ${CLR_DIM}Python:${CLR_RESET} SDK (future)"
    echo "  ${ICON_CPP}  ${CLR_DIM}C/C++:${CLR_RESET}  SDK (future)"
    echo "  ${LOGO_OS_COLOR}${LOGO_OS_SHORT}${CLR_RESET} ${CLR_DIM}OS${CLR_RESET}  ${CLR_BROWN}│${CLR_RESET}  ${ICON_FEDORA} ${CLR_DIM}Fedora${CLR_RESET}"
fi

# ======================================
# OS Detection
# ======================================

# Detecta o sistema operacional e seta LOGO_OS
coffe::detect_os() {
    local os
    os=$(uname -s)

    case "$os" in
        Linux)
            if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || grep -qi microsoft /proc/version 2>/dev/null; then
                LOGO_OS="${ICON_WINDOWS}  WSL"
                LOGO_OS_SHORT="${ICON_WINDOWS}"
                LOGO_OS_COLOR="${CLR_ORANGE}"
            else
                LOGO_OS="${CLR_GREEN}${ICON_LINUX}${CLR_RESET}  ${CLR_GREEN}Linux${CLR_RESET}"
                LOGO_OS_SHORT="${ICON_LINUX}"
                LOGO_OS_COLOR="${CLR_GREEN}"
            fi
            ;;
        Darwin)
            LOGO_OS="$'\uf179'  macOS"
            LOGO_OS_SHORT="$'\uf179'"
            LOGO_OS_COLOR="${CLR_DIM}"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            LOGO_OS="${ICON_WINDOWS}  Windows"
            LOGO_OS_SHORT="${ICON_WINDOWS}"
            LOGO_OS_COLOR="${CLR_BLUE}"
            ;;
        *)
            LOGO_OS="${CLR_GREEN}${ICON_LINUX}${CLR_RESET}  ${CLR_GREEN}Linux${CLR_RESET}"
            LOGO_OS_SHORT="${ICON_LINUX}"
            LOGO_OS_COLOR="${CLR_GREEN}"
            ;;
    esac

    export LOGO_OS LOGO_OS_SHORT LOGO_OS_COLOR
}

# Roda detecção na inicialização
coffe::detect_os

# ======================================
# Utilitários globais
# ======================================

# Limpa o terminal e posiciona no topo
coffe::clear() {
    clear
}

# ======================================
# CLI dispatcher
# ======================================
# Uso: coffe <search|search-in|env|git|docker|ssh|packages> [args...]

coffe() {
    local cmd="${1:-}"
    [[ -z "$cmd" ]] && {
        echo ""
        echo "  ${CLR_DIM}──${CLR_RESET} ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET} ${CLR_LIGHT_BLUE}coffee${CLR_RESET} ${CLR_DIM}  ${CLR_RESET}${LOGO_OS_COLOR}${LOGO_OS_SHORT}${CLR_RESET}${CLR_DIM}  ─────────────────────────────────${CLR_RESET}"
        echo ""
        echo "  ${CLR_CARAMEL}search <query>      ${CLR_RESET} ${CLR_DIM}search files${CLR_RESET}"
        echo "  ${CLR_CARAMEL}search-in <pattern> ${CLR_RESET} ${CLR_DIM}search file contents${CLR_RESET}"
        echo "  ${CLR_CARAMEL}env                 ${CLR_RESET} ${CLR_DIM}environment variable manager${CLR_RESET}"
        echo "  ${CLR_CARAMEL}git                 ${CLR_RESET} ${CLR_DIM}git workflow helpers${CLR_RESET}"
        echo "  ${CLR_CARAMEL}docker              ${CLR_RESET} ${CLR_DIM}docker container tools${CLR_RESET}"
        echo "  ${CLR_CARAMEL}ssh                 ${CLR_RESET} ${CLR_DIM}ssh agent manager${CLR_RESET}"
        echo "  ${CLR_CARAMEL}packages            ${CLR_RESET} ${CLR_DIM}check/install system dependencies${CLR_RESET}"
        echo "  ${CLR_CARAMEL}version             ${CLR_RESET} ${CLR_DIM}show version info${CLR_RESET}"
        echo ""
        return 1
    }
    shift

    case "$cmd" in
        search)    coffe::search "$@" ;;
        search_in) coffe::search_in "$@" ;;
        env)       coffe::env "$@" ;;
        git)       coffe::git "$@" ;;
        docker)    coffe::docker "$@" ;;
        ssh)       coffe::ssh "$@" ;;
        packages)  coffe::packages::install "$@" ;;
        version)   version ;;
        *)
            echo "${ICON_CLOSE} ${CLR_ORANGE}Unknown command:${CLR_RESET} ${CLR_BOLD}$cmd${CLR_RESET}" >&2
            echo "  ${ICON_SEARCH} Try: ${CLR_DIM}coffe <search|search-in|env|git|docker|packages|version>${CLR_RESET}" >&2
            return 1
            ;;
    esac
}
