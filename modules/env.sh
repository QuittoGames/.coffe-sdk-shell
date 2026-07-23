#!/usr/bin/env bash
# shell=bash
#
# env.sh — Gerenciamento de arquivos .env.
#
# Depende de: ui/dialogs.sh (ui::select_file)

ENV_ROOT="$HOME/.secrets"

coffe::env::list() {
    if [[ ! -d "$ENV_ROOT" ]]; then
        echo "${ICON_BAN} No secrets directory found"
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

    echo ""
    echo "${ICON_FILE} Opening:"
    echo "$ENV_ROOT/$file"

    code "$ENV_ROOT/$file"
}

coffe::env::edit() {
    local name="$1"

    local file
    file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)

    if [[ -z "$file" ]]; then
        echo "${ICON_CLOSE} Not found"
        return 1
    fi

    code "$file"
}

coffe::env::create() {
    declare -A folders=(
        ["services"]="GitHub Discord Outlook"
        ["ai"]="OpenAI Anthropic OpenRouter"
        ["databases"]="PostgreSQL MySQL SQLite"
        ["containers"]="DockerHub"
        ["cloud"]="AWS Azure Cloudflare"
        ["servers"]="SSH"
        ["local"]="Development Personal"
    )

    echo "${ICON_KEYBOARD} Initializing secrets structure..."

    for folder in "${!folders[@]}"; do
        mkdir -p "$ENV_ROOT/$folder"

        echo "${ICON_FOLDER} Creating folder: $folder"

        for file in ${folders[$folder]}; do
            local path="$ENV_ROOT/$folder/$file.env"

            if [[ ! -f "$path" ]]; then
                cat > "$path" <<EOF
# ======================================
# ${ICON_KEYBOARD} $file Environment
# ======================================

EOF
                chmod 600 "$path"

                echo "  ${ICON_FILE} Created: $path"
            else
                echo "  ${ICON_CHECK} Already exists: $path"
            fi
        done
    done

    echo ""
    echo "${ICON_CHECK} Secrets structure ready!"
    echo "${ICON_LOCATION} Location: $ENV_ROOT"
}

coffe::env::load() {
    local name="$1"

    local file
    file=$(find "$ENV_ROOT" -name "$name.env" | head -n1)

    if [[ -z "$file" ]]; then
        echo "${ICON_CLOSE} Not found"
        return 1
    fi

    source "$file"

    echo "${ICON_CHECK} $name loaded"
}

coffe::env::add() {
    local env_root="${ENV_ROOT:-$HOME/.secrets}"

    if [[ ! -d "$env_root" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}No secrets directory found${CLR_RESET}"
        return 1
    fi

    local files
    files=$(find "$env_root" -type f -name "*.env" | sed "s|$env_root/||" | sort)

    if [[ -z "$files" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}No .env files found. Run ${CLR_BOLD}env create${CLR_RESET}${CLR_RED} first.${CLR_RESET}"
        return 1
    fi

    echo -e "\n  ${ICON_KEY} ${CLR_BOLD}${CLR_BLUE}Add Key to .env${CLR_RESET}\n"

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
        echo -e "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}"
        return
    fi

    local file
    file=$(echo "$selected" | awk '{print $NF}')
    local full_path="$env_root/$file"

    echo -e "\n  ${ICON_FILE} ${CLR_CARAMEL}Selected:${CLR_RESET} ${CLR_BOLD}$file${CLR_RESET}\n"

    local key=""
    while [[ -z "$key" ]]; do
        echo -ne "  ${ICON_TAG} ${CLR_BLUE}Key name${CLR_RESET}: "
        read -r key

        if [[ -z "$key" ]]; then
            echo -e "  ${ICON_BAN} ${CLR_RED}Key cannot be empty${CLR_RESET}"
        elif ! [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo -e "  ${ICON_BAN} ${CLR_RED}Invalid key name. Use letters, numbers, and underscores only${CLR_RESET}"
            key=""
        elif grep -q "^${key}=" "$full_path" 2>/dev/null; then
            echo -e "  ${ICON_WARNING} ${CLR_ORANGE}Key '${key}' already exists in $file${CLR_RESET}"
            echo -ne "  ${CLR_CARAMEL}Overwrite?${CLR_RESET} (y/N): "
            read -r overwrite
            if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
                key=""
            fi
        fi
    done

    local value=""
    echo -ne "  ${ICON_LOCK} ${CLR_BLUE}Token/value${CLR_RESET} ${CLR_DIM}(hidden input)${CLR_RESET}: "
    read -rs value
    echo ""

    if [[ -z "$value" ]]; then
        echo -e "  ${ICON_BAN} ${CLR_RED}Value cannot be empty${CLR_RESET}"
        return 1
    fi

    echo ""
    echo -e "  ${ICON_EYE} ${CLR_BOLD}Preview:${CLR_RESET}"
    echo -e "    ${CLR_SKY_BLUE}${key}${CLR_RESET}=${CLR_GREEN}\"${value}\"${CLR_RESET}"

    local escaped_file
    escaped_file=$(echo "$file" | sed 's/ /\\ /g')

    echo ""
    echo -ne "  ${ICON_QUESTION} ${CLR_CARAMEL}Add this key to ${CLR_BOLD}$file${CLR_RESET}${CLR_CARAMEL}?${CLR_RESET} (y/N): "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "  ${ICON_TIMES} ${CLR_CARAMEL}Cancelled${CLR_RESET}"
        return
    fi

    {
        echo ""
        echo "# ${key}"
        echo "${key}=${value}"
    } >> "$full_path"

    chmod 600 "$full_path"

    echo -e "  ${ICON_CHECK} ${CLR_GREEN}Key ${CLR_BOLD}${key}${CLR_RESET}${CLR_GREEN} added to ${CLR_BOLD}$file${CLR_RESET}"
    echo -e "  ${ICON_SHIELD} ${CLR_DIM}File permissions set to 600${CLR_RESET}"
}

coffe::env() {
    case "${1:-}" in
        list)   coffe::env::list ;;
        create) coffe::env::create ;;
        edit)   shift; coffe::env::edit "$@" ;;
        load)   shift; coffe::env::load "$@" ;;
        add)    coffe::env::add ;;
        *)
            echo "
                    ${ICON_MICROCHIP} ENV Manager

                    Usage:

                    env list
                    env create
                    env edit <name>
                    env load <name>
                    env add
                "
            ;;
    esac
}
