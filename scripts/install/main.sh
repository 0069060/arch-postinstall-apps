#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../lib/runtime-modules.sh
source "$REPO_DIR/scripts/lib/runtime-modules.sh"

source_runtime_modules "$REPO_DIR"

main() {
  local context_status=0

  load_runtime_invocation_context "$REPO_DIR" "$@" || context_status=$?
  if (( context_status == CLI_HELP_REQUESTED_STATUS )); then
    exit 0
  fi
  if (( context_status != 0 )); then
    exit "$context_status"
  fi

  runtime_state_init
  validate_managed_paths || exit 1
  trap cleanup EXIT

  ensure_not_root || exit 1
  acquire_lock || exit 1

  run_install
}

main "$@"
