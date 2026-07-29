#!/usr/bin/env zsh
# shell=zsh
#
# env.zsh — Gerenciamento de arquivos .env.
#
# Depende de: ui/dialogs.sh (ui::select_file)

ENV_ROOT="$HOME/.secrets"

coffe::env::list() {
    if [[ ! -d "$ENV_ROOT" ]]; then
        print -P "${ICON_BAN} No secrets directory found"
        return 1
    fi

    local selected
    selected=$(find "$ENV_ROOT" -type f -name "*.env" \
        | sed "s|$ENV_ROOT/||" \
        | awk -F/ '{printf "%s %-20s %s %s\n", i, $2, a, $0}' i="$ICON_FILE" a="$ICON_ARROW_RIGHT" \
        | fzf \
            --height=60% \
            --border=rounded \
            --prompt="${ICON_FILE} Select ENV > " \
            --pointer="➜" \
            --marker="✓" \
            --preview="echo {} | awk '{print \$NF}' | xargs -I{} sh -c 'echo ${ICON_FILE} File: {}; echo; sed -n \"1,20p\" {}'")

    if [[ -z "$selected" ]]; then
        return
    fi

    local file
    file=$(echo "$selected" | awk '{print $NF}')

    print ""
    print -P "${ICON_FILE} Opening:"
    print "$ENV_ROOT/$file"

    code "$ENV_ROOT/$file"
}

coffe::env::edit() {
    local name="$1"

    local file
    file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)

    if [[ -z "$file" ]]; then
        print -P "${ICON_CLOSE} Not found"
        return 1
    fi

    code "$file"
}

coffe::env::init() {
    typeset -A folders=(
        services   "GitHub Discord Outlook"
        ai         "OpenAI Anthropic OpenRouter"
        databases  "PostgreSQL MySQL SQLite"
        containers "DockerHub"
        cloud      "AWS Azure Cloudflare"
        servers    "SSH"
        local      "Development Personal"
    )

    print -P "${ICON_KEYBOARD} Initializing secrets structure..."

    local folder
    for folder in ${(k)folders}; do
        mkdir -p "$ENV_ROOT/$folder"

        print -P "${ICON_FOLDER} Creating folder: $folder"

        local file
        for file in ${=folders[$folder]}; do
            local path="$ENV_ROOT/$folder/$file.env"

            if [[ ! -f "$path" ]]; then
                cat > "$path" <<EOF
# ======================================
# ${ICON_KEYBOARD} $file Environment
# ======================================

EOF
                chmod 600 "$path"

                print -P "  ${ICON_FILE} Created: $path"
            else
                print -P "  $(coffe::coffee_icon)  ${CLR_DIM}Already exists:${CLR_RESET} $path"
            fi
        done
    done

    print ""
    print -P "$(coffe::coffee_icon)  ${CLR_BOLD}Secrets structure ready!${CLR_RESET}"
    print -P "  ${CLR_DIM}${ICON_LOCATION} Location:${CLR_RESET} $ENV_ROOT"
}

coffe::env::load() {
    local name="$1"

    if [[ -z "$name" ]]; then
        local files
        files=$(find "$ENV_ROOT" -type f -name "*.env")

        if [[ -z "$files" ]]; then
            print -P "${ICON_BAN} No .env files found in $ENV_ROOT"
            return 1
        fi

        local count=0
        while IFS= read -r file; do
            source "$file"
            ((count++))
        done <<< "$files"

        print -P "$(coffe::coffee_icon)  ${CLR_DIM}$count .env files loaded from${CLR_RESET} $ENV_ROOT"
        return
    fi

    local file
    file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)

    if [[ -z "$file" ]]; then
        print -P "${ICON_CLOSE} Not found"
        return 1
    fi

    source "$file"

    print -P "$(coffe::coffee_icon)  ${CLR_DIM}$name loaded${CLR_RESET}"
}

