#!/usr/bin/env bash
# shellcheck shell=bash

github_ssh_api_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_set_command >/dev/null
}

run_github_ssh_api() {
  local output_array_name="$1"
  local operation_label="$2"
  shift 2

  local stdout_file=""
  local stderr_file=""
  local command_status=0
  local stderr_preview=""
  local -a command_args=()
  local operation_id=""
  local command_line=""
  # shellcheck disable=SC2178,SC2034
  declare -n output_array="$output_array_name"

  output_array=()
  operation_id="github-ssh-api:$(ops_sanitize_id "$operation_label:$*")"
  stdout_file="$(mktemp)" || return 1
  stderr_file="$(mktemp)" || {
    rm -f "$stdout_file"
    return 1
  }

  command_args=(gh api "$@")
  command_line="$(ops_command_line "${command_args[@]}")"
  if github_ssh_api_planner_available; then
    operation_plan_add \
      "$operation_id" \
      "github" \
      "$*" \
      "$operation_label" \
      "medium" \
      "" \
      "allow" \
      "" \
      "repetir comando gh após resolver autenticação ou conectividade" || true
    operation_plan_set_command "$operation_id" "$command_line" "0"
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      operation_plan_set_status "$operation_id" "planned" "dry-run"
      rm -f "$stdout_file" "$stderr_file"
      return 2
    fi
  fi

  if command -v timeout >/dev/null 2>&1; then
    command_args=(timeout --foreground 30s "${command_args[@]}")
  fi

  if "${command_args[@]}" >"$stdout_file" 2>"$stderr_file"; then
    # shellcheck disable=SC2034
    mapfile -t output_array <"$stdout_file"
    if github_ssh_api_planner_available; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    fi
    rm -f "$stdout_file" "$stderr_file"
    return 0
  fi

  command_status=$?
  if github_ssh_api_planner_available; then
    operation_plan_set_status "$operation_id" "failed" "falha na execução"
  fi
  stderr_preview="$(sed -n '1,3p' "$stderr_file" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/[[:space:]]$//')"
  if [[ -n "$stderr_preview" ]]; then
    announce_warning "$operation_label falhou: $stderr_preview"
  else
    announce_warning "$operation_label falhou sem mensagem do gh."
  fi

  if [[ -s "$stderr_file" ]]; then
    {
      printf '[github-ssh] %s\n' "$operation_label"
      sed 's/^/[gh] /' "$stderr_file"
    } >>"$LOG_FILE"
  fi

  rm -f "$stdout_file" "$stderr_file"
  return "$command_status"
}

github_ssh_list_keys() {
  local output_array_name="$1"

  run_github_ssh_api "$output_array_name" \
    "A listagem das chaves SSH do GitHub" \
    user/keys --jq '.[] | [.id, .title, .key] | @tsv'
}

github_ssh_delete_key() {
  local key_id="$1"
  # shellcheck disable=SC2034
  local gh_output=()

  announce_detail "Removendo chave SSH antiga do GitHub: $key_id"
  run_github_ssh_api gh_output \
    "A remoção da chave SSH do GitHub $key_id" \
    --method DELETE "user/keys/$key_id"
}

github_ssh_create_key() {
  local output_array_name="$1"
  local key_name="$2"
  local public_key="$3"

  run_github_ssh_api "$output_array_name" \
    "O envio da chave SSH atual ao GitHub" \
    user/keys --method POST -f "title=$key_name" -f "key=$public_key" --jq '.id'
}
