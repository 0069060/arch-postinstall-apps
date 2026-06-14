#!/usr/bin/env bash
# shellcheck shell=bash

collect_summary_context() {
  SUMMARY_HOST_NAME="$(get_host_name)"
  SUMMARY_BRANCH="$(get_repo_branch "$SCRIPT_DIR" 2>/dev/null || printf '%s\n' "main")"
  SUMMARY_COMMIT="$(current_repo_commit_short "$SCRIPT_DIR")"
  SUMMARY_REPO_PATH="$SCRIPT_DIR"
  SUMMARY_ORIGIN_STATUS="$(current_repo_origin_status "$SCRIPT_DIR")"
  SUMMARY_EXECUTION_MODE="instalação"
  SUMMARY_CHANGES_APPLIED="não"

  if [[ "$CHECK_ONLY" == "1" ]]; then
    SUMMARY_EXECUTION_MODE="verificação"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    SUMMARY_EXECUTION_MODE="dry-run"
    return 0
  fi

  if report_has_changes; then
    SUMMARY_CHANGES_APPLIED="sim"
  fi
}

summary_github_ssh_expected_text() {
  if github_ssh_expected; then
    printf 'sim\n'
    return 0
  fi

  printf 'não\n'
}

collect_summary_ready_components() {
  local source_array_name="$1"
  local target_array_name="$2"
  local collected_ready_components=()
  local component_id
  # shellcheck disable=SC2178
  declare -n summary_status_component_ids="$source_array_name"
  # shellcheck disable=SC2178
  declare -n summary_target_components="$target_array_name"

  for component_id in "${summary_status_component_ids[@]}"; do
    if report_component_counts_as_ready "$component_id"; then
      collected_ready_components+=("$component_id")
    fi
  done

  summary_target_components=("${collected_ready_components[@]}")
}
