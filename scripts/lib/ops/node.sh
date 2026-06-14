#!/usr/bin/env bash
# shellcheck shell=bash

declare -Ag OPS_NODE_OPERATION_ACTIONS=()
declare -Ag OPS_NODE_OPERATION_PREFIXES=()

ops_node_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_run_legacy_node_operation() {
  local action="$1"
  local prefix_path="${2:-}"

  case "$action" in
    npm-config-prefix)
      run_log_only npm config set prefix "$prefix_path"
      ;;
    npm-install-codex)
      retry_log_only npm install -g @openai/codex
      ;;
    *)
      return 1
      ;;
  esac
}

ops_node_operation_executor() {
  local operation_id="$1"
  local action="${OPS_NODE_OPERATION_ACTIONS[$operation_id]:-}"
  local prefix_path="${OPS_NODE_OPERATION_PREFIXES[$operation_id]:-}"

  ops_run_legacy_node_operation "$action" "$prefix_path"
}

ops_plan_node_operation() {
  local action="$1"
  local target="$2"
  local description="$3"
  local command_line="$4"
  local prefix_path="${5:-}"
  local operation_id

  operation_id="node-$action:$(ops_sanitize_id "$target")"
  OPS_NODE_OPERATION_ACTIONS["$operation_id"]="$action"
  OPS_NODE_OPERATION_PREFIXES["$operation_id"]="$prefix_path"

  operation_plan_add \
    "$operation_id" \
    "npm" \
    "$target" \
    "$description" \
    "medium" \
    "" \
    "allow" \
    "ops_node_operation_executor" \
    "remover ou ajustar prefixo npm/Codex manualmente se necessário"
  operation_plan_set_command "$operation_id" "$command_line" "0"

  operation_plan_execute "$operation_id"
}

ops_npm_config_set_prefix() {
  local prefix_path="$1"

  if ! ops_node_planner_available; then
    ops_run_legacy_node_operation npm-config-prefix "$prefix_path"
    return $?
  fi

  ops_plan_node_operation \
    "npm-config-prefix" \
    "$prefix_path" \
    "Configurar prefixo npm para Codex" \
    "$(ops_command_line npm config set prefix "$prefix_path")" \
    "$prefix_path"
}

ops_npm_install_codex_cli() {
  if ! ops_node_planner_available; then
    ops_run_legacy_node_operation npm-install-codex
    return $?
  fi

  ops_plan_node_operation \
    "npm-install-codex" \
    "@openai/codex" \
    "Instalar Codex CLI via npm" \
    "$(ops_command_line npm install -g @openai/codex)"
}
