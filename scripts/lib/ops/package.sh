#!/usr/bin/env bash
# shellcheck shell=bash

declare -Ag OPS_PACMAN_OPERATION_ACTIONS=()
declare -Ag OPS_PACMAN_OPERATION_PACKAGES=()
declare -Ag OPS_AUR_OPERATION_HELPERS=()
declare -Ag OPS_AUR_OPERATION_PACKAGES=()
declare -Ag OPS_YAY_BUILD_OPERATION_DIRS=()

ops_package_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_pacman_db_lock_file() {
  printf '%s\n' "${POSTINSTALL_PACMAN_DB_LOCK_FILE:-/var/lib/pacman/db.lck}"
}

ops_pacman_db_lock_present() {
  [[ -e "$(ops_pacman_db_lock_file)" ]]
}

ops_warn_pacman_lock() {
  local lock_file

  lock_file="$(ops_pacman_db_lock_file)"
  if declare -F announce_warning >/dev/null; then
    announce_warning "Operação bloqueada: lock do pacman encontrado em $lock_file."
  fi
}

ops_block_planned_package_operation_if_locked() {
  local operation_id="$1"

  [[ "${DRY_RUN:-0}" == "1" ]] && return 1
  ops_pacman_db_lock_present || return 1

  ops_warn_pacman_lock
  operation_plan_set_status "$operation_id" "blocked" "lock do pacman encontrado em $(ops_pacman_db_lock_file)"
  return 0
}

ops_run_legacy_pacman_operation() {
  local action="$1"
  shift

  case "$action" in
    upgrade-install)
      retry_interactive_log_only sudo pacman -Syu --needed --noconfirm "$@"
      ;;
    upgrade-full)
      retry_interactive_log_only sudo pacman -Syu --noconfirm
      ;;
    install-needed)
      retry_interactive_log_only sudo pacman -S --needed --noconfirm "$@"
      ;;
    remove-recursive)
      retry_interactive_log_only sudo pacman -Rns --noconfirm "$@"
      ;;
    refresh-databases)
      run_interactive_log_only sudo pacman -Syy --noconfirm
      ;;
    *)
      return 1
      ;;
  esac
}

ops_pacman_operation_executor() {
  local operation_id="$1"
  local action="${OPS_PACMAN_OPERATION_ACTIONS[$operation_id]:-}"
  local packages_text="${OPS_PACMAN_OPERATION_PACKAGES[$operation_id]:-}"
  local packages=()

  if [[ -n "$packages_text" ]]; then
    read -r -a packages <<<"$packages_text"
  fi

  ops_run_legacy_pacman_operation "$action" "${packages[@]}"
}

ops_plan_pacman_operation() {
  local action="$1"
  local description="$2"
  local command_line="$3"
  local target="$4"
  shift 4
  local packages=("$@")
  local packages_label="${packages[*]:-sistema}"
  local operation_id

  operation_id="pacman-$action:$(ops_sanitize_id "$packages_label")"
  OPS_PACMAN_OPERATION_ACTIONS["$operation_id"]="$action"
  OPS_PACMAN_OPERATION_PACKAGES["$operation_id"]="${packages[*]}"

  operation_plan_add \
    "$operation_id" \
    "pacman" \
    "$target" \
    "$description" \
    "high" \
    "" \
    "allow" \
    "ops_pacman_operation_executor" \
    "reexecutar pacman após resolver a causa da falha"
  operation_plan_set_command "$operation_id" "$command_line" "1"

  if ops_block_planned_package_operation_if_locked "$operation_id"; then
    return 2
  fi

  operation_plan_execute "$operation_id"
}

ops_pacman_upgrade_and_install_needed() {
  local packages=("$@")
  local target_label="${packages[*]:-sistema}"

  if ! ops_package_planner_available; then
    ops_run_legacy_pacman_operation upgrade-install "${packages[@]}"
    return $?
  fi

  ops_plan_pacman_operation \
    "upgrade-install" \
    "Instalar pacotes oficiais necessários após atualização" \
    "$(ops_command_line sudo pacman -Syu --needed --noconfirm "${packages[@]}")" \
    "$target_label" \
    "${packages[@]}"
}

ops_pacman_upgrade_full() {
  if ! ops_package_planner_available; then
    ops_run_legacy_pacman_operation upgrade-full
    return $?
  fi

  ops_plan_pacman_operation \
    "upgrade-full" \
    "Atualizar sistema com pacman" \
    "$(ops_command_line sudo pacman -Syu --noconfirm)" \
    "sistema"
}

