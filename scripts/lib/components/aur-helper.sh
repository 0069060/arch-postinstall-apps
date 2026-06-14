#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
# shellcheck source-path=SCRIPTDIR
# shellcheck source=scripts/lib/ops.sh
# shellcheck source=scripts/lib/components.sh

detect_aur_helper() {
  if command -v yay >/dev/null 2>&1; then
    state_set_aur_helper "yay" "yay (reutilizado)"
    return 0
  fi

  if command -v paru >/dev/null 2>&1; then
    state_set_aur_helper "paru" "paru (fallback)"
    return 0
  fi

  state_set_aur_helper "" "indisponível"
  return 1
}

component_detect_aur_helper() {
  detect_aur_helper
}

build_yay() {
  local yay_dir="$1"

  (
    cd "$yay_dir" || exit
    makepkg -si --noconfirm
  )
}

install_yay() {
  local archive_file
  local extracted_yay_dir=""
  local extract_dir=""
  local missing_packages=()
  local package_name
  local status=0

  for package_name in "${AUR_HELPER_SUPPORT_PACKAGES[@]}"; do
    report_add_requested_support_package "$package_name"
  done
  mkdir -p "$REPOSITORIES_DIR"
  collect_missing_packages missing_packages "${AUR_HELPER_SUPPORT_PACKAGES[@]}"
  if ((${#missing_packages[@]} > 0)); then
    if ! ops_pacman_install_needed "${missing_packages[@]}"; then
      return 1
    fi
    for package_name in "${missing_packages[@]}"; do
      report_add_changed_support_package "$package_name"
    done
  fi
  for package_name in "${AUR_HELPER_SUPPORT_PACKAGES[@]}"; do
    if ! config_array_contains missing_packages "$package_name"; then
      report_add_reused_support_package "$package_name"
    fi
  done
  require_command curl
  require_command tar

  archive_file="$(mktemp)"
  register_cleanup_path "$archive_file"

  announce_detail "Baixando snapshot do yay..."
  if ! ops_download_file "$YAY_SNAPSHOT_URL" "$archive_file"; then
    return 1
  fi

  extract_dir="$(mktemp -d)"
  register_cleanup_path "$extract_dir"
  announce_detail "Extraindo snapshot do yay..."
  if ! ops_extract_tar_gz "$archive_file" "$extract_dir"; then
    return 1
  fi

  extracted_yay_dir="$extract_dir/yay"
  if [[ ! -d "$extracted_yay_dir" || -L "$extracted_yay_dir" ]]; then
    announce_error "O snapshot do yay não contém o diretório esperado."
    return 1
  fi

  if [[ -e "$YAY_REPO_DIR" && ! -d "$YAY_REPO_DIR" ]]; then
    announce_error "$YAY_REPO_DIR já existe e não é um diretório."
    return 1
  fi

  announce_detail "Atualizando snapshot do yay em $YAY_REPO_DIR..."
  rm -rf -- "$YAY_REPO_DIR"
  if ! mv "$extracted_yay_dir" "$YAY_REPO_DIR"; then
    announce_error "Não foi possível mover o snapshot do yay para $YAY_REPO_DIR."
    return 1
  fi

  if (( status == 0 )); then
    if ops_build_yay_package "$YAY_REPO_DIR"; then
      state_set_aur_helper "yay" "yay (instalado nesta execução)"
    else
      status=$?
    fi
  fi

  return "$status"
}

component_apply_aur_helper() {
  local aur_helper_name=""

  if command -v yay >/dev/null 2>&1; then
    state_set_aur_helper "yay" "yay (reutilizado)"
    report_set_component_outcome "aur_helper" "$COMPONENT_OUTCOME_REUSED"
    aur_helper_name="$(state_get_aur_helper_name)"
    announce_detail "Usando helper AUR: $aur_helper_name"
    return 0
  fi

  announce_detail "O yay será instalado e usado como helper AUR padrão."
  if ! install_yay; then
    if detect_aur_helper; then
      report_set_component_outcome "aur_helper" "$COMPONENT_OUTCOME_FALLBACK_REUSED"
      aur_helper_name="$(state_get_aur_helper_name)"
      announce_warning "Não foi possível instalar o yay. O script usará o helper AUR disponível: $aur_helper_name."
      return 0
    fi

    announce_error "Não foi possível preparar um helper AUR (yay)."
    return 1
  fi

  state_set_aur_helper "yay" "yay (instalado nesta execução)"
  report_set_component_outcome "aur_helper" "$COMPONENT_OUTCOME_CHANGED"
  aur_helper_name="$(state_get_aur_helper_name)"
  announce_detail "Usando helper AUR: $aur_helper_name"
}

component_verify_aur_helper() {
  component_detect aur_helper
}

ensure_aur_helper() {
  component_apply aur_helper
}
