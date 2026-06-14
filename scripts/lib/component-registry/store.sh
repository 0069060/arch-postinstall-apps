#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

COMPONENT_IDS=()
declare -Ag COMPONENT_LABELS=()
declare -Ag COMPONENT_PIPELINE_PHASES=()
declare -Ag COMPONENT_EXPECTED_FUNCTIONS=()
declare -Ag COMPONENT_PIPELINE_TITLES=()
declare -Ag COMPONENT_PIPELINE_STEP_FUNCTIONS=()
declare -Ag COMPONENT_SUMMARY_FORMATTERS=()
declare -Ag COMPONENT_DETECT_HANDLERS=()
declare -Ag COMPONENT_APPLY_HANDLERS=()
declare -Ag COMPONENT_VERIFY_HANDLERS=()
declare -Ag COMPONENT_RUNTIME_STATUS_FLAGS=()
declare -Ag COMPONENT_CHECK_ONLY_DETECTION_FLAGS=()
declare -Ag COMPONENT_VERIFICATION_FLAGS=()
declare -Ag COMPONENT_SUMMARY_STATUS_FLAGS=()

print_component_ids_by_property() {
  local property_name="$1"
  local expected_value="${2:-1}"
  local component_id
  # shellcheck disable=SC2178
  declare -n property_map="$property_name"

  for component_id in "${COMPONENT_IDS[@]}"; do
    [[ "${property_map[$component_id]:-}" == "$expected_value" ]] || continue
    printf '%s\n' "$component_id"
  done
}
