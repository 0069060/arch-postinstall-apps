#!/usr/bin/env bash
# shellcheck shell=bash

declare -Ag OPS_SSH_OPERATION_ACTIONS=()
declare -Ag OPS_SSH_OPERATION_KEY_PATHS=()
declare -Ag OPS_SSH_OPERATION_PUBLIC_PATHS=()
declare -Ag OPS_SSH_OPERATION_COMMENTS=()

ops_ssh_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_run_legacy_ssh_operation() {
  local action="$1"
  local private_key_path="$2"
  local public_key_path="${3:-}"
  local key_comment="${4:-}"

  case "$action" in
    regenerate-public-key)
      ssh-keygen -y -f "$private_key_path" >"$public_key_path"
      ;;
    generate-key-pair)
      ssh-keygen -t ed25519 -C "$key_comment" -f "$private_key_path" -N ""
      ;;
    *)
      return 1
      ;;
  esac
}

ops_ssh_operation_executor() {
  local operation_id="$1"
  local action="${OPS_SSH_OPERATION_ACTIONS[$operation_id]:-}"
  local private_key_path="${OPS_SSH_OPERATION_KEY_PATHS[$operation_id]:-}"
  local public_key_path="${OPS_SSH_OPERATION_PUBLIC_PATHS[$operation_id]:-}"
  local key_comment="${OPS_SSH_OPERATION_COMMENTS[$operation_id]:-}"

  ops_run_legacy_ssh_operation "$action" "$private_key_path" "$public_key_path" "$key_comment"
}

ops_plan_ssh_operation() {
  local action="$1"
  local private_key_path="$2"
  local public_key_path="$3"
  local key_comment="$4"
  local description="$5"
  local command_line="$6"
  local target="$7"
  local operation_id

  operation_id="ssh-$action:$(ops_sanitize_id "$target")"
  OPS_SSH_OPERATION_ACTIONS["$operation_id"]="$action"
  OPS_SSH_OPERATION_KEY_PATHS["$operation_id"]="$private_key_path"
  OPS_SSH_OPERATION_PUBLIC_PATHS["$operation_id"]="$public_key_path"
  OPS_SSH_OPERATION_COMMENTS["$operation_id"]="$key_comment"

  operation_plan_add \
    "$operation_id" \
    "ssh" \
    "$target" \
    "$description" \
    "medium" \
    "" \
    "allow" \
    "ops_ssh_operation_executor" \
    "remover chave gerada manualmente se necessário"
  operation_plan_set_command "$operation_id" "$command_line" "0"

  operation_plan_execute "$operation_id"
}

ops_ssh_regenerate_public_key() {
  local private_key_path="$1"
  local public_key_path="$2"

  if ! ops_ssh_planner_available; then
    ops_run_legacy_ssh_operation regenerate-public-key "$private_key_path" "$public_key_path"
    return $?
  fi

  ops_plan_ssh_operation \
    "regenerate-public-key" \
    "$private_key_path" \
    "$public_key_path" \
    "" \
    "Recriar chave pública SSH local" \
    "$(ops_command_line ssh-keygen -y -f "$private_key_path" '>' "$public_key_path")" \
    "$public_key_path"
}

ops_ssh_generate_key_pair() {
  local key_comment="$1"
  local key_path="$2"

  if ! ops_ssh_planner_available; then
    ops_run_legacy_ssh_operation generate-key-pair "$key_path" "" "$key_comment"
    return $?
  fi

  ops_plan_ssh_operation \
    "generate-key-pair" \
    "$key_path" \
    "${key_path}.pub" \
    "$key_comment" \
    "Gerar par de chaves SSH local" \
    "$(ops_command_line ssh-keygen -t ed25519 -C "$key_comment" -f "$key_path" -N "")" \
    "$key_path"
}
