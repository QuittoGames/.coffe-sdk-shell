#!/usr/bin/env zsh
# shell=zsh
#
# zsh.zsh — Gerenciamento de plugins Zsh.
#
# Detecta automaticamente o framework (Oh My Zsh, zinit, zplug, antibody)
# e gerencia plugins de forma dinâmica de acordo com o .zshrc do sistema.
#
# Depende de: ui/icons.sh, ui/colors/ansi_colors.sh

COFFE_ZSHRC="${COFFE_ZSHRC:-$HOME/.zsh/.zshrc}"
COFFE_ZSH_PLUGINS="${COFFE_ZSH_PLUGINS:-$HOME/.zsh/plugins.zsh}"
COFFE_ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# =============================================================================
# Framework detection
# =============================================================================

coffe::zsh::_detect_framework() {
    local zshrc="$1"

    if grep -q "oh-my-zsh" "$zshrc" 2>/dev/null; then
        print "ohmyzsh"
    elif grep -q "zinit " "$zshrc" 2>/dev/null; then
        print "zinit"
    elif grep -q "zplug " "$zshrc" 2>/dev/null; then
        print "zplug"
    elif grep -q "antibody " "$zshrc" 2>/dev/null; then
        print "antibody"
    elif grep -q "antigen " "$zshrc" 2>/dev/null; then
        print "antigen"
    else
        print "unknown"
    fi
}

# =============================================================================
# Plugin source: dedicated plugins.zsh > grep-parsed .zshrc
# =============================================================================

coffe::zsh::_load_plugins_file() {
    local file="$1"
    [[ ! -f "$file" ]] && return 1

    (
        plugins=()
        source "$file" 2>/dev/null
        printf '%s\n' "${plugins[@]}"
    ) | grep -v '^$'
}

coffe::zsh::_parse_ohmyzsh() {
    local zshrc="$1"

    local plugins_file="$COFFE_ZSH_PLUGINS"
    if [[ -f "$plugins_file" ]]; then
        coffe::zsh::_load_plugins_file "$plugins_file"
        return
    fi

    local raw
    raw=$(grep -E '^plugins=\(' "$zshrc" 2>/dev/null | head -1)

    if print -- "$raw" | grep -q ')'; then
        local inline
        inline=$(print -- "$raw" | sed 's/^plugins=(//; s/).*//')
        for p in ${=inline}; do
            print -- "$p"
        done
        return
    fi

    local start end
    start=$(grep -n '^plugins=(' "$zshrc" 2>/dev/null | head -1 | cut -d: -f1)
    if [[ -n "$start" ]]; then
        end=$(sed -n "${start},\$p" "$zshrc" 2>/dev/null | grep -n '^)' | head -1 | cut -d: -f1)
        if [[ -n "$end" ]]; then
            local last=$((start + end - 2))
            if [[ $last -ge $((start + 1)) ]]; then
                sed -n "$((start+1)),${last}p" "$zshrc" 2>/dev/null \
                    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
                    | grep -v '^$'
            fi
        fi
    fi

    local zraw
    zraw=$(grep -E '^zsh_plugins=\(' "$zshrc" 2>/dev/null | head -1)
    if [[ -n "$zraw" ]]; then
        local zinline
        zinline=$(print -- "$zraw" | sed 's/^zsh_plugins=(//; s/).*//')
        for p in ${=zinline}; do
            print -- "$p"
        done
    fi

    grep -E '^\s*zsh_plugin_install\s+' "$zshrc" 2>/dev/null \
        | sed 's/.*zsh_plugin_install[[:space:]]*//' \
        | sed 's/\\//g' \
        | xargs -n1 echo \
        | grep -E '^[a-zA-Z_-]+$' 2>/dev/null || true
}

coffe::zsh::_parse_zinit() {
    local zshrc="$1"
    local re='zinit[[:space:]]+(ice|light|wait|load|for)[[:space:]]+(.+)'

    while IFS= read -r line; do
        if [[ "$line" =~ $re ]]; then
            local repo="$match[2]"
            repo=$(print -- "$repo" | sed 's/\\//g' | xargs)
            [[ -n "$repo" ]] && print -- "$repo"
        fi
    done < <(grep -E '^\s*zinit\s+' "$zshrc" 2>/dev/null | grep -v '^#')
}

