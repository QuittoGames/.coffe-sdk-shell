#!/usr/bin/env bash
# shell=bash
#
# search.sh — Busca de arquivos e texto.
#
# Depende de: ui/dialogs.sh (ui::select_file, ui::grep)

coffe::search() {
    local query="${1:-}"

    local file
    file=$(ui::select_file "$query")

    [[ -z "$file" ]] && return

    echo "${ICON_FILE} Opening: $file"

    code "$file"
}

coffe::search_in() {
    local query="${1:-}"

    [[ -z "$query" ]] && {
        echo "Usage: search_in <pattern>"
        return 1
    }

    local result
    result=$(ui::grep "$query")

    [[ -z "$result" ]] && return

    # rg output: file:line:content
    # Extrai só file:line para o --goto do code
    local file_line
    file_line=$(cut -d: -f1,2 <<< "$result")

    code -g "$file_line"
}
