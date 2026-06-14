#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# shellcheck source-path=SCRIPTDIR
# shellcheck source=scripts/lib/ops.sh
# shellcheck source=scripts/lib/components.sh
# shellcheck source=scripts/lib/runtime-state.sh

declare -Ag SHELL_CONFIG_CONTENT_BLOCKS=()

setup_codex_cli() {
  local codex_path_line="export PATH=\"\$HOME/Codex/bin:\$PATH\""
  local fish_codex_path_marker="if not contains \"\$HOME/Codex/bin\" \$PATH"
  local fish_codex_path_block="if not contains \"\$HOME/Codex/bin\" \$PATH
    set -gx PATH \"\$HOME/Codex/bin\" \$PATH
end"

  if codex_cli_ready; then
    announce_detail "O Codex CLI já está configurado. Etapa ignorada."
    return 0
  fi

  require_command npm

  announce_detail "Configurando o prefixo do npm em $HOME/Codex..."
  if ! ops_npm_config_set_prefix "$HOME/Codex"; then
    announce_error "Não foi possível configurar o prefixo do npm para o Codex CLI."
    return 1
  fi

  ensure_shell_config_line "$BASHRC_FILE" "$codex_path_line" "$codex_path_line" || return 1
  ensure_shell_config_line "$ZSHRC_FILE" "$codex_path_line" "$codex_path_line" || return 1
  ensure_shell_config_line "$FISH_CONFIG_FILE" "$fish_codex_path_marker" "$fish_codex_path_block" || return 1

  export PATH="$HOME/Codex/bin:$PATH"

  announce_detail "Instalando Codex CLI em $HOME/Codex..."
  if ! ops_npm_install_codex_cli; then
    announce_error "Não foi possível instalar o Codex CLI."
    return 1
  fi

  if ! mark_checkpoint "codex_cli"; then
    announce_error "Não foi possível registrar o checkpoint do Codex CLI."
    return 1
  fi
}

ensure_shell_config_line() {
  local config_file="$1"
  local marker_line="$2"
  local content_block="$3"
  local operation_id=""

  mkdir -p "$(dirname "$config_file")"
  if [[ -f "$config_file" ]] && grep -qxF "$marker_line" "$config_file"; then
    return 0
  fi

  backup_sensitive_file_if_exists "$config_file" "backup shell config" || return 1
  operation_id="edit-shell-config:$(sanitize_label "$config_file")"
  SHELL_CONFIG_CONTENT_BLOCKS["$operation_id"]="$content_block"
  operation_plan_add \
    "$operation_id" \
    "filesystem" \
    "$config_file" \
    "edit shell config" \
    "medium" \
    "" \
    "allow" \
    "operation_shell_config_append_executor" \
    "restaurar $config_file pelo backup registrado" || return 1
  if [[ -n "${SAFETY_LAST_BACKUP_PATH:-}" ]]; then
    operation_plan_set_backup_path "$operation_id" "$SAFETY_LAST_BACKUP_PATH"
  fi
  operation_plan_execute "$operation_id"
}

operation_shell_config_append_executor() {
  local operation_id="$1"
  local config_file="${OPERATION_PLAN_TARGETS[$operation_id]:-}"
  local content_block="${SHELL_CONFIG_CONTENT_BLOCKS[$operation_id]:-}"

  [[ -n "$config_file" && -n "$content_block" ]] || return 1
  if [[ ! -f "$config_file" ]]; then
    touch "$config_file"
  fi

  printf '\n%s\n' "$content_block" >>"$config_file"
}

codex_cli_shell_configured() {
  local codex_path_line="export PATH=\"\$HOME/Codex/bin:\$PATH\""
  local fish_codex_path_marker="if not contains \"\$HOME/Codex/bin\" \$PATH"

  [[ -f "$BASHRC_FILE" ]] || return 1
  [[ -f "$ZSHRC_FILE" ]] || return 1
  [[ -f "$FISH_CONFIG_FILE" ]] || return 1

  grep -qxF "$codex_path_line" "$BASHRC_FILE" || return 1
  grep -qxF "$codex_path_line" "$ZSHRC_FILE" || return 1
  grep -qxF "$fish_codex_path_marker" "$FISH_CONFIG_FILE" || return 1
}

codex_cli_ready() {
  command -v codex >/dev/null 2>&1 && codex_cli_shell_configured
}

component_detect_codex_cli() {
  codex_cli_ready
}

component_apply_codex_cli() {
  local missing_packages=()

  component_enabled "codex_cli" || return 0

  collect_missing_packages missing_packages "${CODEX_CLI_PACKAGES[@]}"
  if ((${#missing_packages[@]} > 0)); then
    announce_detail "Instalando dependências do Codex CLI..."
    if ! ops_pacman_install_needed "${missing_packages[@]}"; then
      announce_error "Não foi possível instalar as dependências do Codex CLI."
      return 1
    fi
  fi

  if ! setup_codex_cli; then
    return 1
  fi
}

component_verify_codex_cli() {
  local package_name

  for package_name in "${CODEX_CLI_PACKAGES[@]}"; do
    case "$package_name" in
      nodejs)
        verify_command "nodejs" "nodejs" "node" "pacman_package" "nodejs"
        ;;
      *)
        verify_package "$package_name" "$package_name" "$package_name" "pacman_package" "$package_name"
        ;;
    esac
  done
  verify_command "codex" "codex" "codex" "codex_cli_setup" "codex_cli"
}
