#!/usr/bin/env zsh
# shell=zsh
#
# ssh.zsh — Gerenciamento do SSH Agent.
#
# Depende de: ui/theme/coffe_theme.sh (cores + ícones)

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk-shell}"

if [[ -z "$CLR_RESET" ]]; then
    source "$COFFE_SDK_ROOT/ui/theme/coffe_theme.sh"
fi

coffe::ssh() {
    local cmd="${1:-}"
    [[ -z "$cmd" ]] && {
        print ""
        print -P "  ${CLR_DIM}──${CLR_RESET} ${CLR_BLUE}${COFFE_SDK_ICON}${CLR_RESET} ${CLR_LIGHT_BLUE}ssh${CLR_RESET} ${CLR_DIM}────────────────────────────────────${CLR_RESET}"
        print ""
        print -P "  ${CLR_CARAMEL}init_service    ${CLR_RESET} ${CLR_DIM}install, start agent & add keys${CLR_RESET}"
        print -P "  ${CLR_CARAMEL}add_key         ${CLR_RESET} ${CLR_DIM}add SSH keys to agent${CLR_RESET}"
        print ""
        return 1
    }
    shift

    case "$cmd" in
        init_service) ssh_init_service "$@" ;;
        add_key)     ssh_add_key "$@" ;;
        *)
            print -P "${ICON_CLOSE} ${CLR_ORANGE}Unknown ssh command:${CLR_RESET} ${CLR_BOLD}$cmd${CLR_RESET}" >&2
            return 1
            ;;
    esac
}

ssh_add_key() {
    local ssh_dir="$HOME/.ssh"
    local keys=()

    [[ -d "$ssh_dir" ]] || {
        print -P "${CLR_RED}${ICON_CLOSE}${CLR_RESET} ${CLR_BOLD}Erro:${CLR_RESET} $ssh_dir não encontrado"
        return 1
    }

    for key in "$ssh_dir"/id_{ed25519,ecdsa,rsa,dsa} "$ssh_dir"/id_ecdsa_sk "$ssh_dir"/id_ed25519_sk; do
        [[ -f "$key" ]] && keys+=("$key")
    done

    if [[ ${#keys[@]} -eq 0 ]]; then
        print -P "${CLR_ORANGE}${ICON_WARNING}${CLR_RESET} Nenhuma chave privada encontrada em $ssh_dir"
        return 1
    fi

    print -P "${CLR_BLUE}${ICON_KEY}${CLR_RESET} Adicionando chaves ao agent..."

    for key in "${keys[@]}"; do
        local name
        name=$(basename "$key")
        if ssh-add -q "$key" 2>/dev/null; then
            print -P "  ${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} $name"
        else
            print -P "  ${CLR_RED}${ICON_CLOSE}${CLR_RESET} $name — ${CLR_DIM}falha ao adicionar${CLR_RESET}"
        fi
    done

    print -P "${CLR_DIM}─────────────────────────────────────${CLR_RESET}"
}

ssh_init_service() {
    local template="$COFFE_SDK_ROOT/templates/systemd/ssh_manager.service"
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/ssh_manager.service"

    if [[ ! -f "$template" ]]; then
        print -P "${CLR_RED}${ICON_CLOSE}${CLR_RESET} ${CLR_BOLD}Erro:${CLR_RESET} Template não encontrado"
        print -P "  ${CLR_RED}╰─${ICON_ARROW_RIGHT}${CLR_RESET} $template"
        return 1
    fi

    print -P "${CLR_BLUE}${CLR_BOLD}${ICON_COG} SSH Agent Service ${CLR_RESET}"
    print -P "${CLR_DIM}─────────────────────────────────────${CLR_RESET}"
    mkdir -p "$service_dir"

    if [[ ! -f "$service_file" ]]; then
        print -P "${CLR_ORANGE}${ICON_TOOLS}${CLR_RESET} Instalando ssh_manager.service..."

        cp "$template" "$service_file"
        chmod 644 "$service_file"

        print -P "  ${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} Serviço instalado com sucesso!"
    else
        print -P "  ${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} Serviço já existe — pulando instalação"
    fi

    print
    systemctl --user daemon-reload
    systemctl --user enable --now ssh-agent

    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

    print
    print -P "${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} SSH Agent iniciado!"
    print -P "  ${CLR_BLUE}${ICON_KEY}${CLR_RESET} Socket: ${CLR_CREAM}$SSH_AUTH_SOCK${CLR_RESET}"
    print -P "${CLR_DIM}─────────────────────────────────────${CLR_RESET}"

    ssh_add_key
}
