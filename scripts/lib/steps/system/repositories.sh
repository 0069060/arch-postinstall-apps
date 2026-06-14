#!/usr/bin/env bash
# shellcheck shell=bash

create_directories_step() {
  step_result_reset

  if ! create_directories; then
    step_result_hard_fail "Não foi possível criar os diretórios base do ambiente."
    return 0
  fi

  step_result_success "Os diretórios base foram garantidos."
}

relocate_home_backups_step() {
  local loose_backups=()
  local backup_path=""
  local move_status=0
  local moved_count=0
  local failed_count=0

  step_result_reset

  collect_loose_home_backups loose_backups
  if ((${#loose_backups[@]} == 0)); then
    step_result_skipped "Nenhum backup solto foi encontrado na home."
    return 0
  fi

  announce_detail "Preview de backups soltos que seriam movidos:"
  for backup_path in "${loose_backups[@]}"; do
    announce_detail "- $backup_path -> $BACKUPS_DIR/"
  done
  if ! confirm_home_relocation_batch \
    "Mover backups soltos em HOME" \
    "${#loose_backups[@]} item(ns)" \
    "$BACKUPS_DIR" \
    "MOVE HOME BACKUPS"; then
    step_result_soft_fail "Movimentação de backups soltos bloqueada ou cancelada."
    return 0
  fi

  for backup_path in "${loose_backups[@]}"; do
    if relocate_loose_home_backup "$backup_path"; then
      move_status=0
    else
      move_status=$?
    fi

    case "$move_status" in
      0)
        moved_count=$((moved_count + 1))
        report_mark_change "home_backup:$(basename "$backup_path")"
        ;;
      *)
        failed_count=$((failed_count + 1))
        ;;
    esac
  done

  if (( failed_count > 0 )); then
    step_result_soft_fail "Nem todos os backups soltos na home puderam ser movidos para $BACKUPS_DIR."
    return 0
  fi

  if (( moved_count > 0 )); then
    step_result_success "Os backups soltos da home foram movidos para $BACKUPS_DIR."
    return 0
  fi

  step_result_skipped "Os backups soltos da home já estavam alinhados com $BACKUPS_DIR."
}

relocate_home_repositories_step() {
  local loose_repositories=()
  local repo_dir
  local repo_name=""
  local target_repo_dir=""
  local move_status=0
  local moved_count=0
  local failed_count=0

  step_result_reset

  collect_loose_home_git_repositories loose_repositories
  if ((${#loose_repositories[@]} == 0)); then
    step_result_skipped "Nenhum repositório git solto foi encontrado na home."
    return 0
  fi

  announce_detail "Preview de repositórios soltos que seriam movidos:"
  for repo_dir in "${loose_repositories[@]}"; do
    announce_detail "- $repo_dir -> $REPOSITORIES_DIR/$(basename "$repo_dir")"
  done
  if ! confirm_home_relocation_batch \
    "Mover repositórios Git soltos em HOME" \
    "${#loose_repositories[@]} repositório(s)" \
    "$REPOSITORIES_DIR" \
    "MOVE HOME REPOSITORIES"; then
    step_result_soft_fail "Movimentação de repositórios soltos bloqueada ou cancelada."
    return 0
  fi

  for repo_dir in "${loose_repositories[@]}"; do
    repo_name="$(basename "$repo_dir")"
    target_repo_dir="$REPOSITORIES_DIR/$repo_name"
    if [[ -e "$target_repo_dir" ]]; then
      announce_warning "O repositório '$repo_name' em $HOME não foi movido porque $target_repo_dir já existe."
      operation_plan_add \
        "move-home-repository:$(sanitize_label "$repo_dir")" \
        "filesystem" \
        "$repo_dir -> $target_repo_dir" \
        "move home repository" \
        "medium" \
        "" \
        "allow" \
        "" \
        "mover $target_repo_dir de volta para $repo_dir" || true
      operation_plan_set_status "move-home-repository:$(sanitize_label "$repo_dir")" "skipped" "destino já existe"
      move_status=2
    elif execute_planned_filesystem_move \
      "move-home-repository:$(sanitize_label "$repo_dir")" \
      "$repo_dir" \
      "$target_repo_dir" \
      "move home repository" \
      "mover $target_repo_dir de volta para $repo_dir"; then
      move_status=0
    else
      move_status=$?
    fi

    case "$move_status" in
      0)
        moved_count=$((moved_count + 1))
        report_mark_change "home_repo:$(basename "$repo_dir")"
        ;;
      2)
        ;;
      *)
        failed_count=$((failed_count + 1))
        ;;
    esac
  done

  if (( failed_count > 0 )); then
    step_result_soft_fail "Nem todos os repositórios git soltos na home puderam ser movidos para $REPOSITORIES_DIR."
    return 0
  fi

  if (( moved_count > 0 )); then
    step_result_success "Os repositórios git soltos na home foram movidos para $REPOSITORIES_DIR."
    return 0
  fi

  step_result_skipped "Os repositórios git soltos já estavam alinhados com $REPOSITORIES_DIR."
}

sync_managed_repositories_step() {
  local managed_repo_dirs=()
  local repo_dir=""
  local sync_status=0
  local changed_count=0
  local failed_count=0
  local skipped_count=0

  step_result_reset

  mapfile -t managed_repo_dirs < <(managed_environment_repo_dirs)
  for repo_dir in "${managed_repo_dirs[@]}"; do
    if sync_managed_repo "$repo_dir"; then
      sync_status=0
    else
      sync_status=$?
    fi

    case "$sync_status" in
      0)
        changed_count=$((changed_count + 1))
        ;;
      2|3)
        skipped_count=$((skipped_count + 1))
        ;;
      *)
        failed_count=$((failed_count + 1))
        ;;
    esac
  done

  if (( changed_count > 0 )); then
    report_mark_change "managed_repositories"
  fi

  if (( failed_count > 0 )); then
    step_result_soft_fail "Nem todos os repositórios gerenciados puderam ser sincronizados."
    return 0
  fi

  if (( changed_count > 0 )); then
    step_result_success "Os repositórios gerenciados foram garantidos em Projects, Dots e EasyEffects-Preset."
    return 0
  fi

  if (( skipped_count > 0 )); then
    step_result_skipped "Os repositórios gerenciados já estavam alinhados ou foram mantidos como estão."
    return 0
  fi

  step_result_skipped "Nenhum repositório gerenciado precisou de sincronização."
}
