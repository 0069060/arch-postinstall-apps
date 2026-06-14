#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

STATE_VERIFIED_ITEM_IDS=()
STATE_VERIFIED_ITEMS=()
STATE_MISSING_ITEM_IDS=()
STATE_MISSING_ITEMS=()
declare -Ag STATE_VERIFICATION_LABELS=()
declare -Ag STATE_VERIFICATION_KINDS=()
declare -Ag STATE_VERIFICATION_REPAIR_STRATEGIES=()
declare -Ag STATE_VERIFICATION_TARGETS=()
declare -Ag STATE_VERIFICATION_STATUSES=()
STATE_VERSION_LINES=()

state_reset_verification_results() {
  STATE_VERIFIED_ITEM_IDS=()
  STATE_VERIFIED_ITEMS=()
  STATE_MISSING_ITEM_IDS=()
  STATE_MISSING_ITEMS=()
  STATE_VERIFICATION_LABELS=()
  STATE_VERIFICATION_KINDS=()
  STATE_VERIFICATION_REPAIR_STRATEGIES=()
  STATE_VERIFICATION_TARGETS=()
  STATE_VERIFICATION_STATUSES=()
  STATE_VERSION_LINES=()
}

state_remove_array_item() {
  local array_name="$1"
  local value="$2"
  local filtered_items=()
  local item
  # shellcheck disable=SC2178
  declare -n target_array="$array_name"

  for item in "${target_array[@]}"; do
    [[ "$item" == "$value" ]] && continue
    filtered_items+=("$item")
  done

  target_array=("${filtered_items[@]}")
}

state_record_verification_item() {
  local verification_id="$1"
  local display_label="${2:-$1}"
  local item_kind="${3:-generic}"
  local repair_strategy="${4:-none}"
  local repair_target="${5:-}"
  local item_status="$6"

  [[ -n "$verification_id" ]] || return 1

  STATE_VERIFICATION_LABELS["$verification_id"]="$display_label"
  STATE_VERIFICATION_KINDS["$verification_id"]="$item_kind"
  STATE_VERIFICATION_REPAIR_STRATEGIES["$verification_id"]="$repair_strategy"
  STATE_VERIFICATION_TARGETS["$verification_id"]="$repair_target"
  STATE_VERIFICATION_STATUSES["$verification_id"]="$item_status"

  state_remove_array_item STATE_VERIFIED_ITEM_IDS "$verification_id"
  state_remove_array_item STATE_VERIFIED_ITEMS "$display_label"
  state_remove_array_item STATE_MISSING_ITEM_IDS "$verification_id"
  state_remove_array_item STATE_MISSING_ITEMS "$display_label"

  case "$item_status" in
    verified)
      append_array_item STATE_VERIFIED_ITEM_IDS "$verification_id"
      append_array_item STATE_VERIFIED_ITEMS "$display_label"
      ;;
    missing)
      append_array_item STATE_MISSING_ITEM_IDS "$verification_id"
      append_array_item STATE_MISSING_ITEMS "$display_label"
      ;;
    *)
      return 1
      ;;
  esac
}

state_add_verified_item() {
  state_record_verification_item "$1" "${2:-$1}" "${3:-generic}" "${4:-none}" "${5:-}" "verified"
}

state_add_missing_item() {
  state_record_verification_item "$1" "${2:-$1}" "${3:-generic}" "${4:-none}" "${5:-}" "missing"
}

state_add_version_line() {
  append_array_item STATE_VERSION_LINES "$1"
}

state_has_missing_items() {
  (( ${#STATE_MISSING_ITEM_IDS[@]} > 0 ))
}

state_has_verified_item() {
  local expected="$1"
  local item

  for item in "${STATE_VERIFIED_ITEM_IDS[@]}"; do
    [[ "$item" == "$expected" ]] && return 0
  done

  return 1
}

state_get_verification_label() {
  printf '%s\n' "${STATE_VERIFICATION_LABELS[$1]:-$1}"
}

state_get_verification_kind() {
  printf '%s\n' "${STATE_VERIFICATION_KINDS[$1]:-generic}"
}

state_get_verification_repair_strategy() {
  printf '%s\n' "${STATE_VERIFICATION_REPAIR_STRATEGIES[$1]:-none}"
}

state_get_verification_target() {
  printf '%s\n' "${STATE_VERIFICATION_TARGETS[$1]:-}"
}