coffe::zsh::_parse_zplug() {
    local zshrc="$1"
    local re='zplug[[:space:]]+\"([^\"]+)\"'

    while IFS= read -r line; do
        if [[ "$line" =~ $re ]]; then
            local repo="$match[1]"
            [[ -n "$repo" ]] && print -- "$repo"
        fi
    done < <(grep -E '^\s*zplug\s+' "$zshrc" 2>/dev/null | grep -v '^#')
}

coffe::zsh::_parse_antibody() {
    local zshrc="$1"
    local re='antibody[[:space:]]+(bundle|add)[[:space:]]+(.+)'

    while IFS= read -r line; do
        if [[ "$line" =~ $re ]]; then
            local repo="$match[2]"
            repo=$(print -- "$repo" | xargs)
            [[ -n "$repo" ]] && print -- "$repo"
        fi
    done < <(grep -E '^\s*antibody\s+' "$zshrc" 2>/dev/null | grep -v '^#')
}

coffe::zsh::_parse_antigen() {
    local zshrc="$1"
    local re='antigen[[:space:]]+(bundle|add|use)[[:space:]]+(.+)'

    while IFS= read -r line; do
        if [[ "$line" =~ $re ]]; then
            local repo="$match[2]"
            repo=$(print -- "$repo" | xargs)
            [[ -n "$repo" ]] && print -- "$repo"
        fi
    done < <(grep -E '^\s*antigen\s+' "$zshrc" 2>/dev/null | grep -v '^#')
}

coffe::zsh::_parse_unknown() {
    local zshrc="$1"
    local re1='plugin[[:space:]]+([a-zA-Z_-]+)'
    local re2='clone.*plugins/([a-zA-Z_-]+)'

    while IFS= read -r line; do
        if [[ "$line" =~ $re1 ]] || [[ "$line" =~ $re2 ]]; then
            local p="$match[1]"
            [[ -n "$p" ]] && print -- "$p"
        fi
    done < <(grep -E '(plugin|clone.*plugins/)' "$zshrc" 2>/dev/null | grep -v '^#')
}

coffe::zsh::_parse_plugins() {
    local zshrc="$1"
    local framework="$2"
    local result

    result=$(coffe::zsh::_parse_ohmyzsh "$zshrc")
    if [[ -z "$result" ]]; then
        case "$framework" in
            zinit)    result=$(coffe::zsh::_parse_zinit "$zshrc") ;;
            zplug)    result=$(coffe::zsh::_parse_zplug "$zshrc") ;;
            antibody) result=$(coffe::zsh::_parse_antibody "$zshrc") ;;
            antigen)  result=$(coffe::zsh::_parse_antigen "$zshrc") ;;
            *)        result=$(coffe::zsh::_parse_unknown "$zshrc") ;;
        esac
        if [[ -z "$result" ]]; then
            result=$(coffe::zsh::_parse_unknown "$zshrc")
        fi
    fi

    print -- "$result" | sort -u
}

# =============================================================================
# Repositorios conhecidos de plugins
# =============================================================================

# =============================================================================
# Plugin classification
# =============================================================================

coffe::zsh::_is_builtin() {
    local plugin="$1"
    case "$plugin" in
        adb|aliases|ansible|autojump|aws|brew|bundler|cargo|cake)
            return 0 ;;
        colored-man-pages|command-not-found|composer|debian|docker|docker-compose|dotenv)
            return 0 ;;
        emacs|fabric|fasd|fzf|gcloud|gem|git|github|golang|gpg-agent|gradle)
            return 0 ;;
        helm|heroku|history|history-substring-search)
            return 0 ;;
        jsontools|kubectl|laravel|lein|macos|man|meteor|minikube|mix)
            return 0 ;;
        node|npm|nvm|osx|pass|pip|pod|postgres|pow|python)
            return 0 ;;
        rails|rake|redis|ruby|rust|sbt|scala|screen|sdk|sudo|svn|systemd)
            return 0 ;;
        terraform|terminal|tmux|ubuntu|vagrant|vi-mode|virtualenv|vscode)
            return 0 ;;
        xcode|yarn|yum|z|zsh-interactive-cd)
            return 0 ;;
        *) return 1 ;;
    esac
}

