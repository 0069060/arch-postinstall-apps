#!/usr/bin/env bash
# shellcheck shell=bash

legacy_install_dir_path() {
  printf '%s\n' "$REPOSITORIES_DIR/arch-postinstall-apps"
}

relocate_managed_install_repo() {
  local legacy_install_dir=""

  legacy_install_dir="$(legacy_install_dir_path)"
  [[ "$legacy_install_dir" != "$INSTALL_DIR" ]] || return 3
  [[ -d "$legacy_install_dir" ]] || return 2

  if [[ -e "$INSTALL_DIR" ]]; then
    announce_warning "O clone gerenciado legado em $legacy_install_dir não foi movido porque $INSTALL_DIR já existe."
    return 2
  fi

  if [[ ! -d "$legacy_install_dir/.git" ]]; then
    announce_warning "$legacy_install_dir existe, mas não é um repositório git gerenciado."
    return 2
  fi

  mkdir -p "$(dirname "$INSTALL_DIR")"
  announce_detail "Movendo clone gerenciado para $INSTALL_DIR..."
  if mv "$legacy_install_dir" "$INSTALL_DIR"; then
    return 0
  fi

  announce_warning "Não foi possível mover o clone gerenciado para $INSTALL_DIR."
  return 1
}

directory_is_git_repository() {
  local dir_path="$1"

  git -C "$dir_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

home_repo_relocation_allowed() {
  local repo_dir="$1"
  local repo_name=""

  repo_name="$(basename "$repo_dir")"
  case "$repo_name" in
    Backups|Codex|Dots|EasyEffects-Preset|Pictures|Projects|Repositories|Videos)
      return 1
      ;;
  esac

  return 0
}

collect_loose_home_git_repositories() {
  local array_name="$1"
  local candidate
  local nullglob_was_enabled=0
  # shellcheck disable=SC2178
  declare -n target_repositories="$array_name"

  target_repositories=()

  if shopt -q nullglob; then
    nullglob_was_enabled=1
  fi
  shopt -s nullglob

  for candidate in "$HOME"/*; do
    [[ -d "$candidate" && ! -L "$candidate" ]] || continue
    home_repo_relocation_allowed "$candidate" || continue
    directory_is_git_repository "$candidate" || continue
    target_repositories+=("$candidate")
  done

  if [[ "$nullglob_was_enabled" != "1" ]]; then
    shopt -u nullglob
  fi
}

relocate_loose_home_git_repository() {
  local source_repo_dir="$1"
  local repo_name=""
  local target_repo_dir=""

  repo_name="$(basename "$source_repo_dir")"
  target_repo_dir="$REPOSITORIES_DIR/$repo_name"

  if [[ -e "$target_repo_dir" ]]; then
    announce_warning "O repositório '$repo_name' em $HOME não foi movido porque $target_repo_dir já existe."
    return 2
  fi

  announce_detail "Movendo repositório git para $target_repo_dir..."
  if mv "$source_repo_dir" "$target_repo_dir"; then
    return 0
  fi

  announce_warning "Não foi possível mover o repositório '$repo_name' para $target_repo_dir."
  return 1
}
