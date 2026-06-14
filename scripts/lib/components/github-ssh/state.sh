#!/usr/bin/env bash
# shellcheck shell=bash

build_ssh_key_name() {
  local github_login=""

  if [[ -n "$GITHUB_SSH_KEY_NAME" ]]; then
    printf '%s\n' "$GITHUB_SSH_KEY_NAME"
    return
  fi

  if command -v gh >/dev/null 2>&1; then
    github_login="$(ops_gh_get_authenticated_login 2>/dev/null || true)"
    if [[ -n "$github_login" ]]; then
      printf '%s\n' "$github_login"
      return
    fi
  fi

  printf '%s\n' "$USER"
}

github_ssh_explicit_name_requested() {
  [[ -n "$GITHUB_SSH_KEY_NAME" ]]
}

current_public_ssh_key() {
  [[ -f "${SSH_KEY_PATH}.pub" ]] || return 1
  awk 'NR == 1 { print $1, $2 }' "${SSH_KEY_PATH}.pub"
}

find_current_github_ssh_key() {
  local current_key
  local existing_keys=()
  local key_id=""
  local key_name=""
  local key_value=""

  current_key="$(current_public_ssh_key)" || return 1
  github_ssh_list_keys existing_keys >/dev/null 2>&1 || return 1
  ((${#existing_keys[@]} > 0)) || return 1

  while IFS=$'\t' read -r key_id key_name key_value; do
    [[ -n "$key_id" && -n "${key_value:-}" ]] || continue
    if [[ "$key_value" == "$current_key" ]]; then
      printf '%s\t%s\n' "$key_id" "$key_name"
      return 0
    fi
  done <<<"$(printf '%s\n' "${existing_keys[@]}")"

  return 1
}

github_has_expected_ssh_key_name() {
  local key_data
  local current_key_name=""

  if ! github_ssh_explicit_name_requested; then
    return 0
  fi

  key_data="$(find_current_github_ssh_key 2>/dev/null || true)"
  [[ -n "$key_data" ]] || return 1
  IFS=$'\t' read -r _ current_key_name <<<"$key_data"
  [[ "$current_key_name" == "$(build_ssh_key_name)" ]]
}

github_ssh_repo_origin_ready() {
  local repo_dir="$1"
  local expected_ssh_url=""
  local expected_https_url=""
  local preferred_transport=""

  [[ -d "$repo_dir/.git" ]] || return 0

  preferred_transport="$(managed_repo_preferred_transport "$repo_dir" 2>/dev/null || true)"
  if [[ "$preferred_transport" == "https" ]]; then
    expected_https_url="$(managed_repo_expected_https_origin_url "$repo_dir" 2>/dev/null || true)"
    [[ -n "$expected_https_url" ]] || return 1
    [[ "$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)" == "$expected_https_url" ]]
    return
  fi

  expected_ssh_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"
  if [[ -n "$expected_ssh_url" ]]; then
    [[ "$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)" == "$expected_ssh_url" ]]
    return
  fi

  [[ "$(current_repo_origin_status "$repo_dir")" == "ssh" ]]
}

github_ssh_ready() {
  local managed_repo_dirs=()
  local repo_dir=""

  [[ -f "${SSH_KEY_PATH}.pub" ]] || return 1
  command -v gh >/dev/null 2>&1 || return 1
  gh auth status >/dev/null 2>&1 || return 1
  github_ssh_repo_origin_ready "$SCRIPT_DIR" || return 1
  github_ssh_repo_origin_ready "$INSTALL_DIR" || return 1
  mapfile -t managed_repo_dirs < <(managed_environment_repo_dirs)
  for repo_dir in "${managed_repo_dirs[@]}"; do
    github_ssh_repo_origin_ready "$repo_dir" || return 1
  done
  github_has_expected_ssh_key_name
}

component_detect_github_ssh() {
  github_ssh_ready
}
