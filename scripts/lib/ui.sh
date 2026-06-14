#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

UI_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/ui"

# shellcheck source=ui/styles.sh
source "$UI_LIB_DIR/styles.sh"
# shellcheck source=ui/logging.sh
source "$UI_LIB_DIR/logging.sh"
# shellcheck source=ui/notice.sh
source "$UI_LIB_DIR/notice.sh"
# shellcheck source=ui/summary-primitives.sh
source "$UI_LIB_DIR/summary-primitives.sh"
