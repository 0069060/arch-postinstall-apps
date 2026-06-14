#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

PACKAGE_CONFIG_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/package-config"

# shellcheck source=package-config/parser.sh
source "$PACKAGE_CONFIG_LIB_DIR/parser.sh"
# shellcheck source=package-config/origin.sh
source "$PACKAGE_CONFIG_LIB_DIR/origin.sh"
# shellcheck source=package-config/reporting.sh
source "$PACKAGE_CONFIG_LIB_DIR/reporting.sh"
