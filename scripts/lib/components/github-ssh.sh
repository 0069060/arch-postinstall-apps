#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# shellcheck source-path=SCRIPTDIR
# shellcheck source=scripts/lib/ops.sh
# shellcheck source=scripts/lib/status.sh
# shellcheck source=scripts/lib/components.sh
# shellcheck source=scripts/lib/repo.sh
# shellcheck source=scripts/lib/components/github-ssh/clipboard.sh
# shellcheck source=scripts/lib/components/github-ssh/auth.sh
# shellcheck source=scripts/lib/components/github-ssh/key.sh
# shellcheck source=scripts/lib/components/github-ssh/publish.sh
# shellcheck source=scripts/lib/components/github-ssh/state.sh
# shellcheck source=scripts/lib/components/github-ssh/apply.sh
# shellcheck source=scripts/lib/components/github-ssh/verify.sh

GITHUB_SSH_COMPONENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/github-ssh"
# shellcheck source=github-ssh/clipboard.sh
source "$GITHUB_SSH_COMPONENT_DIR/clipboard.sh"
# shellcheck source=github-ssh/auth.sh
source "$GITHUB_SSH_COMPONENT_DIR/auth.sh"
# shellcheck source=github-ssh/key.sh
source "$GITHUB_SSH_COMPONENT_DIR/key.sh"
# shellcheck source=github-ssh/publish.sh
source "$GITHUB_SSH_COMPONENT_DIR/publish.sh"
# shellcheck source=github-ssh/state.sh
source "$GITHUB_SSH_COMPONENT_DIR/state.sh"
# shellcheck source=github-ssh/apply.sh
source "$GITHUB_SSH_COMPONENT_DIR/apply.sh"
# shellcheck source=github-ssh/verify.sh
source "$GITHUB_SSH_COMPONENT_DIR/verify.sh"
