#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

REPO_ORIGIN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/origin"

# shellcheck source=origin/status.sh
source "$REPO_ORIGIN_LIB_DIR/status.sh"
# shellcheck source=origin/remote.sh
source "$REPO_ORIGIN_LIB_DIR/remote.sh"
# shellcheck source=origin/transport.sh
source "$REPO_ORIGIN_LIB_DIR/transport.sh"
# shellcheck source=origin/managed.sh
source "$REPO_ORIGIN_LIB_DIR/managed.sh"
