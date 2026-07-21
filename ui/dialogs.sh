#!/usr/bin/env bash
# shell=bash
#
# dialogs.sh — Widgets de UI que combinam finders com fzf.
#
# Nenhuma destas funções chama `fzf` diretamente.
# Toda interação com fzf passa por fzf::*.
# Nenhum módulo deve chamar fzf::* ou fzf diretamente.
# Módulos usam apenas ui::*.

ui::select_file() {
    local query="${1:-}"

    fd \
        --hidden \
        --follow \
        --exclude .git \
        --type f \
        . "${2:-$HOME}" |
    fzf::files \
        --query="$query"
}

ui::select_dir() {
    local query="${1:-}"

    fd \
        --hidden \
        --follow \
        --exclude .git \
        --type d \
        . "${2:-$HOME}" |
    fzf::dirs \
        --query="$query"
}

ui::grep() {
    local pattern="${1:-}"

    [[ -z "$pattern" ]] && {
        echo "Usage: ui::grep <pattern> [path]"
        return 1
    }

    rg \
        --line-number \
        --hidden \
        --glob '!.git' \
        "$pattern" "${2:-$HOME}" |
    fzf::grep
}

ui::select_history() {
    local query="${1:-}"

    history |
    fzf::history \
        --query="$query"
}

ui::confirm() {
    local prompt="${1:-Confirm?}"

    echo "$prompt (y/N): "

    read -r response

    [[ "$response" == "y" || "$response" == "Y" ]]
}
