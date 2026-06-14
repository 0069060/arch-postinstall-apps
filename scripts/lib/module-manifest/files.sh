#!/usr/bin/env bash
# shellcheck shell=bash

register_module_file "scripts/lib/module-manifest/registry.sh" \
  bootstrap-check runtime-check
register_module_file "scripts/lib/module-manifest/files.sh" \
  bootstrap-check runtime-check

register_module_file "scripts/lib/cli.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/runtime-config.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/invocation-context.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/execution-report.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/execution-report/changes.sh" \
  runtime-check
register_module_file "scripts/lib/execution-report/packages.sh" \
  runtime-check
register_module_file "scripts/lib/execution-report/components.sh" \
  runtime-check
register_module_file "scripts/lib/step-result.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ui/styles.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ui/logging.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ui/notice.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ui/summary-primitives.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ui.sh" \
  runtime-check
register_module_file "scripts/lib/pipeline.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/step-registry.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/step-manifest.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/step-pipeline.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/process.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/locking.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/env.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/operation-planner.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/safety.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/environment-validation.sh" \
  bootstrap-fragment bootstrap-check runtime-entrypoint runtime-check
register_module_file "scripts/lib/ops/common.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/privilege.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/package.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/filesystem.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/git.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/github.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/node.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/ssh.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops/systemd.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/ops.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/repo/manifest/store.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/manifest/registration.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/manifest/definitions.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/manifest/queries.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/manifest.sh" \
  runtime-check
register_module_file "scripts/lib/repo/origin/status.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/origin/remote.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/origin/transport.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/origin/managed.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/origin.sh" \
  runtime-check
register_module_file "scripts/lib/repo/relocation.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo/sync.sh" \
  bootstrap-fragment bootstrap-check runtime-check
register_module_file "scripts/lib/repo.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/home-backups.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/bootstrap/repo-sync.sh" \
  bootstrap-fragment bootstrap-check
register_module_file "scripts/bootstrap/config.sh" \
  bootstrap-fragment bootstrap-check
register_module_file "scripts/bootstrap/steps/system.sh" \
  bootstrap-fragment bootstrap-check
register_module_file "scripts/bootstrap/steps/packages.sh" \
  bootstrap-fragment bootstrap-check
register_module_file "scripts/bootstrap/steps/repo.sh" \
  bootstrap-fragment bootstrap-check
register_module_file "scripts/bootstrap/entrypoint.sh" \
  bootstrap-fragment bootstrap-check

register_module_file "scripts/lib/core.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/component-config.sh" \
  runtime-check
register_module_file "scripts/lib/component-registry.sh" \
  runtime-check
register_module_file "scripts/lib/component-registry/store.sh" \
  runtime-check
register_module_file "scripts/lib/component-registry/registration.sh" \
  runtime-check
register_module_file "scripts/lib/component-registry/queries.sh" \
  runtime-check
register_module_file "scripts/lib/component-manifest.sh" \
  runtime-check
register_module_file "scripts/lib/components.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/components/codex.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/components/aur-helper.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/components/desktop.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/components/github-ssh.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/package-config.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/package-config/parser.sh" \
  runtime-check
register_module_file "scripts/lib/package-config/origin.sh" \
  runtime-check
register_module_file "scripts/lib/package-config/reporting.sh" \
  runtime-check
register_module_file "scripts/lib/package-repos.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/package-install.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/verification.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/repair.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/repair/plan.sh" \
  runtime-check
register_module_file "scripts/lib/repair/actions.sh" \
  runtime-check
register_module_file "scripts/lib/repair/final-verification.sh" \
  runtime-check
register_module_file "scripts/lib/summary.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/summary/context.sh" \
  runtime-check
register_module_file "scripts/lib/summary/render.sh" \
  runtime-check
register_module_file "scripts/lib/summary/writer.sh" \
  runtime-check
register_module_file "scripts/lib/steps/system.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/steps/system/environment.sh" \
  runtime-check
register_module_file "scripts/lib/steps/system/configuration.sh" \
  runtime-check
register_module_file "scripts/lib/steps/system/repositories.sh" \
  runtime-check
register_module_file "scripts/lib/steps/packages.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/steps/codex.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/steps/desktop.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/steps/github-ssh.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/steps/verification.sh" \
  runtime-entrypoint runtime-check
register_module_file "scripts/lib/flow.sh" \
  runtime-entrypoint runtime-check

register_module_file "scripts/lib/runtime-state.sh" runtime-check
register_module_file "scripts/lib/runtime-state/packages.sh" runtime-check
register_module_file "scripts/lib/runtime-state/verification.sh" runtime-check
register_module_file "scripts/lib/runtime-state/runtime-flags.sh" runtime-check
register_module_file "scripts/lib/status.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/clipboard.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/auth.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/key.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/publish.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/publish/api.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/publish/sync.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/state.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/apply.sh" runtime-check
register_module_file "scripts/lib/components/github-ssh/verify.sh" runtime-check
