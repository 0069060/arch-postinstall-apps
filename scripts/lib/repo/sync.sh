#!/usr/bin/env bash
# shellcheck shell=bash

managed_repo_is_dirty() {
  local repo_dir="$1"

  ! git -C "$repo_dir" diff --quiet --no-ext-diff || \
    ! git -C "$repo_dir" diff --cached --quiet --no-ext-diff || \
    [[ -n "$(git -C "$repo_dir" status --porcelain --untracked-files=normal)" ]]
}

sync_git_main_branch() {
  local repo_dir="$1"
  local repo_label="$2"
  local sync_mode="${3:-strict}"
  local fetched_origin=0

  if ops_git_fetch_origin "$repo_dir"; then
    fetched_origin=1
  elif [[ "$sync_mode" == "bootstrap" ]]; then
    announce_warning "Falha ao buscar atualizações de origin. O script tentará usar a cópia local."
  else
    announce_warning "Não foi possível buscar atualizações de $repo_label."
    return 1
  fi

  if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/main"; then
    if ! ops_git_checkout_main "$repo_dir"; then
      if [[ "$sync_mode" == "bootstrap" ]]; then
        announce_error "Não foi possível trocar para a branch local 'main'."
      else
        announce_warning "Não foi possível trocar $repo_label para a branch 'main'."
      fi
      return 1
    fi
  elif git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/main"; then
    if ! ops_git_checkout_main_from_origin "$repo_dir"; then
      if [[ "$sync_mode" == "bootstrap" ]]; then
        announce_error "Não foi possível criar a branch local 'main' a partir de origin."
      else
        announce_warning "Não foi possível criar a branch local 'main' de $repo_label."
      fi
      return 1
    fi
  elif [[ "$sync_mode" == "bootstrap" && "$fetched_origin" == "0" ]]; then
    announce_error "Não foi possível atualizar origin e a branch 'main' não existe localmente."
    announce_error "Verifique acesso ao GitHub ou recupere um clone local válido."
    return 1
  else
    if [[ "$sync_mode" == "bootstrap" ]]; then
      announce_error "Branch 'main' não encontrada no repositório local nem em origin."
    else
      announce_warning "A branch 'main' não foi encontrada em $repo_label."
    fi
    return 1
  fi

  if [[ "$sync_mode" == "bootstrap" && "$fetched_origin" == "0" ]]; then
    announce_warning "O 'git pull' será ignorado porque o fetch de origin falhou. O script continuará com a branch local."
    return 0
  fi

  if ops_git_pull_main_ff_only "$repo_dir"; then
    return 0
  fi

  if [[ "$sync_mode" == "bootstrap" ]]; then
    announce_warning "Falha ao atualizar 'main' com 'git pull --ff-only'. O script continuará com a cópia atual."
    return 0
  fi

  announce_warning "Não foi possível atualizar $repo_label com 'git pull --ff-only'."
  return 1
}

sync_managed_repo() {
  local repo_dir="$1"
  local repo_label=""
  local previous_commit=""
  local current_commit=""
  local clone_origin_url=""
  local clone_submodules="0"
  local label_suffix=""

  repo_label="$(managed_repo_display_name "$repo_dir")"
  clone_submodules="$(managed_repo_clone_submodules "$repo_dir" 2>/dev/null || printf '0\n')"
  label_suffix="do repositório $repo_label"

  if ! command -v git >/dev/null 2>&1; then
    announce_warning "O git não está disponível para sincronizar $label_suffix."
    return 1
  fi

  if [[ -d "$repo_dir/.git" ]]; then
    previous_commit="$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || true)"

    if ! managed_repo_origin_matches_expected "$repo_dir"; then
      announce_warning "O diretório $repo_dir já é um repositório git com origin diferente. A sincronização será ignorada."
      return 2
    fi

    if managed_repo_is_dirty "$repo_dir"; then
      announce_warning "O repositório em $repo_dir tem alterações locais. A atualização automática será ignorada."
      return 2
    fi

    if ! ensure_managed_repo_origin_remote "$repo_dir"; then
      announce_warning "Não foi possível ajustar o remoto de $label_suffix."
      return 1
    fi

    announce_detail "Atualizando $label_suffix..."
    if ! sync_git_main_branch "$repo_dir" "$label_suffix"; then
      return 1
    fi
    if [[ "$clone_submodules" == "1" ]]; then
      announce_detail "Atualizando submódulos $label_suffix..."
      if ! ops_git_update_submodules "$repo_dir"; then
        announce_warning "Não foi possível atualizar os submódulos de $repo_label."
        return 1
      fi
    fi

    current_commit="$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || true)"
    if [[ -n "$previous_commit" && "$previous_commit" == "$current_commit" ]]; then
      return 3
    fi

    return 0
  fi

  if [[ -e "$repo_dir" && -n "$(find "$repo_dir" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
    announce_warning "$repo_dir já existe e não está vazio. O clone de $label_suffix será ignorado."
    return 2
  fi

  announce_detail "Clonando $label_suffix em $repo_dir..."
  clone_origin_url="$(managed_repo_preferred_origin_url "$repo_dir" 2>/dev/null || true)"
  if [[ -z "$clone_origin_url" ]]; then
    announce_warning "Não foi possível definir a URL de clone de $label_suffix."
    return 1
  fi

  if ops_git_clone_main "$clone_origin_url" "$repo_dir" "$clone_submodules"; then
    return 0
  fi

  announce_warning "Não foi possível clonar $label_suffix."
  return 1
}
