#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

GITHUB_SSH_PUBLISH_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/publish"

# shellcheck source=publish/api.sh
source "$GITHUB_SSH_PUBLISH_LIB_DIR/api.sh"
# shellcheck source=publish/sync.sh
source "$GITHUB_SSH_PUBLISH_LIB_DIR/sync.sh"
