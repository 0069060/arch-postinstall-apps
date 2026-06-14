#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

REPORT_REQUESTED_MAIN_OFFICIAL_PACKAGES=()
REPORT_REQUESTED_MAIN_AUR_PACKAGES=()
REPORT_REUSED_MAIN_OFFICIAL_PACKAGES=()
REPORT_REUSED_MAIN_AUR_PACKAGES=()
REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES=()
REPORT_CHANGED_MAIN_AUR_PACKAGES=()
REPORT_REQUESTED_SUPPORT_PACKAGES=()
REPORT_REUSED_SUPPORT_PACKAGES=()
REPORT_CHANGED_SUPPORT_PACKAGES=()
REPORT_REQUESTED_ENVIRONMENT_PACKAGES=()
REPORT_REUSED_ENVIRONMENT_PACKAGES=()
REPORT_CHANGED_ENVIRONMENT_PACKAGES=()

report_reset_packages() {
  REPORT_REQUESTED_MAIN_OFFICIAL_PACKAGES=()
  REPORT_REQUESTED_MAIN_AUR_PACKAGES=()
  REPORT_REUSED_MAIN_OFFICIAL_PACKAGES=()
  REPORT_REUSED_MAIN_AUR_PACKAGES=()
  REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES=()
  REPORT_CHANGED_MAIN_AUR_PACKAGES=()
  REPORT_REQUESTED_SUPPORT_PACKAGES=()
  REPORT_REUSED_SUPPORT_PACKAGES=()
  REPORT_CHANGED_SUPPORT_PACKAGES=()
  REPORT_REQUESTED_ENVIRONMENT_PACKAGES=()
  REPORT_REUSED_ENVIRONMENT_PACKAGES=()
  REPORT_CHANGED_ENVIRONMENT_PACKAGES=()
}

report_add_requested_main_official_package() {
  append_array_item REPORT_REQUESTED_MAIN_OFFICIAL_PACKAGES "$1"
}

report_add_reused_main_official_package() {
  append_array_item REPORT_REUSED_MAIN_OFFICIAL_PACKAGES "$1"
}

report_add_changed_main_official_package() {
  append_array_item REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES "$1"
  report_mark_change "main_official:$1"
}

report_add_requested_main_aur_package() {
  append_array_item REPORT_REQUESTED_MAIN_AUR_PACKAGES "$1"
}

report_add_reused_main_aur_package() {
  append_array_item REPORT_REUSED_MAIN_AUR_PACKAGES "$1"
}

report_add_changed_main_aur_package() {
  append_array_item REPORT_CHANGED_MAIN_AUR_PACKAGES "$1"
  report_mark_change "main_aur:$1"
}

report_add_requested_support_package() {
  append_array_item REPORT_REQUESTED_SUPPORT_PACKAGES "$1"
}

report_add_reused_support_package() {
  append_array_item REPORT_REUSED_SUPPORT_PACKAGES "$1"
}

report_add_changed_support_package() {
  append_array_item REPORT_CHANGED_SUPPORT_PACKAGES "$1"
  report_mark_change "support:$1"
}

report_add_requested_environment_package() {
  append_array_item REPORT_REQUESTED_ENVIRONMENT_PACKAGES "$1"
}

report_add_reused_environment_package() {
  append_array_item REPORT_REUSED_ENVIRONMENT_PACKAGES "$1"
}

report_add_changed_environment_package() {
  append_array_item REPORT_CHANGED_ENVIRONMENT_PACKAGES "$1"
  report_mark_change "environment:$1"
}

report_reset_environment_packages() {
  REPORT_REQUESTED_ENVIRONMENT_PACKAGES=()
  REPORT_REUSED_ENVIRONMENT_PACKAGES=()
  REPORT_CHANGED_ENVIRONMENT_PACKAGES=()
}
