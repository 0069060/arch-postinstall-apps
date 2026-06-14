#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

if [[ "${MODULE_MANIFEST_LOADED:-0}" == "1" ]]; then
  return 0
fi
readonly MODULE_MANIFEST_LOADED=1

MODULE_MANIFEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/module-manifest"

# shellcheck source=module-manifest/registry.sh
source "$MODULE_MANIFEST_LIB_DIR/registry.sh"
# shellcheck source=module-manifest/files.sh
source "$MODULE_MANIFEST_LIB_DIR/files.sh"

unset MODULE_MANIFEST_LIB_DIR
