#!/usr/bin/env bash
# shellcheck shell=bash

is_interactive_terminal() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

dangerous_confirmation_matches() {
  local expected_text="$1"
  local actual_text="$2"

  [[ -n "$actual_text" && "$actual_text" == "$expected_text" ]]
}

confirm_dangerous_operation() {
  local operation_label="$1"
  local expected_text="$2"
  local response=""

  [[ -n "$expected_text" ]] || return 1

  announce_warning "$operation_label"
  announce_prompt "Digite '$expected_text' para confirmar:"
  if ! is_interactive_terminal; then
    announce_warning "Confirmação bloqueada: terminal interativo indisponível."
    return 1
  fi

  IFS= read -r response </dev/tty || true
  dangerous_confirmation_matches "$expected_text" "$response"
}

safety_timestamp() {
  date +%Y%m%d%H%M%S
}

safety_backup_dir() {
  printf '%s/arch-postinstall-sensitive/%s\n' "$BACKUPS_DIR" "$(safety_timestamp)"
}

safety_backup_path_for() {
  local source_path="$1"
  local backup_dir="$2"
  local source_label=""
  local backup_path=""
  local suffix=1

  source_label="$(sanitize_label "${source_path#/}")"
  backup_path="$backup_dir/$source_label"
  while [[ -e "$backup_path" || -L "$backup_path" ]]; do
    backup_path="$backup_dir/$source_label.$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$backup_path"
}

backup_sensitive_file_if_exists() {
  local source_path="$1"
  local operation_label="$2"
  local operation_id="${3:-backup:$(sanitize_label "$source_path")}"
  local backup_dir=""
  local backup_path=""

  SAFETY_LAST_BACKUP_PATH=""
  operation_plan_add "$operation_id" "backup" "$source_path" "$operation_label" "medium" "" "allow" "" "restaurar arquivo a partir do backup"

  if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
    operation_plan_set_status "$operation_id" "skipped" "arquivo inexistente"
    return 0
  fi

  backup_dir="$(safety_backup_dir)"
  mkdir -p "$backup_dir"
  backup_path="$(safety_backup_path_for "$source_path" "$backup_dir")"
  operation_plan_set_backup_path "$operation_id" "$backup_path"
  if cp -p -- "$source_path" "$backup_path"; then
    SAFETY_LAST_BACKUP_PATH="$backup_path"
    operation_plan_set_status "$operation_id" "succeeded" "backup criado"
    announce_detail "Backup criado: $backup_path"
    return 0
  fi

  operation_plan_set_status "$operation_id" "failed" "falha ao criar backup"
  announce_error "Não foi possível criar backup de $source_path."
  return 1
}

backup_sensitive_system_file_if_exists() {
  local source_path="$1"
  local operation_label="$2"
  local operation_id="${3:-system-backup:$(sanitize_label "$source_path")}"
  local backup_dir=""
  local backup_path=""

  SAFETY_LAST_BACKUP_PATH=""
  operation_plan_add "$operation_id" "backup" "$source_path" "$operation_label" "high" "" "allow" "" "restaurar arquivo de sistema a partir do backup"

  if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
    operation_plan_set_status "$operation_id" "skipped" "arquivo inexistente"
    return 0
  fi

  backup_dir="$(safety_backup_dir)"
  mkdir -p "$backup_dir"
  backup_path="$(safety_backup_path_for "$source_path" "$backup_dir")"
  operation_plan_set_backup_path "$operation_id" "$backup_path"
  if sudo cat "$source_path" >"$backup_path"; then
    SAFETY_LAST_BACKUP_PATH="$backup_path"
    chmod 600 "$backup_path"
    operation_plan_set_status "$operation_id" "succeeded" "backup criado"
    announce_detail "Backup criado: $backup_path"
    return 0
  fi

  operation_plan_set_status "$operation_id" "failed" "falha ao criar backup"
  announce_error "Não foi possível criar backup de $source_path."
  return 1
}

confirm_home_relocation_batch() {
  local operation_label="$1"
  local target_label="$2"
  local destination_path="$3"
  local expected_text="$4"
  local operation_id="${5:-home-relocation:$(sanitize_label "$operation_label:$target_label")}"
  local policy="block"

  announce_warning "$operation_label"
  announce_detail "Alvo: $target_label"
  announce_detail "Destino: $destination_path"

  if [[ "$ALLOW_HOME_CHANGES" == "1" ]]; then
    policy="allow"
  fi
  operation_plan_add "$operation_id" "filesystem" "$target_label -> $destination_path" "$operation_label" "high" "$expected_text" "$policy" "" "mover manualmente de volta se necessário"

  if [[ "$DRY_RUN" == "1" ]]; then
    operation_plan_set_status "$operation_id" "planned" "dry-run"
    return 2
  fi

  if [[ "$ALLOW_HOME_CHANGES" == "1" ]]; then
    announce_detail "Alterações em HOME permitidas por --allow-home-changes."
    operation_plan_set_status "$operation_id" "succeeded" "permitida por flag"
    return 0
  fi

  if ! is_interactive_terminal; then
    announce_warning "Operação bloqueada em modo não interativo. Use --allow-home-changes para permitir explicitamente."
    operation_plan_set_status "$operation_id" "blocked" "ambiente não interativo"
    return 2
  fi

  if confirm_dangerous_operation "$operation_label" "$expected_text"; then
    operation_plan_set_status "$operation_id" "succeeded" "confirmada"
    return 0
  fi

  announce_warning "Operação cancelada: confirmação textual não recebida."
  operation_plan_set_status "$operation_id" "blocked" "confirmação recusada"
  return 2
}

confirm_system_config_edit() {
  local target_path="$1"
  local expected_text="EDIT PACMAN CONFIG"
  local operation_id="${2:-system-config:$(sanitize_label "$target_path")}"
  local policy="block"

  if [[ "$ALLOW_SYSTEM_CONFIG" == "1" ]]; then
    policy="allow"
  fi
  operation_plan_add "$operation_id" "system-config" "$target_path" "edit system config" "high" "$expected_text" "$policy" "" "restaurar arquivo pelo backup registrado"

  if [[ "$DRY_RUN" == "1" ]]; then
    operation_plan_set_status "$operation_id" "planned" "dry-run"
    return 2
  fi

  if [[ "$ALLOW_SYSTEM_CONFIG" == "1" ]]; then
    announce_detail "Edição de configuração de sistema permitida por --allow-system-config."
    operation_plan_set_status "$operation_id" "succeeded" "permitida por flag"
    return 0
  fi

  if ! is_interactive_terminal; then
    announce_warning "Edição de $target_path bloqueada em modo não interativo. Use --allow-system-config para permitir explicitamente."
    operation_plan_set_status "$operation_id" "blocked" "ambiente não interativo"
    return 2
  fi

  if confirm_dangerous_operation "A edição de $target_path requer confirmação explícita." "$expected_text"; then
    operation_plan_set_status "$operation_id" "succeeded" "confirmada"
    return 0
  fi

  operation_plan_set_status "$operation_id" "blocked" "confirmação recusada"
  return 2
}

operation_filesystem_move_executor() {
  local operation_id="$1"
  local target="${OPERATION_PLAN_TARGETS[$operation_id]:-}"
  local source_path="${target%% -> *}"
  local destination_path="${target#* -> }"

  [[ -n "$source_path" && -n "$destination_path" && "$source_path" != "$destination_path" ]] || return 1
  mv -- "$source_path" "$destination_path"
}

execute_planned_filesystem_move() {
  local operation_id="$1"
  local source_path="$2"
  local destination_path="$3"
  local description="$4"
  local rollback_hint="$5"

  operation_plan_add \
    "$operation_id" \
    "filesystem" \
    "$source_path -> $destination_path" \
    "$description" \
    "medium" \
    "" \
    "allow" \
    "operation_filesystem_move_executor" \
    "$rollback_hint" || return 1
  operation_plan_execute "$operation_id"
}
