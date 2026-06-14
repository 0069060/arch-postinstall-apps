#!/usr/bin/env bash
# shellcheck shell=bash

declare -Ag OPS_SYSTEMD_OPERATION_SCOPES=()
declare -Ag OPS_SYSTEMD_OPERATION_ACTIONS=()
declare -Ag OPS_SYSTEMD_OPERATION_UNITS=()

ops_systemd_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_run_legacy_systemd_operation() {
  local scope="$1"
  local action="$2"
  shift 2

  case "$scope:$action" in
    user:daemon-reload)
      run_log_only systemctl --user daemon-reload
      ;;
    user:start)
      run_log_only systemctl --user start "$@"
      ;;
    system:start)
      run_log_only sudo systemctl start "$@"
      ;;
    system:enable)
      run_log_only sudo systemctl enable "$@"
      ;;
    *)
      return 1
      ;;
  esac
}

ops_systemd_operation_executor() {
  local operation_id="$1"
  local scope="${OPS_SYSTEMD_OPERATION_SCOPES[$operation_id]:-}"
  local action="${OPS_SYSTEMD_OPERATION_ACTIONS[$operation_id]:-}"
  local units_text="${OPS_SYSTEMD_OPERATION_UNITS[$operation_id]:-}"
  local units=()

  if [[ -n "$units_text" ]]; then
    read -r -a units <<<"$units_text"
  fi

  ops_run_legacy_systemd_operation "$scope" "$action" "${units[@]}"
}

ops_plan_systemd_operation() {
  local scope="$1"
  local action="$2"
  local description="$3"
  local command_line="$4"
  local requires_root="$5"
  shift 5
  local units=("$@")
  local units_label="${units[*]:-daemon-reload}"
  local operation_id

  operation_id="systemd-$scope-$action:$(ops_sanitize_id "$units_label")"
  OPS_SYSTEMD_OPERATION_SCOPES["$operation_id"]="$scope"
  OPS_SYSTEMD_OPERATION_ACTIONS["$operation_id"]="$action"
  OPS_SYSTEMD_OPERATION_UNITS["$operation_id"]="${units[*]}"

  operation_plan_add \
    "$operation_id" \
    "systemd" \
    "$units_label" \
    "$description" \
    "medium" \
    "" \
    "allow" \
    "ops_systemd_operation_executor" \
    "verificar unidade e repetir systemctl manualmente"
  operation_plan_set_command "$operation_id" "$command_line" "$requires_root"

  operation_plan_execute "$operation_id"
}

ops_systemctl_user_daemon_reload() {
  if ! ops_systemd_planner_available; then
    ops_run_legacy_systemd_operation user daemon-reload
    return $?
  fi

  ops_plan_systemd_operation \
    "user" \
    "daemon-reload" \
    "Recarregar unidades systemd do usuário" \
    "$(ops_command_line systemctl --user daemon-reload)" \
    "0"
}

ops_systemctl_user_start() {
  local units=("$@")

  if ! ops_systemd_planner_available; then
    ops_run_legacy_systemd_operation user start "${units[@]}"
    return $?
  fi

  ops_plan_systemd_operation \
    "user" \
    "start" \
    "Iniciar unidades systemd do usuário" \
    "$(ops_command_line systemctl --user start "${units[@]}")" \
    "0" \
    "${units[@]}"
}

ops_systemctl_start() {
  local units=("$@")

  if ! ops_systemd_planner_available; then
    ops_run_legacy_systemd_operation system start "${units[@]}"
    return $?
  fi

  ops_plan_systemd_operation \
    "system" \
    "start" \
    "Iniciar unidades systemd do sistema" \
    "$(ops_command_line sudo systemctl start "${units[@]}")" \
    "1" \
    "${units[@]}"
}

ops_systemctl_enable() {
  local units=("$@")

  if ! ops_systemd_planner_available; then
    ops_run_legacy_systemd_operation system enable "${units[@]}"
    return $?
  fi

  ops_plan_systemd_operation \
    "system" \
    "enable" \
    "Habilitar unidades systemd do sistema" \
    "$(ops_command_line sudo systemctl enable "${units[@]}")" \
    "1" \
    "${units[@]}"
}
