# helpers.bash — Setup compartilhado para todos os testes do Coffee SDK

export REPO_ROOT
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export TEST_ROOT
TEST_ROOT="$(mktemp -d "/tmp/coffe-test-XXXXXX")"

export MOCK_DIR="$TEST_ROOT/mocks"
mkdir -p "$MOCK_DIR"
export PATH="$MOCK_DIR:$PATH"

mock_command() {
  local cmd="$1"
  local stdout="${2:-}"
  local stderr="${3:-}"
  local exit_code="${4:-0}"

  # Conteúdo vai para arquivos: o mock gerado fica com sintaxe sempre válida,
  # mesmo que o stdout contenha aspas/JSON (embed direto quebraria o script).
  printf '%s' "$stdout" > "$MOCK_DIR/$cmd.stdout"
  printf '%s' "$stderr" > "$MOCK_DIR/$cmd.stderr"

  cat > "$MOCK_DIR/$cmd" <<SCRIPT
#!/usr/bin/env bash
[[ -s "$MOCK_DIR/$cmd.stdout" ]] && cat "$MOCK_DIR/$cmd.stdout"
[[ -s "$MOCK_DIR/$cmd.stderr" ]] && cat "$MOCK_DIR/$cmd.stderr" >&2
exit $exit_code
SCRIPT
  chmod +x "$MOCK_DIR/$cmd"
}

mock_command_stdin() {
  local cmd="$1"
  shift
  cat > "$MOCK_DIR/$cmd" <<SCRIPT
#!/usr/bin/env bash
$@
SCRIPT
  chmod +x "$MOCK_DIR/$cmd"
}

# Mocks padrao para comandos externos
mock_command "jq"       '{"name":"Coffee SDK","version":"1.0.0","createdBy":"Quitto","config":{"debug":false}}'
mock_command "rpm"      "bash-5.2.0-1.fc44.x86_64"
mock_command "sudo"     ""
mock_command "dnf"      ""
mock_command "tmux"     ""
mock_command "code"     ""
mock_command "chmod"    ""

# NOTA: grep NÃO é mockado de propósito. Comandos como `grep -q` precisam de
# comportamento real (exit code por match) — um mock com exit 0 fixo quebra
# cache.sh e a resolução de ENV_ROOT. grep é determinístico e sempre presente.

setup_sdk_root() {
  export COFFE_SDK_ROOT="$TEST_ROOT/sdk"

  # Recria o SDK de teste do zero a cada teste (estado limpo e determinístico)
  rm -rf "$COFFE_SDK_ROOT"
  mkdir -p "$COFFE_SDK_ROOT"

  # Simula a instalação real: copia a estrutura do repo
  cp "$REPO_ROOT/coffe.sh" "$REPO_ROOT/coffe.zsh" "$COFFE_SDK_ROOT/"
  cp -r "$REPO_ROOT/config/." "$COFFE_SDK_ROOT/config/"
  cp -r "$REPO_ROOT/ui/." "$COFFE_SDK_ROOT/ui/"
  cp -r "$REPO_ROOT/modules/." "$COFFE_SDK_ROOT/modules/"
  cp -r "$REPO_ROOT/data/." "$COFFE_SDK_ROOT/data/"
  cp -r "$REPO_ROOT/templates/." "$COFFE_SDK_ROOT/templates/"

  # Cache de teste começa vazio (não copiar o .cache real do usuário)
  mkdir -p "$COFFE_SDK_ROOT/.cache" "$COFFE_SDK_ROOT/config/bat/themes"
  : > "$COFFE_SDK_ROOT/.cache/packages.txt"
}

teardown() {
  rm -rf "$TEST_ROOT"
}