coffe::zsh::_plugin_url() {
    local plugin="$1"
    case "$plugin" in
        zsh-autosuggestions)            print "git@github.com:zsh-users/zsh-autosuggestions.git" ;;
        zsh-syntax-highlighting)        print "git@github.com:zsh-users/zsh-syntax-highlighting.git" ;;
        zsh-completions)                print "git@github.com:zsh-users/zsh-completions.git" ;;
        zsh-history-substring-search)   print "git@github.com:zsh-users/zsh-history-substring-search.git" ;;
        fzf-tab)                        print "git@github.com:Aloxaf/fzf-tab.git" ;;
        you-should-use)                 print "git@github.com:MichaelAquilina/zsh-you-should-use.git" ;;
        fzf-zsh-plugin)                 print "git@github.com:unixorn/fzf-zsh-plugin.git" ;;
        fast-syntax-highlighting)       print "git@github.com:zdharma-continuum/fast-syntax-highlighting.git" ;;
        zsh-autocomplete)               print "git@github.com:marlonrichert/zsh-autocomplete.git" ;;
        zsh-vi-mode)                    print "git@github.com:jeffreytse/zsh-vi-mode.git" ;;
        powerlevel10k)                  print "git@github.com:romkatv/powerlevel10k.git" ;;
        zsh-navigation-tools)           print "git@github.com:psprint/zsh-navigation-tools.git" ;;
        zsh-autoenv)                    print "git@github.com:Tarrasch/zsh-autoenv.git" ;;
        zsh-bd)                         print "git@github.com:Tarrasch/zsh-bd.git" ;;
        zsh-aliases-exa)                print "git@github.com:DarrinTisdale/zsh-aliases-exa.git" ;;
        zsh-docker-aliases)             print "git@github.com:akarzim/zsh-docker-aliases.git" ;;
        zsh-interactive-cd)             print "git@github.com:b4b4r07/zsh-interactive-cd.git" ;;
        zsh-ls-colors)                  print "git@github.com:trapd00r/LS_COLORS.git" ;;
        zsh-reload)                     print "git@github.com:mattmc3/zsh-reload.git" ;;
        zsh-snap)                       print "git@github.com:marlonrichert/zsh-snap.git" ;;
        zsh-efish)                      print "git@github.com:cjayross/zsh-efish.git" ;;
        *)                              print "" ;;
    esac
}

# =============================================================================
# Instalacao de plugins
# =============================================================================

coffe::zsh::_is_installed() {
    local plugin="$1"
    local custom_dir="$COFFE_ZSH_CUSTOM/plugins"
    [[ -d "$custom_dir/$plugin" ]]
}

coffe::zsh::_install_git() {
    local plugin_name="$1"
    local url="$2"

    local dest="$COFFE_ZSH_CUSTOM/plugins/$plugin_name"

    if [[ -d "$dest" ]]; then
        print -P "  ${ICON_CHECK} ${CLR_GREEN}$plugin_name${CLR_RESET} ${CLR_DIM}já instalado${CLR_RESET}"
        return 0
    fi

    print -P "  ${ICON_DOWNLOAD} ${CLR_CARAMEL}Instalando${CLR_RESET} ${CLR_BOLD}$plugin_name${CLR_RESET} ${CLR_DIM}($url)${CLR_RESET}"

    if ! command -v git &>/dev/null; then
        print -P "  ${ICON_CLOSE} ${CLR_RED}Git não encontrado${CLR_RESET}" >&2
        return 1
    fi

    mkdir -p "$(dirname "$dest")"

    if git clone --depth=1 "$url" "$dest" 2>/dev/null; then
        print -P "  ${ICON_CHECK} ${CLR_GREEN}$plugin_name instalado${CLR_RESET}"
        return 0
    else
        rm -rf "$dest" 2>/dev/null
        print -P "  ${ICON_CLOSE} ${CLR_RED}Falha ao instalar $plugin_name${CLR_RESET}" >&2
        return 1
    fi
}

# =============================================================================
# Subcomandos
# =============================================================================

