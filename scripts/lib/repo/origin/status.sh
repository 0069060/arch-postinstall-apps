#!/usr/bin/env bash
# shellcheck shell=bash

get_repo_branch() {
  local repo_dir="$1"
  local branch_name=""

  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 1
  fi

  branch_name="$(git -C "$repo_dir" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [[ -n "$branch_name" ]]; then
    printf '%s\n' "$branch_name"
    return 0
  fi

  branch_name="$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || true)"
  [[ -n "$branch_name" ]] || return 1
  printf 'detached@%s\n' "$branch_name"
}

current_repo_origin_status() {
  local repo_dir="$1"
  local current_origin_url=""
  local managed_https_url=""
  local managed_ssh_url=""

  current_origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  managed_https_url="$(managed_repo_expected_https_origin_url "$repo_dir" 2>/dev/null || true)"
  managed_ssh_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"

  if [[ -z "$current_origin_url" ]]; then
    printf '%s\n' "ausente"
    return 0
  fi

  if [[ "$current_origin_url" == "$REPO_SSH_URL" || ( -n "$managed_ssh_url" && "$current_origin_url" == "$managed_ssh_url" ) ]]; then
    printf '%s\n' "ssh"
    return 0
  fi

  if [[ "$current_origin_url" == "$REPO_HTTPS_URL" || ( -n "$managed_https_url" && "$current_origin_url" == "$managed_https_url" ) ]]; then
    printf '%s\n' "https"
    return 0
  fi

  printf '%s\n' "personalizado"
}

current_repo_commit_short() {
  local repo_dir="$1"
  local commit_hash=""

  commit_hash="$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || true)"
  [[ -n "$commit_hash" ]] || {
    printf '%s\n' "indisponível"
    return 0
  }

  printf '%s\n' "$commit_hash"
}
