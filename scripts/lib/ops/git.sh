#!/usr/bin/env bash
# shellcheck shell=bash

declare -Ag OPS_GIT_OPERATION_ACTIONS=()
declare -Ag OPS_GIT_OPERATION_REPO_DIRS=()
declare -Ag OPS_GIT_OPERATION_ORIGINS=()
declare -Ag OPS_GIT_OPERATION_SUBMODULES=()

ops_git_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_run_legacy_git_operation() {
  local action="$1"
  local repo_dir="$2"
  local origin_url="${3:-}"
  local clone_submodules="${4:-0}"
  local clone_args=(clone --branch main --single-branch)

  case "$action" in
    remote-add-origin)
      git -C "$repo_dir" remote add origin "$origin_url"
      ;;
    remote-set-origin)
      git -C "$repo_dir" remote set-url origin "$origin_url"
      ;;
    fetch-origin)
      retry_log_only git -C "$repo_dir" fetch origin
      ;;
    checkout-main)
      run_log_only git -C "$repo_dir" checkout main
      ;;
    checkout-main-from-origin)
      run_log_only git -C "$repo_dir" checkout -b main origin/main
      ;;
    pull-main-ff-only)
      retry_log_only git -C "$repo_dir" pull --ff-only origin main
      ;;
    update-submodules)
      retry_log_only git -C "$repo_dir" submodule update --init --recursive
      ;;
    clone-main)
      if [[ "$clone_submodules" == "1" ]]; then
        clone_args+=(--recurse-submodules)
      fi
      clone_args+=("$origin_url" "$repo_dir")
      retry_log_only git "${clone_args[@]}"
      ;;
    *)
      return 1
      ;;
  esac
}

ops_git_operation_executor() {
  local operation_id="$1"
  local action="${OPS_GIT_OPERATION_ACTIONS[$operation_id]:-}"
  local repo_dir="${OPS_GIT_OPERATION_REPO_DIRS[$operation_id]:-}"
  local origin_url="${OPS_GIT_OPERATION_ORIGINS[$operation_id]:-}"
  local clone_submodules="${OPS_GIT_OPERATION_SUBMODULES[$operation_id]:-0}"

  ops_run_legacy_git_operation "$action" "$repo_dir" "$origin_url" "$clone_submodules"
}

ops_plan_git_operation() {
  local action="$1"
  local repo_dir="$2"
  local origin_url="$3"
  local clone_submodules="$4"
  local description="$5"
  local command_line="$6"
  local target="$7"
  local operation_id

  operation_id="git-$action:$(ops_sanitize_id "$target")"
  OPS_GIT_OPERATION_ACTIONS["$operation_id"]="$action"
  OPS_GIT_OPERATION_REPO_DIRS["$operation_id"]="$repo_dir"
  OPS_GIT_OPERATION_ORIGINS["$operation_id"]="$origin_url"
  OPS_GIT_OPERATION_SUBMODULES["$operation_id"]="$clone_submodules"

  operation_plan_add \
    "$operation_id" \
    "git" \
    "$target" \
    "$description" \
    "medium" \
    "" \
    "allow" \
    "ops_git_operation_executor" \
    "revisar o repositório local e repetir o comando git se necessário"
  operation_plan_set_command "$operation_id" "$command_line" "0"

  operation_plan_execute "$operation_id"
}

ops_git_remote_add_origin() {
  local repo_dir="$1"
  local origin_url="$2"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation remote-add-origin "$repo_dir" "$origin_url"
    return $?
  fi

  ops_plan_git_operation \
    "remote-add-origin" \
    "$repo_dir" \
    "$origin_url" \
    "0" \
    "Adicionar origin git" \
    "$(ops_command_line git -C "$repo_dir" remote add origin "$origin_url")" \
    "$repo_dir <- $origin_url"
}

ops_git_remote_set_origin() {
  local repo_dir="$1"
  local origin_url="$2"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation remote-set-origin "$repo_dir" "$origin_url"
    return $?
  fi

  ops_plan_git_operation \
    "remote-set-origin" \
    "$repo_dir" \
    "$origin_url" \
    "0" \
    "Atualizar origin git" \
    "$(ops_command_line git -C "$repo_dir" remote set-url origin "$origin_url")" \
    "$repo_dir <- $origin_url"
}

ops_git_fetch_origin() {
  local repo_dir="$1"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation fetch-origin "$repo_dir"
    return $?
  fi

  ops_plan_git_operation \
    "fetch-origin" \
    "$repo_dir" \
    "" \
    "0" \
    "Buscar atualizações de origin" \
    "$(ops_command_line git -C "$repo_dir" fetch origin)" \
    "$repo_dir"
}

ops_git_checkout_main() {
  local repo_dir="$1"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation checkout-main "$repo_dir"
    return $?
  fi

  ops_plan_git_operation \
    "checkout-main" \
    "$repo_dir" \
    "" \
    "0" \
    "Trocar repositório para main" \
    "$(ops_command_line git -C "$repo_dir" checkout main)" \
    "$repo_dir"
}

ops_git_checkout_main_from_origin() {
  local repo_dir="$1"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation checkout-main-from-origin "$repo_dir"
    return $?
  fi

  ops_plan_git_operation \
    "checkout-main-from-origin" \
    "$repo_dir" \
    "" \
    "0" \
    "Criar main local a partir de origin/main" \
    "$(ops_command_line git -C "$repo_dir" checkout -b main origin/main)" \
    "$repo_dir"
}

ops_git_pull_main_ff_only() {
  local repo_dir="$1"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation pull-main-ff-only "$repo_dir"
    return $?
  fi

  ops_plan_git_operation \
    "pull-main-ff-only" \
    "$repo_dir" \
    "" \
    "0" \
    "Atualizar main com fast-forward" \
    "$(ops_command_line git -C "$repo_dir" pull --ff-only origin main)" \
    "$repo_dir"
}

ops_git_update_submodules() {
  local repo_dir="$1"

  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation update-submodules "$repo_dir"
    return $?
  fi

  ops_plan_git_operation \
    "update-submodules" \
    "$repo_dir" \
    "" \
    "0" \
    "Atualizar submódulos git" \
    "$(ops_command_line git -C "$repo_dir" submodule update --init --recursive)" \
    "$repo_dir"
}

ops_git_clone_main() {
  local repo_url="$1"
  local repo_dir="$2"
  local clone_submodules="${3:-0}"
  local clone_args=(clone --branch main --single-branch)

  if [[ "$clone_submodules" == "1" ]]; then
    clone_args+=(--recurse-submodules)
  fi

  clone_args+=("$repo_url" "$repo_dir")
  if ! ops_git_planner_available; then
    ops_run_legacy_git_operation clone-main "$repo_dir" "$repo_url" "$clone_submodules"
    return $?
  fi

  ops_plan_git_operation \
    "clone-main" \
    "$repo_dir" \
    "$repo_url" \
    "$clone_submodules" \
    "Clonar repositório git" \
    "$(ops_command_line git "${clone_args[@]}")" \
    "$repo_dir <- $repo_url"
}
