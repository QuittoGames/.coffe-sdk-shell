setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
}

@test "CLR_RESET esta definido" {
  [ -n "$CLR_RESET" ]
}

@test "CLR_BOLD esta definido" {
  [ -n "$CLR_BOLD" ]
}

@test "CLR_DIM esta definido" {
  [ -n "$CLR_DIM" ]
}

@test "CLR_CREAM esta definido" {
  [ -n "$CLR_CREAM" ]
}

@test "CLR_WHITE esta definido" {
  [ -n "$CLR_WHITE" ]
}

@test "CLR_BLUE esta definido" {
  [ -n "$CLR_BLUE" ]
}

@test "CLR_GREEN esta definido" {
  [ -n "$CLR_GREEN" ]
}

@test "CLR_RED esta definido" {
  [ -n "$CLR_RED" ]
}

@test "CLR_ORANGE esta definido" {
  [ -n "$CLR_ORANGE" ]
}

@test "CLR_CARAMEL esta definido" {
  [ -n "$CLR_CARAMEL" ]
}

@test "CLR_SKY_BLUE esta definido" {
  [ -n "$CLR_SKY_BLUE" ]
}

@test "CLR_FG (alias semantico) esta definido" {
  [ -n "$CLR_FG" ]
}

@test "CLR_PRIMARY (alias semantico) esta definido" {
  [ -n "$CLR_PRIMARY" ]
}

@test "CLR_SUCCESS esta definido" {
  [ -n "$CLR_SUCCESS" ]
}

@test "CLR_WARNING esta definido" {
  [ -n "$CLR_WARNING" ]
}

@test "CLR_RESET comeca com escape \\033" {
  [[ "$CLR_RESET" == $'\033['* ]]
}

@test "CLR_BOLD comeca com escape \\033" {
  [[ "$CLR_BOLD" == $'\033['* ]]
}

@test "HEX_BLUE esta definido" {
  [ -n "$HEX_BLUE" ]
}

@test "HEX_GREEN esta definido" {
  [ -n "$HEX_GREEN" ]
}

@test "HEX_CREAM esta definido" {
  [ -n "$HEX_CREAM" ]
}

@test "HEX_WHITE esta definido" {
  [ -n "$HEX_WHITE" ]
}

@test "todos CLR_* nao sao vazios" {
  local vars
  vars=$(compgen -v | grep '^CLR_' | grep -v 'CLR_BG_' | grep -v 'CLR_MUTED')
  local fail=false
  for var in $vars; do
    if [[ -z "${!var}" ]]; then
      echo "Variavel vazia: $var" >&2
      fail=true
    fi
  done
  $fail && return 1
  return 0
}

@test "todos HEX_* sao codigos hex validos" {
  local vars
  vars=$(compgen -v | grep '^HEX_')
  local fail=false
  for var in $vars; do
    local val="${!var}"
    if [[ -z "$val" ]]; then
      echo "HEX vazia: $var" >&2
      fail=true
    elif ! [[ "$val" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
      echo "HEX invalida: $var = $val" >&2
      fail=true
    fi
  done
  $fail && return 1
  return 0
}
