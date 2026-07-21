#!/usr/bin/env bash
# shell=bash
#
# packages.sh — Gerenciamento de dependências do sistema.
#
# Depende de: config/cache.sh
#
# Lê o arquivo data/dependencies.conf, que contém:
#   - PACKAGES="..." — pacotes dnf (multilinha, com comentários)
#   - NON_DNF=( )    — pacotes não-dnf instalados por outros meios
#                      (formato: "nome:/path/que/deve/existir")
#
# Usa cache para não rodar rpm -q repetidamente entre sessões.

COFFEE_DEPENDENCIES="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}/data/dependencies.conf"

source "${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}/config/cache.sh"

# --------------------------------------
# Load
# --------------------------------------

coffe::packages::load() {
    local file="$COFFEE_DEPENDENCIES"

    if [[ ! -f "$file" ]]; then
        echo "Dependency file not found: $file" >&2
        return 1
    fi

    # Sourceia o arquivo para obter PACKAGES (dnf) e NON_DNF (outros)
    source "$file"

    # --- DNF packages ---
    PKGS=()
    while IFS= read -r line; do
        line="${line%%#*}"                  # remove comentários inline
        line="${line//[[:space:]]/}"        # remove espaços extra
        [[ -n "$line" ]] && PKGS+=("$line")
    done <<< "$PACKAGES"

    # --- Non-DNF packages ---
    EXTRA_PKGS=()
    for entry in "${NON_DNF[@]}"; do
        local name="${entry%%:*}"
        local check_path="${entry#*:}"
        check_path="${check_path/#\~/$HOME}"  # expande ~
        EXTRA_PKGS+=("$name:$check_path")
    done

    return 0
}

# --------------------------------------
# Check
# --------------------------------------

coffe::packages::check() {
    coffe::packages::load || return 1
    coffe::cache::init

    MISSING=()
    MISSING_EXTRA=()
    CACHED=()

    # --- DNF: verifica com rpm -q (com cache) ---
    for package in "${PKGS[@]}"; do
        if coffe::cache::has "$package"; then
            CACHED+=("$package")
            continue
        fi

        if rpm -q "$package" &>/dev/null; then
            coffe::cache::add "$package"
            CACHED+=("$package")
        else
            MISSING+=("$package")
        fi
    done

    # --- Non-DNF: verifica por existência de path ---
    for entry in "${EXTRA_PKGS[@]}"; do
        local name="${entry%%:*}"
        local check_path="${entry#*:}"

        if coffe::cache::has "$name"; then
            CACHED+=("$name")
            continue
        fi

        if [[ -d "$check_path" ]] || [[ -f "$check_path" ]]; then
            coffe::cache::add "$name"
            CACHED+=("$name")
        else
            MISSING_EXTRA+=("$name:$check_path")
        fi
    done
}

# --------------------------------------
# Status
# --------------------------------------

coffe::packages::status() {
    coffe::packages::check

    local total_dnf="${#PKGS[@]}"
    local missing_dnf="${#MISSING[@]}"
    local installed_dnf=$(( total_dnf - missing_dnf ))

    local total_extra="${#EXTRA_PKGS[@]}"
    local missing_extra="${#MISSING_EXTRA[@]}"
    local installed_extra=$(( total_extra - missing_extra ))

    local total_all=$(( total_dnf + total_extra ))
    local installed_all=$(( installed_dnf + installed_extra ))

    echo "Dependencies: ${installed_all}/${total_all} installed"

    if [[ "$missing_dnf" -gt 0 ]]; then
        echo ""
        echo "DNF packages missing (${missing_dnf}):"
        printf '  - %s\n' "${MISSING[@]}"
    fi

    if [[ "$missing_extra" -gt 0 ]]; then
        echo ""
        echo "Non-DNF packages missing (${missing_extra}):"
        for entry in "${MISSING_EXTRA[@]}"; do
            local name="${entry%%:*}"
            local path="${entry#*:}"
            printf '  - %s (expected at: %s)\n' "$name" "$path"
        done
    fi
}

# --------------------------------------
# Install
# --------------------------------------

# Executa um comando em segundo plano via tmux.
# Se já estiver dentro de tmux: abre uma nova janela.
# Se tmux existir mas não estiver dentro: cria sessão destacada.
# Retorna 0 se conseguiu lançar em tmux, 1 se tmux não estiver disponível.
coffe::packages::run_in_tmux() {
    local session="$1"
    local cmd="$2"

    if command -v tmux &>/dev/null && [[ -n "$TMUX" ]]; then
        tmux new-window -n "$session" "$cmd; echo; echo '[Press any key]'; read -n1"
        echo "  → tmux window: \"$session\""
        return 0
    elif command -v tmux &>/dev/null; then
        tmux new-session -d -s "$session" "$cmd; echo; echo '[Press any key]'; read -n1"
        echo "  → tmux session: \"$session\""
        echo "    Attach: tmux attach -t \"$session\""
        return 0
    fi

    return 1
}

# Instala pacotes DNF (sem tmux, bloqueante).
# Atualiza o cache ao finalizar com sucesso.
coffe::packages::install_dnf() {
    local pkgs=("$@")

    if sudo dnf install -y "${pkgs[@]}"; then
        local pkg
        for pkg in "${pkgs[@]}"; do
            coffe::cache::add "$pkg"
        done
        return 0
    fi

    return 1
}

# Mostra instruções para dependências não-DNF
coffe::packages::report_extra() {
    local entries=("$@")

    echo ""
    echo "Non-DNF packages need manual install:"
    local entry name path
    for entry in "${entries[@]}"; do
        name="${entry%%:*}"
        path="${entry#*:}"
        printf '  - %s (expected at: %s)\n' "$name" "$path"
    done
    echo ""
    echo "Run the install script or clone the repo for each."
}

# Orquestrador principal de instalação.
coffe::packages::install() {
    coffe::packages::check

    local has_missing=${#MISSING[@]}
    local has_extra=${#MISSING_EXTRA[@]}

    # Tudo ok
    if [[ "$has_missing" -eq 0 && "$has_extra" -eq 0 ]]; then
        if [[ $HOME == "true" ]]; then
            echo "All dependencies installed."
        fi
        return 0
    fi

    # --- DNF ---
    if [[ "$has_missing" -gt 0 ]]; then
        echo "Installing DNF packages (${has_missing}):"
        printf '  - %s\n' "${MISSING[@]}"
        echo ""

        local session="coffe-dnf-$$"
        local cmd="sudo dnf install -y ${MISSING[*]}"

        if ! coffe::packages::run_in_tmux "$session" "$cmd"; then
            echo "  → tmux not available — running directly."
            coffe::packages::install_dnf "${MISSING[@]}" || return 1
        fi

        echo ""
    fi

    # --- Non-DNF ---
    if [[ "$has_extra" -gt 0 ]]; then
        coffe::packages::report_extra "${MISSING_EXTRA[@]}"
    fi
}
