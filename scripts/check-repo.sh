#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOCAL_INSTALL_FILE="$REPO_DIR/install.sh"
PUBLIC_BOOTSTRAP_FILE="$REPO_DIR/dist/install.sh"

# shellcheck disable=SC1091
source "$REPO_DIR/scripts/bootstrap/bootstrap-modules.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/scripts/lib/runtime-modules.sh"

SYNTAX_FILES=()
SHELLCHECK_FILES=()

append_check_file() {
  local array_name="$1"
  local file_path="$2"
  local existing
  # shellcheck disable=SC2178
  declare -n target_array="$array_name"

  for existing in "${target_array[@]}"; do
    [[ "$existing" == "$file_path" ]] && return 0
  done

  target_array+=("$file_path")
}

append_manifest_files() {
  local target_array_name="$1"
  shift
  local relative_path

  for relative_path in "$@"; do
    append_check_file "$target_array_name" "$REPO_DIR/$relative_path"
  done
}

check_help_output() {
  bash "$LOCAL_INSTALL_FILE" --help | grep -Fq -- '--exclusive-key'
  bash "$LOCAL_INSTALL_FILE" --help | grep -Fq -- '--ssh-name'
  bash "$PUBLIC_BOOTSTRAP_FILE" --help | grep -Fq -- '--exclusive-key'
  bash "$PUBLIC_BOOTSTRAP_FILE" --help | grep -Fq -- '--ssh-name'
}

check_cli_parser() {
  local parser_log

  parser_log="$(mktemp)"

  if bash "$LOCAL_INSTALL_FILE" --opcao-inexistente >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'opção desconhecida' "$parser_log"

  if bash "$LOCAL_INSTALL_FILE" -s >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$LOCAL_INSTALL_FILE" -s "" >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$LOCAL_INSTALL_FILE" --ssh-name= >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$LOCAL_INSTALL_FILE" -- lixo >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'argumentos extras não reconhecidos' "$parser_log"

  bash "$LOCAL_INSTALL_FILE" --help | grep -Fq -- '--dry-run'
  if bash "$LOCAL_INSTALL_FILE" --check --dry-run >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq -- '--check e --dry-run' "$parser_log"

  bash "$LOCAL_INSTALL_FILE" --dry-run >"$parser_log" 2>&1
  grep -Fq 'Dry-run: nenhum comando' "$parser_log"

  if bash "$PUBLIC_BOOTSTRAP_FILE" --opcao-inexistente >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'opção desconhecida' "$parser_log"

  if bash "$PUBLIC_BOOTSTRAP_FILE" -s >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$PUBLIC_BOOTSTRAP_FILE" -s "" >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$PUBLIC_BOOTSTRAP_FILE" --ssh-name= >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor' "$parser_log"

  if bash "$PUBLIC_BOOTSTRAP_FILE" -- lixo >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'argumentos extras não reconhecidos' "$parser_log"

  bash "$PUBLIC_BOOTSTRAP_FILE" --help | grep -Fq -- '--dry-run'
  if bash "$PUBLIC_BOOTSTRAP_FILE" --check --dry-run >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq -- '--check e --dry-run' "$parser_log"
  rm -f "$parser_log"
}

check_published_bootstrap_parser() {
  local parser_log

  parser_log="$(mktemp)"

  if bash "$REPO_DIR/scripts/check-published-bootstrap.sh" --retry >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'faltou informar o valor de --retry' "$parser_log"

  if bash "$REPO_DIR/scripts/check-published-bootstrap.sh" --sleep 0 >"$parser_log" 2>&1; then
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq -- '--sleep precisa ser um inteiro positivo' "$parser_log"

  rm -f "$parser_log"
}

