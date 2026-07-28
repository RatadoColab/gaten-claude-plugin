---
name: azure-devops
description: This skill should be used when designing or implementing CI/CD pipelines on Azure DevOps (Azure Pipelines). Covers the YAML pipeline structure (stages/jobs/steps), triggers, agent pools, variable groups and Azure Key Vault integration, service connections, environments with approvals and gates, deployment jobs and strategies (runOnce, rolling, canary), pipeline templates, and azure-pipelines.yml examples deploying to OpenShift.
---

# Azure DevOps — Azure Pipelines

## Visão Geral

Diretrizes específicas para construir pipelines de CI/CD no Azure DevOps usando Azure Pipelines em
YAML (`azure-pipelines.yml`), versionado no repositório. Carregar junto de `ci-cd` — aqui ficam
apenas os conceitos próprios da plataforma. Os princípios gerais (fail fast, build once/deploy many,
gates de qualidade) vêm de `ci-cd`.

> Preferir **pipelines YAML** aos *classic pipelines* (editor visual): YAML é pipeline-como-código,
> revisável e versionado.

---

## Princípios Fundamentais

- **Pipeline-como-código YAML:** definir em `azure-pipelines.yml` versionado e revisado como código
- **Build once, deploy many:** herdar de `ci-cd` — buildar o artefato uma vez e promovê-lo entre
  environments via tag imutável (`$(Build.SourceVersion)`)
- **Secrets sempre via cofre:** integrar variable groups ao Azure Key Vault; nunca segredo em texto
  puro no YAML
- **Menor privilégio nas service connections:** a credencial só pode fazer o que o deploy exige
- **Gates antes de produção:** environments com approvals/checks bloqueiam deploys não aprovados

---

## Estrutura do Pipeline

Hierarquia de cima para baixo:

| Nível       | Papel                                                          |
|-------------|----------------------------------------------------------------|
| **stage**   | Fase macro do fluxo (Build, Test, Deploy); roda em sequência ou paralelo |
| **job**     | Unidade que roda em um agente; jobs de um stage rodam em paralelo por padrão |
| **step**    | Ação individual: `task:` (tarefa pronta) ou `script:`/`bash:` (comando) |
| **pool**    | Agente que executa o job: Microsoft-hosted ou self-hosted      |

- **Triggers:** `trigger` (CI por push em branches) e `pr` (validação de pull request)
- **Agent pools:** *Microsoft-hosted* (efêmero, sem manutenção) vs *self-hosted* (controle de rede,
  acesso a recursos internos como um cluster OpenShift on-prem)

---

## Variáveis e Secrets

- **Variable groups:** agrupam variáveis reutilizáveis entre pipelines (Library → Variable groups)
- **Azure Key Vault:** ligar um variable group ao Key Vault para injetar secrets em runtime — nunca
  colocar segredos em texto puro no YAML
- **Secret variables:** marcar variáveis sensíveis como `secret`; não são exibidas em logs
- Referenciar variáveis com `$(nome)`; secrets só são expostos a steps que os declaram

```yaml
variables:
  - group: prod-secrets        # variable group ligado ao Key Vault
  - name: imageTag
    value: $(Build.SourceVersion)   # hash do commit como tag imutável
```

> Ver `domains/devsecops/SKILL.md` para gestão de secrets e credenciais (OIDC) no pipeline.

---

## Service Connections

- Autenticam o pipeline a recursos externos: container registries, clouds, clusters Kubernetes/OpenShift
- Para OpenShift, usar uma service connection do tipo Kubernetes apontando para a API do cluster com
  um **ServiceAccount token** dedicado (menor privilégio, escopo no Project alvo)
- Aplicar menor privilégio: a credencial só deve poder fazer o que o deploy exige

---

## Environments, Approvals e Gates

- **Environment:** alvo lógico de deploy (ex.: `staging`, `production`) com histórico e rastreabilidade
- **Approvals & checks:** exigir aprovação manual, janela de tempo ou gate automático antes de
  implantar em produção
- **Deployment job:** job especial (`deployment:`) que registra o deploy no environment e suporta
  estratégias com hooks de ciclo de vida

| Estratégia  | Comportamento                                          | Quando usar              |
|-------------|--------------------------------------------------------|--------------------------|
| **runOnce** | Executa `preDeploy`/`deploy`/`routeTraffic`/`postRouteTraffic`/`on:` uma vez | Padrão            |
| **rolling** | Substitui instâncias em lotes                          | Reduzir downtime         |
| **canary**  | Implanta em incrementos com validação entre eles       | Alto risco               |

---

## Templates

- Extrair etapas comuns para arquivos de template e reutilizá-las com `extends` ou `- template:` —
  padroniza pipelines entre projetos e centraliza gates de segurança
- Templates aceitam `parameters` tipados para customização controlada

---

## Exemplo — `azure-pipelines.yml` (build → scan → deploy no OpenShift)

Pipeline completo em **`references/azure-pipelines-openshift.md`**. Estrutura: 2 stages (Build com lint/test/SCA + `Docker@2` buildAndPush via service connection; DeployProd com `deployment:` job em `environment: production` exigindo approval), variable group ligado ao Key Vault, tag imutável `$(Build.SourceVersion)` e task `oc-setup@2` (requer a extensão "Red Hat OpenShift" na organização).

---

## Referências

- Ver `domains/ci-cd/SKILL.md` para estágios, gates de qualidade e estratégias de deploy (base desta skill)
- Ver `domains/kubernetes/SKILL.md` para o cluster alvo da service connection Kubernetes/OpenShift
- Ver `domains/openshift/SKILL.md` para o alvo de deploy (Route, SCC, `oc`)
- Ver `domains/containers/SKILL.md` para o build da imagem publicada no registry
- Ver `domains/devsecops/SKILL.md` para SAST/SCA/DAST e gestão de secrets no pipeline
- [Azure Pipelines — YAML schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Azure Pipelines — Deployment jobs](https://learn.microsoft.com/azure/devops/pipelines/process/deployment-jobs)
