setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/config/cache.sh"
}

@test "coffe::cache::init cria diretorio e arquivo de cache" {
  local cache_dir="$COFFE_SDK_ROOT/.cache"
  local cache_file="$cache_dir/packages.txt"

  rm -rf "$cache_dir"
  coffe::cache::init

  [ -d "$cache_dir" ]
  [ -f "$cache_file" ]
}

@test "coffe::cache::init nao falha se cache ja existe" {
  coffe::cache::init
  coffe::cache::init
}

@test "coffe::cache::add insere pacote no cache" {
  coffe::cache::init
  coffe::cache::add "bash"

  run grep -qFx "bash" "$COFFE_SDK_ROOT/.cache/packages.txt"
  [ "$status" -eq 0 ]
}

@test "coffe::cache::add nao duplica entradas" {
  coffe::cache::init
  coffe::cache::add "bash"
  coffe::cache::add "bash"

  local count
  count=$(grep -cFx "bash" "$COFFE_SDK_ROOT/.cache/packages.txt")
  [ "$count" -eq 1 ]
}

@test "coffe::cache::has retorna 0 para pacote em cache" {
  coffe::cache::init
  coffe::cache::add "git"

  coffe::cache::has "git"
}

@test "coffe::cache::has retorna 1 para pacote nao em cache" {
  coffe::cache::init

  run coffe::cache::has "nonexistent"
  [ "$status" -eq 1 ]
}

@test "coffe::cache::has retorna 1 para cache vazio" {
  coffe::cache::init

  run coffe::cache::has "anything"
  [ "$status" -eq 1 ]
}

@test "coffe::cache::clear remove arquivo de cache" {
  coffe::cache::init
  coffe::cache::add "python"
  coffe::cache::clear

  [ ! -f "$COFFE_SDK_ROOT/.cache/packages.txt" ]
}

@test "coffe::cache::clear nao falha quando cache nao existe" {
  rm -rf "$COFFE_SDK_ROOT/.cache"
  coffe::cache::clear
}

@test "coffe::cache::list mostra pacotes quando ha entradas" {
  coffe::cache::init
  coffe::cache::add "bash"
  coffe::cache::add "git"

  run coffe::cache::list
  [ "$status" -eq 0 ]
  [[ "$output" == *"bash"* ]]
  [[ "$output" == *"git"* ]]
}

@test "coffe::cache::list mostra (empty) quando vazio" {
  coffe::cache::init

  run coffe::cache::list
  [ "$status" -eq 0 ]
  [[ "$output" == "(empty)" ]]
}

@test "coffe::cache::add suporta nomes com caracteres especiais" {
  coffe::cache::init
  coffe::cache::add "rust-analyzer-1.84.0"

  coffe::cache::has "rust-analyzer-1.84.0"
}

@test "coffe::cache::add cria diretorio se nao existir" {
  rm -rf "$COFFE_SDK_ROOT/.cache"
  coffe::cache::add "bash"

  [ -d "$COFFE_SDK_ROOT/.cache" ]
  [ -f "$COFFE_SDK_ROOT/.cache/packages.txt" ]
}
