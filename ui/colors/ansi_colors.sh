#!/usr/bin/env bash
# shell=bash
#
# ansi_color.sh — Tabela de cores e estilos ANSI (24-bit TrueColor).
# Paleta: "Modern Blue Coffee" (Azul vibrante/moderno como destaque principal)
#
# Uso: source "$COFFE_SDK_ROOT/ui/ansi_color.sh"

# ======================================
# Modificadores de Texto
# ======================================
CLR_RESET=$'\033[0m'
CLR_BOLD=$'\033[1m'
CLR_DIM=$'\033[2m'
CLR_ITALIC=$'\033[3m'
CLR_UNDERLINE=$'\033[4m'

# ======================================
# Cores do Tema (ANSI Foreground)
# ======================================

# Fallbacks de fundo escuro espresso
CLR_BG_DARK=$'\033[38;2;22;20;19m'       # #161413 — Espresso escuro
CLR_BG_SURFACE=$'\033[38;2;35;31;29m'     # #231F1D — Mocha suave

# Base Neutra (Tom de Café / Espuma)
CLR_CREAM=$'\033[38;2;224;215;208m'       # #E0D7D0 — Espuma de leite (Texto principal)
CLR_WHITE=$'\033[38;2;255;255;255m'       # #FFFFFF — Branco limpo (Seleção)

# AZUIS DOMINANTES (Modernos, vivos e marcantes)
CLR_BLUE=$'\033[38;2;79;130;230m'         # #4F82E6 — Azul elétrico suave / Primário
CLR_LIGHT_BLUE=$'\033[38;2;120;169;255m'  # #78A9FF — Azul luminoso (Headers/Info)
CLR_SKY_BLUE=$'\033[38;2;56;189;248m'     # #38BDF8 — Cyan azul moderno (Ponteiro/Highlight)
CLR_ICE_BLUE=$'\033[38;2;147;197;253m'    # #93C5FD — Azul glacial (Glow de seleção)

# ACENTOS DE CAFÉ (Secundários / Suportes)
CLR_CARAMEL=$'\033[38;2;198;154;114m'     # #C69A72 — Caramelo quente (Destaque sutil)
CLR_GREEN=$'\033[38;2;120;200;154m'       # #78C89A — Verde Matcha (Sucesso/Marker)
CLR_ORANGE=$'\033[38;2;224;154;103m'      # #E09A67 — Canela (Warning/Spinner)
CLR_BROWN=$'\033[38;2;74;94;117m'         # #4A5E75 — Azul Aço com toque Taupe (Bordas)

# ======================================
# Mapeamento Semântico (Papel da Cor)
# ======================================
CLR_FG="$CLR_CREAM"
CLR_PRIMARY="$CLR_BLUE"
CLR_ACCENT="$CLR_SKY_BLUE"
CLR_INFO="$CLR_LIGHT_BLUE"
CLR_SUCCESS="$CLR_GREEN"
CLR_WARNING="$CLR_ORANGE"
CLR_BORDER="$CLR_BLUE"
CLR_MUTED="$CLR_DIM"

# ======================================
# Cores de Fundo (ANSI Background)
# ======================================
CLR_BG_DARK_BG=$'\033[48;2;22;20;19m'
CLR_BG_SURFACE_BG=$'\033[48;2;35;31;29m'
CLR_CREAM_BG=$'\033[48;2;224;215;208m'
CLR_WHITE_BG=$'\033[48;2;255;255;255m'
CLR_BLUE_BG=$'\033[48;2;79;130;230m'
CLR_LIGHT_BLUE_BG=$'\033[48;2;120;169;255m'
CLR_SKY_BLUE_BG=$'\033[48;2;56;189;248m'
CLR_ICE_BLUE_BG=$'\033[48;2;147;197;253m'
CLR_CARAMEL_BG=$'\033[48;2;198;154;114m'
CLR_GREEN_BG=$'\033[48;2;120;200;154m'
CLR_ORANGE_BG=$'\033[48;2;224;154;103m'
CLR_BROWN_BG=$'\033[48;2;74;94;117m'

# ======================================
# Códigos HEX puros (para FZF e afins)
# ======================================
HEX_BG_DARK="#161413"
HEX_BG_SURFACE="#231F1D"
HEX_CREAM="#E0D7D0"
HEX_WHITE="#FFFFFF"
HEX_BLUE="#4F82E6"
HEX_LIGHT_BLUE="#78A9FF"
HEX_SKY_BLUE="#38BDF8"
HEX_ICE_BLUE="#93C5FD"
HEX_CARAMEL="#C69A72"
HEX_GREEN="#78C89A"
HEX_ORANGE="#E09A67"
HEX_BROWN="#4A5E75"
