#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

REPO_MANIFEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/manifest"

# shellcheck source=manifest/store.sh
source "$REPO_MANIFEST_LIB_DIR/store.sh"
# shellcheck source=manifest/registration.sh
source "$REPO_MANIFEST_LIB_DIR/registration.sh"
# shellcheck source=manifest/definitions.sh
source "$REPO_MANIFEST_LIB_DIR/definitions.sh"
# shellcheck source=manifest/queries.sh
source "$REPO_MANIFEST_LIB_DIR/queries.sh"
