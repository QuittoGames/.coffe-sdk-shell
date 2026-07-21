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

coffe::env() {
    case "${1:-}" in
        list)   coffe::env::list ;;
        create) coffe::env::create ;;
        edit)   shift; coffe::env::edit "$@" ;;
        load)   shift; coffe::env::load "$@" ;;
        *)
            echo "
                    ${ICON_MICROCHIP} ENV Manager

                    Usage:

                    env list
                    env create
                    env edit <name>
                    env load <name>
                "
            ;;
    esac
}
