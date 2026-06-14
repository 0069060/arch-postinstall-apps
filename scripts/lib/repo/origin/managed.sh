#!/usr/bin/env bash
# shellcheck shell=bash

managed_repo_preferred_origin_url() {
  local repo_dir="$1"
  local https_url=""
  local ssh_url=""
  local preferred_transport=""

  https_url="$(managed_repo_expected_https_origin_url "$repo_dir" 2>/dev/null || true)"
  ssh_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"
  preferred_transport="$(managed_repo_preferred_transport "$repo_dir" 2>/dev/null || true)"
  [[ -n "$https_url" && -n "$ssh_url" ]] || return 1

  case "$preferred_transport" in
    https)
      printf '%s\n' "$https_url"
      return 0
      ;;
    ssh)
      printf '%s\n' "$ssh_url"
      return 0
      ;;
  esac

  if github_ssh_expected && git_ssh_transport_ready "$ssh_url"; then
    printf '%s\n' "$ssh_url"
    return 0
  fi

  printf '%s\n' "$https_url"
}

ensure_managed_repo_origin_remote() {
  local repo_dir="$1"
  local desired_origin_url=""

  desired_origin_url="$(managed_repo_preferred_origin_url "$repo_dir" 2>/dev/null || true)"
  [[ -n "$desired_origin_url" ]] || return 1

  ensure_repo_origin_remote "$repo_dir" "$desired_origin_url"
}

ensure_managed_repo_origin_ssh() {
  local repo_dir="$1"
  local desired_origin_url=""

  desired_origin_url="$(managed_repo_expected_ssh_origin_url "$repo_dir" 2>/dev/null || true)"
  [[ -n "$desired_origin_url" ]] || return 1

  ensure_repo_origin_remote "$repo_dir" "$desired_origin_url"
}

reconcile_managed_repo_origin_ssh() {
  local repo_dir="$1"
  local preferred_transport=""

  [[ -d "$repo_dir/.git" ]] || return 2
  preferred_transport="$(managed_repo_preferred_transport "$repo_dir" 2>/dev/null || true)"
  [[ "$preferred_transport" != "https" ]] || return 2

  if ! managed_repo_origin_matches_expected "$repo_dir"; then
    announce_detail "Foi detectado um remoto origin personalizado em $repo_dir. A configuração atual será mantida."
    return 2
  fi

  if ! ensure_managed_repo_origin_ssh "$repo_dir"; then
    return 1
  fi

  return 0
}

easyeffects_preset_origin_matches() {
  managed_repo_origin_matches_expected "$EASY_EFFECTS_PRESET_DIR"
}
