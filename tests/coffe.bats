setup() {
  load helpers
  setup_sdk_root

  # Copia arquivos reais para o SDK root de teste
  cp "$REPO_ROOT/config/packages.sh" "$COFFE_SDK_ROOT/config/"
  cp "$REPO_ROOT/config/cache.sh" "$COFFE_SDK_ROOT/config/"
  cp -r "$REPO_ROOT/ui/." "$COFFE_SDK_ROOT/ui/"
  cp -r "$REPO_ROOT/modules/." "$COFFE_SDK_ROOT/modules/"
  cp "$REPO_ROOT/data/info.json" "$COFFE_SDK_ROOT/data/"
  cp "$REPO_ROOT/data/dependencies.conf" "$COFFE_SDK_ROOT/data/"

  source "$COFFE_SDK_ROOT/coffe.sh"
}

@test "source carrega sem erros" {
  source "$COFFE_SDK_ROOT/coffe.sh"
}

@test "COFFE_SDK_ROOT tem valor padrao correto" {
  local default_root
  default_root="${COFFE_SDK_ROOT:-$HOME/.coffe-sdk-shell}"
  [ -n "$default_root" ]
}

@test "version imprime nome do SDK" {
  run version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Coffee SDK"* ]]
}

@test "version imprime versao" {
  run version
  [[ "$output" == *"1.0.0"* ]]
}

@test "version imprime autor" {
  run version
  [[ "$output" == *"Quitto"* ]]
}

@test "version retorna 1 se info.json nao existe" {
  mv "$COFFE_SDK_ROOT/data/info.json" "$COFFE_SDK_ROOT/data/info.json.bak"

  run version
  [ "$status" -eq 1 ]

  mv "$COFFE_SDK_ROOT/data/info.json.bak" "$COFFE_SDK_ROOT/data/info.json"
}

@test "coffe sem argumentos imprime usage" {
  run coffe
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "coffe version chama funcao version" {
  run coffe version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Coffee SDK"* ]]
}

@test "coffe com comando desconhecido imprime erro" {
  mock_command "fzf" "/nonexistent"
  run coffe nonexistent_command_xyz
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown"* ]]
}

@test "coffe packages executa install" {
  run coffe packages
}

@test "coffe search aceita query opcional" {
  mock_command "fd" "/tmp/test.txt"
  mock_command "fzf" "/tmp/test.txt"
  run coffe search "config"
}

@test "coffe search_in requer pattern" {
  run coffe search_in
  [ "$status" -eq 1 ]
}
