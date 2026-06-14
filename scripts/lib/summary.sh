#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

SUMMARY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/summary"

# shellcheck source=summary/context.sh
source "$SUMMARY_LIB_DIR/context.sh"
# shellcheck source=summary/render.sh
source "$SUMMARY_LIB_DIR/render.sh"
# shellcheck source=summary/writer.sh
source "$SUMMARY_LIB_DIR/writer.sh"

print_summary() {
  local status_component_ids=()
  local ready_components=()

  collect_summary_context
  mapfile -t status_component_ids < <(component_summary_status_ids)
  collect_summary_ready_components status_component_ids ready_components

  close_step_block

  if [[ "$STEP_OUTPUT_ONLY" == "1" ]]; then
    print_step_output_summary status_component_ids
  else
    print_full_summary status_component_ids ready_components
  fi

  write_summary_file status_component_ids ready_components
}
