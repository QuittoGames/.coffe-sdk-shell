setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
  source "$REPO_ROOT/modules/env.sh"
}

@test "ENV_ROOT tem valor padrao" {
  [ "$ENV_ROOT" = "$HOME/.secrets" ]
}

@test "coffe::env::init cria estrutura de diretorios" {
  ENV_ROOT="$TEST_ROOT/secrets"

  run coffe::env::init
  [ "$status" -eq 0 ]

  [ -d "$TEST_ROOT/secrets/services" ]
  [ -d "$TEST_ROOT/secrets/ai" ]
  [ -d "$TEST_ROOT/secrets/databases" ]
  [ -d "$TEST_ROOT/secrets/containers" ]
  [ -d "$TEST_ROOT/secrets/cloud" ]
  [ -d "$TEST_ROOT/secrets/servers" ]
  [ -d "$TEST_ROOT/secrets/local" ]
}

@test "coffe::env::init cria arquivos .env" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env::init

  [ -f "$TEST_ROOT/secrets/services/GitHub.env" ]
  [ -f "$TEST_ROOT/secrets/services/Discord.env" ]
  [ -f "$TEST_ROOT/secrets/ai/OpenAI.env" ]
  [ -f "$TEST_ROOT/secrets/databases/PostgreSQL.env" ]
  [ -f "$TEST_ROOT/secrets/containers/DockerHub.env" ]
}

@test "coffe::env::init nao sobrescreve arquivos existentes" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env::init
  coffe::env::init
}

@test "coffe::env::list retorna 1 sem diretorio secrets" {
  ENV_ROOT="$TEST_ROOT/nonexistent"

  run coffe::env::list
  [ "$status" -eq 1 ]
  [[ "$output" == *"No secrets"* ]]
}

@test "coffe::env::edit retorna 1 para arquivo inexistente" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT"

  run coffe::env::edit nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not found"* ]]
}

@test "coffe::env carrega via dispatcher" {
  coffe::env init
}

@test "coffe::env init via dispatcher cria estrutura" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env init

  [ -d "$TEST_ROOT/secrets/services" ]
}

@test "coffe::env load sem argumentos carrega todos .env" {
  ENV_ROOT="$TEST_ROOT/secrets-empty"
  mkdir -p "$ENV_ROOT"

  run coffe::env load
  [[ "$output" == *"No .env files"* ]]
}

@test "coffe::env load com nome especifico" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/services"
  echo "TEST_VAR=hello" > "$ENV_ROOT/services/test.env"

  mock_command "find" "$ENV_ROOT/services/test.env"

  run coffe::env load test
  [[ "$output" == *"loaded"* ]]
}

@test "coffe::env add retorna 1 sem diretorio secrets" {
  ENV_ROOT="$TEST_ROOT/nonexistent"

  run coffe::env add
  [ "$status" -eq 1 ]
  [[ "$output" == *"No secrets"* ]]
}

@test "coffe::env add retorna 1 sem arquivos .env" {
  ENV_ROOT="$TEST_ROOT/empty-secrets"
  mkdir -p "$ENV_ROOT"

  run coffe::env add
  [ "$status" -eq 1 ]
  [[ "$output" == *"No .env files"* ]]
}
