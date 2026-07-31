#!/usr/bin/env bash
# shell=bash
#
# env.sh — Gerenciamento de variáveis de ambiente.
#
# Estrutura (ENV_ROOT, padrão: ~/.secrets):
#   global.sh              → variáveis gerais (carregado sempre)
#   <categoria>/<nome>.env → segredos por serviço
#     DB, Projects, Code_Agents, Services, AI, Cloud, Containers, Servers
#
# Raiz configurável (prioridade):
#   1. $COFFE_ENV_ROOT (env var)
#   2. $COFFE_SDK_ROOT/config/env.conf  (definido por `coffe env root <path>`)
#   3. ~/.secrets (padrão)
#
# Interface máquina (Rust/scripts — stdout limpo, 1 item por linha):
#   coffe env root                 → raiz atual
#   coffe env list [cat] [--full]  → caminhos relativos (absolutos com --full)
#   coffe env select [cat]         → TTY: fzf e imprime o escolhido (absoluto)
#                                    sem TTY: imprime todos os candidatos (absolutos)
#   coffe env load <nome>          → precisa de `source` no shell
#
# Depende de: ui/icons.sh (ICON_*), ui/colors/ansi_colors.sh (CLR_*),
#             fzf, rg, find, sed, code

ENV_CONF="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk-shell}/config/env.conf"

# ============================================================
# Helpers (privados)
# ============================================================

# Raiz padrão: config persistido tem prioridade sobre ~/.secrets
coffe::env::_default_root() {
    if [[ -f "$ENV_CONF" ]]; then
        local line
        line=$(grep -E "^ENV_ROOT=" "$ENV_CONF" 2>/dev/null | tail -n1)
        if [[ -n "$line" ]]; then
            printf '%s\n' "${line#ENV_ROOT=}"
            return
        fi
    fi
    printf '%s\n' "$HOME/.secrets"
}

# Raiz efetiva (resolvida no load do módulo)
ENV_ROOT="${COFFE_ENV_ROOT:-$(coffe::env::_default_root)}"

# Lista arquivos de env (relativos a ENV_ROOT), incluindo global.sh.
# Com categoria, lista só os .env daquela categoria.
coffe::env::_files() {
    local categoria="$1"

    if [[ -n "$categoria" ]]; then
        find "$ENV_ROOT/$categoria" -type f -name "*.env" 2>/dev/null \
            | sed "s|$ENV_ROOT/||" \
            | sort
    else
        find "$ENV_ROOT" \( -type f -name "*.env" -o -name "global.sh" \) 2>/dev/null \
            | sed "s|$ENV_ROOT/||" \
            | sort
    fi
}

# Seleciona um arquivo de env via fzf.
# Retorna a linha selecionada (última coluna = caminho relativo)
# ou vazio se o usuário cancelar.
coffe::env::_pick_file() {
    local files="$1"
    [[ -z "$files" ]] && return 1

    echo "$files" \
        | awk -F/ '{ if (NF == 1) printf "%s %-20s %s %s\n", i, $1, a, $0; else printf "%s %-20s %s %s\n", i, $2, a, $0 }' i="$ICON_FILE" a="$ICON_ARROW_RIGHT" \
        | fzf \
            --height=60% \
            --border=rounded \
            --prompt="${ICON_FILE} Select ENV > " \
            --pointer="➜" \
            --marker="✓" \
            --preview="echo {} | awk '{print \$NF}' | xargs -I{} sh -c 'echo ${ICON_FILE} File: {}; echo; sed -n \"1,20p\" $ENV_ROOT/{}'"
}

# Valida nome de chave (letras, números e underscore)
coffe::env::_valid_key() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}

# Mensagem padrão de arquivo não encontrado
coffe::env::_not_found() {
    echo "${ICON_CLOSE} Not found: $1" >&2
}

# Carrega um arquivo de env no shell atual
coffe::env::_load_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    source "$file"
}

