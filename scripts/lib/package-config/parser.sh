#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

PACKAGE_CATEGORY_ORDER=()
declare -Ag PACKAGE_CATEGORY_BY_PACKAGE=()

trim_package_config_line() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

register_package_category() {
  local category_label="$1"
  local existing_label

  for existing_label in "${PACKAGE_CATEGORY_ORDER[@]}"; do
    [[ "$existing_label" == "$category_label" ]] && return 0
  done

  PACKAGE_CATEGORY_ORDER+=("$category_label")
}

append_package() {
  local array_name="$1"
  local package="$2"
  local existing
  # shellcheck disable=SC2178
  declare -n target_array="$array_name"

  if ! package_name_is_valid "$package"; then
    announce_error "Nome de pacote inválido na configuração: $package"
    return 2
  fi

  for existing in "${target_array[@]}"; do
    if [[ "$existing" == "$package" ]]; then
      return 1
    fi
  done

  target_array+=("$package")
  return 0
}

package_name_is_valid() {
  local package="$1"

  [[ -n "$package" ]] || return 1
  [[ "$package" =~ ^[a-z0-9@._+-]+$ ]] || return 1
  [[ "$package" != -* ]]
}

package_category_for_package() {
  printf '%s\n' "${PACKAGE_CATEGORY_BY_PACKAGE[$1]:-Geral}"
}

load_package_file() {
  local package_path="$1"
  local array_name="$2"
  local default_category_label="$3"
  local current_category_label="$default_category_label"
  local line
  local category_label=""

  if [[ ! -f "$package_path" ]]; then
    if [[ "$package_path" == "$EXTRA_PACKAGE_FILE" ]]; then
      announce_detail "Pacotes extras não encontrados em $package_path. Etapa ignorada."
    fi
    return 0
  fi

  register_package_category "$default_category_label"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim_package_config_line "$line")"
    [[ -n "$line" ]] || continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      category_label="$(trim_package_config_line "${BASH_REMATCH[1]}")"
      [[ -n "$category_label" ]] || {
        announce_error "Categoria inválida em $package_path."
        return 1
      }
      current_category_label="$category_label"
      register_package_category "$current_category_label"
      continue
    fi
    if [[ "$line" == \[* || "$line" == *\] ]]; then
      announce_error "Categoria inválida em $package_path."
      return 1
    fi

    if append_package "$array_name" "$line"; then
      PACKAGE_CATEGORY_BY_PACKAGE["$line"]="$current_category_label"
    else
      case "$?" in
        1)
          ;;
        *)
          return 1
          ;;
      esac
    fi
  done <"$package_path"
}

load_packages() {
  local array_name="$1"
  # shellcheck disable=SC2178
  declare -n target_array="$array_name"

  [[ -f "$PACKAGE_FILE" ]] || {
    announce_error "Lista de pacotes não encontrada em $PACKAGE_FILE"
    return 1
  }

  target_array=()
  PACKAGE_CATEGORY_ORDER=()
  PACKAGE_CATEGORY_BY_PACKAGE=()
  load_package_file "$PACKAGE_FILE" "$array_name" "Geral" || return 1
  load_package_file "$EXTRA_PACKAGE_FILE" "$array_name" "Extras" || return 1
}