check_package_parser_validation() {
  local parser_log
  local temp_dir

  parser_log="$(mktemp)"
  temp_dir="$(mktemp -d)"

  printf '[Browsers]\nfirefox\n--config\n' >"$temp_dir/packages.txt"
  if (
    announce_detail() { :; }
    announce_error() { printf '%s\n' "$*" >&2; }
    # shellcheck disable=SC2034
    PACKAGE_FILE="$temp_dir/packages.txt"
    # shellcheck disable=SC2034
    EXTRA_PACKAGE_FILE="$temp_dir/packages-extra.txt"
    # shellcheck source=lib/package-config/parser.sh
    source "$REPO_DIR/scripts/lib/package-config/parser.sh"
    load_packages TEST_PACKAGES
  ) >"$parser_log" 2>&1; then
    rm -rf "$temp_dir"
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'Nome de pacote inválido' "$parser_log"

  printf '[]\n' >"$temp_dir/packages.txt"
  if (
    announce_detail() { :; }
    announce_error() { printf '%s\n' "$*" >&2; }
    # shellcheck disable=SC2034
    PACKAGE_FILE="$temp_dir/packages.txt"
    # shellcheck disable=SC2034
    EXTRA_PACKAGE_FILE="$temp_dir/packages-extra.txt"
    # shellcheck source=lib/package-config/parser.sh
    source "$REPO_DIR/scripts/lib/package-config/parser.sh"
    load_packages TEST_PACKAGES
  ) >"$parser_log" 2>&1; then
    rm -rf "$temp_dir"
    rm -f "$parser_log"
    return 1
  fi
  grep -Fq 'Categoria inválida' "$parser_log"

  rm -rf "$temp_dir"
  rm -f "$parser_log"
}

check_tar_extraction_guard() {
  local archive_file
  local destination_dir
  local source_dir
  local tar_log

  archive_file="$(mktemp)"
  destination_dir="$(mktemp -d)"
  source_dir="$(mktemp -d)"
  tar_log="$(mktemp)"

  printf 'x\n' >"$source_dir/file"
  tar -czf "$archive_file" -C "$source_dir" --transform='s#^file$#../evil#' file

  if (
    announce_error() { printf '%s\n' "$*" >&2; }
    # shellcheck source=lib/ops/filesystem.sh
    source "$REPO_DIR/scripts/lib/ops/filesystem.sh"
    ops_extract_tar_gz "$archive_file" "$destination_dir"
  ) >"$tar_log" 2>&1; then
    rm -rf "$destination_dir" "$source_dir"
    rm -f "$archive_file" "$tar_log"
    return 1
  fi
  grep -Fq 'caminho inseguro' "$tar_log"

  rm -rf "$destination_dir" "$source_dir"
  rm -f "$archive_file" "$tar_log"
}