coffe::zsh::install() {
    local target="${1:-}"

    if [[ ! -f "$COFFE_ZSHRC" ]]; then
        print -P "  ${ICON_CLOSE} ${CLR_RED}.zshrc não encontrado em $COFFE_ZSHRC${CLR_RESET}" >&2
        return 1
    fi

    local framework
    framework=$(coffe::zsh::_detect_framework "$COFFE_ZSHRC")

    print ""
    print -P "  ${CLR_DIM}──${CLR_RESET} ${ICON_ZSH:-${ICON_SHELL}} ${CLR_LIGHT_BLUE}zsh${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}install${CLR_RESET} ${CLR_DIM}────────────────────────────${CLR_RESET}"
    print ""

    if [[ "$target" == "." ]]; then
        local plugins_count=0
        local plugins=()
        while IFS= read -r p; do
            [[ -n "$p" ]] && plugins+=("$p") && ((plugins_count++))
        done < <(coffe::zsh::_parse_plugins "$COFFE_ZSHRC" "$framework")

        if [[ $plugins_count -eq 0 ]]; then
            print -P "  ${ICON_BAN} ${CLR_CARAMEL}Nenhum plugin encontrado no .zshrc${CLR_RESET}"
            return 1
        fi

        print -P "  ${ICON_PLUGIN} ${CLR_DIM}Framework:${CLR_RESET} ${CLR_BOLD}$framework${CLR_RESET}"
        print -P "  ${ICON_LIST} ${CLR_DIM}Plugins detectados:${CLR_RESET} $plugins_count"
        print ""

        local builtin_count=0 installed_count=0 new_count=0 failed_count=0
        local plugin
        for plugin in "${plugins[@]}"; do
            if coffe::zsh::_is_builtin "$plugin"; then
                print -P "  ${ICON_CHECK} ${CLR_DIM}$plugin${CLR_RESET} ${CLR_DIM}(builtin)${CLR_RESET}"
                ((builtin_count++))
                continue
            fi

            local url
            url=$(coffe::zsh::_plugin_url "$plugin")

            if [[ -z "$url" ]]; then
                print -P "  ${ICON_BAN} ${CLR_CARAMEL}$plugin${CLR_RESET} ${CLR_DIM}(desconhecido)${CLR_RESET}"
                ((failed_count++))
                continue
            fi

            if coffe::zsh::_is_installed "$plugin"; then
                print -P "  ${ICON_CHECK} ${CLR_GREEN}$plugin${CLR_RESET} ${CLR_DIM}(ok)${CLR_RESET}"
                ((installed_count++))
                continue
            fi

            if coffe::zsh::_install_git "$plugin" "$url"; then
                ((new_count++))
            else
                ((failed_count++))
            fi
        done

        print ""
        print -P "  ${CLR_DIM}────────────────────────────────────────${CLR_RESET}"
        print -P "  ${ICON_CHECK} ${CLR_DIM}Builtin${CLR_RESET} ............ ${CLR_BOLD}$builtin_count${CLR_RESET}"
        print -P "  ${ICON_CHECK} ${CLR_GREEN}Instalados${CLR_RESET} ........ ${CLR_BOLD}$installed_count${CLR_RESET}"
        print -P "  ${ICON_DOWNLOAD} ${CLR_CARAMEL}Novos${CLR_RESET} ............ ${CLR_BOLD}$new_count${CLR_RESET}"
        print -P "  ${ICON_CLOSE} ${CLR_RED}Falhas${CLR_RESET} ............ ${CLR_BOLD}$failed_count${CLR_RESET}"
        print ""

    elif [[ -n "$target" ]]; then
        if coffe::zsh::_is_builtin "$target"; then
            print -P "  ${ICON_CHECK} ${CLR_DIM}$target${CLR_RESET} ${CLR_DIM}(builtin)${CLR_RESET}"
            return 0
        fi

        local url
        url=$(coffe::zsh::_plugin_url "$target")
        if [[ -z "$url" ]]; then
            print -P "  ${ICON_BAN} ${CLR_CARAMEL}$target${CLR_RESET} ${CLR_DIM}não é um plugin externo conhecido${CLR_RESET}"
            return 1
        fi

        coffe::zsh::_install_git "$target" "$url"
    else
        print -P "  ${CLR_CARAMEL}install <plugin> ${CLR_RESET} ${CLR_DIM}instala um plugin específico${CLR_RESET}"
        print -P "  ${CLR_CARAMEL}install .         ${CLR_RESET} ${CLR_DIM}instala todos os plugins do .zshrc${CLR_RESET}"
        return 1
    fi
}

