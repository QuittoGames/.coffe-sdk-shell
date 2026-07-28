setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
  source "$REPO_ROOT/ui/theme/coffe_theme.sh"
}

@test "_FZF_OPTS e um array" {
  declare -p _FZF_OPTS 2>/dev/null
}

@test "_FZF_OPTS tem elementos" {
  [ "${#_FZF_OPTS[@]}" -gt 0 ]
}

@test "_FZF_COLORS e um array" {
  declare -p _FZF_COLORS 2>/dev/null
}

@test "_FZF_COLORS tem elementos" {
  [ "${#_FZF_COLORS[@]}" -gt 0 ]
}

@test "_FZF_BINDS e um array" {
  declare -p _FZF_BINDS 2>/dev/null
}

@test "_FZF_BINDS tem elementos" {
  [ "${#_FZF_BINDS[@]}" -gt 0 ]
}

@test "FZF_DEFAULT_COMMAND esta definido" {
  [ -n "$FZF_DEFAULT_COMMAND" ]
}

@test "FZF_DEFAULT_COMMAND usa fd" {
  [[ "$FZF_DEFAULT_COMMAND" == *"fd"* ]]
}

@test "FZF_CTRL_T_COMMAND esta definido" {
  [ -n "$FZF_CTRL_T_COMMAND" ]
}

@test "FZF_ALT_C_COMMAND esta definido" {
  [ -n "$FZF_ALT_C_COMMAND" ]
}

@test "FZF_FILES_OPTS e um array" {
  declare -p FZF_FILES_OPTS 2>/dev/null
}

@test "FZF_GREP_OPTS e um array" {
  declare -p FZF_GREP_OPTS 2>/dev/null
}

@test "FZF_DIRS_OPTS e um array" {
  declare -p FZF_DIRS_OPTS 2>/dev/null
}

@test "FZF_HISTORY_OPTS e um array" {
  declare -p FZF_HISTORY_OPTS 2>/dev/null
}

@test "FZF_GIT_OPTS e um array" {
  declare -p FZF_GIT_OPTS 2>/dev/null
}

@test "FZF_DOCKER_OPTS e um array" {
  declare -p FZF_DOCKER_OPTS 2>/dev/null
}

@test "BAT_THEME esta definido" {
  [ -n "$BAT_THEME" ]
}

@test "BAT_THEME e cpptools_dark_vs" {
  [[ "$BAT_THEME" == *"cpptools"* ]]
}

@test "FZF_CTRL_T_OPTS esta definido" {
  [ -n "$FZF_CTRL_T_OPTS" ]
}

@test "FZF_CTRL_R_OPTS esta definido" {
  [ -n "$FZF_CTRL_R_OPTS" ]
}

@test "FZF_ALT_C_OPTS esta definido" {
  [ -n "$FZF_ALT_C_OPTS" ]
}

@test "_FZF_OPTS inclui --height" {
  local found=false
  for opt in "${_FZF_OPTS[@]}"; do
    [[ "$opt" == "--height="* ]] && found=true
  done
  $found
}

@test "_FZF_OPTS inclui --preview" {
  local found=false
  for opt in "${_FZF_OPTS[@]}"; do
    [[ "$opt" == "--preview="* ]] && found=true
  done
  $found
}

@test "_FZF_OPTS inclui --border=rounded" {
  local found=false
  for opt in "${_FZF_OPTS[@]}"; do
    [[ "$opt" == "--border=rounded" ]] && found=true
  done
  $found
}