check_safety_guards() {
  local safety_log
  local temp_dir

  safety_log="$(mktemp)"
  temp_dir="$(mktemp -d)"

  if (
    announce_detail() { printf '%s\n' "$*" >>"$safety_log"; }
    announce_warning() { printf '%s\n' "$*" >>"$safety_log"; }
    announce_error() { printf '%s\n' "$*" >>"$safety_log"; }
    announce_prompt() { printf '%s\n' "$*" >>"$safety_log"; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck disable=SC2034
    BACKUPS_DIR="$temp_dir/backups"
    # shellcheck disable=SC2034
    export DRY_RUN=0
    # shellcheck disable=SC2034
    ALLOW_HOME_CHANGES=0
    # shellcheck source=lib/safety.sh
    source "$REPO_DIR/scripts/lib/safety.sh"
    is_interactive_terminal() { return 1; }

    dangerous_confirmation_matches "MOVE HOME REPOSITORIES" "" && return 1
    dangerous_confirmation_matches "MOVE HOME REPOSITORIES" "MOVE HOME REPOSITORIES" || return 1
    if confirm_home_relocation_batch "Mover repositórios Git soltos em HOME" "1 repositório" "$temp_dir/repositories" "MOVE HOME REPOSITORIES"; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'status=blocked'
  ); then
    :
  else
    rm -rf "$temp_dir"
    rm -f "$safety_log"
    return 1
  fi

  printf 'conteudo\n' >"$temp_dir/shellrc"
  if ! (
    announce_detail() { :; }
    announce_error() { printf '%s\n' "$*" >&2; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck disable=SC2034
    BACKUPS_DIR="$temp_dir/backups"
    # shellcheck source=lib/safety.sh
    source "$REPO_DIR/scripts/lib/safety.sh"
    backup_sensitive_file_if_exists "$temp_dir/shellrc" "backup shell config" || return 1
    find "$temp_dir/backups" -type f -exec grep -Fq 'conteudo' {} \;
    report_safety_operation_lines | grep -Fq 'backup shell config'
  ); then
    rm -rf "$temp_dir"
    rm -f "$safety_log"
    return 1
  fi

  rm -rf "$temp_dir"
  rm -f "$safety_log"
}

check_operation_planner() {
  local planner_log
  local temp_dir

  planner_log="$(mktemp)"
  temp_dir="$(mktemp -d)"

  if ! (
    announce_detail() { printf '%s\n' "$*" >>"$planner_log"; }
    announce_warning() { printf '%s\n' "$*" >>"$planner_log"; }
    announce_error() { printf '%s\n' "$*" >>"$planner_log"; }
    announce_prompt() { printf '%s\n' "$*" >>"$planner_log"; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck disable=SC2034
    BACKUPS_DIR="$temp_dir/backups"
    # shellcheck disable=SC2034
    export DRY_RUN=0
    # shellcheck source=lib/safety.sh
    source "$REPO_DIR/scripts/lib/safety.sh"
    is_interactive_terminal() { return 1; }

    failing_executor() { return 1; }

    operation_plan_add "planned-op" "filesystem" "$temp_dir/source -> $temp_dir/target" "move fixture" "high" "MOVE FIXTURE" "block" "" "move back"
    operation_plan_set_command "planned-op" "mv $temp_dir/source $temp_dir/target" "0"
    operation_plan_render | grep -Fq 'move fixture'
    operation_plan_render | grep -Fq "comando=mv $temp_dir/source $temp_dir/target"
    operation_plan_render | grep -Fq 'bloqueia não interativo=sim'

    operation_plan_add "blocked-op" "filesystem" "$temp_dir/source -> $temp_dir/target" "blocked fixture" "high" "" "block" "failing_executor" "move back"
    if operation_plan_execute "blocked-op"; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'blocked fixture'
    report_safety_operation_lines | grep -Fq 'status=blocked'
    report_safety_operation_lines | grep -Fq 'rollback=move back'

    operation_plan_add "failed-op" "filesystem" "$temp_dir/source -> $temp_dir/target" "failed fixture" "medium" "" "allow" "failing_executor" "manual cleanup"
    if operation_plan_execute "failed-op"; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'failed fixture'
    report_safety_operation_lines | grep -Fq 'status=failed'

    printf 'shell\n' >"$temp_dir/shellrc"
    backup_sensitive_file_if_exists "$temp_dir/shellrc" "backup shell config" "backup-shell-fixture" || return 1
    report_safety_operation_lines | grep -Fq 'backup shell config'
    report_safety_operation_lines | grep -Fq 'backup='
  ); then
    rm -rf "$temp_dir"
    rm -f "$planner_log"
    return 1
  fi

  rm -rf "$temp_dir"
  rm -f "$planner_log"
}

check_system_operation_planner() {
  local command_log
  local temp_dir

  command_log="$(mktemp)"
  temp_dir="$(mktemp -d)"

  if ! (
    announce_detail() { :; }
    announce_warning() { :; }
    announce_error() { printf '%s\n' "$*" >>"$command_log"; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    is_interactive_terminal() { return 0; }
    retry_interactive_log_only() {
      printf 'interactive:%s\n' "$*" >>"$command_log"
      return "${RETRY_INTERACTIVE_STATUS:-0}"
    }
    retry_log_only() {
      printf 'retry:%s\n' "$*" >>"$command_log"
      return "${RETRY_STATUS:-0}"
    }
    run_interactive_log_only() {
      printf 'run-interactive:%s\n' "$*" >>"$command_log"
      return "${RUN_INTERACTIVE_STATUS:-0}"
    }
    run_log_only() {
      printf 'run:%s\n' "$*" >>"$command_log"
      return "${RUN_STATUS:-0}"
    }
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck source=lib/ops/common.sh
    source "$REPO_DIR/scripts/lib/ops/common.sh"
    # shellcheck source=lib/ops/package.sh
    source "$REPO_DIR/scripts/lib/ops/package.sh"
    # shellcheck source=lib/ops/systemd.sh
    source "$REPO_DIR/scripts/lib/ops/systemd.sh"
    # shellcheck disable=SC2034
    POSTINSTALL_PACMAN_DB_LOCK_FILE="$temp_dir/db.lck"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_pacman_install_needed firefox; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Instalar pacotes oficiais necessários'
    operation_plan_render | grep -Fq 'tipo=pacman'
    operation_plan_render | grep -Fq 'comando=sudo pacman -S --needed --noconfirm firefox'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_aur_install_needed yay visual-studio-code-bin; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Instalar pacotes AUR necessários com yay'
    operation_plan_render | grep -Fq 'tipo=aur'
    operation_plan_render | grep -Fq 'comando=yay -S --needed --noconfirm visual-studio-code-bin'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_systemctl_start mullvad-daemon; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Iniciar unidades systemd do sistema'
    operation_plan_render | grep -Fq 'tipo=systemd'
    operation_plan_render | grep -Fq 'comando=sudo systemctl start mullvad-daemon'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    touch "$POSTINSTALL_PACMAN_DB_LOCK_FILE"
    if ops_pacman_install_needed firefox; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'status=blocked'
    report_safety_operation_lines | grep -Fq 'lock do pacman'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    if ops_aur_install_needed yay visual-studio-code-bin; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'status=blocked'
    report_safety_operation_lines | grep -Fq 'lock do pacman'
    test ! -s "$command_log"

    rm -f "$POSTINSTALL_PACMAN_DB_LOCK_FILE"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    RETRY_INTERACTIVE_STATUS=0
    ops_pacman_install_needed firefox || return 1
    grep -Fq 'interactive:sudo pacman -S --needed --noconfirm firefox' "$command_log"
    report_safety_operation_lines | grep -Fq 'status=succeeded'

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    RETRY_INTERACTIVE_STATUS=1
    if ops_pacman_install_needed broken-package; then
      return 1
    elif [[ "$?" != "1" ]]; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'status=failed'

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    RUN_STATUS=1
    if ops_systemctl_start broken.service; then
      return 1
    elif [[ "$?" != "1" ]]; then
      return 1
    fi
    grep -Fq 'run:sudo systemctl start broken.service' "$command_log"
    report_safety_operation_lines | grep -Fq 'status=failed'
  ); then
    rm -rf "$temp_dir"
    rm -f "$command_log"
    return 1
  fi

  rm -rf "$temp_dir"
  rm -f "$command_log"
}

check_external_operation_planner() {
  local command_log
  local exclusive_output
  local temp_dir

  command_log="$(mktemp)"
  temp_dir="$(mktemp -d)"

  if ! (
    announce_detail() { :; }
    announce_warning() { :; }
    announce_error() { printf '%s\n' "$*" >>"$command_log"; }
    announce_prompt() { :; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    get_host_name() { printf 'test-host\n'; }
    retry() {
      printf 'retry:%s\n' "$*" >>"$command_log"
      return "${RETRY_STATUS:-0}"
    }
    retry_log_only() {
      printf 'retry-log:%s\n' "$*" >>"$command_log"
      return "${RETRY_LOG_STATUS:-0}"
    }
    run_log_only() {
      printf 'run:%s\n' "$*" >>"$command_log"
      return "${RUN_STATUS:-0}"
    }
    run_gh_auth_flow() {
      printf 'gh-auth:%s\n' "$*" >>"$command_log"
      return "${GH_AUTH_STATUS:-0}"
    }
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck source=lib/safety.sh
    source "$REPO_DIR/scripts/lib/safety.sh"
    # shellcheck source=lib/ops/common.sh
    source "$REPO_DIR/scripts/lib/ops/common.sh"
    # shellcheck source=lib/ops/git.sh
    source "$REPO_DIR/scripts/lib/ops/git.sh"
    # shellcheck source=lib/ops/github.sh
    source "$REPO_DIR/scripts/lib/ops/github.sh"
    # shellcheck source=lib/ops/node.sh
    source "$REPO_DIR/scripts/lib/ops/node.sh"
    # shellcheck source=lib/ops/ssh.sh
    source "$REPO_DIR/scripts/lib/ops/ssh.sh"
    # shellcheck source=lib/components/github-ssh/key.sh
    source "$REPO_DIR/scripts/lib/components/github-ssh/key.sh"
    is_interactive_terminal() { return "${INTERACTIVE_STATUS:-0}"; }

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_git_clone_main "https://example.invalid/repo.git" "$temp_dir/repo"; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Clonar repositório git'
    operation_plan_render | grep -Fq 'tipo=git'
    operation_plan_render | grep -Fq 'comando=git clone --branch main --single-branch https://example.invalid/repo.git'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_npm_install_codex_cli; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Instalar Codex CLI via npm'
    operation_plan_render | grep -Fq 'tipo=npm'
    operation_plan_render | grep -Fq 'comando=npm install -g @openai/codex'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_ssh_generate_key_pair "test@example.invalid" "$temp_dir/id_ed25519"; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Gerar par de chaves SSH local'
    operation_plan_render | grep -Fq 'tipo=ssh'
    operation_plan_render | grep -Fq 'ssh-keygen'
    test ! -s "$command_log"

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    if ops_gh_create_ssh_key "test-key" "ssh-ed25519 AAAATEST"; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Enviar chave SSH ao GitHub'
    operation_plan_render | grep -Fq 'tipo=github'
    operation_plan_render | grep -Fq 'key=\<public-key\>'
    test ! -s "$command_log"
    ops_command_line gh api user -f "token=ghp_secret" -f "password=hidden" github_pat_secret |
      grep -Fq 'token=\<redacted\>'
    ops_command_line gh api user -f "token=ghp_secret" -f "password=hidden" github_pat_secret |
      grep -Fq 'password=\<redacted\>'
    if ops_command_line gh api user -f "token=ghp_secret" -f "password=hidden" github_pat_secret |
      grep -Fq 'ghp_secret'; then
      return 1
    fi

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=1
    export EXCLUSIVE_GITHUB_SSH_KEY=1
    if confirm_exclusive_github_ssh_key; then
      return 1
    elif [[ "$?" != "2" ]]; then
      return 1
    fi
    operation_plan_render | grep -Fq 'Remover outras chaves SSH do GitHub'
    operation_plan_render | grep -Fq 'confirmação=DELETE GITHUB SSH KEYS'

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    export EXCLUSIVE_GITHUB_SSH_KEY=1
    export INTERACTIVE_STATUS=1
    if exclusive_output="$(confirm_exclusive_github_ssh_key 2>&1)"; then
      return 1
    fi
    if [[ "$exclusive_output" == *"/dev/tty"* ]]; then
      return 1
    fi
    report_safety_operation_lines | grep -Fq 'Remover outras chaves SSH do GitHub'
    report_safety_operation_lines | grep -Fq 'status=blocked'

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    export RETRY_LOG_STATUS=1
    if ops_npm_install_codex_cli; then
      return 1
    elif [[ "$?" != "1" ]]; then
      return 1
    fi
    grep -Fq 'retry-log:npm install -g @openai/codex' "$command_log"
    report_safety_operation_lines | grep -Fq 'status=failed'

    report_reset_changes
    operation_plan_reset
    : >"$command_log"
    export DRY_RUN=0
    export RETRY_LOG_STATUS=0
    ops_git_fetch_origin "$temp_dir/repo" || return 1
    grep -Fq "retry-log:git -C $temp_dir/repo fetch origin" "$command_log"
    report_safety_operation_lines | grep -Fq 'status=succeeded'
  ); then
    rm -rf "$temp_dir"
    rm -f "$command_log"
    return 1
  fi

  rm -rf "$temp_dir"
  rm -f "$command_log"
}

check_check_mode_sudo_validation() {
  local validation_log

  validation_log="$(mktemp)"

  if ! (
    announce_detail() { printf 'detail:%s\n' "$*" >>"$validation_log"; }
    announce_warning() { printf 'warning:%s\n' "$*" >>"$validation_log"; }
    announce_error() { printf 'error:%s\n' "$*" >>"$validation_log"; }
    announce_prompt() { printf 'prompt:%s\n' "$*" >>"$validation_log"; }
    ensure_arch() { return 0; }
    ensure_supported_session() { return 0; }
    require_command() { printf 'require:%s\n' "$1" >>"$validation_log"; return 0; }
    ops_sudo_auth() { printf 'sudo-auth-called\n' >>"$validation_log"; return 1; }
    init_logging() { printf 'init-logging\n' >>"$validation_log"; }
    sanitize_label() { printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'; }
    # shellcheck source=lib/step-result.sh
    source "$REPO_DIR/scripts/lib/step-result.sh"
    # shellcheck source=lib/execution-report/changes.sh
    source "$REPO_DIR/scripts/lib/execution-report/changes.sh"
    # shellcheck source=lib/operation-planner.sh
    source "$REPO_DIR/scripts/lib/operation-planner.sh"
    # shellcheck source=lib/environment-validation.sh
    source "$REPO_DIR/scripts/lib/environment-validation.sh"

    report_reset_changes
    operation_plan_reset
    export CHECK_ONLY=1
    export DRY_RUN=0
    validate_execution_environment_step "instalador" "ambiente ok"
    [[ "$STEP_RESULT_STATUS" == "success" ]]
    ! grep -Fq 'sudo-auth-called' "$validation_log"
    grep -Fq 'Check: sudo encontrado; autenticação interativa não será solicitada.' "$validation_log"
    report_safety_operation_lines | grep -Fq 'Validar requisito de sudo para execução real'
    report_safety_operation_lines | grep -Fq 'status=skipped'

    report_reset_changes
    operation_plan_reset
    step_result_reset
    : >"$validation_log"
    export CHECK_ONLY=0
    ops_sudo_auth() { printf 'sudo-auth-called\n' >>"$validation_log"; return 0; }
    validate_execution_environment_step "instalador" "ambiente ok"
    [[ "$STEP_RESULT_STATUS" == "success" ]]
    grep -Fq 'sudo-auth-called' "$validation_log"
  ); then
    rm -f "$validation_log"
    return 1
  fi

  rm -f "$validation_log"
}

check_repair_flow_regressions() {
  local repair_log
  local step_log

  repair_log="$(mktemp)"
  step_log="$(mktemp)"

  if ! (
    announce_detail() { printf 'detail:%s\n' "$*" >>"$repair_log"; }
    announce_warning() { printf 'warning:%s\n' "$*" >>"$repair_log"; }
    announce_error() { printf 'error:%s\n' "$*" >>"$repair_log"; }
    package_is_installed() { return 1; }
    package_exists_in_official_repos() { return 1; }
    ensure_aur_helper() { return 0; }
    state_get_aur_helper_name() { printf 'yay\n'; }
    ops_pacman_install_needed() { printf 'pacman:%s\n' "$*" >>"$repair_log"; }
    ops_aur_install_needed() { printf 'aur:%s\n' "$*" >>"$repair_log"; }
    setup_codex_cli() { printf 'codex\n' >>"$repair_log"; }
    ensure_managed_repo_origin_ssh() { printf 'repo:%s\n' "$1" >>"$repair_log"; }
    ensure_repo_origin_remote() { return 0; }
    start_desktop_user_services() { printf 'services\n' >>"$repair_log"; }
    desktop_integration_ready() { return 0; }
    has_checkpoint() { return 0; }
    mark_checkpoint() { return 0; }
    state_get_verification_label() { printf '%s\n' "$1"; }
    state_get_verification_target() {
      case "$1" in
        pacman) printf 'less\n' ;;
        classified) printf 'zen-browser-bin\n' ;;
        repo) printf '/tmp/repo\n' ;;
      esac
    }
    state_get_verification_repair_strategy() {
      case "$1" in
        pacman) printf 'pacman_package\n' ;;
        classified) printf 'package_classify\n' ;;
        service) printf 'service_start\n' ;;
        codex) printf 'codex_cli_setup\n' ;;
        repo) printf 'repo_origin_ssh\n' ;;
      esac
    }
    # shellcheck source=lib/process.sh
    source "$REPO_DIR/scripts/lib/process.sh"
    # shellcheck source=lib/repair/plan.sh
    source "$REPO_DIR/scripts/lib/repair/plan.sh"
    # shellcheck source=lib/repair/actions.sh
    source "$REPO_DIR/scripts/lib/repair/actions.sh"

    local repair_pacman_packages=()
    local repair_aur_packages=()
    local repair_origin_repos=()
    local repair_missing_pacman_packages=()
    local repair_should_repair_codex=0
    local repair_should_start_services=0
    # shellcheck disable=SC2034
    local STATE_MISSING_ITEM_IDS=(pacman classified service codex repo)

    collect_final_repair_plan \
      repair_pacman_packages \
      repair_aur_packages \
      repair_origin_repos \
      repair_should_repair_codex \
      repair_should_start_services
    [[ "${repair_pacman_packages[*]}" == "less" ]]
    [[ "${repair_aur_packages[*]}" == "zen-browser-bin" ]]
    [[ "${repair_origin_repos[*]}" == "/tmp/repo" ]]
    (( repair_should_repair_codex == 1 ))
    (( repair_should_start_services == 1 ))

    repair_missing_pacman_packages repair_pacman_packages repair_missing_pacman_packages
    [[ "${repair_missing_pacman_packages[*]}" == "less" ]]
    grep -Fq 'pacman:less' "$repair_log"
    repair_desktop_services_if_needed repair_should_start_services repair_missing_pacman_packages
    grep -Fq 'services' "$repair_log"
  ); then
    rm -f "$repair_log" "$step_log"
    return 1
  fi

  if ! (
    # shellcheck disable=SC2034
    style_step=""
    # shellcheck disable=SC2034
    style_muted=""
    # shellcheck disable=SC2034
    STEP_OUTPUT_ONLY=1
    # shellcheck disable=SC2034
    step_counter=16
    # shellcheck disable=SC2034
    step_total=16
    # shellcheck disable=SC2034
    step_open=0
    state_has_missing_items() { (( STATE_HAS_MISSING == 1 )); }
    collect_final_repair_plan() { return 0; }
    run_final_repair_plan() { return 0; }
    verify_installation() { STATE_HAS_MISSING=0; }
    style_text() { printf '%s' "$2"; }
    write_log_only() { :; }
    # shellcheck source=lib/ui/notice.sh
    source "$REPO_DIR/scripts/lib/ui/notice.sh"
    # shellcheck source=lib/repair/final-verification.sh
    source "$REPO_DIR/scripts/lib/repair/final-verification.sh"

    # shellcheck disable=SC2034
    local package_list=()
    local STATE_HAS_MISSING=1

    attempt_final_repair_once package_list >"$step_log"
    grep -Fq 'Etapa 17/17' "$step_log"
  ); then
    rm -f "$repair_log" "$step_log"
    return 1
  fi

  rm -f "$repair_log" "$step_log"
}