coffe::zsh::list() {
    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}/plugins"
    local custom_dir="$COFFE_ZSH_CUSTOM/plugins"

    print ""
    print -P "  ${CLR_DIM}──${CLR_RESET} ${ICON_ZSH:-${ICON_SHELL}} ${CLR_LIGHT_BLUE}zsh${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}list${CLR_RESET} ${CLR_DIM}──────────────────────────────${CLR_RESET}"
    print ""

    if [[ -d "$omz_dir" ]]; then
        local n
        n=$(find "$omz_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        print -P "  ${ICON_FOLDER} ${CLR_DIM}Oh My Zsh builtins:${CLR_RESET} ${CLR_BOLD}$n${CLR_RESET}"
    fi

    if [[ -d "$custom_dir" ]]; then
        print ""
        print -P "  ${ICON_FOLDER_OPEN} ${CLR_CARAMEL}Custom plugins:${CLR_RESET}"
        print ""
        local d
        for d in "$custom_dir"/*(/); do
            local name
            name=$(basename "$d")
            local git_info=""
            if [[ -d "$d/.git" ]]; then
                local remote
                remote=$(git -C "$d" remote get-url origin 2>/dev/null || print "")
                if [[ -n "$remote" ]]; then
                    git_info=" ${CLR_DIM}($remote)${CLR_RESET}"
                else
                    git_info=" ${CLR_DIM}(local)${CLR_RESET}"
                fi
            fi
            print -P "  ${ICON_PLUGIN} ${CLR_BOLD}$name${CLR_RESET}$git_info"
        done
    else
        print -P "  ${ICON_BAN} ${CLR_CARAMEL}Nenhum plugin custom instalado${CLR_RESET}"
    fi

    print ""
}

coffe::zsh::status() {
    local zshrc="$COFFE_ZSHRC"

    print ""
    print -P "  ${CLR_DIM}──${CLR_RESET} ${ICON_ZSH:-${ICON_SHELL}} ${CLR_LIGHT_BLUE}zsh${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}status${CLR_RESET} ${CLR_DIM}────────────────────────────${CLR_RESET}"
    print ""

    if [[ ! -f "$zshrc" ]]; then
        print -P "  ${ICON_CLOSE} ${CLR_RED}.zshrc não encontrado${CLR_RESET}"
        return 1
    fi

    local framework
    framework=$(coffe::zsh::_detect_framework "$zshrc")

    print -P "  ${ICON_CONFIG} ${CLR_DIM}.zshrc:${CLR_RESET}      ${CLR_BOLD}$zshrc${CLR_RESET}"
    print -P "  ${ICON_PLUGIN} ${CLR_DIM}Framework:${CLR_RESET}   ${CLR_BOLD}$framework${CLR_RESET}"
    print -P "  ${ICON_TERMINAL} ${CLR_DIM}Shell:${CLR_RESET}      ${CLR_BOLD}$SHELL${CLR_RESET}"

    local omz_dir="${ZSH:-$HOME/.oh-my-zsh}"
    if [[ -d "$omz_dir" ]]; then
        local omz_ver
        omz_ver=$(grep "^ZSH_VERSION=" "$omz_dir/oh-my-zsh.sh" 2>/dev/null | cut -d= -f2 || print "unknown")
        print -P "  ${ICON_FOLDER} ${CLR_DIM}Oh My Zsh:${CLR_RESET}   ${CLR_BOLD}${omz_ver:-installed}${CLR_RESET}"
    fi

    print ""
    print -P "  ${CLR_CARAMEL}Plugins no .zshrc:${CLR_RESET}"
    print ""

    local plugins=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && plugins+=("$p")
    done < <(coffe::zsh::_parse_plugins "$zshrc" "$framework")

    if [[ ${#plugins[@]} -eq 0 ]]; then
        print -P "    ${CLR_DIM}(nenhum plugin encontrado)${CLR_RESET}"
    else
        local plugin
        for plugin in "${plugins[@]}"; do
            local status_icon="${ICON_CLOSE}"
            local status_color="${CLR_RED}"
            local status_text="ausente"

            if coffe::zsh::_is_builtin "$plugin"; then
                status_icon="${ICON_CHECK}"
                status_color="${CLR_BLUE}"
                status_text="builtin"
            elif coffe::zsh::_is_installed "$plugin"; then
                status_icon="${ICON_CHECK}"
                status_color="${CLR_GREEN}"
                status_text="instalado"
                local install_dir="$COFFE_ZSH_CUSTOM/plugins/$plugin"
                if [[ -d "$install_dir/.git" ]]; then
                    local plugin_remote
                    plugin_remote=$(git -C "$install_dir" remote get-url origin 2>/dev/null || print "")
                    [[ -n "$plugin_remote" ]] && status_text+=" (${plugin_remote##*/})"
                fi
            fi

            print -P "    ${status_icon} ${status_color}${plugin}${CLR_RESET} ${CLR_DIM}${status_text}${CLR_RESET}"
        done
    fi

    print ""
}

