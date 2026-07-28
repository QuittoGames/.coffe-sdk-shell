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

  cat > "$MOCK_DIR/$cmd" <<SCRIPT
#!/usr/bin/env bash
[[ -n "$stdout" ]] && echo "$stdout"
[[ -n "$stderr" ]] && echo "$stderr" >&2
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
mock_command "mkdir"    ""
mock_command "touch"    ""
mock_command "rm"       ""
mock_command "code"     ""
mock_command "chmod"    ""
mock_command "grep"     ""

setup_sdk_root() {
  export COFFE_SDK_ROOT="$TEST_ROOT/sdk"
  mkdir -p "$COFFE_SDK_ROOT"/{config,ui/{colors,theme},modules,data,.cache}

  cat > "$COFFE_SDK_ROOT/data/info.json" <<'JSON'
{
  "name": "Coffee SDK",
  "version": "1.0.0",
  "createdBy": "Quitto",
  "config": { "debug": false }
}
JSON

  cat > "$COFFE_SDK_ROOT/data/dependencies.conf" <<'CONF'
PACKAGES="bash
coreutils
findutils
git
fzf"

NON_DNF=(
  "oh-my-bash:$HOME/.oh-my-bash"
)
CONF
}

teardown() {
  rm -rf "$TEST_ROOT"
}
