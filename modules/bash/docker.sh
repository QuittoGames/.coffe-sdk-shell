#!/usr/bin/env bash
# shell=bash
#
# docker.sh — Atalhos Docker com fzf.
#
# Depende de: ui/dialogs.sh

coffe::docker::ps() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" |
    fzf::docker \
        --prompt="${ICON_DOCKER} PS > " \
        --header-lines=1 \
        --preview='echo {} | awk "{print \$1}" | xargs docker inspect'
}

coffe::docker::logs() {
    local container
    container=$(docker ps --format "{{.ID}} {{.Names}}" |
        fzf::docker \
            --prompt="${ICON_DOCKER} Logs > " \
            --preview='echo {} | awk "{print \$1}" | xargs docker logs --tail 50' |
        awk '{print $1}')

    [[ -z "$container" ]] && return

    docker logs -f "$container"
}

coffe::docker::stop() {
    local container
    container=$(docker ps --format "{{.ID}} {{.Names}} {{.Status}}" |
        fzf::docker \
            --prompt="${ICON_DOCKER} Stop > " \
            --preview='echo {} | awk "{print \$1}" | xargs docker inspect' |
        awk '{print $1}')

    [[ -z "$container" ]] && return

    docker stop "$container"
}

coffe::docker() {
    case "${1:-}" in
        ps)    shift; coffe::docker::ps "$@" ;;
        logs)  shift; coffe::docker::logs "$@" ;;
        stop)  shift; coffe::docker::stop "$@" ;;
        *)     command docker "$@" ;;
    esac
}
