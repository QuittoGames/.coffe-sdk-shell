setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
  source "$REPO_ROOT/modules/bash/path.sh"
}

# ============================================================
# list
# ============================================================

@test "coffe::path list retorna 1 sem arquivo de config" {
  run coffe::path list
  [ "$status" -eq 1 ]
  [[ "$output" == *"No paths"* ]]
}

@test "coffe::path list imprime NAME=PATH" {
  mkdir -p "$COFFE_SDK_ROOT/config"
  printf 'FOO=/tmp/foo\nBAR=/opt/bar/bin\n' > "$PATHS_CONF"

  run coffe::path list
  [ "$status" -eq 0 ]
  [ "$output" = "FOO=/tmp/foo
BAR=/opt/bar/bin" ]
}

@test "coffe::path list --paths imprime so os paths" {
  mkdir -p "$COFFE_SDK_ROOT/config"
  printf 'FOO=/tmp/foo\nBAR=/opt/bar/bin\n' > "$PATHS_CONF"

  run coffe::path list --paths
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/foo
/opt/bar/bin" ]
}

@test "coffe::path list ignora comentarios" {
  mkdir -p "$COFFE_SDK_ROOT/config"
  printf '# comentario\nFOO=/tmp/foo\n' > "$PATHS_CONF"

  run coffe::path list
  [ "$status" -eq 0 ]
  [[ "$output" != *"comentario"* ]]
  [[ "$output" == *"FOO=/tmp/foo"* ]]
}

# ============================================================
# add
# ============================================================

@test "coffe::path add cria paths.conf com NAME=PATH expandido" {
  coffe::path add FOO /tmp/foo

  [ -f "$PATHS_CONF" ]
  [ "$(cat "$PATHS_CONF")" = "FOO=/tmp/foo" ]
}

@test "coffe::path add expande til para $HOME" {
  coffe::path add FOO "~/bin"

  [ "$(cat "$PATHS_CONF")" = "FOO=$HOME/bin" ]
}

@test "coffe::path add atualiza entrada existente" {
  coffe::path add FOO /tmp/foo
  coffe::path add FOO /opt/foo

  [ "$(cat "$PATHS_CONF")" = "FOO=/opt/foo" ]
}

@test "coffe::path add rejeita nome invalido" {
  run coffe::path add "FOO BAR" /tmp/foo
  [ "$status" -eq 1 ]
  [[ "$output" == *"inválido"* || "$output" == *"invalido"* ]]
}

@test "coffe::path add sem args nao-TTY imprime uso" {
  run coffe::path add
  [ "$status" -eq 1 ]
  [[ "$output" == *"Uso"* ]]
}

@test "coffe::path add path vazio rejeitado" {
  run coffe::path add FOO ""
  [ "$status" -eq 1 ]
}

# ============================================================
# get
# ============================================================

@test "coffe::path get retorna o path" {
  coffe::path add FOO /tmp/foo

  run coffe::path get FOO
  [ "$status" -eq 0 ]
  [ "$output" = "/tmp/foo" ]
}

@test "coffe::path get retorna 1 para nome inexistente" {
  run coffe::path get NAO_EXISTE
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not found"* ]]
}

# ============================================================
# remove
# ============================================================

@test "coffe::path remove remove a entrada" {
  coffe::path add FOO /tmp/foo

  run coffe::path remove FOO
  [ "$status" -eq 0 ]

  run coffe::path list
  [ "$status" -eq 1 ]
}

@test "coffe::path remove retorna 1 para nome inexistente" {
  run coffe::path remove NAO_EXISTE
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not found"* ]]
}

# ============================================================
# file / dispatcher
# ============================================================

@test "coffe::path file imprime o caminho do arquivo" {
  run coffe::path file
  [ "$status" -eq 0 ]
  [ "$output" = "$COFFE_SDK_ROOT/config/paths.conf" ]
}

@test "coffe::path via dispatcher adiciona e lista" {
  coffe::path add FOO /tmp/foo

  run coffe::path list
  [ "$status" -eq 0 ]
  [ "$output" = "FOO=/tmp/foo" ]
}
