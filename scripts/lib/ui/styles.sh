#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

init_output_styles() {
  style_reset=""
  style_step=""
  style_detail=""
  style_success=""
  style_warning=""
  style_error=""
  style_muted=""

  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    style_reset=$'\033[0m'
    style_step=$'\033[1;36m'
    style_detail=$'\033[0;37m'
    style_success=$'\033[1;32m'
    style_warning=$'\033[1;33m'
    style_error=$'\033[1;31m'
    style_muted=$'\033[0;90m'
  fi
}

style_text() {
  local style="$1"
  local text="$2"

  if [[ -z "$style" ]]; then
    printf '%s' "$text"
    return 0
  fi

  printf '%s%s%s' "$style" "$text" "$style_reset"
}
