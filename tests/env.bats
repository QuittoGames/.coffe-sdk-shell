setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
  source "$REPO_ROOT/modules/bash/env.sh"
}

# ============================================================
# Raiz (ENV_ROOT / env.conf)
# ============================================================

@test "ENV_ROOT tem valor padrao" {
  [ "$ENV_ROOT" = "$HOME/.secrets" ]
}

@test "_default_root usa ~/.secrets sem env.conf" {
  run coffe::env::_default_root
  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/.secrets" ]
}

@test "_default_root le ENV_ROOT do env.conf" {
  mkdir -p "$COFFE_SDK_ROOT/config"
  echo "ENV_ROOT=$TEST_ROOT/custom-secrets" > "$COFFE_SDK_ROOT/config/env.conf"

  run coffe::env::_default_root
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_ROOT/custom-secrets" ]
}

@test "coffe::env root imprime a raiz atual" {
  ENV_ROOT="$TEST_ROOT/secrets"

  run coffe::env root
  [ "$status" -eq 0 ]
  [ "$output" = "$TEST_ROOT/secrets" ]
}

@test "coffe::env root <path> define e persiste em env.conf" {
  coffe::env::root "$TEST_ROOT/new-secrets"

  [ "$ENV_ROOT" = "$TEST_ROOT/new-secrets" ]
  [ -d "$TEST_ROOT/new-secrets" ]
  [ -f "$COFFE_SDK_ROOT/config/env.conf" ]
  [ "$(cat "$COFFE_SDK_ROOT/config/env.conf")" = "ENV_ROOT=$TEST_ROOT/new-secrets" ]
}

@test "coffe::env root <path> atualiza env.conf existente" {
  mkdir -p "$COFFE_SDK_ROOT/config"
  echo "ENV_ROOT=$TEST_ROOT/old" > "$COFFE_SDK_ROOT/config/env.conf"

  coffe::env::root "$TEST_ROOT/new-secrets"

  [ "$(cat "$COFFE_SDK_ROOT/config/env.conf")" = "ENV_ROOT=$TEST_ROOT/new-secrets" ]
}

# ============================================================
# init
# ============================================================

@test "coffe::env::init cria estrutura de diretorios" {
  ENV_ROOT="$TEST_ROOT/secrets"

  run coffe::env::init
  [ "$status" -eq 0 ]

  for dir in DB Projects Code_Agents Services AI Cloud Containers Servers; do
    [ -d "$TEST_ROOT/secrets/$dir" ]
  done
}

@test "coffe::env::init cria arquivos .env" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env::init

  [ -f "$TEST_ROOT/secrets/Services/GitHub.env" ]
  [ -f "$TEST_ROOT/secrets/Services/Discord.env" ]
  [ -f "$TEST_ROOT/secrets/AI/OpenAI.env" ]
  [ -f "$TEST_ROOT/secrets/DB/PostgreSQL.env" ]
  [ -f "$TEST_ROOT/secrets/DB/MySQL.env" ]
  [ -f "$TEST_ROOT/secrets/Containers/DockerHub.env" ]
  [ -f "$TEST_ROOT/secrets/Code_Agents/OpenCode.env" ]
  [ -f "$TEST_ROOT/secrets/Projects/Development.env" ]
}

@test "coffe::env::init cria global.sh" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env::init

  [ -f "$TEST_ROOT/secrets/global.sh" ]
}

@test "coffe::env::init nao sobrescreve arquivos existentes" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env::init
  coffe::env::init
}

# ============================================================
# list
# ============================================================

@test "coffe::env::list retorna 1 sem diretorio secrets" {
  ENV_ROOT="$TEST_ROOT/nonexistent"

  run coffe::env::list
  [ "$status" -eq 1 ]
  [[ "$output" == *"No secrets"* ]]
}

@test "coffe::env list imprime caminhos relativos" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/Services"
  echo "A=1" > "$ENV_ROOT/Services/x.env"
  echo "# global" > "$ENV_ROOT/global.sh"

  run coffe::env list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Services/x.env"* ]]
  [[ "$output" == *"global.sh"* ]]
}

@test "coffe::env list --full imprime caminhos absolutos" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/Services"
  echo "A=1" > "$ENV_ROOT/Services/x.env"

  run coffe::env list --full
  [ "$status" -eq 0 ]
  [[ "$output" == *"$ENV_ROOT/Services/x.env"* ]]
}

@test "coffe::env list <categoria> filtra por categoria" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/Services" "$ENV_ROOT/DB"
  echo "A=1" > "$ENV_ROOT/Services/x.env"
  echo "B=2" > "$ENV_ROOT/DB/y.env"

  run coffe::env list DB
  [ "$status" -eq 0 ]
  [[ "$output" == *"DB/y.env"* ]]
  [[ "$output" != *"Services/x.env"* ]]
}

# ============================================================
# select
# ============================================================

@test "coffe::env select sem TTY imprime caminhos absolutos" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/Services"
  echo "A=1" > "$ENV_ROOT/Services/x.env"

  run coffe::env select
  [ "$status" -eq 0 ]
  [ "$output" = "$ENV_ROOT/Services/x.env" ]
}

@test "coffe::env select sem arquivos retorna 1" {
  ENV_ROOT="$TEST_ROOT/empty"
  mkdir -p "$ENV_ROOT"

  run coffe::env select
  [ "$status" -eq 1 ]
  [[ "$output" == *"No env files"* ]]
}

# ============================================================
# edit
# ============================================================

@test "coffe::env::edit retorna 1 para arquivo inexistente" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT"

  run coffe::env::edit nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"Not found"* ]]
}

@test "coffe::env::edit sem nome abre global.sh" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT"
  echo "# global" > "$ENV_ROOT/global.sh"

  run coffe::env::edit
  [ "$status" -eq 0 ]
}

@test "coffe::env::edit global abre global.sh" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT"
  echo "# global" > "$ENV_ROOT/global.sh"

  run coffe::env::edit global
  [ "$status" -eq 0 ]
}

# ============================================================
# dispatcher
# ============================================================

@test "coffe::env carrega via dispatcher" {
  coffe::env init
}

@test "coffe::env init via dispatcher cria estrutura" {
  ENV_ROOT="$TEST_ROOT/secrets"

  coffe::env init

  [ -d "$TEST_ROOT/secrets/Services" ]
}

# ============================================================
# load
# ============================================================

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

  run coffe::env load test
  [[ "$output" == *"loaded"* ]]
}

@test "coffe::env load global carrega global.sh" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT"
  echo "GLOBAL_TEST_VAR=from-global" > "$ENV_ROOT/global.sh"

  coffe::env::load global

  [ "$GLOBAL_TEST_VAR" = "from-global" ]
}

@test "coffe::env load carrega global.sh antes dos .env" {
  ENV_ROOT="$TEST_ROOT/secrets"
  mkdir -p "$ENV_ROOT/services"
  echo "GLOBAL_TEST_VAR=global" > "$ENV_ROOT/global.sh"
  echo "GLOBAL_TEST_VAR=service" > "$ENV_ROOT/services/x.env"

  coffe::env::load

  [ "$GLOBAL_TEST_VAR" = "service" ]
}

# ============================================================
# add
# ============================================================

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
