#!/usr/bin/env bash
# shellcheck shell=bash

classify_package_origin() {
  local package_name="$1"
  local origin_status=0

  if package_exists_in_official_repos "$package_name"; then
    origin_status=0
  else
    origin_status=$?
  fi

  if [[ "$origin_status" == "0" ]]; then
    printf 'official\n'
    return 0
  fi

  if [[ "$origin_status" == "1" ]]; then
    printf 'aur\n'
    return 0
  fi

  announce_error "Não foi possível classificar o pacote '$package_name' entre repositório oficial e AUR."
  return 1
}

target_packages_have_origin() {
  local array_name="$1"
  local expected_origin="$2"
  # shellcheck disable=SC2178
  declare -n target_packages="$array_name"
  local package_name
  local package_origin=""

  for package_name in "${target_packages[@]}"; do
    package_origin="$(classify_package_origin "$package_name")" || return 2
    [[ "$package_origin" == "$expected_origin" ]] && return 0
  done

  return 1
}

target_packages_have_official_entries() {
  target_packages_have_origin "$1" "official"
}

target_packages_have_aur_entries() {
  target_packages_have_origin "$1" "aur"
}

collect_packages_by_origin() {
  local source_array_name="$1"
  local expected_origin="$2"
  local target_array_name="$3"
  # shellcheck disable=SC2178
  declare -n source_packages="$source_array_name"
  # shellcheck disable=SC2178
  declare -n target_packages="$target_array_name"
  local package_name
  local package_origin=""

  target_packages=()

  for package_name in "${source_packages[@]}"; do
    package_origin="$(classify_package_origin "$package_name")" || return 1
    [[ "$package_origin" == "$expected_origin" ]] || continue
    target_packages+=("$package_name")
  done
}
