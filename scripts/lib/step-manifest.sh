#!/usr/bin/env bash
# shellcheck shell=bash

register_step_definition "runtime_validate_environment" \
  "mode=all" \
  "title=Validando ambiente..." \
  "function=runtime_validate_environment_step" \
  "count_for_progress=1"
register_step_definition "load_configuration" \
  "mode=all" \
  "title=Carregando configuração..." \
  "function=load_configuration_step" \
  "count_for_progress=1"
register_step_definition "check_only_verification" \
  "mode=check" \
  "title=Executando verificação sem alterações..." \
  "function=check_only_step" \
  "count_for_progress=1"
register_step_definition "dry_run_plan" \
  "mode=dry-run" \
  "title=Montando plano sem alterações..." \
  "function=dry_run_plan_step" \
  "count_for_progress=1"
register_step_definition "create_directories" \
  "mode=install" \
  "title=Criando diretórios..." \
  "function=create_directories_step" \
  "count_for_progress=1"
register_step_definition "relocate_home_backups" \
  "mode=install" \
  "title=Organizando backups da home..." \
  "function=relocate_home_backups_step" \
  "count_for_progress=1"
register_step_definition "relocate_home_repositories" \
  "mode=install" \
  "title=Reorganizando repositórios da home..." \
  "function=relocate_home_repositories_step" \
  "count_for_progress=1"
register_step_definition "sync_managed_repositories" \
  "mode=install" \
  "title=Sincronizando repositórios gerenciados..." \
  "function=sync_managed_repositories_step" \
  "count_for_progress=1"
register_step_definition "ensure_multilib" \
  "mode=install" \
  "title=Preparando repositório multilib..." \
  "function=ensure_multilib_step" \
  "count_for_progress=1"
register_step_definition "update_system" \
  "mode=install" \
  "title=Atualizando o sistema..." \
  "function=update_system_step" \
  "count_for_progress=1"
register_step_definition "install_local_support_packages" \
  "mode=install" \
  "title=Instalando ferramentas de suporte..." \
  "function=install_local_support_packages_step" \
  "count_for_progress=1"
register_step_definition "prepare_package_installation" \
  "mode=install" \
  "title=" \
  "function=prepare_package_installation_step" \
  "count_for_progress=0"
register_step_definition "install_official_packages" \
  "mode=install" \
  "title=Instalando apps oficiais..." \
  "function=install_official_packages_step" \
  "count_for_progress=1"
register_step_definition "install_aur_packages" \
  "mode=install" \
  "title=Instalando apps AUR..." \
  "function=install_aur_packages_step" \
  "count_for_progress=1"
register_step_definition "finalize_package_installation" \
  "mode=install" \
  "title=" \
  "function=finalize_package_installation_step" \
  "count_for_progress=0"
register_step_definition "final_verification" \
  "mode=install" \
  "title=Validando instalação..." \
  "function=final_verification_step" \
  "count_for_progress=1"

register_step_definition "bootstrap_validate_environment" \
  "mode=bootstrap" \
  "title=Validando ambiente..." \
  "function=bootstrap_validate_environment_step" \
  "count_for_progress=1"
register_step_definition "bootstrap_check_dependencies" \
  "mode=bootstrap" \
  "title=Verificando dependências iniciais já instaladas..." \
  "function=bootstrap_check_dependencies_step" \
  "count_for_progress=1"
register_step_definition "bootstrap_install_dependencies" \
  "mode=bootstrap" \
  "title=Instalando dependências iniciais..." \
  "function=bootstrap_install_dependencies_step" \
  "count_for_progress=1"
register_step_definition "bootstrap_sync_repo" \
  "mode=bootstrap" \
  "title=Sincronizando repositório..." \
  "function=bootstrap_sync_repo_step" \
  "count_for_progress=1"
