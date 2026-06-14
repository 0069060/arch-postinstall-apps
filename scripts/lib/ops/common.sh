#!/usr/bin/env bash
# shellcheck shell=bash

ops_sanitize_id() {
  if declare -F sanitize_label >/dev/null; then
    sanitize_label "$1"
    return 0
  fi

  printf '%s' "$1" | tr -cs '[:alnum:].@_-' '-'
}

ops_redact_command_arg() {
  local arg="$1"

  case "$arg" in
    *token=*|*TOKEN=*|*secret=*|*SECRET=*|*password=*|*PASSWORD=*)
      printf '%s\n' "${arg%%=*}=<redacted>"
      ;;
    ghp_*|github_pat_*|glpat-*|xoxb-*|xoxp-*)
      printf '<redacted>\n'
      ;;
    *)
      printf '%s\n' "$arg"
      ;;
  esac
}

ops_command_line() {
  local command_line=""
  local part
  local rendered_part
  local quoted_part

  for part in "$@"; do
    rendered_part="$(ops_redact_command_arg "$part")"
    printf -v quoted_part '%q' "$rendered_part"
    command_line="${command_line:+$command_line }$quoted_part"
  done

  printf '%s\n' "$command_line"
}
