#!/usr/bin/env bash
# shellcheck shell=bash

component_apply_github_ssh() {
  local managed_repo_dirs=()
  local missing_packages=()
  local package_name
  local reconcile_status=0
  local repo_dir=""

  if ! github_ssh_expected; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_DISABLED"
    announce_detail "A configuração do GitHub SSH foi desativada por opção."
    return
  fi

  if ! confirm_exclusive_github_ssh_key; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_DECLINED"
    return
  fi

  announce_detail "Verificando estado atual do GitHub SSH..."
  if ! github_ssh_force_reconcile && github_ssh_ready; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_REUSED"
    announce_detail "O GitHub SSH já está configurado. Etapa ignorada."
    return
  fi

  if has_checkpoint "github_ssh"; then
    announce_detail "Checkpoint do GitHub SSH encontrado. Conferindo autenticação e chave atual..."
  fi

  announce_detail "Registrando dependências da etapa de GitHub SSH..."
  for package_name in "${GITHUB_SSH_SUPPORT_PACKAGES[@]}"; do
    report_add_requested_support_package "$package_name"
  done
  announce_detail "Verificando dependências da etapa de GitHub SSH..."
  collect_missing_packages missing_packages "${GITHUB_SSH_SUPPORT_PACKAGES[@]}"
  if ((${#missing_packages[@]} > 0)); then
    if ! ops_pacman_install_needed "${missing_packages[@]}"; then
      report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
      announce_warning "Não foi possível instalar github-cli/openssh. A configuração do GitHub será ignorada."
      return
    fi
    for package_name in "${missing_packages[@]}"; do
      report_add_changed_support_package "$package_name"
    done
  else
    announce_detail "As dependências do GitHub SSH já estão disponíveis."
  fi
  for package_name in "${GITHUB_SSH_SUPPORT_PACKAGES[@]}"; do
    if ! config_array_contains missing_packages "$package_name"; then
      report_add_reused_support_package "$package_name"
    fi
  done

  if ! command -v gh >/dev/null 2>&1 || ! command -v ssh-keygen >/dev/null 2>&1; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
    announce_warning "github-cli ou ssh-keygen está indisponível. A configuração do GitHub será ignorada."
    return
  fi

  if ! ensure_ssh_key; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
    announce_warning "Não foi possível preparar a chave SSH local. A configuração do GitHub será ignorada."
    return
  fi

  if ! ensure_github_auth; then
    cleanup_temp_clipboard_utility || true
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
    announce_warning "A autenticação do GitHub não foi concluída. O envio da chave SSH será ignorado."
    return
  fi

  if ! upload_ssh_key; then
    cleanup_temp_clipboard_utility || true
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
    announce_warning "Não foi possível enviar a chave SSH para o GitHub."
    return
  fi

  cleanup_temp_clipboard_utility || true
  if ! mark_checkpoint "github_ssh"; then
    report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_SOFT_FAILED"
    announce_warning "A chave SSH foi configurada, mas o checkpoint do GitHub SSH não pôde ser registrado."
    return
  fi
  report_set_component_outcome "github_ssh" "$COMPONENT_OUTCOME_CHANGED"

  if ! ensure_repo_origin_remote "$SCRIPT_DIR" "$REPO_SSH_URL"; then
    announce_warning "A chave SSH foi configurada, mas não foi possível ajustar o remoto do repositório para SSH."
  fi
  if [[ "$INSTALL_DIR" != "$SCRIPT_DIR" ]]; then
    if reconcile_managed_repo_origin_ssh "$INSTALL_DIR"; then
      reconcile_status=0
    else
      reconcile_status=$?
    fi
    if [[ "$reconcile_status" == "1" ]]; then
      announce_warning "A chave SSH foi configurada, mas não foi possível ajustar o clone gerenciado para SSH."
    fi
  fi

  mapfile -t managed_repo_dirs < <(managed_environment_repo_dirs)
  for repo_dir in "${managed_repo_dirs[@]}"; do
    if reconcile_managed_repo_origin_ssh "$repo_dir"; then
      reconcile_status=0
    else
      reconcile_status=$?
    fi
    if [[ "$reconcile_status" == "1" ]]; then
      announce_warning "A chave SSH foi configurada, mas não foi possível ajustar o repositório gerenciado em $repo_dir para SSH."
    fi
  done
}
