#!/usr/bin/env zsh
# shell=zsh
#
# path.zsh — Paths globais de ambiente.
#
# Gerencia entradas nomeadas NAME=PATH em $PATHS_CONF (config/paths.conf).
# Os paths são armazenados EXPANDIDOS (absolute), prontos para consumo
# por scripts/Rust sem nenhuma transformação extra. O shell aplica essas
# entradas no PATH em todo login (ver loader de ~/.zsh/modules/env.zsh).
#
# Interface máquina (Rust/scripts — stdout limpo, 1 item por linha):
#   coffe path                → help
#   coffe path list           → NAME=PATH (como armazenado)
#   coffe path list --paths   → só os paths (1 por linha, p/ montar PATH)
#   coffe path get <name>     → path do nome
#   coffe path add <name> <path>  → adiciona/atualiza (UI vai pra stderr)
#   coffe path remove <name>  → remove a entrada
#   coffe path file           → caminho do arquivo de config
#
# TTY sem args: `coffe path add` pergunta o nome e o path interativamente.
#
# Depende de: ui/icons.sh (ICON_*), ui/colors/ansi_colors.sh (CLR_*),
#             grep, sed

# Local do config: usa COFFE_PATHS_CONF (exportado pelo shell em
# ~/.zsh/envaroment/global.zsh) se definido; senão, o padrão do SDK.
PATHS_CONF="${COFFE_PATHS_CONF:-${COFFE_SDK_ROOT:-$HOME/.coffe-sdk-shell}/config/paths.conf}"

# ============================================================
# Helpers (privados)
# ============================================================

# Valida nome de entrada (letras, números e underscore)
coffe::path::_valid_name() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

# Expande ~ e $HOME para caminho absoluto
coffe::path::_expand() {
    local p="$1"
    if [[ "$p" == "~"* ]]; then
        p="$HOME${p#\~}"
    fi
    p="${p//\$HOME/$HOME}"
    print -r -- "$p"
}

# Linhas válidas NAME=PATH do arquivo de config (ignora comentários)
coffe::path::_entries() {
    [[ -f "$PATHS_CONF" ]] || return 1
    grep -E "^[a-zA-Z_][a-zA-Z0-9_]*=" "$PATHS_CONF" 2>/dev/null
}

# ============================================================
# Comandos
# ============================================================

coffe::path::list() {
    local paths_only=false arg
    for arg in "$@"; do
        [[ "$arg" == "--paths" ]] && paths_only=true
    done

    local entries
    entries=$(coffe::path::_entries)

    if [[ -z "$entries" ]]; then
        print -P "${ICON_BAN} No paths found in $PATHS_CONF" >&2
        return 1
    fi

    if [[ "$paths_only" == true ]]; then
        local line
        while IFS= read -r line; do
            print -r -- "${line#*=}"
        done <<< "$entries"
    else
        print -r -- "$entries"
    fi
}

coffe::path::get() {
    local name="$1"

    if [[ -z "$name" ]]; then
        print -P "${ICON_BAN} Uso: coffe path get <name>" >&2
        return 1
    fi

    local line
    line=$(grep -E "^${name}=" "$PATHS_CONF" 2>/dev/null | tail -n1)

    if [[ -z "$line" ]]; then
        print -P "${ICON_CLOSE} Not found: $name" >&2
        return 1
    fi

    print -r -- "${line#*=}"
}

