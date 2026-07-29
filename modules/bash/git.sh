#!/usr/bin/env bash
# shell=bash
#
# git.sh — Atalhos Git com fzf.
#
# Depende de: ui/dialogs.sh (ui::select_file, ui::select_dir)

coffe::git::checkout() {
    git branch -a |
    fzf::git \
        --prompt="${ICON_GIT} Branch > " \
        --preview="git log --oneline --graph --decorate {}" |
    sed 's/^\* //; s/^remotes\/origin\///' |
    xargs git checkout
}

coffe::git::log() {
    git log \
        --oneline \
        --graph \
        --decorate \
        --all |
    fzf::git \
        --prompt="${ICON_GIT} Log > " \
        --ansi \
        --preview='echo {} | awk "{print \$2}" | xargs git show --stat'
}

coffe::git::diff() {
    local files
    files=$(git diff --name-only | ui::select_file)

    [[ -z "$files" ]] && return

    git diff "$files"
}

coffe::git::status() {
    git status --short |
    fzf::git \
        --prompt="󰊢 Git Status > " \
        --preview='
            f=$(echo {} | cut -c4-);
            s=$(echo {} | cut -c1-2);
            if [ "$s" = "??" ]; then
                echo "  untracked  $f";
                bat --color=always "$f" 2>/dev/null;
            elif [ "$s" = "M " ]; then
                git diff --cached --color=always -- "$f" 2>/dev/null;
            else
                git diff --color=always -- "$f" 2>/dev/null;
            fi
        '
}

coffe::git() {
    case "${1:-}" in
        checkout) shift; coffe::git::checkout "$@" ;;
        log)      shift; coffe::git::log "$@" ;;
        diff)     shift; coffe::git::diff "$@" ;;
        status)   shift; coffe::git::status "$@" ;;
        *)        command git "$@" ;;
    esac
}
