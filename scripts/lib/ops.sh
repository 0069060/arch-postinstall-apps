#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

OPS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/ops"

# shellcheck source=ops/common.sh
source "$OPS_LIB_DIR/common.sh"
# shellcheck source=ops/privilege.sh
source "$OPS_LIB_DIR/privilege.sh"
# shellcheck source=ops/package.sh
source "$OPS_LIB_DIR/package.sh"
# shellcheck source=ops/filesystem.sh
source "$OPS_LIB_DIR/filesystem.sh"
# shellcheck source=ops/git.sh
source "$OPS_LIB_DIR/git.sh"
# shellcheck source=ops/github.sh
source "$OPS_LIB_DIR/github.sh"
# shellcheck source=ops/node.sh
source "$OPS_LIB_DIR/node.sh"
# shellcheck source=ops/ssh.sh
source "$OPS_LIB_DIR/ssh.sh"
# shellcheck source=ops/systemd.sh
source "$OPS_LIB_DIR/systemd.sh"
