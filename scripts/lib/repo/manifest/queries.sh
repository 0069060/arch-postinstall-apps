#!/usr/bin/env bash
# shellcheck shell=bash

managed_repo_id_for_dir() {
  local expected_repo_dir="$1"
  local repo_id

  for repo_id in "${MANAGED_REPO_IDS[@]}"; do
    if [[ "${MANAGED_REPO_DIRS[$repo_id]}" == "$expected_repo_dir" ]]; then
      printf '%s\n' "$repo_id"
      return 0
    fi
  done

  return 1
}

managed_repo_expected_https_origin_url() {
  local repo_id=""

  repo_id="$(managed_repo_id_for_dir "$1")" || return 1
  printf '%s\n' "${MANAGED_REPO_HTTPS_URLS[$repo_id]}"
}

managed_repo_expected_ssh_origin_url() {
  local repo_id=""

  repo_id="$(managed_repo_id_for_dir "$1")" || return 1
  printf '%s\n' "${MANAGED_REPO_SSH_URLS[$repo_id]}"
}

managed_environment_repo_dirs() {
  local repo_id

  for repo_id in "${MANAGED_REPO_IDS[@]}"; do
    [[ "${MANAGED_REPO_ENVIRONMENT_FLAGS[$repo_id]}" == "1" ]] || continue
    printf '%s\n' "${MANAGED_REPO_DIRS[$repo_id]}"
  done
}

managed_repo_clone_submodules() {
  local repo_id=""

  repo_id="$(managed_repo_id_for_dir "$1")" || return 1
  printf '%s\n' "${MANAGED_REPO_CLONE_SUBMODULE_FLAGS[$repo_id]:-0}"
}

managed_repo_preferred_transport() {
  local repo_id=""

  repo_id="$(managed_repo_id_for_dir "$1")" || return 1
  printf '%s\n' "${MANAGED_REPO_PREFERRED_TRANSPORTS[$repo_id]:-auto}"
}

managed_repo_display_name() {
  local repo_id=""

  repo_id="$(managed_repo_id_for_dir "$1")" || {
    basename "$1"
    return 0
  }
  printf '%s\n' "${MANAGED_REPO_LABELS[$repo_id]}"
}
