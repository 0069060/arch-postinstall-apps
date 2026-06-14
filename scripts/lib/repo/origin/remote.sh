#!/usr/bin/env bash
# shellcheck shell=bash

ensure_repo_origin_remote() {
  local repo_dir="$1"
  local desired_origin_url="${2:-$REPO_HTTPS_URL}"
  local current_origin_url=""
  local allowed_origin_urls=()
  local managed_https_url=""
  local managed_ssh_url=""
  local allowed_origin_url=""
  local matches_allowed_origin=1

  current_origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"

  if [[ -z "$current_origin_url" ]]; then
    ops_git_remote_add_origin "$repo_dir" "$desired_origin_url"
    return
  fi

  allowed_origin_urls=("$REPO_HTTPS_URL" "$REPO_SSH_URL")
  managed_https_url="$(managed_repo_expected_https_origin_url "$repo_dir" 2>/dev/null || true)"
  managed_ssh_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"
  [[ -n "$managed_https_url" ]] && allowed_origin_urls+=("$managed_https_url")
  [[ -n "$managed_ssh_url" ]] && allowed_origin_urls+=("$managed_ssh_url")

  for allowed_origin_url in "${allowed_origin_urls[@]}"; do
    if [[ "$current_origin_url" == "$allowed_origin_url" ]]; then
      matches_allowed_origin=0
      break
    fi
  done

  if [[ "$matches_allowed_origin" != "0" ]]; then
    announce_detail "Foi detectado um remoto origin personalizado em $repo_dir. A configuração atual será mantida."
    return
  fi

  if [[ "$current_origin_url" != "$desired_origin_url" ]]; then
    ops_git_remote_set_origin "$repo_dir" "$desired_origin_url"
  fi
}

managed_repo_origin_matches_expected() {
  local repo_dir="$1"
  local current_origin_url=""
  local expected_https_url=""
  local expected_ssh_url=""

  current_origin_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  expected_https_url="$(managed_repo_expected_https_origin_url "$repo_dir" 2>/dev/null || true)"
  expected_ssh_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"
  [[ -n "$current_origin_url" && -n "$expected_https_url" && -n "$expected_ssh_url" ]] || return 1

  [[ "$current_origin_url" == "$expected_https_url" || "$current_origin_url" == "$expected_ssh_url" ]]
}
