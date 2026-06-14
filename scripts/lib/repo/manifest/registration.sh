#!/usr/bin/env bash
# shellcheck shell=bash

register_managed_repo() {
  local repo_id="$1"
  shift

  local assignment=""
  local repo_dir=""
  local https_url=""
  local ssh_url=""
  local repo_label=""
  local environment_repo=""
  local clone_submodules="0"
  local preferred_transport="auto"

  for assignment in "$@"; do
    case "$assignment" in
      dir=*)
        repo_dir="${assignment#*=}"
        ;;
      https_url=*)
        https_url="${assignment#*=}"
        ;;
      ssh_url=*)
        ssh_url="${assignment#*=}"
        ;;
      label=*)
        repo_label="${assignment#*=}"
        ;;
      environment=*)
        environment_repo="${assignment#*=}"
        ;;
      clone_submodules=*)
        clone_submodules="${assignment#*=}"
        ;;
      preferred_transport=*)
        preferred_transport="${assignment#*=}"
        ;;
      *)
        printf 'Erro: metadado de repositório desconhecido para %s: %s\n' "$repo_id" "$assignment" >&2
        return 1
        ;;
    esac
  done

  if [[ -z "$repo_id" || -z "$repo_dir" || -z "$https_url" || -z "$ssh_url" || \
    -z "$repo_label" || -z "$environment_repo" ]]; then
    printf 'Erro: repositório gerenciado incompleto: %s\n' "${repo_id:-indefinido}" >&2
    return 1
  fi

  case "$clone_submodules" in
    0|1)
      ;;
    *)
      printf 'Erro: clone_submodules inválido para %s: %s\n' "$repo_id" "$clone_submodules" >&2
      return 1
      ;;
  esac

  case "$preferred_transport" in
    auto|https|ssh)
      ;;
    *)
      printf 'Erro: preferred_transport inválido para %s: %s\n' "$repo_id" "$preferred_transport" >&2
      return 1
      ;;
  esac

  MANAGED_REPO_IDS+=("$repo_id")
  MANAGED_REPO_DIRS["$repo_id"]="$repo_dir"
  MANAGED_REPO_HTTPS_URLS["$repo_id"]="$https_url"
  MANAGED_REPO_SSH_URLS["$repo_id"]="$ssh_url"
  MANAGED_REPO_LABELS["$repo_id"]="$repo_label"
  MANAGED_REPO_ENVIRONMENT_FLAGS["$repo_id"]="$environment_repo"
  MANAGED_REPO_CLONE_SUBMODULE_FLAGS["$repo_id"]="$clone_submodules"
  MANAGED_REPO_PREFERRED_TRANSPORTS["$repo_id"]="$preferred_transport"
}
