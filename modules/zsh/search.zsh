#!/usr/bin/env zsh
# shell=zsh
#
# search.zsh — Busca de arquivos e texto.
#
# Depende de: ui/dialogs.sh (ui::select_file, ui::grep)

coffe::search() {
    local query="${1:-}"

    local file
    file=$(ui::select_file "$query")

    [[ -z "$file" ]] && return

    print "${ICON_FILE} Opening: $file"

    code "$file"
}

coffe::search_in() {
    local query="${1:-}"

    [[ -z "$query" ]] && {
        print "Usage: search_in <pattern>"
        return 1
    }

    local result
    result=$(ui::grep "$query")

    [[ -z "$result" ]] && return

    local file_line
    file_line=$(cut -d: -f1,2 <<< "$result")

    code -g "$file_line"
}
