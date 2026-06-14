#!/usr/bin/env bash
# shellcheck shell=bash

register_component() {
  local component_id="$1"
  shift

  local assignment=""
  local component_label=""
  local pipeline_phase=""
  local expected_function=""
  local pipeline_title=""
  local pipeline_step_function=""
  local summary_formatter=""
  local detect_handler=""
  local apply_handler=""
  local verify_handler=""
  local has_runtime_status=""
  local check_only_detection=""
  local verification_enabled=""
  local summary_status_enabled=""

  for assignment in "$@"; do
    case "$assignment" in
      label=*)
        component_label="${assignment#*=}"
        ;;
      pipeline_phase=*)
        pipeline_phase="${assignment#*=}"
        ;;
      expected_function=*)
        expected_function="${assignment#*=}"
        ;;
      pipeline_title=*)
        pipeline_title="${assignment#*=}"
        ;;
      pipeline_step_function=*)
        pipeline_step_function="${assignment#*=}"
        ;;
      summary_formatter=*)
        summary_formatter="${assignment#*=}"
        ;;
      detect_handler=*)
        detect_handler="${assignment#*=}"
        ;;
      apply_handler=*)
        apply_handler="${assignment#*=}"
        ;;
      verify_handler=*)
        verify_handler="${assignment#*=}"
        ;;
      has_runtime_status=*)
        has_runtime_status="${assignment#*=}"
        ;;
      check_only_detection=*)
        check_only_detection="${assignment#*=}"
        ;;
      verification_enabled=*)
        verification_enabled="${assignment#*=}"
        ;;
      summary_status_enabled=*)
        summary_status_enabled="${assignment#*=}"
        ;;
      *)
        printf 'Erro: metadado de componente desconhecido para %s: %s\n' "$component_id" "$assignment" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$component_id" || -z "$component_label" || -z "$pipeline_phase" || \
    -z "$expected_function" || -z "$pipeline_title" || -z "$pipeline_step_function" || \
    -z "$detect_handler" || -z "$apply_handler" || -z "$verify_handler" || \
    -z "$has_runtime_status" || -z "$check_only_detection" || \
    -z "$verification_enabled" || -z "$summary_status_enabled" ]]; then
    printf 'Erro: componente incompleto: %s\n' "${component_id:-indefinido}" >&2
    return 1
  fi

  COMPONENT_IDS+=("$component_id")
  COMPONENT_LABELS["$component_id"]="$component_label"
  COMPONENT_PIPELINE_PHASES["$component_id"]="$pipeline_phase"
  COMPONENT_EXPECTED_FUNCTIONS["$component_id"]="$expected_function"
  COMPONENT_PIPELINE_TITLES["$component_id"]="$pipeline_title"
  COMPONENT_PIPELINE_STEP_FUNCTIONS["$component_id"]="$pipeline_step_function"
  COMPONENT_SUMMARY_FORMATTERS["$component_id"]="$summary_formatter"
  COMPONENT_DETECT_HANDLERS["$component_id"]="$detect_handler"
  COMPONENT_APPLY_HANDLERS["$component_id"]="$apply_handler"
  COMPONENT_VERIFY_HANDLERS["$component_id"]="$verify_handler"
  COMPONENT_RUNTIME_STATUS_FLAGS["$component_id"]="$has_runtime_status"
  COMPONENT_CHECK_ONLY_DETECTION_FLAGS["$component_id"]="$check_only_detection"
  COMPONENT_VERIFICATION_FLAGS["$component_id"]="$verification_enabled"
  COMPONENT_SUMMARY_STATUS_FLAGS["$component_id"]="$summary_status_enabled"
}
