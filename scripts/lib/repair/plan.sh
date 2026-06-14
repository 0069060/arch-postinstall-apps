#!/usr/bin/env bash
# shellcheck shell=bash

collect_package_classify_repair() {
  local verification_label="$1"
  local repair_target="$2"
  local pacman_array_name="$3"
  local aur_array_name="$4"
  local package_origin_status=0

  [[ -n "$repair_target" ]] || {
    announce_error "Item ausente sem alvo classificável para reparo: $verification_label"
    return 1
  }

  if package_exists_in_official_repos "$repair_target"; then
    package_origin_status=0
  else
    package_origin_status=$?
  fi

  if [[ "$package_origin_status" == "0" ]]; then
    append_array_item "$pacman_array_name" "$repair_target"
    return 0
  fi

  if [[ "$package_origin_status" == "2" ]]; then
    announce_error "Não foi possível classificar o item ausente '$verification_label' para a correção automática."
    return 1
  fi

  append_array_item "$aur_array_name" "$repair_target"
}

collect_final_repair_item() {
  local verification_id="$1"
  local pacman_array_name="$2"
  local aur_array_name="$3"
  local origin_array_name="$4"
  local codex_flag_name="$5"
  local service_flag_name="$6"
  local verification_label=""
  local repair_strategy=""
  local repair_target=""
  # shellcheck disable=SC2178
  declare -n repair_should_repair_codex_ref="$codex_flag_name"
  # shellcheck disable=SC2178
  declare -n repair_should_start_services_ref="$service_flag_name"

  verification_label="$(state_get_verification_label "$verification_id")"
  repair_strategy="$(state_get_verification_repair_strategy "$verification_id")"
  repair_target="$(state_get_verification_target "$verification_id")"

  case "$repair_strategy" in
    none|"")
      return 0
      ;;
    pacman_package)
      [[ -n "$repair_target" ]] || {
        announce_error "Item ausente sem alvo de reparo via pacman: $verification_label"
        return 1
      }
      append_array_item "$pacman_array_name" "$repair_target"
      ;;
    package_classify)
      collect_package_classify_repair "$verification_label" "$repair_target" "$pacman_array_name" "$aur_array_name"
      ;;
    service_start)
      repair_should_start_services_ref=1
      ;;
    codex_cli_setup)
      repair_should_repair_codex_ref=1
      ;;
    repo_origin_ssh)
      [[ -n "$repair_target" ]] || {
        announce_error "Item ausente sem caminho de repositório para reparo do remoto SSH: $verification_label"
        return 1
      }
      append_array_item "$origin_array_name" "$repair_target"
      ;;
    *)
      announce_error "Estratégia de reparo desconhecida para '$verification_label': $repair_strategy"
      return 1
      ;;
  esac
}

collect_final_repair_plan() {
  local pacman_array_name="$1"
  local aur_array_name="$2"
  local origin_array_name="$3"
  local codex_flag_name="$4"
  local service_flag_name="$5"
  local verification_id

  for verification_id in "${STATE_MISSING_ITEM_IDS[@]}"; do
    collect_final_repair_item \
      "$verification_id" \
      "$pacman_array_name" \
      "$aur_array_name" \
      "$origin_array_name" \
      "$codex_flag_name" \
      "$service_flag_name" || return 1
  done
}
