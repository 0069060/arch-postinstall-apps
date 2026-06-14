#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

REPAIR_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/repair"

# shellcheck source=repair/plan.sh
source "$REPAIR_LIB_DIR/plan.sh"
# shellcheck source=repair/actions.sh
source "$REPAIR_LIB_DIR/actions.sh"
# shellcheck source=repair/final-verification.sh
source "$REPAIR_LIB_DIR/final-verification.sh"
