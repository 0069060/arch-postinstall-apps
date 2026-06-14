#!/usr/bin/env bash
# shellcheck shell=bash

sync_repo() {
  local current_branch=""
  local clone_origin_url=""

  mkdir -p "$(dirname "$INSTALL_DIR")"

  relocate_managed_install_repo || true

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    announce_detail "Atualizando clone gerenciado..."
    if managed_repo_is_dirty "$INSTALL_DIR"; then
      current_branch="$(get_repo_branch "$INSTALL_DIR" 2>/dev/null || true)"
      if [[ -n "$current_branch" && "$current_branch" != "main" ]]; then
        announce_error "O clone gerenciado está com mudanças locais na branch '$current_branch'."
        announce_error "Não dá para executar com segurança a branch 'main' sem limpar ou mover essas mudanças."
        return 1
      fi

      announce_warning "O repositório local tem alterações. A atualização automática será ignorada."
      return 0
    fi

    if ! ensure_managed_repo_origin_remote "$INSTALL_DIR"; then
      announce_error "Não foi possível ajustar o remoto origin do clone gerenciado."
      return 1
    fi

    sync_git_main_branch "$INSTALL_DIR" "clone gerenciado" "bootstrap"
    return
  fi

  if [[ -e "$INSTALL_DIR" ]]; then
    announce_error "$INSTALL_DIR já existe e não é um repositório git."
    return 1
  fi

  announce_detail "Clonando repositório pela primeira vez..."
  clone_origin_url="$(managed_repo_preferred_origin_url "$INSTALL_DIR" 2>/dev/null || true)"
  if [[ -z "$clone_origin_url" ]]; then
    announce_error "Não foi possível definir a URL de clone do repositório principal."
    return 1
  fi

  if ! ops_git_clone_main "$clone_origin_url" "$INSTALL_DIR"; then
    announce_error "Falha ao clonar 'main' de $clone_origin_url."
    announce_error "Verifique acesso ao GitHub e se a branch existe no remoto."
    return 1
  fi
}
