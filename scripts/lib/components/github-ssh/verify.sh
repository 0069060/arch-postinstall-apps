#!/usr/bin/env bash
# shellcheck shell=bash

component_verify_github_ssh() {
  local managed_repo_dirs=()
  local package_name
  local repo_dir=""
  local verification_id=""

  for package_name in "${GITHUB_SSH_SUPPORT_PACKAGES[@]}"; do
    case "$package_name" in
      github-cli)
        verify_command "github-cli" "github-cli" "gh" "pacman_package" "github-cli"
        ;;
      openssh)
        verify_command "openssh" "openssh" "ssh-keygen" "pacman_package" "openssh"
        ;;
    esac
  done

  if github_ssh_repo_origin_ready "$SCRIPT_DIR"; then
    state_add_verified_item "origin-ssh-script-dir" "origin-ssh-script-dir" "repo" "repo_origin_ssh" "$SCRIPT_DIR"
  else
    state_add_missing_item "origin-ssh-script-dir" "origin-ssh-script-dir" "repo" "repo_origin_ssh" "$SCRIPT_DIR"
  fi

  if [[ "$INSTALL_DIR" != "$SCRIPT_DIR" && -d "$INSTALL_DIR/.git" ]]; then
    if github_ssh_repo_origin_ready "$INSTALL_DIR"; then
      state_add_verified_item "origin-ssh-install-dir" "origin-ssh-install-dir" "repo" "repo_origin_ssh" "$INSTALL_DIR"
    else
      state_add_missing_item "origin-ssh-install-dir" "origin-ssh-install-dir" "repo" "repo_origin_ssh" "$INSTALL_DIR"
    fi
  fi

  mapfile -t managed_repo_dirs < <(managed_environment_repo_dirs)
  for repo_dir in "${managed_repo_dirs[@]}"; do
    [[ -d "$repo_dir/.git" ]] || continue
    verification_id="origin-ssh-$(basename "$repo_dir")"
    if github_ssh_repo_origin_ready "$repo_dir"; then
      state_add_verified_item "$verification_id" "$verification_id" "repo" "repo_origin_ssh" "$repo_dir"
    else
      state_add_missing_item "$verification_id" "$verification_id" "repo" "repo_origin_ssh" "$repo_dir"
    fi
  done
}
