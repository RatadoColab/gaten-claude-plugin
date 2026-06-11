---
name: ci-cd
description: This skill should be used when designing or implementing CI/CD pipelines. Covers pipeline stages, automated testing gates, build artifacts, deployment strategies (rolling, blue-green, canary, feature flags), quality gates, pipeline security, and GitHub Actions/GitLab CI examples.
version: 0.1.0
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

- Credenciais do pipeline com menor privilégio e escopo curto (OIDC em vez de chaves longevas)
- Secrets injetados em runtime via cofre — nunca em variáveis em texto puro no YAML
- Fixar (pin) versões de actions/imagens por hash para evitar supply chain attack
- Isolar runners; não executar código não confiável de PRs com credenciais de produção

> Ver `../devsecops/SKILL.md` para os scans (SAST/SCA/DAST/IaC/imagem), supply chain e secrets do pipeline.

---

## Exemplo — GitHub Actions

```yaml
name: ci
on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  build-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read            # menor privilégio
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci              # instalação reproduzível
      - run: npm run lint        # gate de estilo
      - run: npm test -- --coverage
      - run: npm audit --audit-level=high   # SCA
```

---

## Exemplo — GitLab CI

```yaml
stages: [build, test, deploy]

build:
  stage: build
  script:
    - docker build -t "$IMAGE:$CI_COMMIT_SHORT_SHA" .   # tag imutável por commit

test:
  stage: test
  script:
    - npm ci
    - npm test

deploy_prod:
  stage: deploy
  when: manual                  # gate de aprovação para produção
  environment: production
  script:
    - ./scripts/deploy.sh "$IMAGE:$CI_COMMIT_SHORT_SHA"
```

---

## Referências

- Ver `../containers/SKILL.md` para empacotar artefatos como imagens
- Ver `../iac/SKILL.md` para GitOps e provisionamento dos ambientes de deploy
- Ver `../observability/SKILL.md` para verificação pós-deploy e decisão de canary
- Ver `../devsecops/SKILL.md` para SAST/SCA/DAST, supply chain e gestão de secrets no pipeline
- [DORA — Capabilities](https://dora.dev/capabilities/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
