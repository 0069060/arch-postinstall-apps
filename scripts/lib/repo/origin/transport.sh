#!/usr/bin/env bash
# shellcheck shell=bash

git_ssh_transport_ready() {
  local repo_url="$1"

  [[ -n "$repo_url" ]] || return 1
  command -v git >/dev/null 2>&1 || return 1

  GIT_SSH_COMMAND='ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new' \
    git ls-remote "$repo_url" HEAD >/dev/null 2>&1
}
