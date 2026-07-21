#!/usr/bin/env bash
# shell=bash
#
# search.sh — Busca de arquivos e texto.
#
# Depende de: ui/dialogs.sh (ui::select_file, ui::grep)

search() {
    local query="${1:-}"

    local file
    file=$(ui::select_file "$query")

    [[ -z "$file" ]] && return

    echo "${ICON_FILE} Opening: $file"

    code "$file"
}

search_in() {
    local query="$1"

    [[ -z "$query" ]] && {
        echo "Usage: search_in <text>"
        return 1
    }

    local result
    result=$(ui::grep "$query")

    [[ -z "$result" ]] && return

    code -g "$(cut -d: -f1,2 <<< "$result")"
}
