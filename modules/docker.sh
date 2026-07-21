#!/usr/bin/env bash
# shell=bash
#
# docker.sh — Atalhos Docker com fzf.
#
# Depende de: ui/dialogs.sh

docker::ps() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" |
    fzf::docker \
        --prompt="󰡨 Docker PS > " \
        --header-lines=1 \
        --preview='echo {} | awk "{print \$1}" | xargs docker inspect'
}

docker::logs() {
    local container
    container=$(docker ps --format "{{.ID}} {{.Names}}" |
        fzf::docker \
            --prompt="󰡨 Docker Logs > " \
            --preview='echo {} | awk "{print \$1}" | xargs docker logs --tail 50' |
        awk '{print $1}')

    [[ -z "$container" ]] && return

    docker logs -f "$container"
}

docker::stop() {
    local container
    container=$(docker ps --format "{{.ID}} {{.Names}} {{.Status}}" |
        fzf::docker \
            --prompt="󰡨 Stop > " \
            --preview='echo {} | awk "{print \$1}" | xargs docker inspect' |
        awk '{print $1}')

    [[ -z "$container" ]] && return

    docker stop "$container"
}

docker() {
    case "${1:-}" in
        ps)    shift; docker::ps "$@" ;;
        logs)  shift; docker::logs "$@" ;;
        stop)  shift; docker::stop "$@" ;;
        *)     command docker "$@" ;;
    esac
}
