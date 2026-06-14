# Final Review

Este documento resume o estado preparado para revisão após a limpeza de histórico e as fases de hardening.

## Branches

- Histórico curado: `rewrite/history-cleanup`
- Fase 1: `improve/post-history-cleanup`
- Fase 2: `improve/phase2-safety-guards`
- Fase 3: `improve/phase3-operation-planner`
- Fase 4: `improve/phase4-system-operations`
- Fase 5: `improve/phase5-external-operations`
- Fase 6: `improve/phase6-hardening-docs`

`origin/main` deve continuar intacta até revisão final e decisão explícita de publicação.

## Resumo Das Fases

- Histórico: reduzido para commits lógicos em `rewrite/history-cleanup`, preservando o estado final.
- Fase 1: correções e testes iniciais de segurança/parser.
- Fase 2: guards para operações perigosas em `~`, backups sensíveis, confirmação textual e semântica de `--check`/`--dry-run`.
- Fase 3: operation planner central com status padronizado e summary integrado.
- Fase 4: pacman, AUR e systemd roteados pelo planner.
- Fase 5: git, GitHub/SSH, npm/Codex e operações externas roteadas pelo planner.
- Fase 6: consolidação de helpers, rollback hints visíveis, docs e checklist final.

## Modos

- `--check`: valida ambiente/configuração/estado esperado sem autenticar `sudo`, sem instalar e sem aplicar side effects. Requisitos de root/sudo são reportados.
- `--dry-run`: renderiza o plano de execução e operações planejadas, sem executar comandos externos ou tocar arquivos.
- Execução real: aplica mudanças usando wrappers planejados, registra status e summary.

## Operation Planner

Cada operação planejada pode registrar:

- tipo;
- alvo;
- descrição;
- risco;
- comando renderizado com redaction básica de secrets;
- necessidade de root/sudo;
- confirmação textual;
- política para modo não interativo;
- executor;
- status;
- backup;
- rollback hint.

Status padronizados:

- `planned`
- `skipped`
- `blocked`
- `succeeded`
- `failed`

## Rollback Manual

Rollback automático completo ainda não existe. Use o summary final como ponto de partida:

- Shell rc: restaurar o arquivo a partir do backup informado no summary.
- Movimentos em `~`: mover o item do destino registrado de volta para a origem.
- `/etc/pacman.conf`: restaurar a partir do backup sensível registrado.
- Repositórios git: revisar origin/local path e repetir ou desfazer `remote set-url`, clone ou movimentação manualmente.
- Chaves GitHub SSH: remover/recriar chaves pela UI do GitHub ou `gh api`, usando os IDs envolvidos quando disponíveis.

## Validação

Rodar antes de revisão final:

```bash
bash scripts/check-repo.sh
bash scripts/build-bootstrap.sh --check
bash scripts/build-lint-entrypoints.sh --check
bash scripts/update-readme-packages.sh --check
bash install.sh --check
bash install.sh --dry-run
bash install.sh --help
bash dist/install.sh --help
```

## Riscos Restantes

- Dry-run não resolve dependências reais de pacman/AUR.
- Autenticação interativa do `gh` continua delegada ao GitHub CLI.
- Rollback automático não foi implementado.
- O fluxo é direcionado a Arch Linux com Wayland/Hyprland, não a instalações genéricas.
- O bootstrap remoto ainda pode sincronizar o clone gerenciado e preparar dependências iniciais antes de entrar no runtime local.

## Recomendação De Publicação

1. Revisar a branch `improve/phase6-hardening-docs`.
2. Comparar contra `origin/main` e contra `rewrite/history-cleanup`.
3. Rodar todos os comandos de validação acima.
4. Abrir PR para revisão, sem force push em `main`.
5. Só substituir `origin/main` por decisão explícita após revisão do diff, do bootstrap gerado e do summary de dry-run.
