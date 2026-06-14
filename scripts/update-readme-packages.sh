#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck source-path=SCRIPTDIR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
README_FILE="$REPO_DIR/README.md"
PACKAGE_FILE="$REPO_DIR/config/packages.txt"
# Used by the shared package parser when this script sources package-config.sh.
# shellcheck disable=SC2034
EXTRA_PACKAGE_FILE="$REPO_DIR/config/packages-extra.txt"
README_PACKAGE_ITEMS=()
# shellcheck source=lib/component-config.sh
source "$REPO_DIR/scripts/lib/component-config.sh"
# shellcheck source=lib/package-config.sh
source "$REPO_DIR/scripts/lib/package-config.sh"
# shellcheck source=bootstrap/config.sh
source "$REPO_DIR/scripts/bootstrap/config.sh"

announce_error() {
  printf 'Erro: %s\n' "$1" >&2
}

usage() {
  cat <<'EOF'
Uso:
  bash scripts/update-readme-packages.sh
  bash scripts/update-readme-packages.sh --check
EOF
}

render_package_block() {
  print_item_list() {
    local array_name="$1"
    # shellcheck disable=SC2178
    declare -n target_array="$array_name"
    local current_item

    printf '  '
    printf "\`%s\`" "${target_array[0]}"
    for current_item in "${target_array[@]:1}"; do
      printf ", \`%s\`" "$current_item"
    done
    printf '\n'
  }

  print_main_packages_by_category() {
    local category
    local category_items=()
    local package_item

    for category in "${PACKAGE_CATEGORY_ORDER[@]}"; do
      category_items=()
      for package_item in "${README_PACKAGE_ITEMS[@]}"; do
        [[ "${PACKAGE_CATEGORY_BY_PACKAGE[$package_item]:-}" == "$category" ]] || continue
        category_items+=("$package_item")
      done

      ((${#category_items[@]} > 0)) || continue
      printf '%s\n' "- Apps principais - $category:"
      print_item_list category_items
    done
  }

  [[ -f "$PACKAGE_FILE" ]] || {
    announce_error "Lista de pacotes não encontrada em $PACKAGE_FILE"
    return 1
  }

  README_PACKAGE_ITEMS=()
  PACKAGE_CATEGORY_ORDER=()
  PACKAGE_CATEGORY_BY_PACKAGE=()
  load_package_file "$PACKAGE_FILE" README_PACKAGE_ITEMS "Geral"

  printf '%s\n' '<!-- packages:start -->'
  printf '%s\n' '- Dependências do bootstrap remoto:'
  print_item_list BOOTSTRAP_REMOTE_PACKAGES
  printf '%s\n' '- Ferramentas de suporte instaladas no fluxo local:'
  print_item_list LOCAL_SUPPORT_PACKAGES
  printf '%s\n' '- Helper AUR padrão preparado pelo script:'
  print_item_list AUR_HELPER_README_ITEMS
  printf '%s\n' '- Dependências da etapa de GitHub SSH:'
  print_item_list GITHUB_SSH_SUPPORT_PACKAGES
  print_main_packages_by_category
  if component_enabled "codex_cli"; then
    printf '%s\n' '- Componentes usados para instalar e executar o Codex CLI:'
    print_item_list CODEX_CLI_README_ITEMS
  fi
  printf '%s\n' '- Dependências do ambiente gráfico:'
  print_item_list DESKTOP_INTEGRATION_PACKAGES
  printf '%s\n' '- Dependência temporária, quando necessária:'
  print_item_list TEMPORARY_CLIPBOARD_PACKAGES
  printf '%s\n' '<!-- packages:end -->'
}

replace_package_block() {
  local temp_file
  local start_line
  local end_line

  start_line="$(grep -n '^<!-- packages:start -->$' "$README_FILE" | cut -d: -f1)"
  end_line="$(grep -n '^<!-- packages:end -->$' "$README_FILE" | cut -d: -f1)"

  [[ -n "$start_line" && -n "$end_line" ]] || {
    printf 'Erro: marcadores de pacotes não encontrados no README.\n' >&2
    exit 1
  }

  temp_file="$(mktemp)"
  if (( start_line > 1 )); then
    head -n $((start_line - 1)) "$README_FILE" >"$temp_file"
  else
    : >"$temp_file"
  fi

  render_package_block >>"$temp_file"
  tail -n +$((end_line + 1)) "$README_FILE" >>"$temp_file"

  if [[ "${1:-}" == "--check" ]]; then
    if ! cmp -s "$README_FILE" "$temp_file"; then
      printf 'Erro: a seção de pacotes do README está desatualizada. Rode bash scripts/update-readme-packages.sh.\n' >&2
      rm -f "$temp_file"
      exit 1
    fi
    rm -f "$temp_file"
    return 0
  fi

  mv "$temp_file" "$README_FILE"
}

main() {
  case "${1:-}" in
    ""|--check)
      replace_package_block "${1:-}"
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf 'Erro: opção desconhecida: %s\n' "${1:-}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