coffe::zsh::update() {
    local custom_dir="$COFFE_ZSH_CUSTOM/plugins"

    print ""
    print -P "  ${CLR_DIM}──${CLR_RESET} ${ICON_ZSH:-${ICON_SHELL}} ${CLR_LIGHT_BLUE}zsh${CLR_RESET} ${CLR_DIM}·${CLR_RESET} ${CLR_LIGHT_BLUE}update${CLR_RESET} ${CLR_DIM}────────────────────────────${CLR_RESET}"
    print ""

    if [[ ! -d "$custom_dir" ]]; then
        print -P "  ${ICON_BAN} ${CLR_CARAMEL}Nenhum plugin custom para atualizar${CLR_RESET}"
        return 1
    fi

    local updated=0 failed=0
    local d
    for d in "$custom_dir"/*(/); do
        if [[ -d "$d/.git" ]]; then
            local name
            name=$(basename "$d")
            print -n "  ${ICON_SYNC} ${CLR_CARAMEL}Atualizando${CLR_RESET} ${CLR_BOLD}$name${CLR_RESET} ... "
            if git -C "$d" pull --ff-only --depth=1 2>/dev/null; then
                print -P "${CLR_GREEN}ok${CLR_RESET}"
                ((updated++))
            else
                print -P "${CLR_RED}falha${CLR_RESET}"
                ((failed++))
            fi
        fi
    done

    print ""
    print -P "  ${CLR_DIM}────────────────────────────────────────${CLR_RESET}"
    print -P "  ${ICON_CHECK} ${CLR_GREEN}${updated} atualizados${CLR_RESET}  ${ICON_BAN} ${CLR_RED}${failed} falhas${CLR_RESET}"
    print ""
}

# =============================================================================
# Dispatcher
# =============================================================================

coffe::zsh() {
    case "${1:-}" in
        install) shift; coffe::zsh::install "$@" ;;
        list)    coffe::zsh::list ;;
        status)  coffe::zsh::status ;;
        update)  coffe::zsh::update ;;
        *)
            print ""
            print -P "  ${CLR_DIM}──${CLR_RESET} ${ICON_ZSH:-${ICON_SHELL}} ${CLR_LIGHT_BLUE}zsh${CLR_RESET} ${CLR_DIM}────────────────────────────────────${CLR_RESET}"
            print ""
            print -P "  ${CLR_CARAMEL}install <plugin> ${CLR_RESET} ${CLR_DIM}install a specific plugin${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}install .         ${CLR_RESET} ${CLR_DIM}install all plugins from .zshrc${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}list              ${CLR_RESET} ${CLR_DIM}list installed plugins${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}status            ${CLR_RESET} ${CLR_DIM}check plugin installation status${CLR_RESET}"
            print -P "  ${CLR_CARAMEL}update            ${CLR_RESET} ${CLR_DIM}update all custom plugins${CLR_RESET}"
            print ""
            ;;
    esac
}