# Renderiza resultados do rg (formato: arquivo:linha:conteudo)
coffe::env::_render_results() {
    local all_results="$1"

    echo "$all_results" | while IFS= read -r line; do
        local file="${line%%:*}"
        local rest="${line#*:}"
        local line_num="${rest%%:*}"
        local content="${rest#*:}"

        local display_path="$file"
        if [[ "$file" == "$ENV_ROOT"* ]]; then
            display_path="~${file#$HOME}"
        fi

        local key_name="${content%%=*}"
        local value="${content#*=}"

        echo "  ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET}  ${CLR_CARAMEL}${display_path}${CLR_RESET}  ${CLR_DIM} ${line_num}${CLR_RESET}"
        echo "     ${CLR_SKY_BLUE}${key_name}${CLR_RESET}  ${CLR_DIM}=${CLR_RESET}  ${CLR_GREEN}${value}${CLR_RESET}"
        echo ""
    done
}

# ============================================================
# Comandos
# ============================================================

# Mostra ou define a raiz dos envs (persistido em config/env.conf)
coffe::env::root() {
    local path="$1"

    if [[ -n "$path" ]]; then
        path="${path%/}"
        mkdir -p "$path" 2>/dev/null || true

        if [[ -f "$ENV_CONF" ]]; then
            sed -i "s|^ENV_ROOT=.*|ENV_ROOT=$path|" "$ENV_CONF" 2>/dev/null || true
            grep -q "^ENV_ROOT=" "$ENV_CONF" 2>/dev/null || echo "ENV_ROOT=$path" >> "$ENV_CONF"
        else
            mkdir -p "$(dirname "$ENV_CONF")" 2>/dev/null || true
            echo "ENV_ROOT=$path" > "$ENV_CONF"
        fi

        ENV_ROOT="$path"
        echo "  $(coffe::coffee_icon) ${CLR_GREEN}ENV_ROOT=${CLR_BOLD}$path${CLR_RESET}${CLR_GREEN} (persistido em $ENV_CONF)${CLR_RESET}" >&2
        return 0
    fi

    printf '%s\n' "$ENV_ROOT"
}

# Lista os arquivos de env (saída máquina: 1 por linha)
coffe::env::list() {
    if [[ ! -d "$ENV_ROOT" ]]; then
        echo "${ICON_BAN} No secrets directory found" >&2
        return 1
    fi

    local categoria="" full=false arg
    for arg in "$@"; do
        case "$arg" in
            --full) full=true ;;
            *) categoria="$arg" ;;
        esac
    done

    local files
    files=$(coffe::env::_files "$categoria")

    if [[ -z "$files" ]]; then
        echo "${ICON_BAN} No env files found in $ENV_ROOT${categoria:+/$categoria}" >&2
        return 1
    fi

    if [[ "$full" == true ]]; then
        local f
        while IFS= read -r f; do
            printf '%s\n' "$ENV_ROOT/$f"
        done <<< "$files"
    else
        printf '%s\n' "$files"
    fi
}

# Seleciona um arquivo de env.
# TTY: fzf interativo → imprime o caminho ABSOLUTO do escolhido.
# Sem TTY (Rust/script): imprime todos os candidatos absolutos, 1 por linha.
coffe::env::select() {
    local categoria="$1"
    local files
    files=$(coffe::env::_files "$categoria")

    if [[ -z "$files" ]]; then
        echo "${ICON_BAN} No env files found in $ENV_ROOT${categoria:+/$categoria}" >&2
        return 1
    fi

    # modo máquina: stdout não é TTY → lista candidatos absolutos
    if [[ ! -t 1 ]]; then
        local f
        while IFS= read -r f; do
            printf '%s\n' "$ENV_ROOT/$f"
        done <<< "$files"
        return 0
    fi

    # modo interativo: fzf
    local selected
    selected=$(coffe::env::_pick_file "$files")
    [[ -z "$selected" ]] && return 1

    local rel_file
    rel_file=$(echo "$selected" | awk '{print $NF}')
    printf '%s\n' "$ENV_ROOT/$rel_file"
}

coffe::env::edit() {
    local name="$1"
    local file="$ENV_ROOT/global.sh"

    if [[ -n "$name" && "$name" != "global" ]]; then
        file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)
    fi

    if [[ ! -f "$file" ]]; then
        coffe::env::_not_found "${name:-global}"
        return 1
    fi

    code "$file"
}

