#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

declare -ag MODULE_BOOTSTRAP_FRAGMENT_FILES=()
declare -ag MODULE_BOOTSTRAP_CHECK_FILES=()
declare -ag MODULE_RUNTIME_ENTRYPOINT_FILES=()
declare -ag MODULE_RUNTIME_CHECK_FILES=()

manifest_append_unique() {
  local array_name="$1"
  local module_path="$2"
  local existing
  # shellcheck disable=SC2178
  declare -n target_array="$array_name"

  for existing in "${target_array[@]}"; do
    [[ "$existing" == "$module_path" ]] && return 0
  done

  target_array+=("$module_path")
}

register_module_file() {
  local module_path="$1"
  shift

  local role
  for role in "$@"; do
    case "$role" in
      bootstrap-fragment)
        manifest_append_unique MODULE_BOOTSTRAP_FRAGMENT_FILES "$module_path"
        ;;
      bootstrap-check)
        manifest_append_unique MODULE_BOOTSTRAP_CHECK_FILES "$module_path"
        ;;
      runtime-entrypoint)
        manifest_append_unique MODULE_RUNTIME_ENTRYPOINT_FILES "$module_path"
        ;;
      runtime-check)
        manifest_append_unique MODULE_RUNTIME_CHECK_FILES "$module_path"
        ;;
      *)
        printf 'Erro: papel de módulo desconhecido: %s\n' "$role" >&2
        return 1
        ;;
    esac
  done
}
