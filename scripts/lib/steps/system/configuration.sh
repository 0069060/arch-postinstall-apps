#!/usr/bin/env bash
# shellcheck shell=bash

load_configuration_step() {
  local array_name="$1"

  step_result_reset
  if ! load_packages "$array_name"; then
    step_result_hard_fail "Não foi possível carregar a configuração de pacotes."
    return 0
  fi

  if ! report_requested_main_packages "$array_name"; then
    step_result_hard_fail "Não foi possível classificar a lista principal de pacotes."
    return 0
  fi

  if [[ "$CHECK_ONLY" != "1" && "$DRY_RUN" != "1" ]]; then
    if ! append_runtime_install_pipeline "$array_name"; then
      step_result_hard_fail "Não foi possível montar o pipeline de instalação."
      return 0
    fi
    set_step_total "$(pipeline_count_steps_for_mode install)"
  fi

  step_result_success "A configuração de pacotes foi carregada."
}

dry_run_plan_step() {
  local array_name="$1"
  local loose_backups=()
  local loose_repositories=()
  local dry_run_official_packages=()
  local dry_run_aur_packages=()
  local dry_run_aur_helper="${AUR_HELPER_NAME:-yay}"
  local dry_run_managed_repo_dirs=()
  local repo_dir=""
  local repo_origin_url=""
  local codex_prefix="$HOME/Codex"
  local codex_path_line="export PATH=\"\$HOME/Codex/bin:\$PATH\""
  local dry_run_github_key_name="${GITHUB_SSH_KEY_NAME:-$USER}"
  # shellcheck disable=SC2178
  declare -n dry_run_packages="$array_name"

  step_result_reset

  announce_detail "Dry-run: nenhum comando de instalação, movimentação, edição ou autenticação será executado."
  announce_detail "${#dry_run_packages[@]} pacote(s) declarado(s) seriam considerados."
  announce_detail "Plano de fases que seriam avaliadas em uma execução real:"
  announce_detail "- validar ambiente Arch/Wayland/Hyprland e sudo"
  announce_detail "- carregar configuração de pacotes"
  announce_detail "- preparar diretórios, backups e repositórios gerenciados"
  announce_detail "- preparar multilib e atualização do sistema"
  announce_detail "- instalar pacotes oficiais e AUR declarados"
  announce_detail "- aplicar componentes Codex, desktop e GitHub SSH"
  announce_detail "- executar verificação final e resumo"

  collect_loose_home_backups loose_backups
  if ((${#loose_backups[@]} > 0)); then
    operation_plan_add \
      "dry-run-home-backups" \
      "filesystem" \
      "${#loose_backups[@]} item(ns) -> $BACKUPS_DIR" \
      "Mover backups soltos em HOME" \
      "high" \
      "MOVE HOME BACKUPS" \
      "block" \
      "" \
      "mover manualmente de volta se necessário"
  fi

  collect_loose_home_git_repositories loose_repositories
  if ((${#loose_repositories[@]} > 0)); then
    operation_plan_add \
      "dry-run-home-repositories" \
      "filesystem" \
      "${#loose_repositories[@]} repositório(s) -> $REPOSITORIES_DIR" \
      "Mover repositórios Git soltos em HOME" \
      "high" \
      "MOVE HOME REPOSITORIES" \
      "block" \
      "" \
      "mover manualmente de volta se necessário"
  fi

  if ! multilib_enabled; then
    operation_plan_add \
      "dry-run-pacman-config" \
      "system-config" \
      "/etc/pacman.conf" \
      "edit system config" \
      "high" \
      "EDIT PACMAN CONFIG" \
      "block" \
      "" \
      "restaurar arquivo pelo backup registrado"
  fi

  collect_packages_by_origin "$array_name" "official" dry_run_official_packages || dry_run_official_packages=()
  collect_packages_by_origin "$array_name" "aur" dry_run_aur_packages || dry_run_aur_packages=()

  if ((${#dry_run_official_packages[@]} > 0)); then
    operation_plan_add \
      "dry-run-pacman-install" \
      "pacman" \
      "${dry_run_official_packages[*]}" \
      "Instalar pacotes oficiais necessários" \
      "high" \
      "" \
      "allow" \
      "" \
      "reexecutar pacman após resolver a causa da falha"
    operation_plan_set_command \
      "dry-run-pacman-install" \
      "$(ops_command_line sudo pacman -S --needed --noconfirm "${dry_run_official_packages[@]}")" \
      "1"
  fi

  if ((${#dry_run_aur_packages[@]} > 0)); then
    operation_plan_add \
      "dry-run-aur-install" \
      "aur" \
      "${dry_run_aur_packages[*]}" \
      "Instalar pacotes AUR necessários com $dry_run_aur_helper" \
      "high" \
      "" \
      "allow" \
      "" \
      "resolver falha do helper AUR e repetir instalação"
    operation_plan_set_command \
      "dry-run-aur-install" \
      "$(ops_command_line "$dry_run_aur_helper" -S --needed --noconfirm "${dry_run_aur_packages[@]}")" \
      "0"
  fi

  if printf '%s\n' "${dry_run_packages[@]}" | grep -Fxq 'mullvad-vpn'; then
    operation_plan_add \
      "dry-run-systemd-start:mullvad-daemon" \
      "systemd" \
      "mullvad-daemon" \
      "Iniciar unidades systemd do sistema" \
      "medium" \
      "" \
      "allow" \
      "" \
      "verificar unidade e repetir systemctl manualmente"
    operation_plan_set_command \
      "dry-run-systemd-start:mullvad-daemon" \
      "$(ops_command_line sudo systemctl start mullvad-daemon)" \
      "1"
    operation_plan_add \
      "dry-run-systemd-enable:mullvad-daemon" \
      "systemd" \
      "mullvad-daemon" \
      "Habilitar unidades systemd do sistema" \
      "medium" \
      "" \
      "allow" \
      "" \
      "verificar unidade e repetir systemctl manualmente"
    operation_plan_set_command \
      "dry-run-systemd-enable:mullvad-daemon" \
      "$(ops_command_line sudo systemctl enable mullvad-daemon)" \
      "1"
  fi

  if ((${#DESKTOP_USER_SERVICES[@]} > 0)); then
    operation_plan_add \
      "dry-run-systemd-user-start:desktop-services" \
      "systemd" \
      "${DESKTOP_USER_SERVICES[*]}" \
      "Iniciar unidades systemd do usuário" \
      "medium" \
      "" \
      "allow" \
      "" \
      "verificar unidade e repetir systemctl manualmente"
    operation_plan_set_command \
      "dry-run-systemd-user-start:desktop-services" \
      "$(ops_command_line systemctl --user start "${DESKTOP_USER_SERVICES[@]}")" \
      "0"
  fi

  mapfile -t dry_run_managed_repo_dirs < <(managed_environment_repo_dirs)
  if ((${#dry_run_managed_repo_dirs[@]} > 0)); then
    for repo_dir in "${dry_run_managed_repo_dirs[@]}"; do
      repo_origin_url="$(managed_repo_preferred_origin_url "$repo_dir" 2>/dev/null || true)"
      [[ -n "$repo_origin_url" ]] || repo_origin_url="<origem não resolvida>"
      operation_plan_add \
        "dry-run-git-sync:$(sanitize_label "$repo_dir")" \
        "git" \
        "$repo_dir <- $repo_origin_url" \
        "Sincronizar repositório gerenciado" \
        "medium" \
        "" \
        "allow" \
        "" \
        "revisar o repositório local e repetir o comando git se necessário"
      operation_plan_set_command \
        "dry-run-git-sync:$(sanitize_label "$repo_dir")" \
        "$(ops_command_line git clone --branch main --single-branch "$repo_origin_url" "$repo_dir")" \
        "0"
    done
  fi

  operation_plan_add \
    "dry-run-git-sync:install-dir" \
    "git" \
    "$INSTALL_DIR <- $REPO_HTTPS_URL" \
    "Sincronizar repositório principal" \
    "medium" \
    "" \
    "allow" \
    "" \
    "revisar o clone local e repetir o comando git se necessário"
  operation_plan_set_command \
    "dry-run-git-sync:install-dir" \
    "$(ops_command_line git -C "$INSTALL_DIR" pull --ff-only origin main)" \
    "0"

  if component_enabled "codex_cli"; then
    operation_plan_add \
      "dry-run-npm-prefix:codex" \
      "npm" \
      "$codex_prefix" \
      "Configurar prefixo npm para Codex" \
      "medium" \
      "" \
      "allow" \
      "" \
      "remover ou ajustar prefixo npm/Codex manualmente se necessário"
    operation_plan_set_command \
      "dry-run-npm-prefix:codex" \
      "$(ops_command_line npm config set prefix "$codex_prefix")" \
      "0"
    operation_plan_add \
      "dry-run-npm-install:codex" \
      "npm" \
      "@openai/codex" \
      "Instalar Codex CLI via npm" \
      "medium" \
      "" \
      "allow" \
      "" \
      "remover pacote npm global se necessário"
    operation_plan_set_command \
      "dry-run-npm-install:codex" \
      "$(ops_command_line npm install -g @openai/codex)" \
      "0"
    operation_plan_add \
      "dry-run-shell-config:codex-bash" \
      "filesystem" \
      "$BASHRC_FILE" \
      "edit shell config" \
      "medium" \
      "" \
      "allow" \
      "" \
      "restaurar $BASHRC_FILE pelo backup registrado"
    operation_plan_set_command "dry-run-shell-config:codex-bash" "append: $codex_path_line" "0"
    operation_plan_add \
      "dry-run-shell-config:codex-zsh" \
      "filesystem" \
      "$ZSHRC_FILE" \
      "edit shell config" \
      "medium" \
      "" \
      "allow" \
      "" \
      "restaurar $ZSHRC_FILE pelo backup registrado"
    operation_plan_set_command "dry-run-shell-config:codex-zsh" "append: $codex_path_line" "0"
    operation_plan_add \
      "dry-run-shell-config:codex-fish" \
      "filesystem" \
      "$FISH_CONFIG_FILE" \
      "edit shell config" \
      "medium" \
      "" \
      "allow" \
      "" \
      "restaurar $FISH_CONFIG_FILE pelo backup registrado"
    operation_plan_set_command "dry-run-shell-config:codex-fish" "append Codex PATH block" "0"
  fi

  if github_ssh_expected; then
    operation_plan_add \
      "dry-run-ssh-key:github" \
      "ssh" \
      "$SSH_KEY_PATH" \
      "Gerar ou reutilizar chave SSH local" \
      "medium" \
      "" \
      "allow" \
      "" \
      "remover chave gerada manualmente se necessário"
    operation_plan_set_command \
      "dry-run-ssh-key:github" \
      "$(ops_command_line ssh-keygen -t ed25519 -C '<git-email-or-user@host>' -f "$SSH_KEY_PATH" -N "")" \
      "0"
    operation_plan_add \
      "dry-run-github-auth:login" \
      "github" \
      "github.com" \
      "Autenticar GitHub CLI" \
      "medium" \
      "" \
      "allow" \
      "" \
      "repetir gh auth após resolver autenticação ou conectividade"
    operation_plan_set_command \
      "dry-run-github-auth:login" \
      "$(ops_command_line gh auth login --web --git-protocol ssh --scopes admin:public_key)" \
      "0"
    operation_plan_add \
      "dry-run-github-ssh-key:create" \
      "github" \
      "user/keys:$dry_run_github_key_name" \
      "Enviar chave SSH ao GitHub" \
      "medium" \
      "" \
      "allow" \
      "" \
      "remover chave criada no GitHub se necessário"
    operation_plan_set_command \
      "dry-run-github-ssh-key:create" \
      "$(ops_command_line gh api user/keys --method POST -f "title=$dry_run_github_key_name" -f "key=<public-key>" --jq '.id')" \
      "0"
    if [[ "$EXCLUSIVE_GITHUB_SSH_KEY" == "1" ]]; then
      operation_plan_add \
        "dry-run-github-ssh-key:exclusive-delete" \
        "github" \
        "user/keys exceto chave atual" \
        "Remover outras chaves SSH do GitHub" \
        "high" \
        "DELETE GITHUB SSH KEYS" \
        "block" \
        "" \
        "recriar chaves removidas manualmente no GitHub se necessário"
      operation_plan_set_command \
        "dry-run-github-ssh-key:exclusive-delete" \
        "$(ops_command_line gh api --method DELETE 'user/keys/<other-key-id>')" \
        "0"
    fi
  fi

  announce_detail "Operações sensíveis planejadas:"
  while IFS= read -r operation_line; do
    announce_detail "- $operation_line"
  done < <(operation_plan_render)
  operation_plan_report_all
  print_summary
  STEP_RESULT_SUMMARY_PRINTED=1

  step_result_success "O plano de dry-run foi montado sem aplicar alterações."
}

check_only_step() {
  local array_name="$1"
  local detection_component_ids=()
  local component_id
  local package_name

  step_result_reset
  mapfile -t detection_component_ids < <(component_check_only_detection_ids)
  for component_id in "${detection_component_ids[@]}"; do
    component_prepare_check_only_state "$component_id" || true
  done
  for package_name in "${LOCAL_SUPPORT_PACKAGES[@]}"; do
    report_add_requested_support_package "$package_name"
  done
  for package_name in "${DESKTOP_INTEGRATION_PACKAGES[@]}"; do
    report_add_requested_environment_package "$package_name"
  done
  verify_installation "$array_name"
  print_summary
  STEP_RESULT_SUMMARY_PRINTED=1
  if state_has_missing_items; then
    step_result_soft_fail "A verificação sem alterações encontrou itens ausentes."
    return 0
  fi

  step_result_success "A verificação sem alterações foi concluída."
}