coffe::env::init() {
    declare -A folders=(
        ["DB"]="PostgreSQL MySQL SQLite"
        ["Projects"]="Development Personal"
        ["Code_Agents"]="OpenCode Claude"
        ["Services"]="GitHub Discord Outlook"
        ["AI"]="OpenAI Anthropic OpenRouter"
        ["Cloud"]="AWS Azure Cloudflare"
        ["Containers"]="DockerHub"
        ["Servers"]="SSH"
    )

    echo "${ICON_KEYBOARD} Initializing secrets structure..."

    local folder file target
    for folder in "${!folders[@]}"; do
        mkdir -p "$ENV_ROOT/$folder"

        echo "${ICON_FOLDER} Creating folder: $folder"

        for file in ${folders[$folder]}; do
            target="$ENV_ROOT/$folder/$file.env"

            if [[ ! -f "$target" ]]; then
                cat > "$target" <<EOF
# ======================================
# ${ICON_KEYBOARD} $file Environment
# ======================================

EOF
                chmod 600 "$target"

                echo "  ${ICON_FILE} Created: $target"
            else
                echo "  $(coffe::coffee_icon)  ${CLR_DIM}Already exists:${CLR_RESET} $target"
            fi
        done
    done

    # global.sh — variáveis gerais (carregado antes dos segredos)
    if [[ ! -f "$ENV_ROOT/global.sh" ]]; then
        cat > "$ENV_ROOT/global.sh" <<EOF
# ======================================
# ${ICON_GLOBE} Global Environment Variables
# Variáveis gerais — carregadas antes dos segredos.
# Ex.: PATH, EDITOR, LESS, configurações locais.
# ======================================

EOF
        chmod 600 "$ENV_ROOT/global.sh"

        echo "  ${ICON_FILE} Created: $ENV_ROOT/global.sh"
    fi

    echo ""
    echo "$(coffe::coffee_icon)  ${CLR_BOLD}Secrets structure ready!${CLR_RESET}"
    echo "  ${CLR_DIM}${ICON_LOCATION} Location:${CLR_RESET} $ENV_ROOT"
}

coffe::env::load() {
    local name="$1"

    if [[ -z "$name" ]]; then
        local files
        files=$(find "$ENV_ROOT" -type f -name "*.env" 2>/dev/null)

        if [[ -z "$files" && ! -f "$ENV_ROOT/global.sh" ]]; then
            echo "${ICON_BAN} No .env files found in $ENV_ROOT" >&2
            return 1
        fi

        local file
        local count=0

        # variáveis gerais primeiro
        if [[ -f "$ENV_ROOT/global.sh" ]]; then
            source "$ENV_ROOT/global.sh"
            ((count += 1))
        fi

        while IFS= read -r file; do
            source "$file"
            ((count += 1))
        done <<< "$files"

        echo "$(coffe::coffee_icon)  ${CLR_DIM}$count env files loaded from${CLR_RESET} $ENV_ROOT"
        return
    fi

    if [[ "$name" == "global" ]]; then
        if [[ ! -f "$ENV_ROOT/global.sh" ]]; then
            coffe::env::_not_found "global"
            return 1
        fi

        source "$ENV_ROOT/global.sh"
        echo "$(coffe::coffee_icon)  ${CLR_DIM}global loaded${CLR_RESET}"
        return
    fi

    local file
    file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)

    if [[ -z "$file" ]]; then
        coffe::env::_not_found "$name"
        return 1
    fi

    source "$file"
    echo "$(coffe::coffee_icon)  ${CLR_DIM}$name loaded${CLR_RESET}"
}

