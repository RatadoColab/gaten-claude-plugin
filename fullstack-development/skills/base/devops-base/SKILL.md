---
name: devops-base
description: This skill should be used when planning or implementing DevOps and CI/CD work. Covers DevOps culture, automation principles, shift-left and DevSecOps, immutability, idempotency, the four DORA metrics, and how to navigate the CI/CD, containers, OpenShift, Azure DevOps, IaC, observability, and DevSecOps domains.
version: 0.1.0
---

# DevOps Base — Fundamentos de DevOps e CI/CD

## Visão Geral

Fornece os princípios culturais e técnicos transversais ao trabalho de DevOps, independente de
ferramenta ou plataforma. As práticas detalhadas de cada disciplina ficam nas skills de domínio
(`ci-cd`, `containers`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`); esta
base estabelece o vocabulário comum, os princípios inegociáveis e a forma de medir sucesso.

DevOps é a união de cultura, práticas e ferramentas que encurta o ciclo entre uma mudança de
código e sua entrega em produção com segurança e confiabilidade.

## Cultura DevOps

- **Responsabilidade compartilhada:** desenvolvimento e operações compartilham a propriedade do
  ciclo de vida — "you build it, you run it"
- **Colaboração sobre silos:** remover barreiras entre dev, ops, QA e segurança
- **Postmortems sem culpa (blameless):** falhas são oportunidades de aprendizado sistêmico, não de
  punição individual
- **Melhoria contínua:** medir, experimentar, ajustar — pequenos incrementos frequentes
- **Feedback rápido:** encurtar o ciclo entre ação e sinal (testes, deploy, observabilidade)

## Princípios Fundamentais

- **Automatize tudo:** build, teste, deploy, provisionamento e rollback devem ser automáticos e
  reproduzíveis — passos manuais são fonte de erro e gargalo
- **Shift-left:** mover validação (testes, segurança, qualidade) o mais cedo possível no ciclo,
  reduzindo o custo de corrigir defeitos
- **Fail fast:** detectar e sinalizar falhas o quanto antes; pipeline quebrado bloqueia a entrega
- **Idempotência:** executar a mesma operação de provisionamento/deploy múltiplas vezes produz o
  mesmo estado final — base de IaC e automação confiável
- **Imutabilidade:** infraestrutura e artefatos não são alterados in-place; são reconstruídos a
  partir de definições versionadas, eliminando drift e "snowflake servers"
- **Tudo como código:** infraestrutura, pipelines, configuração e políticas vivem em controle de
  versão (Git como fonte da verdade)
- **Versionamento e rastreabilidade:** todo artefato e mudança são versionados e auditáveis

## DevSecOps — Segurança Integrada

Segurança é responsabilidade de todos e deve estar embutida no pipeline, não ser uma etapa final.

- **Nunca** armazenar secrets (chaves, senhas, tokens) em texto puro no repositório — usar cofre
  de secrets (Vault, sealed secrets, secret managers da nuvem)
- Embutir scans automáticos em cada estágio: **SAST** (código), **SCA** (dependências), **DAST**
  (runtime) e **IaC scanning** (misconfiguração de infraestrutura)
- Aplicar princípios de **zero-trust** e menor privilégio nas credenciais do pipeline
- Gerar e assinar **SBOM** (Software Bill of Materials) para rastrear a cadeia de suprimentos

> Ver `../../domains/devsecops/SKILL.md` para scans no pipeline, IaC/image scanning, SBOM, supply
> chain e gestão de secrets/credenciais. Para segurança de aplicação web/API (OWASP Top 10), ver
> `../../domains/security/SKILL.md`.

## Métricas DORA

As quatro métricas DORA (DevOps Research and Assessment) medem a performance de entrega de software
e devem guiar a melhoria contínua:

| Métrica                    | O que mede                                              | Direção desejada |
|----------------------------|--------------------------------------------------------|------------------|
| **Deployment Frequency**   | Com que frequência se faz deploy em produção           | Maior            |
| **Lead Time for Changes**  | Tempo do commit até o código em produção               | Menor            |
| **Mean Time to Restore**   | Tempo para restaurar serviço após uma falha (MTTR)     | Menor            |
| **Change Failure Rate**    | % de deploys que causam falha exigindo correção        | Menor            |

- Times de elite fazem deploy múltiplas vezes ao dia, com lead time de minutos, usando canary
  releases e feature flags para reduzir risco
- Combine métricas DORA com sinais de produtividade de engenharia — não otimize um número isolado
- As plataformas (GitHub Actions, GitLab, Jenkins) fornecem os dados de deploy/build necessários,
  mas calcular DORA exige instrumentação ou integração — não há cálculo nativo pronto

## Fluxo de Trabalho Recomendado

1. **Entender o contexto:** stack, ambientes, plataforma de CI, restrições de compliance
2. **Definir como código:** pipeline, infraestrutura e configuração versionados
3. **Automatizar o caminho crítico:** build → teste → scan → deploy → verificação
4. **Tornar reversível:** todo deploy deve ter estratégia de rollback clara
5. **Observar:** instrumentar métricas, logs e traces antes de considerar pronto
6. **Iterar:** medir DORA, identificar gargalos, melhorar incrementalmente

## Precedência de Skills de Domínio

Ao trabalhar uma tarefa de DevOps, carregar o domínio pertinente sobre esta base:

| Tarefa                                          | Skill de domínio a carregar          |
|-------------------------------------------------|--------------------------------------|
| Pipeline, build, testes, deploy, releases       | `../../domains/ci-cd/SKILL.md`       |
| Pipeline no Azure DevOps / Azure Pipelines      | `../../domains/azure-devops/SKILL.md` (+ `ci-cd`) |
| Dockerfile, imagens, Kubernetes, registries     | `../../domains/containers/SKILL.md`  |
| Deploy/manifests no OpenShift (Route, SCC, oc)  | `../../domains/openshift/SKILL.md` (+ `containers`) |
| Terraform/IaC, GitOps, provisionamento, secrets | `../../domains/iac/SKILL.md`         |
| Métricas, logs, traces, alertas, SLO/SLI        | `../../domains/observability/SKILL.md` |
| Scans no pipeline, IaC/image scanning, SBOM, supply chain, secrets | `../../domains/devsecops/SKILL.md` |

## Referências

- Ver `../../domains/ci-cd/SKILL.md` para pipelines e estratégias de deploy
- Ver `../../domains/azure-devops/SKILL.md` para CI/CD no Azure DevOps
- Ver `../../domains/containers/SKILL.md` para containerização e orquestração
- Ver `../../domains/openshift/SKILL.md` para deploy no OpenShift
- Ver `../../domains/iac/SKILL.md` para infraestrutura como código e GitOps
- Ver `../../domains/observability/SKILL.md` para observabilidade e SRE
- Ver `../../domains/devsecops/SKILL.md` para segurança no pipeline e na infraestrutura
- [DORA — DevOps Research and Assessment](https://dora.dev/)
- [Google SRE Book](https://sre.google/books/)
- [OWASP CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
