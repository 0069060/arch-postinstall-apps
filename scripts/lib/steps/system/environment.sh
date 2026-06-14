#!/usr/bin/env bash
# shellcheck shell=bash

runtime_validate_environment_step() {
  validate_execution_environment_step "instalador" "O ambiente foi validado."
}

update_system_step() {
  step_result_reset

  if [[ "$SYSTEM_UPDATED" == "1" ]]; then
    announce_detail "O sistema já foi atualizado no bootstrap. A nova atualização completa será ignorada."
    step_result_skipped "A atualização completa do sistema foi ignorada porque já ocorreu no bootstrap."
    return 0
  fi

  if ops_pacman_upgrade_full; then
    step_result_success "A atualização completa do sistema foi concluída."
    return 0
  fi

  step_result_hard_fail "Não foi possível concluir a atualização completa do sistema."
}

ensure_multilib_step() {
  step_result_reset

  if ! ensure_multilib; then
    step_result_hard_fail "Não foi possível preparar o repositório multilib."
    return 0
  fi

  step_result_success "O repositório multilib foi preparado."
}
