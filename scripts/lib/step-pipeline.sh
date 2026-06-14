#!/usr/bin/env bash
# shellcheck shell=bash

append_runtime_component_steps() {
  local phase="$1"
  local component_ids=()
  local component_id
  local pipeline_title=""
  local pipeline_function=""

  case "$phase" in
    pre_package)
      mapfile -t component_ids < <(component_pre_package_pipeline_ids)
      ;;
    post_package)
      mapfile -t component_ids < <(component_post_package_pipeline_ids)
      ;;
    *)
      printf 'Erro: fase de pipeline desconhecida: %s\n' "$phase" >&2
      return 1
      ;;
  esac

  for component_id in "${component_ids[@]}"; do
    pipeline_title="$(component_pipeline_title "$component_id")"
    pipeline_function="$(component_pipeline_step_function "$component_id")"
    pipeline_add_step "$component_id" "install" "$pipeline_title" "$pipeline_function" "1"
  done
}

append_runtime_install_pipeline() {
  local package_array_name="$1"
  local origin_status=0

  append_registered_step "create_directories"
  append_registered_step "relocate_home_backups"
  append_registered_step "relocate_home_repositories"
  append_registered_step "ensure_multilib"
  append_registered_step "update_system"
  append_registered_step "install_local_support_packages"
  append_runtime_component_steps "pre_package"
  append_registered_step "sync_managed_repositories"

  if target_packages_have_official_entries "$package_array_name"; then
    append_registered_step "prepare_package_installation"
    append_registered_step "install_official_packages" "$package_array_name"
  else
    origin_status=$?
    if [[ "$origin_status" != "1" ]]; then
      return 1
    fi
  fi

  if target_packages_have_aur_entries "$package_array_name"; then
    if ! pipeline_contains_step_id "prepare_package_installation"; then
      append_registered_step "prepare_package_installation"
    fi
    append_registered_step "install_aur_packages" "$package_array_name"
  else
    origin_status=$?
    if [[ "$origin_status" != "1" ]]; then
      return 1
    fi
  fi

  if pipeline_contains_step_id "prepare_package_installation"; then
    append_registered_step "finalize_package_installation"
  fi

  append_runtime_component_steps "post_package"
  append_registered_step "final_verification" "$package_array_name"
}

define_runtime_pipeline() {
  local package_array_name="$1"

  pipeline_reset
  if [[ "$DRY_RUN" == "1" ]]; then
    append_registered_step "load_configuration" "$package_array_name"
    append_registered_step "dry_run_plan" "$package_array_name"
    return 0
  fi

  append_registered_step "runtime_validate_environment"
  append_registered_step "load_configuration" "$package_array_name"

  if [[ "$CHECK_ONLY" == "1" ]]; then
    append_registered_step "check_only_verification" "$package_array_name"
  fi
}

define_bootstrap_pipeline() {
  local missing_packages_array_name="$1"

  pipeline_reset
  append_registered_step "bootstrap_validate_environment"
  append_registered_step "bootstrap_check_dependencies" "$missing_packages_array_name"

  if bootstrap_missing_packages_present "$missing_packages_array_name"; then
    append_registered_step "bootstrap_install_dependencies" "$missing_packages_array_name"
  fi

  append_registered_step "bootstrap_sync_repo"
}

bootstrap_missing_packages_present() {
  local array_name="$1"
  declare -n missing_packages="$array_name"

  (( ${#missing_packages[@]} > 0 ))
}
