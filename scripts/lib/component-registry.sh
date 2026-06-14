#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

COMPONENT_REGISTRY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/component-registry"

# shellcheck source=component-config.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/component-config.sh"
# shellcheck source=component-registry/store.sh
source "$COMPONENT_REGISTRY_LIB_DIR/store.sh"
# shellcheck source=component-registry/registration.sh
source "$COMPONENT_REGISTRY_LIB_DIR/registration.sh"
# shellcheck source=component-registry/queries.sh
source "$COMPONENT_REGISTRY_LIB_DIR/queries.sh"