coffe::env::add() {
    local env_root="$ENV_ROOT"

    if [[ ! -d "$env_root" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}No secrets directory found${CLR_RESET}" >&2
        return 1
    fi

    local files
    files=$(coffe::env::_files)

    if [[ -z "$files" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}No .env files found. Run ${CLR_BOLD}env init${CLR_RESET}${CLR_RED} first.${CLR_RESET}" >&2
        return 1
    fi

    echo -e "\n  ${ICON_KEY} ${CLR_BOLD}${CLR_BLUE}Add Key to .env${CLR_RESET}\n" >&2

    local selected
    selected=$(coffe::env::_pick_file "$files")
    [[ -z "$selected" ]] && { echo -e "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}" >&2; return; }

    local rel_file
    rel_file=$(echo "$selected" | awk '{print $NF}')
    local full_path="$env_root/$rel_file"

    echo -e "\n  ${ICON_FILE} ${CLR_CARAMEL}Selected:${CLR_RESET} ${CLR_BOLD}$rel_file${CLR_RESET}\n" >&2

    local key=""
    while [[ -z "$key" ]]; do
        echo -ne "  ${ICON_TAG} ${CLR_BLUE}Key name${CLR_RESET}: " >&2
        read -r key

        if [[ -z "$key" ]]; then
            echo -e "  ${ICON_BAN} ${CLR_RED}Key cannot be empty${CLR_RESET}" >&2
        elif ! coffe::env::_valid_key "$key"; then
            echo -e "  ${ICON_BAN} ${CLR_RED}Invalid key name. Use letters, numbers, and underscores only${CLR_RESET}" >&2
            key=""
        elif grep -q "^${key}=" "$full_path" 2>/dev/null; then
            echo -e "  ${ICON_WARNING} ${CLR_ORANGE}Key '${key}' already exists in $rel_file${CLR_RESET}" >&2
            echo -ne "  ${CLR_CARAMEL}Overwrite?${CLR_RESET} (y/N): " >&2
            read -r overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                key=""
            fi
        fi
    done

    local value=""
    echo -ne "  ${ICON_LOCK} ${CLR_BLUE}Token/value${CLR_RESET} ${CLR_DIM}(hidden input)${CLR_RESET}: " >&2
    read -rs value
    echo "" >&2

    if [[ -z "$value" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}Value cannot be empty${CLR_RESET}" >&2
        return 1
    fi

    echo "" >&2
    echo -e "  ${ICON_EYE} ${CLR_BOLD}Preview:${CLR_RESET}" >&2
    echo -e "    ${CLR_SKY_BLUE}${key}${CLR_RESET}=${CLR_GREEN}\"${value}\"${CLR_RESET}" >&2

    echo "" >&2
    echo -ne "  ${ICON_QUESTION} ${CLR_CARAMEL}Add this key to ${CLR_BOLD}$rel_file${CLR_RESET}${CLR_CARAMEL}?${CLR_RESET} (y/N): " >&2
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}" >&2
        return
    fi

    {
        echo ""
        echo "# ${key}"
        echo "${key}=${value}"
    } >> "$full_path"

    chmod 600 "$full_path"

    echo -e "  $(coffe::coffee_icon) ${CLR_GREEN}Key ${CLR_BOLD}${key}${CLR_RESET}${CLR_GREEN} added to ${CLR_BOLD}$rel_file${CLR_RESET}" >&2
    echo -e "  ${ICON_SHIELD} ${CLR_DIM}File permissions set to 600${CLR_RESET}" >&2
}

coffe::env::find() {
    local key="$1"

    echo ""
    echo "  ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET}  ${CLR_LIGHT_BLUE}env${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}search${CLR_RESET}"

    if [[ -z "$key" ]]; then
        echo ""
        echo "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}specify a key to search${CLR_RESET}"
        echo ""
        return 1
    fi

    if ! command -v rg &>/dev/null; then
        echo ""
        echo "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}rg (ripgrep) not found${CLR_RESET}"
        echo "  ${CLR_DIM}${ICON_TOOLS}${CLR_RESET}  ${CLR_CARAMEL}sudo dnf install ripgrep${CLR_RESET}"
        echo ""
        return 1
    fi

    local search_dirs=()
    if [[ -d "$ENV_ROOT" ]]; then
        search_dirs+=("$ENV_ROOT")
    fi
    if [[ -f ".env" ]]; then
        search_dirs+=(".")
    fi

    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        echo ""
        echo "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}no .env sources found${CLR_RESET}"
        echo "  ${CLR_DIM}       ${ENV_ROOT} missing and no local .env${CLR_RESET}"
        echo ""
        return 1
    fi

    local all_results=""
    local dir results
    for dir in "${search_dirs[@]}"; do
        results=$(rg -in "^[^=]*${key}[^=]*=" "$dir" --glob "*.env" --glob "global.sh" 2>&1)
        if [[ -n "$results" ]]; then
            all_results="$all_results"$'\n'"$results"
        fi
    done

    all_results=$(echo "$all_results" | sed '/^$/d')

    local count
    count=$(echo "$all_results" | wc -l)
    local plural=""
    (( count > 1 )) && plural="s"
    local match_label="${count} match${plural}"

    if [[ -z "$all_results" || "$count" -eq 0 ]]; then
        echo ""
        echo "  ${CLR_DIM}${ICON_SEARCH}${CLR_RESET}  ${CLR_CARAMEL}${CLR_BOLD}\"${key}\"${CLR_RESET}  ${CLR_DIM}·${CLR_RESET}  ${CLR_RED}✗${CLR_RESET}  ${CLR_DIM}no matches${CLR_RESET}"
        echo ""
        return 1
    fi

    echo ""
    echo "  ${CLR_DIM}${ICON_SEARCH}${CLR_RESET}  ${CLR_CARAMEL}${CLR_BOLD}\"${key}\"${CLR_RESET}  ${CLR_DIM}·${CLR_RESET}  ${CLR_LIGHT_BLUE}${match_label}${CLR_RESET}"
    echo ""

    coffe::env::_render_results "$all_results"
}

coffe::env() {
    case "${1:-}" in
        root)   shift; coffe::env::root "$@" ;;
        list)   shift; coffe::env::list "$@" ;;
        select) shift; coffe::env::select "$@" ;;
        init)   coffe::env::init ;;
        edit)   shift; coffe::env::edit "$@" ;;
        load)   shift; coffe::env::load "$@" ;;
        add)    coffe::env::add ;;
        find)   shift; coffe::env::find "$@" ;;
        search) shift; coffe::env::find "$@" ;;
        *)
            echo ""
            echo "  ${CLR_DIM}──${CLR_RESET} ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET} ${CLR_LIGHT_BLUE}env${CLR_RESET} ${CLR_DIM}────────────────────────────────────${CLR_RESET}"
            echo ""
            echo "  ${CLR_CARAMEL}root [path]         ${CLR_RESET} ${CLR_DIM}mostra/define a raiz dos envs (persistente)${CLR_RESET}"
            echo "  ${CLR_CARAMEL}list [cat] [--full] ${CLR_RESET} ${CLR_DIM}lista arquivos (1 por linha, p/ scripts)${CLR_RESET}"
            echo "  ${CLR_CARAMEL}select [cat]        ${CLR_RESET} ${CLR_DIM}seleciona arquivo (fzf; sem TTY lista)${CLR_RESET}"
            echo "  ${CLR_CARAMEL}init                ${CLR_RESET} ${CLR_DIM}cria estrutura de categorias + global.sh${CLR_RESET}"
            echo "  ${CLR_CARAMEL}edit [name]         ${CLR_RESET} ${CLR_DIM}edita global.sh (padrão) ou <name>.env${CLR_RESET}"
            echo "  ${CLR_CARAMEL}load [name]         ${CLR_RESET} ${CLR_DIM}carrega global.sh + .env, ou um específico${CLR_RESET}"
            echo "  ${CLR_CARAMEL}add                 ${CLR_RESET} ${CLR_DIM}adiciona chave a um arquivo${CLR_RESET}"
            echo "  ${CLR_CARAMEL}find <key>          ${CLR_RESET} ${CLR_DIM}busca chave entre os arquivos${CLR_RESET}"
            echo "  ${CLR_CARAMEL}search <key>        ${CLR_RESET} ${CLR_DIM}alias para find${CLR_RESET}"
            echo ""
            ;;
    esac
}
