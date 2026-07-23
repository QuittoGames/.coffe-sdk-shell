#!/usr/bin/env bash
# shell=bash
#
# ssh.sh — Gerenciamento do SSH Agent.
#
# Depende de: ui/theme/coffe_theme.sh (cores + ícones)

COFFE_SDK_ROOT="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk}"

# Garante cores e ícones carregados (source seguro caso já tenha sido carregado)
if [[ -z "$CLR_RESET" ]]; then
    source "$COFFE_SDK_ROOT/ui/theme/coffe_theme.sh"
fi

coffe::ssh() {
    local cmd="${1:-}"
    [[ -z "$cmd" ]] && {
        echo -e "${CLR_BLUE}${ICON_KEY}${CLR_RESET} ${CLR_BOLD}SSH${CLR_RESET} ${CLR_DIM}— commands${CLR_RESET}"
        echo
        echo -e "  ${ICON_COG}  coffe ssh init_service    Install & start SSH agent"
        return 1
    }
    shift

    case "$cmd" in
        init_service) ssh_init_service "$@" ;;
        *)
            echo -e "${ICON_CLOSE} ${CLR_ORANGE}Unknown ssh command:${CLR_RESET} ${CLR_BOLD}$cmd${CLR_RESET}" >&2
            return 1
            ;;
    esac
}

ssh_init_service() {
    local template="$COFFE_SDK_ROOT/templates/systemd/ssh_manager.service"
    local service_dir="$HOME/.config/systemd/user"
    local service_file="$service_dir/ssh_manager.service"

    if [[ ! -f "$template" ]]; then
        echo -e "${CLR_RED}${ICON_CLOSE}${CLR_RESET} ${CLR_BOLD}Erro:${CLR_RESET} Template não encontrado"
        echo -e "  ${CLR_RED}╰─${ICON_ARROW_RIGHT}${CLR_RESET} $template"
        return 1
    fi

    echo -e "${CLR_BLUE}${CLR_BOLD}${ICON_COG} SSH Agent Service ${CLR_RESET}"
    echo -e "${CLR_DIM}─────────────────────────────────────${CLR_RESET}"
    mkdir -p "$service_dir"

    if [[ ! -f "$service_file" ]]; then
        echo -e "${CLR_ORANGE}${ICON_TOOLS}${CLR_RESET} Instalando ssh_manager.service..."

        cp "$template" "$service_file"
        chmod 644 "$service_file"

        echo -e "  ${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} Serviço instalado com sucesso!"
    else
        echo -e "  ${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} Serviço já existe — pulando instalação"
    fi

    echo
    systemctl --user daemon-reload
    systemctl --user enable --now ssh-agent

    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

    echo
    echo -e "${CLR_SUCCESS}${ICON_CHECK}${CLR_RESET} SSH Agent iniciado!"
    echo -e "  ${CLR_BLUE}${ICON_KEY}${CLR_RESET} Socket: ${CLR_CREAM}$SSH_AUTH_SOCK${CLR_RESET}"
    echo -e "${CLR_DIM}─────────────────────────────────────${CLR_RESET}"
}
