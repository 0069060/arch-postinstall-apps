#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

REPORT_CHANGE_MARKERS=()
REPORT_SAFETY_OPERATIONS=()

report_reset_changes() {
  REPORT_CHANGE_MARKERS=()
  REPORT_SAFETY_OPERATIONS=()
}

report_mark_change() {
  append_array_item REPORT_CHANGE_MARKERS "$1"
}

report_record_safety_operation() {
  local operation="$1"
  local target="$2"
  local backup_path="${3:-}"
  local status="${4:-}"
  local reason="${5:-}"
  local rollback_hint="${6:-}"

  REPORT_SAFETY_OPERATIONS+=("$operation"$'\t'"$target"$'\t'"${backup_path:-nenhum}"$'\t'"$status"$'\t'"$reason"$'\t'"$rollback_hint")
}

report_record_planned_operation() {
  local operation_id="$1"
  local operation="${OPERATION_PLAN_DESCRIPTIONS[$operation_id]:-}"
  local target="${OPERATION_PLAN_TARGETS[$operation_id]:-}"
  local backup_path="${OPERATION_PLAN_BACKUP_PATHS[$operation_id]:-}"
  local status="${OPERATION_PLAN_STATUSES[$operation_id]:-planned}"
  local reason="${OPERATION_PLAN_REASONS[$operation_id]:-}"
  local rollback_hint="${OPERATION_PLAN_ROLLBACK_HINTS[$operation_id]:-}"

  [[ -n "$operation" && -n "$target" ]] || return 0
  report_record_safety_operation "$operation" "$target" "$backup_path" "$status" "$reason" "$rollback_hint"
}

report_safety_operation_lines() {
  local entry
  local operation=""
  local target=""
  local backup_path=""
  local status=""
  local reason=""
  local rollback_hint=""

  if ((${#REPORT_SAFETY_OPERATIONS[@]} == 0)); then
    printf '%s\n' "nenhuma"
    return 0
  fi

  for entry in "${REPORT_SAFETY_OPERATIONS[@]}"; do
    IFS=$'\t' read -r operation target backup_path status reason rollback_hint <<<"$entry"
    printf '%s | alvo=%s | backup=%s | status=%s | motivo=%s' \
      "$operation" "$target" "$backup_path" "$status" "$reason"
    if [[ -n "$rollback_hint" ]]; then
      printf ' | rollback=%s' "$rollback_hint"
    fi
    printf '\n'
  done
}

report_has_changes() {
  local component_id
  local component_outcome

  if (( ${#REPORT_CHANGE_MARKERS[@]} > 0 )); then
    return 0
  fi

  if (( ${#REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES[@]} > 0 || \
    ${#REPORT_CHANGED_MAIN_AUR_PACKAGES[@]} > 0 || \
    ${#REPORT_CHANGED_SUPPORT_PACKAGES[@]} > 0 || \
    ${#REPORT_CHANGED_ENVIRONMENT_PACKAGES[@]} > 0 )); then
    return 0
  fi

  for component_id in "${!REPORT_COMPONENT_OUTCOMES[@]}"; do
    component_outcome="${REPORT_COMPONENT_OUTCOMES[$component_id]:-}"
    [[ "$(component_outcome_changed_flag "$component_outcome")" == "1" ]] && return 0
  done

  return 1
}
