#!/usr/bin/env bash
# shellcheck shell=bash

print_summary_section() {
  local title="$1"
  echo "│"
  printf '│  %s\n' "$(style_text "$style_step" "$title")"
}

print_summary_item() {
  local label="$1"
  local value="$2"
  local label_length=0
  local padding_width=22

  label_length="$(printf '%s' "$label" | wc -m | tr -d '[:space:]')"
  if [[ -z "$label_length" ]]; then
    label_length=0
  fi
  if (( label_length < padding_width )); then
    printf '│  %s %s%*s %s\n' "$(style_text "$style_detail" "•")" "$label" "$((padding_width - label_length))" "" "$value"
    return 0
  fi

  printf '│  %s %s %s\n' "$(style_text "$style_detail" "•")" "$label" "$value"
}
