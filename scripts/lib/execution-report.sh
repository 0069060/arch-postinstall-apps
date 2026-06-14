#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

EXECUTION_REPORT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/execution-report"

# shellcheck source=execution-report/changes.sh
source "$EXECUTION_REPORT_LIB_DIR/changes.sh"
# shellcheck source=execution-report/packages.sh
source "$EXECUTION_REPORT_LIB_DIR/packages.sh"
# shellcheck source=execution-report/components.sh
source "$EXECUTION_REPORT_LIB_DIR/components.sh"

execution_report_reset() {
  report_reset_changes
  report_reset_packages
  report_reset_component_outcomes
}
