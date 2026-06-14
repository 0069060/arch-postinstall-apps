#!/usr/bin/env bash
# shellcheck shell=bash

repair_missing_pacman_packages() {
  local pacman_array_name="$1"
  local missing_array_name="$2"
  # shellcheck disable=SC2178
  declare -n repair_pacman_packages_ref="$pacman_array_name"
  # shellcheck disable=SC2178
  declare -n repair_missing_pacman_packages_ref="$missing_array_name"

  collect_missing_packages "$missing_array_name" "${repair_pacman_packages_ref[@]}"
  if ((${#repair_missing_pacman_packages_ref[@]} == 0)); then
    return 0
  fi

  announce_detail "Reinstalando itens via pacman..."
  ops_pacman_install_needed "${repair_missing_pacman_packages_ref[@]}"
}

repair_missing_aur_packages() {
  local aur_array_name="$1"
  local aur_package
  local aur_helper_name=""
  # shellcheck disable=SC2178
  declare -n repair_aur_packages_ref="$aur_array_name"

  if ((${#repair_aur_packages_ref[@]} == 0)); then
    return 0
  fi

  ensure_aur_helper || return 1

  for aur_package in "${repair_aur_packages_ref[@]}"; do
    if package_is_installed "$aur_package"; then
      continue
    fi

    announce_detail "Reinstalando item via AUR: $aur_package"
    aur_helper_name="$(state_get_aur_helper_name)"
    ops_aur_install_needed "$aur_helper_name" "$aur_package" || return 1
  done
}

repair_codex_cli_if_needed() {
  local codex_flag_name="$1"
  # shellcheck disable=SC2178
  declare -n repair_should_repair_codex_ref="$codex_flag_name"

  if (( repair_should_repair_codex_ref == 0 )); then
    return 0
  fi

  announce_detail "Reconfigurando o Codex CLI..."
  setup_codex_cli
}

repair_missing_repo_origins() {
  local origin_array_name="$1"
  local repo_dir=""
  # shellcheck disable=SC2178
  declare -n repair_origin_repos_ref="$origin_array_name"

  if ((${#repair_origin_repos_ref[@]} == 0)); then
    return 0
  fi

  announce_detail "Ajustando o remoto principal do repositório..."
  for repo_dir in "${repair_origin_repos_ref[@]}"; do
    if ! ensure_managed_repo_origin_ssh "$repo_dir" && ! ensure_repo_origin_remote "$repo_dir" "$REPO_SSH_URL"; then
      return 1
    fi
  done
}

repair_desktop_services_if_needed() {
  local service_flag_name="$1"
  local missing_pacman_array_name="$2"
  # shellcheck disable=SC2178
  declare -n repair_should_start_services_ref="$service_flag_name"
  # shellcheck disable=SC2178
  declare -n repair_missing_pacman_packages_ref="$missing_pacman_array_name"

  if (( repair_should_start_services_ref == 0 )) && ((${#repair_missing_pacman_packages_ref[@]} == 0)); then
    return 0
  fi

  announce_detail "Tentando iniciar os serviços de usuário necessários..."
  start_desktop_user_services || true
}

mark_desktop_checkpoint_after_repair() {
  if ! desktop_integration_ready; then
    return 0
  fi

  if has_checkpoint "desktop_integration"; then
    return 0
  fi

  if ! mark_checkpoint "desktop_integration"; then
    announce_warning "Não foi possível registrar o checkpoint da integração desktop após a correção automática."
  fi
}

run_final_repair_plan() {
  local pacman_array_name="$1"
  local aur_array_name="$2"
  local origin_array_name="$3"
  local missing_pacman_array_name="$4"
  local codex_flag_name="$5"
  local service_flag_name="$6"

  repair_missing_pacman_packages "$pacman_array_name" "$missing_pacman_array_name" || return 1
  repair_missing_aur_packages "$aur_array_name" || return 1
  repair_codex_cli_if_needed "$codex_flag_name" || return 1
  repair_missing_repo_origins "$origin_array_name" || return 1
  repair_desktop_services_if_needed "$service_flag_name" "$missing_pacman_array_name"
  mark_desktop_checkpoint_after_repair
}
