#!/usr/bin/env bash
# shellcheck shell=bash

register_component \
  "aur_helper" \
  "label=Helper AUR" \
  "pipeline_phase=pre_package" \
  "expected_function=component_expected_always" \
  "pipeline_title=Preparando helper AUR..." \
  "pipeline_step_function=prepare_aur_helper_step" \
  "summary_formatter=state_get_aur_helper_status" \
  "detect_handler=component_detect_aur_helper" \
  "apply_handler=component_apply_aur_helper" \
  "verify_handler=component_verify_aur_helper" \
  "has_runtime_status=0" \
  "check_only_detection=1" \
  "verification_enabled=1" \
  "summary_status_enabled=1"

register_component \
  "codex_cli" \
  "label=Codex CLI" \
  "pipeline_phase=post_package" \
  "expected_function=component_expected_codex_cli" \
  "pipeline_title=Configurando Codex CLI..." \
  "pipeline_step_function=codex_cli_step" \
  "summary_formatter=" \
  "detect_handler=component_detect_codex_cli" \
  "apply_handler=component_apply_codex_cli" \
  "verify_handler=component_verify_codex_cli" \
  "has_runtime_status=0" \
  "check_only_detection=0" \
  "verification_enabled=1" \
  "summary_status_enabled=0"

register_component \
  "desktop_integration" \
  "label=Integração desktop" \
  "pipeline_phase=post_package" \
  "expected_function=component_expected_always" \
  "pipeline_title=Ajustando integração desktop..." \
  "pipeline_step_function=desktop_integration_step" \
  "summary_formatter=format_desktop_integration_status" \
  "detect_handler=component_detect_desktop_integration" \
  "apply_handler=component_apply_desktop_integration" \
  "verify_handler=component_verify_desktop_integration" \
  "has_runtime_status=1" \
  "check_only_detection=1" \
  "verification_enabled=1" \
  "summary_status_enabled=1"

register_component \
  "github_ssh" \
  "label=GitHub SSH" \
  "pipeline_phase=pre_package" \
  "expected_function=github_ssh_expected" \
  "pipeline_title=Configurando GitHub SSH..." \
  "pipeline_step_function=github_ssh_step" \
  "summary_formatter=format_github_ssh_status" \
  "detect_handler=component_detect_github_ssh" \
  "apply_handler=component_apply_github_ssh" \
  "verify_handler=component_verify_github_ssh" \
  "has_runtime_status=1" \
  "check_only_detection=1" \
  "verification_enabled=1" \
  "summary_status_enabled=1"
