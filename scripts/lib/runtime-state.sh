#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

RUNTIME_STATE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/runtime-state"

# shellcheck source=runtime-state/packages.sh
source "$RUNTIME_STATE_LIB_DIR/packages.sh"
# shellcheck source=runtime-state/verification.sh
source "$RUNTIME_STATE_LIB_DIR/verification.sh"
# shellcheck source=runtime-state/runtime-flags.sh
source "$RUNTIME_STATE_LIB_DIR/runtime-flags.sh"

runtime_state_reset() {
  state_reset_package_results
  state_reset_verification_results
  state_reset_runtime_flags
}
