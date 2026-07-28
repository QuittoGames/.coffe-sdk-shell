setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/config/cache.sh"
  source "$REPO_ROOT/config/packages.sh"
}

@test "coffe::packages::load carrega dependencias.conf" {
  coffe::packages::load
  [ "${#PKGS[@]}" -gt 0 ]
  [ "${#EXTRA_PKGS[@]}" -gt 0 ]
}

@test "coffe::packages::load parseia PKGS corretamente" {
  coffe::packages::load

  local found_bash=false
  for pkg in "${PKGS[@]}"; do
    [[ "$pkg" == "bash" ]] && found_bash=true
  done
  $found_bash
}

@test "coffe::packages::load parseia NON_DNF corretamente" {
  coffe::packages::load

  local found_omz=false
  for entry in "${EXTRA_PKGS[@]}"; do
    [[ "$entry" == "oh-my-bash:"* ]] && found_omz=true
  done
  $found_omz
}

@test "coffe::packages::load retorna 1 se dependencies.conf nao existe" {
  rm -f "$COFFE_SDK_ROOT/data/dependencies.conf"

  run coffe::packages::load
  [ "$status" -eq 1 ]
}

@test "coffe::packages::load nao deixa arrays vazios com config valida" {
  coffe::packages::load
  [ "${#PKGS[@]}" -gt 0 ]
}

@test "coffe::packages::check detecta pacotes instalados (rpm mock ok)" {
  coffe::packages::load
  coffe::packages::check

  [ "${#CACHED[@]}" -gt 0 ]
}

@test "coffe::packages::check nao falha se rpm nao encontra pacote" {
  mock_command "rpm" "" "" 1
  coffe::packages::load
  coffe::packages::check
}

@test "coffe::packages::status imprime relatorio" {
  run coffe::packages::status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dependencies:"* ]]
}

@test "coffe::packages::run_in_tmux retorna 1 sem tmux" {
  mock_command "tmux" "" "" 127

  run coffe::packages::run_in_tmux "test-session" "echo hello"
  [ "$status" -eq 1 ]
}

@test "coffe::packages::install chama check e trata faltando" {
  mock_command "rpm" "" "" 1
  mock_command "tmux" "" "" 127
  mock_pkg=$(mktemp)
  echo '#!/usr/bin/env bash' > "$MOCK_DIR/sudo"
  echo "exit 0" >> "$MOCK_DIR/sudo"
  chmod +x "$MOCK_DIR/sudo"

  run coffe::packages::install
}
