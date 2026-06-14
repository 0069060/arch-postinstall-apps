#!/usr/bin/env bash
# shellcheck shell=bash

report_requested_main_packages() {
  local array_name="$1"
  # shellcheck disable=SC2178
  declare -n target_packages="$array_name"
  local package_name
  local package_origin=""

  for package_name in "${target_packages[@]}"; do
    package_origin="$(classify_package_origin "$package_name")" || return 1
    case "$package_origin" in
      official)
        report_add_requested_main_official_package "$package_name"
        ;;
      aur)
        report_add_requested_main_aur_package "$package_name"
        ;;
    esac
  done
}
