#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

OPERATION_PLAN_IDS=()
declare -Ag OPERATION_PLAN_TYPES=()
declare -Ag OPERATION_PLAN_TARGETS=()
declare -Ag OPERATION_PLAN_DESCRIPTIONS=()
declare -Ag OPERATION_PLAN_RISKS=()
declare -Ag OPERATION_PLAN_CONFIRMATION_TEXTS=()
declare -Ag OPERATION_PLAN_NON_INTERACTIVE_POLICIES=()
declare -Ag OPERATION_PLAN_EXECUTORS=()
declare -Ag OPERATION_PLAN_STATUSES=()
declare -Ag OPERATION_PLAN_BACKUP_PATHS=()
declare -Ag OPERATION_PLAN_ROLLBACK_HINTS=()
declare -Ag OPERATION_PLAN_REASONS=()
declare -Ag OPERATION_PLAN_COMMANDS=()
declare -Ag OPERATION_PLAN_REQUIRES_ROOT=()

operation_plan_reset() {
  OPERATION_PLAN_IDS=()
  OPERATION_PLAN_TYPES=()
  OPERATION_PLAN_TARGETS=()
  OPERATION_PLAN_DESCRIPTIONS=()
  OPERATION_PLAN_RISKS=()
  OPERATION_PLAN_CONFIRMATION_TEXTS=()
  OPERATION_PLAN_NON_INTERACTIVE_POLICIES=()
  OPERATION_PLAN_EXECUTORS=()
  OPERATION_PLAN_STATUSES=()
  OPERATION_PLAN_BACKUP_PATHS=()
  OPERATION_PLAN_ROLLBACK_HINTS=()
  OPERATION_PLAN_REASONS=()
  OPERATION_PLAN_COMMANDS=()
  OPERATION_PLAN_REQUIRES_ROOT=()
}

operation_plan_contains_id() {
  local operation_id="$1"
  local existing_id

  for existing_id in "${OPERATION_PLAN_IDS[@]}"; do
    [[ "$existing_id" == "$operation_id" ]] && return 0
  done

  return 1
}

operation_plan_add() {
  local operation_id="$1"
  local operation_type="$2"
  local target="$3"
  local description="$4"
  local risk_level="${5:-low}"
  local confirmation_text="${6:-}"
  local non_interactive_policy="${7:-allow}"
  local executor_function="${8:-}"
  local rollback_hint="${9:-}"

  [[ -n "$operation_id" && -n "$operation_type" && -n "$target" && -n "$description" ]] || {
    announce_error "Operação incompleta não pôde ser planejada."
    return 1
  }

  if ! operation_plan_contains_id "$operation_id"; then
    OPERATION_PLAN_IDS+=("$operation_id")
  fi

  OPERATION_PLAN_TYPES["$operation_id"]="$operation_type"
  OPERATION_PLAN_TARGETS["$operation_id"]="$target"
  OPERATION_PLAN_DESCRIPTIONS["$operation_id"]="$description"
  OPERATION_PLAN_RISKS["$operation_id"]="$risk_level"
  OPERATION_PLAN_CONFIRMATION_TEXTS["$operation_id"]="$confirmation_text"
  OPERATION_PLAN_NON_INTERACTIVE_POLICIES["$operation_id"]="$non_interactive_policy"
  OPERATION_PLAN_EXECUTORS["$operation_id"]="$executor_function"
  OPERATION_PLAN_STATUSES["$operation_id"]="planned"
  OPERATION_PLAN_BACKUP_PATHS["$operation_id"]=""
  OPERATION_PLAN_ROLLBACK_HINTS["$operation_id"]="$rollback_hint"
  OPERATION_PLAN_REASONS["$operation_id"]="planejada"
  OPERATION_PLAN_COMMANDS["$operation_id"]=""
  OPERATION_PLAN_REQUIRES_ROOT["$operation_id"]="0"
}

operation_plan_set_status() {
  local operation_id="$1"
  local status="$2"
  local reason="${3:-}"

  OPERATION_PLAN_STATUSES["$operation_id"]="$status"
  OPERATION_PLAN_REASONS["$operation_id"]="$reason"
  report_record_planned_operation "$operation_id"
}

operation_plan_set_backup_path() {
  local operation_id="$1"
  local backup_path="$2"

  OPERATION_PLAN_BACKUP_PATHS["$operation_id"]="$backup_path"
}

