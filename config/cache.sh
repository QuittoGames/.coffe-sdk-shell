#!/usr/bin/env bash
# shell=bash
#
# cache.sh — Cache de estado para evitar re-check em cada sessão.
#
# Armazena em ~/.coffe-sdk/.cache/ quais pacotes já foram verificados
# como instalados, para que rpm -q não seja chamado repetidamente
# entre sessões do terminal.

CACHE_DIR="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}/.cache"
CACHE_FILE="$CACHE_DIR/packages.txt"

coffe::cache::init() {
    mkdir -p "$CACHE_DIR"
    [[ -f "$CACHE_FILE" ]] || touch "$CACHE_FILE"
}

# Verifica se um pacote está no cache (já confirmado instalado)
coffe::cache::has() {
    local package="$1"
    [[ -f "$CACHE_FILE" ]] && grep -qFx "$package" "$CACHE_FILE"
}

# Marca um pacote como instalado no cache
coffe::cache::add() {
    local package="$1"
    coffe::cache::init
    if ! coffe::cache::has "$package"; then
        echo "$package" >> "$CACHE_FILE"
    fi
}

# Limpa o cache inteiro (força re-verificação)
coffe::cache::clear() {
    rm -f "$CACHE_FILE"
}

# Mostra o conteúdo do cache
coffe::cache::list() {
    coffe::cache::init
    if [[ -s "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo "(empty)"
    fi
}
