#!/usr/bin/env bash
# shellcheck shell=bash

init_logging() {
  if [[ "${POSTINSTALL_LOG_INITIALIZED:-0}" == "1" ]]; then
    return
  fi

  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  export POSTINSTALL_LOG_FILE="$LOG_FILE"
  export POSTINSTALL_LOG_INITIALIZED=1

  exec > >(tee -a "$LOG_FILE") 2>&1
}

write_log_only() {
  if [[ "${POSTINSTALL_LOG_INITIALIZED:-0}" != "1" ]]; then
    return 0
  fi

  printf '%s\n' "$1" >>"$LOG_FILE"
}
