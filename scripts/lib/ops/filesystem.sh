#!/usr/bin/env bash
# shellcheck shell=bash

ops_download_file() {
  local source_url="$1"
  local destination_path="$2"

  retry curl -fsSL "$source_url" -o "$destination_path"
}

ops_extract_tar_gz() {
  local archive_path="$1"
  local destination_dir="$2"
  local member_path=""

  tar -tzf "$archive_path" >/dev/null || return 1
  while IFS= read -r member_path; do
    case "$member_path" in
      ""|/*|..|../*|*/..|*/../*)
        announce_error "Arquivo tar contém caminho inseguro: $member_path"
        return 1
        ;;
    esac
  done < <(tar -tzf "$archive_path")
  tar -xzf "$archive_path" -C "$destination_dir"
}
