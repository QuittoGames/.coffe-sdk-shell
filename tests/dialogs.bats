setup() {
  load helpers
  setup_sdk_root
  source "$REPO_ROOT/ui/icons.sh"
  source "$REPO_ROOT/ui/colors/ansi_colors.sh"
  source "$REPO_ROOT/ui/theme/coffe_theme.sh"
  source "$REPO_ROOT/ui/fzf.sh"
  source "$REPO_ROOT/ui/dialogs.sh"
}

@test "ui::confirm retorna 0 para y" {
  run ui::confirm "Test?" <<< "y"
  [ "$status" -eq 0 ]
}

@test "ui::confirm retorna 0 para Y" {
  run ui::confirm "Test?" <<< "Y"
  [ "$status" -eq 0 ]
}

@test "ui::confirm retorna 1 para n" {
  run ui::confirm "Test?" <<< "n"
  [ "$status" -eq 1 ]
}

@test "ui::confirm retorna 1 para resposta vazia" {
  run ui::confirm "Test?" <<< ""
  [ "$status" -eq 1 ]
}

@test "ui::confirm retorna 1 para qualquer outra resposta" {
  run ui::confirm "Test?" <<< "maybe"
  [ "$status" -eq 1 ]
}

@test "ui::confirm usa prompt padrao se nenhum for fornecido" {
  run ui::confirm <<< ""
  [[ "$output" == *"Confirm?"* ]]
}

@test "ui::select_file aceita query opcional" {
  mock_command "fzf" "/tmp/selected.txt"
  mock_command "fd" "/tmp/selected.txt"

  run ui::select_file "query"
  [ "$status" -eq 0 ]
}

@test "ui::select_dir aceita query opcional" {
  mock_command "fzf" "/tmp/dir"
  mock_command "fd" "/tmp/dir"

  run ui::select_dir "query"
  [ "$status" -eq 0 ]
}

@test "ui::grep imprime usage sem pattern" {
  run ui::grep
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "ui::grep aceita pattern" {
  mock_command "rg" "file.txt:10:match"
  mock_command "fzf" "file.txt:10:match"

  run ui::grep "pattern"
  [ "$status" -eq 0 ]
}

@test "ui::select_history aceita query opcional" {
  mock_command "history" "  100  ls -la"
  mock_command "fzf" "  100  ls -la"

  run ui::select_history "ls"
  [ "$status" -eq 0 ]
}
