#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

declare -Ag REPORT_COMPONENT_OUTCOMES=()

report_reset_component_outcomes() {
  REPORT_COMPONENT_OUTCOMES=()
}

report_set_component_outcome() {
  local component_id="$1"
  local outcome="$2"

  REPORT_COMPONENT_OUTCOMES["$component_id"]="$outcome"

  if [[ "$(component_outcome_changed_flag "$outcome")" == "1" ]]; then
    report_mark_change "component:$component_id"
  fi

  return 0
}

report_get_component_outcome() {
  printf '%s\n' "${REPORT_COMPONENT_OUTCOMES[$1]:-$COMPONENT_OUTCOME_PENDING}"
}

report_component_counts_as_ready() {
  local component_id="$1"

  component_outcome_counts_as_ready "$(report_get_component_outcome "$component_id")"
}
