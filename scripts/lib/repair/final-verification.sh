#!/usr/bin/env bash
# shellcheck shell=bash

attempt_final_repair_once() {
  local array_name="$1"
  local repair_pacman_packages=()
  local repair_aur_packages=()
  local repair_origin_repos=()
  local repair_missing_pacman_packages=()
  local repair_should_repair_codex=0
  local repair_should_start_services=0

  if ! state_has_missing_items; then
    return 0
  fi

  increment_step_total
  announce_step "Tentando corrigir itens ausentes..."
  collect_final_repair_plan \
    repair_pacman_packages \
    repair_aur_packages \
    repair_origin_repos \
    repair_should_repair_codex \
    repair_should_start_services || return 1
  run_final_repair_plan \
    repair_pacman_packages \
    repair_aur_packages \
    repair_origin_repos \
    repair_missing_pacman_packages \
    repair_should_repair_codex \
    repair_should_start_services || return 1
  verify_installation "$array_name"
  ! state_has_missing_items
}

ensure_final_verification_passed() {
  local array_name="$1"

  if ! state_has_missing_items; then
    return 0
  fi

  if attempt_final_repair_once "$array_name"; then
    return 0
  fi

  announce_error "A verificação final encontrou itens ausentes após a instalação."
  announce_error "Itens ausentes: ${STATE_MISSING_ITEMS[*]}"
  return 1
}
