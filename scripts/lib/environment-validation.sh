#!/usr/bin/env bash
# shellcheck shell=bash

validate_execution_environment_step() {
  local context_name="$1"
  local success_message="$2"

  step_result_reset

  if ! ensure_arch; then
    step_result_hard_fail "Este $context_name só pode ser executado em Arch Linux."
    return 0
  fi

  if ! ensure_supported_session; then
    step_result_hard_fail "A sessão atual não é compatível com o $context_name."
    return 0
  fi

  if ! require_command pacman; then
    step_result_hard_fail "O comando 'pacman' é obrigatório para continuar."
    return 0
  fi

  if ! require_command sudo; then
    step_result_hard_fail "O comando 'sudo' é obrigatório para continuar."
    return 0
  fi

  if [[ "${CHECK_ONLY:-0}" == "1" ]]; then
    announce_detail "Check: sudo encontrado; autenticação interativa não será solicitada."
    announce_detail "Uma execução real ainda exigirá sudo/root para pacman, systemd e arquivos de sistema."
    if declare -F operation_plan_add >/dev/null; then
      operation_plan_add \
        "check-sudo-requirement" \
        "privilege" \
        "sudo/root" \
        "Validar requisito de sudo para execução real" \
        "high" \
        "" \
        "allow" \
        "" \
        "executar novamente em terminal interativo se a instalação real precisar autenticar sudo" || true
      operation_plan_set_command "check-sudo-requirement" "sudo -v" "1"
      operation_plan_set_status "check-sudo-requirement" "skipped" "check-only: autenticação não solicitada"
    fi
    init_logging
    step_result_success "$success_message"
    return 0
  fi

  announce_prompt "Autenticando sudo..."
  if ! ops_sudo_auth; then
    step_result_hard_fail "Não foi possível autenticar o sudo."
    return 0
  fi

  init_logging
  step_result_success "$success_message"
}
