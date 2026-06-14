#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

REPO_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/repo"

# shellcheck source=repo/manifest.sh
source "$REPO_LIB_DIR/manifest.sh"
# shellcheck source=repo/origin.sh
source "$REPO_LIB_DIR/origin.sh"
# shellcheck source=repo/relocation.sh
source "$REPO_LIB_DIR/relocation.sh"
# shellcheck source=repo/sync.sh
source "$REPO_LIB_DIR/sync.sh"
