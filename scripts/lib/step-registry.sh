#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

STEP_DEFINITION_IDS=()
declare -Ag STEP_DEFINITION_MODES=()
declare -Ag STEP_DEFINITION_TITLES=()
declare -Ag STEP_DEFINITION_FUNCTIONS=()
declare -Ag STEP_DEFINITION_COUNT_FLAGS=()

register_step_definition() {
  local step_id="$1"
  shift

  local assignment=""
  local step_mode=""
  local step_title=""
  local step_function=""
  local count_for_progress=""

  for assignment in "$@"; do
    case "$assignment" in
      mode=*)
        step_mode="${assignment#*=}"
        ;;
      title=*)
        step_title="${assignment#*=}"
        ;;
      function=*)
        step_function="${assignment#*=}"
        ;;
      count_for_progress=*)
        count_for_progress="${assignment#*=}"
        ;;
      *)
        printf 'Erro: metadado de etapa desconhecido para %s: %s\n' "$step_id" "$assignment" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$step_id" || -z "$step_mode" || -z "$step_function" || -z "$count_for_progress" ]]; then
    printf 'Erro: etapa incompleta: %s\n' "${step_id:-indefinida}" >&2
    return 1
  fi

  STEP_DEFINITION_IDS+=("$step_id")
  STEP_DEFINITION_MODES["$step_id"]="$step_mode"
  STEP_DEFINITION_TITLES["$step_id"]="$step_title"
  STEP_DEFINITION_FUNCTIONS["$step_id"]="$step_function"
  STEP_DEFINITION_COUNT_FLAGS["$step_id"]="$count_for_progress"
}

step_definition_mode() {
  printf '%s\n' "${STEP_DEFINITION_MODES[$1]:-}"
}

step_definition_title() {
  printf '%s\n' "${STEP_DEFINITION_TITLES[$1]:-}"
}

step_definition_function() {
  printf '%s\n' "${STEP_DEFINITION_FUNCTIONS[$1]:-}"
}

step_definition_count_flag() {
  printf '%s\n' "${STEP_DEFINITION_COUNT_FLAGS[$1]:-0}"
}

append_registered_step() {
  local step_id="$1"
  local step_args="${2:-}"
  local step_mode=""
  local step_title=""
  local step_function=""
  local step_count_flag="0"

  step_mode="$(step_definition_mode "$step_id")"
  step_title="$(step_definition_title "$step_id")"
  step_function="$(step_definition_function "$step_id")"
  step_count_flag="$(step_definition_count_flag "$step_id")"

  [[ -n "$step_mode" && -n "$step_function" ]] || {
    printf 'Erro: etapa não registrada: %s\n' "$step_id" >&2
    return 1
  }

  pipeline_add_step "$step_id" "$step_mode" "$step_title" "$step_function" "$step_count_flag" "$step_args"
}
