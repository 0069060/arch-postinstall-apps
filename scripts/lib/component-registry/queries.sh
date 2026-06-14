#!/usr/bin/env bash
# shellcheck shell=bash

component_registry_ids() {
  print_config_array COMPONENT_IDS
}

component_pre_package_pipeline_ids() {
  print_component_ids_by_property COMPONENT_PIPELINE_PHASES "pre_package"
}

component_post_package_pipeline_ids() {
  print_component_ids_by_property COMPONENT_PIPELINE_PHASES "post_package"
}

component_check_only_detection_ids() {
  print_component_ids_by_property COMPONENT_CHECK_ONLY_DETECTION_FLAGS
}

component_verification_ids() {
  print_component_ids_by_property COMPONENT_VERIFICATION_FLAGS
}

component_summary_status_ids() {
  print_component_ids_by_property COMPONENT_SUMMARY_STATUS_FLAGS
}

component_summary_label() {
  printf '%s\n' "${COMPONENT_LABELS[$1]:-$1}"
}

component_is_expected() {
  local expected_function="${COMPONENT_EXPECTED_FUNCTIONS[$1]:-}"

  [[ -n "$expected_function" ]] || return 1
  "$expected_function"
}

component_has_runtime_status() {
  [[ "${COMPONENT_RUNTIME_STATUS_FLAGS[$1]:-0}" == "1" ]]
}

component_pipeline_step_function() {
  local pipeline_step_function="${COMPONENT_PIPELINE_STEP_FUNCTIONS[$1]:-}"

  [[ -n "$pipeline_step_function" ]] || return 1
  printf '%s\n' "$pipeline_step_function"
}

component_pipeline_title() {
  local pipeline_title="${COMPONENT_PIPELINE_TITLES[$1]:-}"

  [[ -n "$pipeline_title" ]] || return 1
  printf '%s\n' "$pipeline_title"
}

component_summary_formatter_function() {
  local summary_formatter="${COMPONENT_SUMMARY_FORMATTERS[$1]:-}"

  [[ -n "$summary_formatter" ]] || return 1
  printf '%s\n' "$summary_formatter"
}

component_action_handler() {
  local action="$1"
  local component_id="$2"
  local handler_name=""

  case "$action" in
    detect)
      handler_name="${COMPONENT_DETECT_HANDLERS[$component_id]:-}"
      ;;
    apply)
      handler_name="${COMPONENT_APPLY_HANDLERS[$component_id]:-}"
      ;;
    verify)
      handler_name="${COMPONENT_VERIFY_HANDLERS[$component_id]:-}"
      ;;
    *)
      return 1
      ;;
  esac

  [[ -n "$handler_name" ]] || return 1
  printf '%s\n' "$handler_name"
}
