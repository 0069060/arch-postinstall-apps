#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

STATE_MAIN_OFFICIAL_PACKAGES=()
STATE_MAIN_AUR_PACKAGES=()
STATE_FAILED_OFFICIAL_PACKAGES=()
STATE_FAILED_AUR_PACKAGES=()

state_reset_package_results() {
  STATE_MAIN_OFFICIAL_PACKAGES=()
  STATE_MAIN_AUR_PACKAGES=()
  STATE_FAILED_OFFICIAL_PACKAGES=()
  STATE_FAILED_AUR_PACKAGES=()
}

state_add_main_official_package() {
  append_array_item STATE_MAIN_OFFICIAL_PACKAGES "$1"
}

state_add_main_aur_package() {
  append_array_item STATE_MAIN_AUR_PACKAGES "$1"
}

state_add_official_failure() {
  append_array_item STATE_FAILED_OFFICIAL_PACKAGES "$1"
}

state_add_aur_failure() {
  append_array_item STATE_FAILED_AUR_PACKAGES "$1"
}

state_has_package_failures() {
  (( ${#STATE_FAILED_OFFICIAL_PACKAGES[@]} > 0 || ${#STATE_FAILED_AUR_PACKAGES[@]} > 0 ))
}