operation_plan_set_command() {
  local operation_id="$1"
  local command_line="$2"
  local requires_root="${3:-0}"

  OPERATION_PLAN_COMMANDS["$operation_id"]="$command_line"
  OPERATION_PLAN_REQUIRES_ROOT["$operation_id"]="$requires_root"
}

operation_plan_describe_line() {
  local operation_id="$1"
  local confirmation_text="${OPERATION_PLAN_CONFIRMATION_TEXTS[$operation_id]:-}"
  local confirmation_label="não"
  local blocked_non_interactive="não"
  local command_line="${OPERATION_PLAN_COMMANDS[$operation_id]:-}"
  local root_label="não"

  [[ -n "$confirmation_text" ]] && confirmation_label="$confirmation_text"
  if [[ "${OPERATION_PLAN_NON_INTERACTIVE_POLICIES[$operation_id]:-allow}" == "block" ]]; then
    blocked_non_interactive="sim"
  fi
  if [[ "${OPERATION_PLAN_REQUIRES_ROOT[$operation_id]:-0}" == "1" ]]; then
    root_label="sim"
  fi

  printf '%s | tipo=%s | alvo=%s | risco=%s | comando=%s | exige root/sudo=%s | confirmação=%s | bloqueia não interativo=%s | status=%s\n' \
    "${OPERATION_PLAN_DESCRIPTIONS[$operation_id]:-}" \
    "${OPERATION_PLAN_TYPES[$operation_id]:-}" \
    "${OPERATION_PLAN_TARGETS[$operation_id]:-}" \
    "${OPERATION_PLAN_RISKS[$operation_id]:-}" \
    "${command_line:-nenhum}" \
    "$root_label" \
    "$confirmation_label" \
    "$blocked_non_interactive" \
    "${OPERATION_PLAN_STATUSES[$operation_id]:-planned}"
}

operation_plan_render() {
  local operation_id

  if ((${#OPERATION_PLAN_IDS[@]} == 0)); then
    printf '%s\n' "nenhuma operação planejada"
    return 0
  fi

  for operation_id in "${OPERATION_PLAN_IDS[@]}"; do
    operation_plan_describe_line "$operation_id"
  done
}

operation_plan_report_all() {
  local operation_id

  for operation_id in "${OPERATION_PLAN_IDS[@]}"; do
    report_record_planned_operation "$operation_id"
  done
}

operation_plan_blocked_non_interactive() {
  local operation_id="$1"

  [[ "${OPERATION_PLAN_NON_INTERACTIVE_POLICIES[$operation_id]:-allow}" == "block" ]] || return 1
  is_interactive_terminal && return 1
  return 0
}

operation_plan_confirm_if_required() {
  local operation_id="$1"
  local confirmation_text="${OPERATION_PLAN_CONFIRMATION_TEXTS[$operation_id]:-}"

  [[ -n "$confirmation_text" ]] || return 0
  confirm_dangerous_operation "${OPERATION_PLAN_DESCRIPTIONS[$operation_id]}" "$confirmation_text"
}

operation_plan_execute() {
  local operation_id="$1"
  local executor_function="${OPERATION_PLAN_EXECUTORS[$operation_id]:-}"
  local executor_status=0

  if [[ "$DRY_RUN" == "1" ]]; then
    operation_plan_set_status "$operation_id" "planned" "dry-run"
    return 2
  fi

  if operation_plan_blocked_non_interactive "$operation_id"; then
    announce_warning "Operação bloqueada em modo não interativo: ${OPERATION_PLAN_DESCRIPTIONS[$operation_id]}"
    operation_plan_set_status "$operation_id" "blocked" "ambiente não interativo"
    return 2
  fi

  if ! operation_plan_confirm_if_required "$operation_id"; then
    operation_plan_set_status "$operation_id" "blocked" "confirmação recusada"
    return 2
  fi

  [[ -n "$executor_function" ]] || {
    operation_plan_set_status "$operation_id" "failed" "executor ausente"
    return 1
  }

  if "$executor_function" "$operation_id"; then
    operation_plan_set_status "$operation_id" "succeeded" "executada"
    return 0
  else
    executor_status=$?
  fi

  case "$executor_status" in
    2)
      operation_plan_set_status "$operation_id" "skipped" "ignorada"
      ;;
    *)
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
      ;;
  esac
  return "$executor_status"
}
