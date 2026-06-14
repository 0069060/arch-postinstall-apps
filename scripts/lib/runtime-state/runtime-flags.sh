#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

STATE_SOFT_FAILURES=()
STATE_AUR_HELPER_NAME=""
STATE_AUR_HELPER_STATUS=""
STATE_TEMP_CLIPBOARD_PACKAGE=""
STATE_OFFICIAL_REPO_METADATA_CHECKED=0
STATE_OFFICIAL_REPO_METADATA_READY=0

state_reset_runtime_flags() {
  STATE_SOFT_FAILURES=()
  STATE_AUR_HELPER_NAME=""
  STATE_AUR_HELPER_STATUS="não preparado"
  STATE_TEMP_CLIPBOARD_PACKAGE=""
  STATE_OFFICIAL_REPO_METADATA_CHECKED=0
  STATE_OFFICIAL_REPO_METADATA_READY=0
}

state_add_soft_failure() {
  append_array_item STATE_SOFT_FAILURES "$1"
}

state_set_aur_helper() {
  STATE_AUR_HELPER_NAME="$1"
  STATE_AUR_HELPER_STATUS="$2"
}

state_get_aur_helper_name() {
  printf '%s\n' "$STATE_AUR_HELPER_NAME"
}

state_get_aur_helper_status() {
  printf '%s\n' "${STATE_AUR_HELPER_STATUS:-indisponível}"
}

state_set_temp_clipboard_package() {
  STATE_TEMP_CLIPBOARD_PACKAGE="$1"
}

state_get_temp_clipboard_package() {
  printf '%s\n' "$STATE_TEMP_CLIPBOARD_PACKAGE"
}

state_official_repo_metadata_checked() {
  [[ "$STATE_OFFICIAL_REPO_METADATA_CHECKED" == "1" ]]
}

state_set_official_repo_metadata_checked() {
  STATE_OFFICIAL_REPO_METADATA_CHECKED=1
}

state_official_repo_metadata_ready() {
  [[ "$STATE_OFFICIAL_REPO_METADATA_READY" == "1" ]]
}

state_set_official_repo_metadata_ready() {
  STATE_OFFICIAL_REPO_METADATA_READY="$1"
}
