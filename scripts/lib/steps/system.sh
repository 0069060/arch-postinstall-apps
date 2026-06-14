#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

SYSTEM_STEPS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/system"

# shellcheck source=system/environment.sh
source "$SYSTEM_STEPS_LIB_DIR/environment.sh"
# shellcheck source=system/configuration.sh
source "$SYSTEM_STEPS_LIB_DIR/configuration.sh"
# shellcheck source=system/repositories.sh
source "$SYSTEM_STEPS_LIB_DIR/repositories.sh"