ops_pacman_install_needed() {
  local packages=("$@")
  local target_label="${packages[*]:-pacotes não informados}"

  if ! ops_package_planner_available; then
    ops_run_legacy_pacman_operation install-needed "${packages[@]}"
    return $?
  fi

  ops_plan_pacman_operation \
    "install-needed" \
    "Instalar pacotes oficiais necessários" \
    "$(ops_command_line sudo pacman -S --needed --noconfirm "${packages[@]}")" \
    "$target_label" \
    "${packages[@]}"
}

ops_pacman_remove_recursive() {
  local packages=("$@")
  local target_label="${packages[*]:-pacotes não informados}"

  if ! ops_package_planner_available; then
    ops_run_legacy_pacman_operation remove-recursive "${packages[@]}"
    return $?
  fi

  ops_plan_pacman_operation \
    "remove-recursive" \
    "Remover pacotes oficiais recursivamente" \
    "$(ops_command_line sudo pacman -Rns --noconfirm "${packages[@]}")" \
    "$target_label" \
    "${packages[@]}"
}

ops_pacman_refresh_databases() {
  if ! ops_package_planner_available; then
    ops_run_legacy_pacman_operation refresh-databases
    return $?
  fi

  ops_plan_pacman_operation \
    "refresh-databases" \
    "Atualizar bancos de dados do pacman" \
    "$(ops_command_line sudo pacman -Syy --noconfirm)" \
    "bancos de dados do pacman"
}

ops_backup_pacman_conf() {
  local backup_path="$1"

  sudo cp /etc/pacman.conf "$backup_path"
}

ops_enable_multilib_config() {
  sudo sed -i \
    '/^[[:space:]]*#\[multilib\][[:space:]]*$/,/^[[:space:]]*#Include = \/etc\/pacman.d\/mirrorlist[[:space:]]*$/ s/^[[:space:]]*#//' \
    /etc/pacman.conf
}

ops_build_yay_package() {
  local yay_dir="$1"
  local operation_id

  if ! ops_package_planner_available; then
    retry_log_only build_yay "$yay_dir"
    return $?
  fi

  operation_id="aur-build-yay:$(ops_sanitize_id "$yay_dir")"
  OPS_YAY_BUILD_OPERATION_DIRS["$operation_id"]="$yay_dir"

  operation_plan_add \
    "$operation_id" \
    "aur" \
    "$yay_dir" \
    "Compilar e instalar helper AUR yay" \
    "high" \
    "" \
    "allow" \
    "ops_build_yay_package_executor" \
    "remover diretório temporário e repetir build se necessário"
  operation_plan_set_command "$operation_id" "$(ops_command_line build_yay "$yay_dir")" "0"

  if ops_block_planned_package_operation_if_locked "$operation_id"; then
    return 2
  fi

  operation_plan_execute "$operation_id"
}

ops_aur_install_needed() {
  local helper_name="$1"
  shift
  local packages=("$@")
  local target_label="${packages[*]:-pacotes AUR não informados}"
  local operation_id

  if ! ops_package_planner_available; then
    retry_log_only "$helper_name" -S --needed --noconfirm "${packages[@]}"
    return $?
  fi

  operation_id="aur-install-needed:$(ops_sanitize_id "$helper_name:${packages[*]}")"
  OPS_AUR_OPERATION_HELPERS["$operation_id"]="$helper_name"
  OPS_AUR_OPERATION_PACKAGES["$operation_id"]="${packages[*]}"

  operation_plan_add \
    "$operation_id" \
    "aur" \
    "$target_label" \
    "Instalar pacotes AUR necessários com $helper_name" \
    "high" \
    "" \
    "allow" \
    "ops_aur_install_needed_executor" \
    "resolver falha do helper AUR e repetir instalação"
  operation_plan_set_command "$operation_id" "$(ops_command_line "$helper_name" -S --needed --noconfirm "${packages[@]}")" "0"

  if ops_block_planned_package_operation_if_locked "$operation_id"; then
    return 2
  fi

  operation_plan_execute "$operation_id"
}

ops_build_yay_package_executor() {
  local operation_id="$1"
  local yay_dir="${OPS_YAY_BUILD_OPERATION_DIRS[$operation_id]:-}"

  retry_log_only build_yay "$yay_dir"
}

ops_aur_install_needed_executor() {
  local operation_id="$1"
  local helper_name="${OPS_AUR_OPERATION_HELPERS[$operation_id]:-}"
  local packages_text="${OPS_AUR_OPERATION_PACKAGES[$operation_id]:-}"
  local packages=()

  if [[ -n "$packages_text" ]]; then
    read -r -a packages <<<"$packages_text"
  fi

  retry_log_only "$helper_name" -S --needed --noconfirm "${packages[@]}"
}