check_readme_commands() {
  grep -Fqx 'curl -fsSL https://obslove.dev | bash' "$REPO_DIR/README.md"
  grep -Fqx 'curl -fsSL https://obslove.dev | bash -s --' "$REPO_DIR/README.md"
}

check_readme_links() {
  if rg -n '/home/' "$REPO_DIR/README.md" >/dev/null 2>&1; then
    printf 'Erro: README.md contém caminhos absolutos locais.\n' >&2
    return 1
  fi
}

check_cloudflare_deploy_files() {
  test -f "$REPO_DIR/.github/workflows/deploy-bootstrap.yml"
  test -f "$REPO_DIR/cloudflare/bootstrap-worker/src/index.js"
  test -f "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
  node --check "$REPO_DIR/cloudflare/bootstrap-worker/src/index.js"
  grep -Fqx 'name = "obslove"' "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
  grep -Fqx 'main = "src/index.js"' "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
  grep -Fqx 'compatibility_date = "2026-03-21"' "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
  grep -Fqx 'workers_dev = false' "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
  grep -Fq 'pattern = "obslove.dev/*"' "$REPO_DIR/cloudflare/bootstrap-worker/wrangler.toml"
}

build_check_file_lists() {
  append_check_file SYNTAX_FILES "$LOCAL_INSTALL_FILE"
  append_check_file SYNTAX_FILES "$PUBLIC_BOOTSTRAP_FILE"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/build-bootstrap.sh"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/build-lint-entrypoints.sh"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/check-published-bootstrap.sh"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/lint/bootstrap.sh"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/lint/runtime.sh"
  append_manifest_files SYNTAX_FILES "${BOOTSTRAP_CHECK_FILES[@]}"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/install/main.sh"
  append_manifest_files SYNTAX_FILES "${RUNTIME_CHECK_FILES[@]}"
  append_check_file SYNTAX_FILES "$REPO_DIR/scripts/update-readme-packages.sh"
  append_check_file SYNTAX_FILES "$REPO_DIR/config/components.sh"

  append_check_file SHELLCHECK_FILES "$LOCAL_INSTALL_FILE"
  append_check_file SHELLCHECK_FILES "$PUBLIC_BOOTSTRAP_FILE"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/check-repo.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/build-bootstrap.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/build-lint-entrypoints.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/check-published-bootstrap.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/lint/bootstrap.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/lint/runtime.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/install/main.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/scripts/update-readme-packages.sh"
  append_check_file SHELLCHECK_FILES "$REPO_DIR/config/components.sh"
}

main() {
  build_check_file_lists
  bash "$REPO_DIR/scripts/build-bootstrap.sh" --check
  bash "$REPO_DIR/scripts/build-lint-entrypoints.sh" --check
  bash "$REPO_DIR/scripts/update-readme-packages.sh" --check
  bash -n "${SYNTAX_FILES[@]}"
  shellcheck -S warning -a -x "${SHELLCHECK_FILES[@]}"
  check_help_output
  check_cli_parser
  check_published_bootstrap_parser
  check_package_parser_validation
  check_tar_extraction_guard
  check_safety_guards
  check_operation_planner
  check_system_operation_planner
  check_external_operation_planner
  check_check_mode_sudo_validation
  check_repair_flow_regressions
  check_readme_commands
  check_readme_links
  check_cloudflare_deploy_files
}

main "$@"
