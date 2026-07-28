---
name: ci-cd
description: This skill should be used when designing or implementing CI/CD pipelines. Typical triggers include "create the CI pipeline", "set up GitHub Actions/GitLab CI", "which deploy strategy should I use?", "add quality gates to the pipeline". Covers pipeline stages, automated testing gates, build artifacts, deployment strategies (rolling, blue-green, canary, feature flags), quality gates, pipeline security, and GitHub Actions/GitLab CI examples.
---

# CI/CD — Pipelines de Integração e Entrega Contínua

## Visão Geral

Diretrizes para construir pipelines de Integração Contínua (CI) e Entrega/Implantação Contínua (CD)
confiáveis, rápidos e seguros. Um bom pipeline transforma cada commit em um candidato a release
validado automaticamente, com feedback rápido e deploy reversível.

---

## Princípios Fundamentais

- **Pipeline como código:** definido em arquivo versionado no repositório, revisado como código
- **Um pipeline por mudança:** todo commit/PR dispara o pipeline; nada chega à produção sem passar
- **Fail fast:** etapas mais rápidas e baratas primeiro (lint, unit) antes das caras (e2e, deploy)
- **Build once, deploy many:** o artefato é construído uma vez e promovido inalterado entre
  ambientes (dev → staging → prod) — nunca rebuildar por ambiente
- **Desacoplar deploy de release:** entregar código em produção desativado e ativá-lo via feature
  flag reduz risco e permite deploys frequentes

---

## Estágios do Pipeline

Ordem típica, do mais rápido/barato ao mais lento/caro:

| Estágio        | Objetivo                                              | Falha bloqueia? |
|----------------|-------------------------------------------------------|-----------------|
| **Lint/Format**| Estilo e padrões de código                            | Sim             |
| **Build**      | Compilar/empacotar o artefato                         | Sim             |
| **Unit tests** | Validar unidades isoladas com cobertura mínima        | Sim             |
| **SAST/SCA**   | Scan de código e dependências vulneráveis             | Sim (crítico)   |
| **Integration**| Validar integração entre componentes                  | Sim             |
| **Package**    | Gerar imagem/artefato versionado e publicar           | Sim             |
| **Deploy staging** | Implantar em ambiente de homologação              | Sim             |
| **E2E/DAST**   | Testes ponta a ponta e scan de runtime                | Sim             |
| **Deploy prod**| Implantar em produção (com estratégia segura)         | Sim             |
| **Verify**     | Health checks e smoke tests pós-deploy                | Sim (rollback)  |

---

## Gates de Qualidade

Critérios objetivos que bloqueiam a progressão do pipeline:

- Cobertura de testes mínima (ex.: ≥ 80% nas linhas alteradas)
- Zero vulnerabilidades de severidade alta/crítica em SAST e SCA
- Todos os testes verdes — nenhuma flakiness tolerada como verde
- Sem secrets detectados (scan de segredos no diff)
- Build reproduzível e artefato assinado

---

## Estratégias de Deploy

| Estratégia      | Como funciona                                                  | Quando usar                          |
|-----------------|---------------------------------------------------------------|--------------------------------------|
| **Rolling**     | Substitui instâncias gradualmente                             | Padrão, baixo custo                  |
| **Blue-Green**  | Dois ambientes idênticos; troca o tráfego de uma vez          | Rollback instantâneo, zero downtime  |
| **Canary**      | Libera para % pequena de usuários, expande se métricas ok     | Alto risco, validação progressiva    |
| **Feature flag**| Deploy do código desativado; ativação controlada em runtime   | Desacoplar deploy de release         |

**Regras:**
- Todo deploy de produção deve ter **rollback automático** disparado por health check/métrica
- Canary e blue-green exigem observabilidade para decidir promover ou reverter
- Feature flags devem ter ciclo de vida — remover flags obsoletas evita dívida técnica

---

## Versionamento de Artefatos

- Versionar artefatos com SemVer ou hash do commit (`app:1.4.2`, `app:sha-a1b2c3d`)
- Publicar em registry imutável; nunca sobrescrever uma tag publicada
- Promover o **mesmo** artefato entre ambientes — diferenças vão em configuração, não no binário
- Manter rastreabilidade: artefato → commit → PR → mudança

---

## Segurança do Pipeline

Segurança do pipeline (OIDC vs chaves longevas, secrets via cofre, pinning por hash, isolamento de runners, scans SAST/SCA/DAST/IaC/imagem, supply chain) é coberta integralmente em `domains/devsecops/SKILL.md` — fonte autoritativa.

---

## Exemplos — GitHub Actions e GitLab CI

Pipelines completos em **`references/pipeline-examples.md`**. Pontos-chave dos exemplos: `permissions: contents: read` (menor privilégio), `npm ci` (instalação reproduzível), tag de imagem imutável por commit (`$CI_COMMIT_SHORT_SHA`) e `when: manual` + `environment` como gate de aprovação para produção.

---

## Referências

- Ver `domains/containers/SKILL.md` para empacotar artefatos como imagens
- Ver `domains/kubernetes/SKILL.md` ou `domains/podman/SKILL.md` conforme o alvo de execução do artefato (cluster ou host único)
- Ver `domains/iac/SKILL.md` para GitOps e provisionamento dos ambientes de deploy
- Ver `domains/observability/SKILL.md` para verificação pós-deploy e decisão de canary
- Ver `domains/devsecops/SKILL.md` para SAST/SCA/DAST, supply chain e gestão de secrets no pipeline
- [DORA — Capabilities](https://dora.dev/capabilities/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
