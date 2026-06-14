#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2154

confirm_exclusive_github_ssh_key() {
  local operation_id="github-ssh-exclusive-key-delete"

  if [[ "$EXCLUSIVE_GITHUB_SSH_KEY" != "1" ]]; then
    return 0
  fi

  if declare -F operation_plan_add >/dev/null; then
    operation_plan_add \
      "$operation_id" \
      "github" \
      "user/keys exceto chave atual" \
      "Remover outras chaves SSH do GitHub" \
      "high" \
      "DELETE GITHUB SSH KEYS" \
      "block" \
      "" \
      "recriar chaves removidas manualmente no GitHub se necessário" || true
    if declare -F operation_plan_set_command >/dev/null; then
      operation_plan_set_command "$operation_id" "gh api --method DELETE user/keys/<other-key-id>" "0"
    fi

    if [[ "${DRY_RUN:-0}" == "1" ]]; then
      operation_plan_set_status "$operation_id" "planned" "dry-run"
      return 2
    fi

    if ! is_interactive_terminal; then
      announce_warning "Remoção exclusiva de chaves SSH bloqueada em modo não interativo."
      operation_plan_set_status "$operation_id" "blocked" "ambiente não interativo"
      return 1
    fi
  fi

  if ! confirm_dangerous_operation \
    "A opção --exclusive-key removerá as outras chaves SSH da sua conta no GitHub." \
    "DELETE GITHUB SSH KEYS"; then
    announce_warning "A remoção das outras chaves SSH do GitHub foi cancelada."
    if declare -F operation_plan_set_status >/dev/null; then
      operation_plan_set_status "$operation_id" "blocked" "confirmação recusada"
    fi
    return 1
  fi

  if declare -F operation_plan_set_status >/dev/null; then
    operation_plan_set_status "$operation_id" "succeeded" "confirmada"
  fi
  return 0
}

ensure_ssh_key() {
  local ssh_dir
  local host_name
  local key_comment

  ssh_dir="$(dirname "$SSH_KEY_PATH")"
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ -f "$SSH_KEY_PATH" ]]; then
    if [[ ! -f "${SSH_KEY_PATH}.pub" ]]; then
      announce_detail "A chave pública SSH não foi encontrada. Recriando ${SSH_KEY_PATH}.pub..."
      if ! ops_ssh_regenerate_public_key "$SSH_KEY_PATH" "${SSH_KEY_PATH}.pub"; then
        announce_error "Não foi possível recriar a chave pública SSH."
        return 1
      fi
      chmod 644 "${SSH_KEY_PATH}.pub"
    fi
    announce_detail "A chave SSH já existe em $SSH_KEY_PATH."
    return 0
  fi

  key_comment="$(git config --global user.email 2>/dev/null || true)"
  if [[ -z "$key_comment" ]]; then
    host_name="$(sanitize_label "$(get_host_name)")"
    key_comment="${USER}@${host_name}"
  fi

  announce_detail "Criando chave SSH em $SSH_KEY_PATH..."
  if ! ops_ssh_generate_key_pair "$key_comment" "$SSH_KEY_PATH"; then
    announce_error "Não foi possível criar a chave SSH."
    return 1
  fi

  return 0
}