coffe::env::add() {
    local env_root="${ENV_ROOT:-$HOME/.secrets}"

    if [[ ! -d "$env_root" ]]; then
        print -P "  ${ICON_BAN} ${CLR_RED}No secrets directory found${CLR_RESET}"
        return 1
    fi

    local files
    files=$(find "$env_root" -type f -name "*.env" | sed "s|$env_root/||" | sort)

    if [[ -z "$files" ]]; then
        print -P "  ${ICON_BAN} ${CLR_RED}No .env files found. Run ${CLR_BOLD}env init${CLR_RESET}${CLR_RED} first.${CLR_RESET}"
        return 1
    fi

    print -P "\n  ${ICON_KEY} ${CLR_BOLD}${CLR_BLUE}Add Key to .env${CLR_RESET}\n"

    local selected
    selected=$(echo "$files" \
        | awk -F/ '{printf "%s %-20s %s %s\n", i, $2, a, $0}' i="$ICON_FILE" a="$ICON_ARROW_RIGHT" \
        | fzf \
            --height=60% \
            --border=rounded \
            --prompt="${ICON_FILE} Select .env > " \
            --pointer="➜" \
            --marker="✓" \
            --preview="echo {} | awk '{print \$NF}' | xargs -I{} sh -c 'echo ${ICON_FILE} File: {}; echo; sed -n \"1,20p\" $env_root/{}'")

    if [[ -z "$selected" ]]; then
        print -P "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}"
        return
    fi

    local file
    file=$(echo "$selected" | awk '{print $NF}')
    local full_path="$env_root/$file"

    print -P "\n  ${ICON_FILE} ${CLR_CARAMEL}Selected:${CLR_RESET} ${CLR_BOLD}$file${CLR_RESET}\n"

    local key=""
    while [[ -z "$key" ]]; do
        print -n "  ${ICON_TAG} ${CLR_BLUE}Key name${CLR_RESET}: "
        read -r key

        if [[ -z "$key" ]]; then
            print -P "  ${ICON_BAN} ${CLR_RED}Key cannot be empty${CLR_RESET}"
        elif ! [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            print -P "  ${ICON_BAN} ${CLR_RED}Invalid key name. Use letters, numbers, and underscores only${CLR_RESET}"
            key=""
        elif grep -q "^${key}=" "$full_path" 2>/dev/null; then
            print -P "  ${ICON_WARNING} ${CLR_ORANGE}Key '${key}' already exists in $file${CLR_RESET}"
            print -n "  ${CLR_CARAMEL}Overwrite?${CLR_RESET} (y/N): "
            read -r overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                key=""
            fi
        fi
    done

    local value=""
    print -n "  ${ICON_LOCK} ${CLR_BLUE}Token/value${CLR_RESET} ${CLR_DIM}(hidden input)${CLR_RESET}: "
    read -rs value
    print ""

    if [[ -z "$value" ]]; then
        print -P "  ${ICON_BAN} ${CLR_RED}Value cannot be empty${CLR_RESET}"
        return 1
    fi

    print ""
    print -P "  ${ICON_EYE} ${CLR_BOLD}Preview:${CLR_RESET}"
    print -P "    ${CLR_SKY_BLUE}${key}${CLR_RESET}=${CLR_GREEN}\"${value}\"${CLR_RESET}"

    local escaped_file
    escaped_file=$(echo "$file" | sed 's/ /\\ /g')

    print ""
    print -n "  ${ICON_QUESTION} ${CLR_CARAMEL}Add this key to ${CLR_BOLD}$file${CLR_RESET}${CLR_CARAMEL}?${CLR_RESET} (y/N): "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print -P "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}"
        return
    fi

    {
        print ""
        print "# ${key}"
        print "${key}=${value}"
    } >> "$full_path"

    chmod 600 "$full_path"

    print -P "  $(coffe::coffee_icon) ${CLR_GREEN}Key ${CLR_BOLD}${key}${CLR_RESET}${CLR_GREEN} added to ${CLR_BOLD}$file${CLR_RESET}"
    print -P "  ${ICON_SHIELD} ${CLR_DIM}File permissions set to 600${CLR_RESET}"
}

coffe::env::find() {
    local key="$1"

    print ""
    print -P "  ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET}  ${CLR_LIGHT_BLUE}env${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}search${CLR_RESET}"

    if [[ -z "$key" ]]; then
        print ""
        print -P "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}specify a key to search${CLR_RESET}"
        print ""
        return 1
    fi

    if ! command -v rg &>/dev/null; then
        print ""
        print -P "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}rg (ripgrep) not found${CLR_RESET}"
        print -P "  ${CLR_DIM}${ICON_TOOLS}${CLR_RESET}  ${CLR_CARAMEL}sudo dnf install ripgrep${CLR_RESET}"
        print ""
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
        print ""
        print -P "  ${CLR_DIM}${ICON_BAN}${CLR_RESET}  ${CLR_RED}no .env sources found${CLR_RESET}"
        print -P "  ${CLR_DIM}       ${ENV_ROOT} missing and no local .env${CLR_RESET}"
        print ""
        return 1
    fi

    local all_results=""
    local dir
    for dir in "${search_dirs[@]}"; do
        local results
        results=$(rg -in "^[^=]*${key}[^=]*=" "$dir" --glob "*.env" 2>&1)
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
        print ""
        print -P "  ${CLR_DIM}${ICON_SEARCH}${CLR_RESET}  ${CLR_CARAMEL}${CLR_BOLD}\"${key}\"${CLR_RESET}  ${CLR_DIM}·${CLR_RESET}  ${CLR_RED}✗${CLR_RESET}  ${CLR_DIM}no matches${CLR_RESET}"
        print ""
        return 1
    fi

    print ""
    print -P "  ${CLR_DIM}${ICON_SEARCH}${CLR_RESET}  ${CLR_CARAMEL}${CLR_BOLD}\"${key}\"${CLR_RESET}  ${CLR_DIM}·${CLR_RESET}  ${CLR_LIGHT_BLUE}${match_label}${CLR_RESET}"
    print ""

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

        print -P "  ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET}  ${CLR_CARAMEL}${display_path}${CLR_RESET}  ${CLR_DIM} ${line_num}${CLR_RESET}"
        print -P "     ${CLR_SKY_BLUE}${key_name}${CLR_RESET}  ${CLR_DIM}=${CLR_RESET}  ${CLR_GREEN}${value}${CLR_RESET}"
        print ""
    done
}

coffe::env() {
    case "${1:-}" in
        list)   coffe::env::list ;;
        init)   coffe::env::init ;;
        edit)   shift; coffe::env::edit "$@" ;;
        load)   shift; coffe::env::load "$@" ;;
        add)    coffe::env::add ;;
        find)   shift; coffe::env::find "$@" ;;
        search) shift; coffe::env::find "$@" ;;
        *)
            print ""
            print -P "  ${CLR_DIM}──${CLR_RESET} ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET} ${CLR_LIGHT_BLUE}env${CLR_RESET} ${CLR_DIM}────────────────────────────────────${CLR_RESET}"
            print ""
            print -P "  ${CLR_CARAMEL}list               ${CLR_RESET} ${CLR_DIM}list all .env files${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}init               ${CLR_RESET} ${CLR_DIM}initialize secrets structure${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}edit <name>        ${CLR_RESET} ${CLR_DIM}edit a .env file${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}load [name]        ${CLR_RESET} ${CLR_DIM}load .env files into shell${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}add                ${CLR_RESET} ${CLR_DIM}add a key to a .env${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}find <key>         ${CLR_RESET} ${CLR_DIM}search for a key across .env files${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}search <key>       ${CLR_RESET} ${CLR_DIM}alias for find${CLR_RESET}"
            print ""
            ;;
    esac
}
