setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
}

@test "COFFE_SDK_ICON esta definido" {
  [ -n "$COFFE_SDK_ICON" ]
}

@test "ICON_SEARCH esta definido" {
  [ -n "$ICON_SEARCH" ]
}

@test "ICON_CLOSE esta definido" {
  [ -n "$ICON_CLOSE" ]
}

@test "ICON_CHECK esta definido" {
  [ -n "$ICON_CHECK" ]
}

@test "ICON_FILE esta definido" {
  [ -n "$ICON_FILE" ]
}

@test "ICON_FOLDER esta definido" {
  [ -n "$ICON_FOLDER" ]
}

@test "ICON_GIT esta definido" {
  [ -n "$ICON_GIT" ]
}

@test "ICON_DOCKER esta definido" {
  [ -n "$ICON_DOCKER" ]
}

@test "ICON_USER esta definido" {
  [ -n "$ICON_USER" ]
}

@test "ICON_KEY esta definido" {
  [ -n "$ICON_KEY" ]
}

@test "ICON_LINUX esta definido" {
  [ -n "$ICON_LINUX" ]
}

@test "ICON_FEDORA esta definido" {
  [ -n "$ICON_FEDORA" ]
}

@test "ICON_BASH esta definido" {
  [ -n "$ICON_BASH" ]
}

@test "ICON_COFFE esta definido" {
  [ -n "$ICON_COFFE" ]
}

@test "ICON_WARNING esta definido" {
  [ -n "$ICON_WARNING" ]
}

@test "ICON_TAG esta definido" {
  [ -n "$ICON_TAG" ]
}

@test "ICON_ENV esta definido" {
  [ -n "$ICON_ENV" ]
}

@test "ICON_TOOLS esta definido" {
  [ -n "$ICON_TOOLS" ]
}

@test "ICON_HISTORY esta definido" {
  [ -n "$ICON_HISTORY" ]
}

@test "icons::list lista todas as variaveis ICON_" {
  run icons::list
  [ "$status" -eq 0 ]
  [[ "$output" == *"ICON_SEARCH"* ]]
  [[ "$output" == *"ICON_FILE"* ]]
}

@test "todos os icones sao diferentes de string vazia" {
  local vars
  vars=$(compgen -v | grep '^ICON_' | grep -v '^ICON_COFFE_SDK_ICON$')
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
