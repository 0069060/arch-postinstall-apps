#!/usr/bin/env bash
# shellcheck shell=bash

print_summary_header() {
  echo
  printf '%s %s\n' "$(style_text "$style_success" "╭─")" "$(style_text "$style_success" "Concluído")"
}

print_step_output_summary() {
  local status_array_name="$1"
  local component_id
  local component_label
  local component_status_text
  # shellcheck disable=SC2178
  declare -n summary_status_component_ids="$status_array_name"

  print_summary_header
  print_summary_section "Resultado"
  print_summary_item "Modo:" "$SUMMARY_EXECUTION_MODE"
  print_summary_item "Alterações aplicadas:" "$SUMMARY_CHANGES_APPLIED"
  print_summary_section "Operações sensíveis"
  while IFS= read -r safety_line; do
    print_summary_item "Operação:" "$safety_line"
  done < <(report_safety_operation_lines)
  for component_id in "${summary_status_component_ids[@]}"; do
    component_label="$(component_summary_label "$component_id")"
    component_status_text="$(component_summary_status_text "$component_id")"
    print_summary_item "$component_label:" "$component_status_text"
  done
  print_summary_section "Repositório"
  print_summary_item "Commit:" "$SUMMARY_COMMIT"
  print_summary_section "Arquivos"
  print_summary_item "Log:" "$LOG_FILE"
  print_summary_item "Resumo:" "$SUMMARY_FILE"
  echo "│"
  style_text "$style_muted" "╰─ Fim"
  printf '\n'
}

print_summary_versions() {
  local version_line

  if ((${#STATE_VERSION_LINES[@]} == 0)); then
    print_summary_item "Versões:" "nenhuma"
    return 0
  fi

  print_summary_section "Versões"
  for version_line in "${STATE_VERSION_LINES[@]}"; do
    echo "│    $(style_text "$style_detail" "•") $version_line"
  done
}

print_full_summary() {
  local status_array_name="$1"
  local ready_array_name="$2"
  local component_id
  local component_label
  local component_status_text
  # shellcheck disable=SC2178
  declare -n summary_status_component_ids="$status_array_name"
  # shellcheck disable=SC2178
  declare -n summary_ready_components="$ready_array_name"

  print_summary_header
  print_summary_section "Arquivos"
  print_summary_item "Log:" "$LOG_FILE"
  print_summary_item "Resumo:" "$SUMMARY_FILE"
  print_summary_section "Operações sensíveis"
  while IFS= read -r safety_line; do
    print_summary_item "Operação:" "$safety_line"
  done < <(report_safety_operation_lines)
  print_summary_section "Estado"
  print_summary_item "Modo:" "$SUMMARY_EXECUTION_MODE"
  print_summary_item "Alterações aplicadas:" "$SUMMARY_CHANGES_APPLIED"
  print_summary_item "Hostname:" "$SUMMARY_HOST_NAME"
  print_summary_item "Repositório:" "$SUMMARY_REPO_PATH"
  print_summary_item "Branch:" "$SUMMARY_BRANCH"
  print_summary_item "Commit:" "$SUMMARY_COMMIT"
  print_summary_item "Origin:" "$SUMMARY_ORIGIN_STATUS"
  print_summary_section "Pacotes e configuração"
  print_summary_item "Lista principal via pacman:" "${REPORT_REQUESTED_MAIN_OFFICIAL_PACKAGES[*]:-nenhum}"
  print_summary_item "Alterados via pacman:" "${REPORT_CHANGED_MAIN_OFFICIAL_PACKAGES[*]:-nenhum}"
  print_summary_item "Lista principal via AUR:" "${REPORT_REQUESTED_MAIN_AUR_PACKAGES[*]:-nenhum}"
  print_summary_item "Alterados via AUR:" "${REPORT_CHANGED_MAIN_AUR_PACKAGES[*]:-nenhum}"
  print_summary_item "Suporte alterado:" "${REPORT_CHANGED_SUPPORT_PACKAGES[*]:-nenhuma}"
  print_summary_item "Suporte reutilizado:" "${REPORT_REUSED_SUPPORT_PACKAGES[*]:-nenhuma}"
  print_summary_item "Ambiente alterado:" "${REPORT_CHANGED_ENVIRONMENT_PACKAGES[*]:-nenhuma}"
  print_summary_item "Ambiente reutilizado:" "${REPORT_REUSED_ENVIRONMENT_PACKAGES[*]:-nenhuma}"
  print_summary_item "Componentes prontos:" "${summary_ready_components[*]:-nenhum}"
  print_summary_item "GitHub SSH esperado:" "$(summary_github_ssh_expected_text)"
  for component_id in "${summary_status_component_ids[@]}"; do
    component_label="$(component_summary_label "$component_id")"
    component_status_text="$(component_summary_status_text "$component_id")"
    print_summary_item "$component_label:" "$component_status_text"
  done
  print_summary_section "Verificação"
  print_summary_item "Falhas pacman:" "${STATE_FAILED_OFFICIAL_PACKAGES[*]:-nenhuma}"
  print_summary_item "Falhas AUR:" "${STATE_FAILED_AUR_PACKAGES[*]:-nenhuma}"
  print_summary_item "Falhas parciais:" "${STATE_SOFT_FAILURES[*]:-nenhuma}"
  print_summary_item "Verificados:" "${STATE_VERIFIED_ITEMS[*]:-nenhum}"
  print_summary_item "Ausentes:" "${STATE_MISSING_ITEMS[*]:-nenhum}"
  print_summary_versions
  echo "│"
  style_text "$style_muted" "╰─ Fim"
  printf '\n'
}
