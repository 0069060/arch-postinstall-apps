#!/usr/bin/env bash
# shellcheck shell=bash

write_summary_file() {
  local status_array_name="$1"
  local ready_array_name="$2"
  local component_id
  local component_label
  local component_status_text
  # shellcheck disable=SC2178
  declare -n summary_status_component_ids="$status_array_name"
  # shellcheck disable=SC2178
  declare -n summary_ready_components="$ready_array_name"

  mkdir -p "$(dirname "$SUMMARY_FILE")"
  cat >"$SUMMARY_FILE" <<EOF
Data: $(date '+%Y-%m-%d %H:%M:%S %z')
Modo: $SUMMARY_EXECUTION_MODE
Alterações aplicadas: $SUMMARY_CHANGES_APPLIED
Log: $LOG_FILE
Hostname: $SUMMARY_HOST_NAME
Repositório: $SUMMARY_REPO_PATH
Branch: $SUMMARY_BRANCH
Commit: $SUMMARY_COMMIT
Origin: $SUMMARY_ORIGIN_STATUS
Itens da lista principal declarados via pacman: ${REPORT_REQUESTED_MAIN_OFFICIAL_PACKAGES[*]:-nenhum}
Itens da lista principal alterados via pacman: ${REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES[*]:-nenhum}
Itens da lista principal declarados via AUR: ${REPORT_REQUESTED_MAIN_AUR_PACKAGES[*]:-nenhum}
Itens da lista principal alterados via AUR: ${REPORT_CHANGED_MAIN_AUR_PACKAGES[*]:-nenhum}
Dependências de suporte alteradas: ${REPORT_CHANGED_SUPPORT_PACKAGES[*]:-nenhuma}
Dependências de suporte reutilizadas: ${REPORT_REUSED_SUPPORT_PACKAGES[*]:-nenhuma}
Dependências do ambiente gráfico alteradas: ${REPORT_CHANGED_ENVIRONMENT_PACKAGES[*]:-nenhuma}
Dependências do ambiente gráfico reutilizadas: ${REPORT_REUSED_ENVIRONMENT_PACKAGES[*]:-nenhuma}
Componentes prontos: ${summary_ready_components[*]:-nenhum}
GitHub SSH esperado: $(summary_github_ssh_expected_text)
Operações sensíveis:
$(report_safety_operation_lines | sed 's/^/- /')
$(for component_id in "${summary_status_component_ids[@]}"; do
    component_label="$(component_summary_label "$component_id")"
    component_status_text="$(component_summary_status_text "$component_id")"
    printf '%s: %s\n' "$component_label" "$component_status_text"
  done)
Falhas pacman: ${STATE_FAILED_OFFICIAL_PACKAGES[*]:-nenhuma}
Falhas AUR: ${STATE_FAILED_AUR_PACKAGES[*]:-nenhuma}
Falhas parciais: ${STATE_SOFT_FAILURES[*]:-nenhuma}
Verificados: ${STATE_VERIFIED_ITEMS[*]:-nenhum}
Ausentes: ${STATE_MISSING_ITEMS[*]:-nenhum}
Versões:
$(if ((${#STATE_VERSION_LINES[@]} == 0)); then echo "- nenhuma"; else printf '%s\n' "${STATE_VERSION_LINES[@]/#/- }"; fi)
EOF

  if [[ "$SCRIPT_DIR" != "$INSTALL_DIR" ]]; then
    printf 'Clone gerenciado: %s\n' "$INSTALL_DIR" >>"$SUMMARY_FILE"
  fi
}
