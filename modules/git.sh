#!/usr/bin/env bash
# shell=bash
#
# git.sh — Atalhos Git com fzf.
#
# Depende de: ui/dialogs.sh (ui::select_file, ui::select_dir)

git::checkout() {
    git branch -a |
    fzf::git \
        --prompt="󰊢 Git Branch > " \
        --preview="git log --oneline --graph --decorate {}" |
    sed 's/^\* //; s/^remotes\/origin\///' |
    xargs git checkout
}

git::log() {
    git log \
        --oneline \
        --graph \
        --decorate \
        --all |
    fzf::git \
        --prompt="󰊢 Git Log > " \
        --ansi \
        --preview='echo {} | awk "{print \$2}" | xargs git show --stat'
}

git::diff() {
    local files
    files=$(git diff --name-only | ui::select_file)

    [[ -z "$files" ]] && return

    git diff "$files"
}

git::status() {
    git status --short |
    fzf::git \
        --prompt="󰊢 Git Status > " \
        --preview='git diff --color -- "$(cut -c4- <<< "{}")"'
}

git() {
    case "${1:-}" in
        checkout) shift; git::checkout "$@" ;;
        log)      shift; git::log "$@" ;;
        diff)     shift; git::diff "$@" ;;
        status)   shift; git::status "$@" ;;
        *)        command git "$@" ;;
    esac
}
