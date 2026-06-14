#!/usr/bin/env bash
# shellcheck shell=bash

home_backup_name_matches() {
  local entry_name="$1"
  local nocasematch_was_enabled=0

  if shopt -q nocasematch; then
    nocasematch_was_enabled=1
  fi
  shopt -s nocasematch

  case "$entry_name" in
    *backup*|*.bak|*.bak.*|*.backup|*.backup.*|*.old|*.old.*)
      if [[ "$nocasematch_was_enabled" != "1" ]]; then
        shopt -u nocasematch
      fi
      return 0
      ;;
  esac

  if [[ "$nocasematch_was_enabled" != "1" ]]; then
    shopt -u nocasematch
  fi
  return 1
}

home_backup_relocation_allowed() {
  local backup_path="$1"
  local backup_name=""

  backup_name="$(basename "$backup_path")"
  case "$backup_name" in
    .|..|Backups|Codex|Dots|EasyEffects-Preset|Pictures|Projects|Repositories|Videos)
      return 1
      ;;
  esac

  [[ "$backup_path" != "$BACKUPS_DIR" ]]
}

collect_loose_home_backups() {
  local array_name="$1"
  local candidate
  local candidate_name=""
  local nullglob_was_enabled=0
  # shellcheck disable=SC2178
  declare -n target_backups="$array_name"

  target_backups=()

  if shopt -q nullglob; then
    nullglob_was_enabled=1
  fi
  shopt -s nullglob

  for candidate in "$HOME"/* "$HOME"/.[!.]* "$HOME"/..?*; do
    [[ -e "$candidate" || -L "$candidate" ]] || continue
    home_backup_relocation_allowed "$candidate" || continue
    candidate_name="$(basename "$candidate")"
    home_backup_name_matches "$candidate_name" || continue
    target_backups+=("$candidate")
  done

  if [[ "$nullglob_was_enabled" != "1" ]]; then
    shopt -u nullglob
  fi
}

home_backup_target_path() {
  local source_path="$1"
  local source_name=""
  local target_path=""
  local timestamp=""
  local suffix=1

  source_name="$(basename "$source_path")"
  target_path="$BACKUPS_DIR/$source_name"
  if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
    printf '%s\n' "$target_path"
    return
  fi

  timestamp="$(date +%Y%m%d%H%M%S)"
  target_path="$BACKUPS_DIR/$source_name.$timestamp"
  while [[ -e "$target_path" || -L "$target_path" ]]; do
    target_path="$BACKUPS_DIR/$source_name.$timestamp.$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$target_path"
}

relocate_loose_home_backup() {
  local source_path="$1"
  local target_path=""

  mkdir -p "$BACKUPS_DIR"
  target_path="$(home_backup_target_path "$source_path")"

  announce_detail "Movendo backup para $target_path..."
  if execute_planned_filesystem_move \
    "move-home-backup:$(sanitize_label "$source_path")" \
    "$source_path" \
    "$target_path" \
    "move home backup" \
    "mover $target_path de volta para $source_path"; then
    return 0
  fi

  announce_warning "Não foi possível mover o backup $(basename "$source_path") para $BACKUPS_DIR."
  return 1
}
