#!/usr/bin/env bash
# shellcheck shell=bash

ops_github_planner_available() {
  declare -F operation_plan_add >/dev/null && declare -F operation_plan_execute >/dev/null
}

ops_github_record_direct_operation() {
  local operation_id="$1"
  local target="$2"
  local description="$3"
  local command_line="$4"
  local risk="${5:-medium}"

  ops_github_planner_available || return 1
  operation_plan_add \
    "$operation_id" \
    "github" \
    "$target" \
    "$description" \
    "$risk" \
    "" \
    "allow" \
    "" \
    "repetir comando gh após resolver autenticação ou conectividade" || return 1
  operation_plan_set_command "$operation_id" "$command_line" "0"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    operation_plan_set_status "$operation_id" "planned" "dry-run"
    return 2
  fi

  return 0
}

ops_gh_auth_login() {
  local operation_id="github-auth-login:github.com"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "github.com" \
    "Autenticar GitHub CLI" \
    "$(ops_command_line gh auth login --web --git-protocol ssh --scopes admin:public_key)" \
    "medium"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  run_gh_auth_flow auth login --web --git-protocol ssh --scopes admin:public_key
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}

ops_gh_auth_refresh_admin_public_key() {
  local operation_id="github-auth-refresh:admin-public-key"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "github.com admin:public_key" \
    "Renovar escopo GitHub CLI" \
    "$(ops_command_line gh auth refresh -h github.com -s admin:public_key)" \
    "medium"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  run_gh_auth_flow auth refresh -h github.com -s admin:public_key
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}

ops_gh_get_authenticated_login() {
  local operation_id="github-api-user-login"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "user" \
    "Consultar login autenticado no GitHub" \
    "$(ops_command_line gh api user --jq '.login')" \
    "low"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  retry gh api user --jq '.login'
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}

ops_gh_list_ssh_keys_tsv() {
  local operation_id="github-api-list-ssh-keys"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "user/keys" \
    "Listar chaves SSH do GitHub" \
    "$(ops_command_line gh api user/keys --jq '.[] | [.id, .title, .key] | @tsv')" \
    "medium"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  retry gh api user/keys --jq '.[] | [.id, .title, .key] | @tsv'
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}

ops_gh_delete_ssh_key() {
  local key_id="$1"
  local operation_id=""

  operation_id="github-api-delete-ssh-key:$(ops_sanitize_id "$key_id")"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "user/keys/$key_id" \
    "Remover chave SSH do GitHub" \
    "$(ops_command_line gh api --method DELETE "user/keys/$key_id")" \
    "high"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  retry gh api --method DELETE "user/keys/$key_id"
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}

ops_gh_create_ssh_key() {
  local key_name="$1"
  local public_key="$2"
  local operation_id=""

  operation_id="github-api-create-ssh-key:$(ops_sanitize_id "$key_name")"

  if ops_github_record_direct_operation \
    "$operation_id" \
    "user/keys:$key_name" \
    "Enviar chave SSH ao GitHub" \
    "$(ops_command_line gh api user/keys --method POST -f "title=$key_name" -f "key=<public-key>" --jq '.id')" \
    "medium"; then
    :
  elif [[ "$?" == "2" ]]; then
    return 2
  fi

  retry gh api user/keys --method POST -f "title=$key_name" -f "key=$public_key" --jq '.id'
  local status=$?
  if ops_github_planner_available; then
    if [[ "$status" == "0" ]]; then
      operation_plan_set_status "$operation_id" "succeeded" "executada"
    else
      operation_plan_set_status "$operation_id" "failed" "falha na execução"
    fi
  fi
  return "$status"
}