coffe::path::add() {
    local name="${1:-}"
    local path="${2:-}"

    # Modo interativo (TTY): pergunta o nome e o path
    if [[ -z "$name" ]]; then
        if [[ ! -t 0 ]]; then
            print -P "${ICON_BAN} Uso: coffe path add <name> <path>" >&2
            return 1
        fi

        print -P "\n  ${ICON_PIN} ${CLR_BOLD}${CLR_BLUE}Add Global Path${CLR_RESET}\n" >&2

        while [[ -z "$name" ]]; do
            print -n "  ${ICON_TAG} ${CLR_BLUE}Nome${CLR_RESET}: " >&2
            read -r name
            if [[ -z "$name" ]]; then
                print -P "  ${ICON_BAN} ${CLR_RED}Nome não pode ser vazio${CLR_RESET}" >&2
            elif ! coffe::path::_valid_name "$name"; then
                print -P "  ${ICON_BAN} ${CLR_RED}Nome inválido. Use letras, números e _${CLR_RESET}" >&2
                name=""
            fi
        done

        print -n "  ${ICON_FOLDER_OPEN} ${CLR_BLUE}Path${CLR_RESET}: " >&2
        read -r path

        print "" >&2
    fi

    # Modo máquina: args diretos — validação sem loop
    if [[ -z "$name" || -z "$path" ]]; then
        print -P "${ICON_BAN} Uso: coffe path add <name> <path>" >&2
        return 1
    fi

    if ! coffe::path::_valid_name "$name"; then
        print -P "  ${ICON_BAN} ${CLR_RED}Nome inválido: $name (use letras, números e _)${CLR_RESET}" >&2
        return 1
    fi

    path=$(coffe::path::_expand "$path")
    mkdir -p "${PATHS_CONF:h}" 2>/dev/null || true

    if grep -q "^${name}=" "$PATHS_CONF" 2>/dev/null; then
        # entrada existente → atualiza
        sed -i "s|^${name}=.*|${name}=${path}|" "$PATHS_CONF"
        print -P "  $(coffe::coffee_icon) ${CLR_CARAMEL}Path ${CLR_BOLD}$name${CLR_RESET}${CLR_CARAMEL} atualizado:${CLR_RESET} $path" >&2
    else
        print "${name}=${path}" >> "$PATHS_CONF"
        print -P "  $(coffe::coffee_icon) ${CLR_GREEN}Path ${CLR_BOLD}$name${CLR_RESET}${CLR_GREEN} adicionado:${CLR_RESET} $path" >&2
    fi

    print -P "  ${ICON_LINK} ${CLR_DIM}active na próxima sessão (ver ~/.zsh/envaroment/global.zsh)${CLR_RESET}" >&2
    return 0
}

coffe::path::remove() {
    local name="$1"

    if [[ -z "$name" ]]; then
        print -P "${ICON_BAN} Uso: coffe path remove <name>" >&2
        return 1
    fi

    if ! grep -q "^${name}=" "$PATHS_CONF" 2>/dev/null; then
        print -P "${ICON_CLOSE} Not found: $name" >&2
        return 1
    fi

    sed -i "/^${name}=/d" "$PATHS_CONF"
    print -P "  $(coffe::coffee_icon) ${CLR_GREEN}Path ${CLR_BOLD}$name${CLR_RESET}${CLR_GREEN} removido${CLR_RESET}" >&2
    return 0
}

# ============================================================
# Dispatcher
# ============================================================

coffe::path() {
    case "${1:-}" in
        list)   shift; coffe::path::list "$@" ;;
        add)    shift; coffe::path::add "$@" ;;
        remove) shift; coffe::path::remove "$@" ;;
        rm)     shift; coffe::path::remove "$@" ;;
        get)    shift; coffe::path::get "$@" ;;
        file)   print -r -- "$PATHS_CONF" ;;
        *)
            print ""
            print -P "  ${CLR_DIM}──${CLR_RESET} ${CLR_BLUE}${ICON_PIN}${CLR_RESET} ${CLR_LIGHT_BLUE}path${CLR_RESET} ${CLR_DIM}────────────────────────────────────${CLR_RESET}"
            print ""
            print -P "  ${CLR_CARAMEL}list [--paths]      ${CLR_RESET} ${CLR_DIM}lista NAME=PATH (ou só paths, p/ scripts)${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}get <name>          ${CLR_RESET} ${CLR_DIM}mostra o path de um nome${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}add [name] [path]   ${CLR_RESET} ${CLR_DIM}adiciona path global (sem args: interativo)${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}remove <name>       ${CLR_RESET} ${CLR_DIM}remove um path global${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}file                ${CLR_RESET} ${CLR_DIM}mostra o arquivo de config (paths.conf)${CLR_RESET}"
            print ""
            ;;
    esac
}
