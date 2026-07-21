#!/usr/bin/env bash
# shell=bash
#
# fzf.sh — Camada única de contato com fzf.
#
# Nada além deste arquivo chama `fzf` diretamente.
# Arrays de tema estão em theme/coffe_theme.sh.
# Use as funções `fzf::*` para abrir o seletor.

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}"
source "$COFFE_SDK_ROOT/ui/theme/coffe_theme.sh"

# --------------------------------------
# Core runner
# --------------------------------------

fzf::run() {
    fzf \
        "${_FZF_OPTS[@]}" \
        "${_FZF_COLORS[@]}" \
        "${_FZF_BINDS[@]}" \
        "$@"
}

# --------------------------------------
# Namespaced API
# --------------------------------------

fzf::files()   { fzf::run "${FZF_FILES_OPTS[@]}"   "$@"; }
fzf::grep()    { fzf::run "${FZF_GREP_OPTS[@]}"    "$@"; }
fzf::dirs()    { fzf::run "${FZF_DIRS_OPTS[@]}"    "$@"; }
fzf::history() { fzf::run "${FZF_HISTORY_OPTS[@]}" "$@"; }
fzf::git()     { fzf::run "${FZF_GIT_OPTS[@]}"     "$@"; }
fzf::docker()  { fzf::run "${FZF_DOCKER_OPTS[@]}"  "$@"; }

# --------------------------------------
# Debug
# --------------------------------------

if [[ "$DEBUG" == "true" ]]; then
    echo "${ICON_CHECK} Coffee SDK — FZF runner loaded"
fi
