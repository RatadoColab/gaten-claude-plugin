# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.2.0] - 2026-06-10

### Adicionado

#### Agentes
- `devops-cicd` — DevOps, CI/CD, containerização, infraestrutura como código e observabilidade (color yellow)

#### Skills base
- `base/devops-base` — fundamentos de DevOps: cultura, princípios transversais, DevSecOps, métricas DORA e navegação entre os domínios

#### Skills de domínio
- `domains/ci-cd` — pipelines, estágios, gates de qualidade e estratégias de deploy (exemplos GitHub Actions/GitLab CI)
- `domains/containers` — Docker e Kubernetes (imagens multi-stage, probes, limites, scan e registries)
- `domains/openshift` — especificidades do OpenShift sobre Kubernetes (Route, SCC `restricted-v2`, BuildConfig/ImageStream, S2I, `oc`, OpenShift GitOps)
- `domains/azure-devops` — Azure Pipelines (stages/jobs/steps, service connections, variable groups/Key Vault, environments com approvals, deployment strategies)
- `domains/iac` — infraestrutura como código e GitOps (Terraform/Pulumi, state, drift, ArgoCD/Flux, secrets)
- `domains/observability` — três pilares (métricas/logs/traces), OpenTelemetry, golden signals, SLI/SLO/error budget e alerting acionável
- `domains/devsecops` — segurança no pipeline e na infraestrutura (SAST/SCA/DAST, IaC/image scanning, SBOM/cosign, OIDC, supply chain)

### Alterado

#### Commands
- `/fullstack-development:new-feature` — orquestração condicional do `devops-cicd`: quando a demanda tem solicitações explícitas de DevOps, o `spec-dev` gera uma seção DevOps na spec e o `devops-cicd` revisa apenas essa seção, restrito ao seu escopo

#### Skills de domínio
- `domains/security` — adicionada seção `## Referências` com cross-links (incl. `devsecops`); escopo reafirmado como segurança de aplicação web/API, complementar ao `devsecops` (pipeline/infra)

#### Projeto
- `plugin.json` — versão `0.2.0` e `description` atualizada para incluir o eixo DevOps/CI-CD
- `CLAUDE.md` — documentação do conjunto devops, das assimetrias intencionais (`ci-cd` inline vs `azure-devops`; `security` vs `devsecops` por audiência) e dos gatilhos de split futuro
- Precedência de carregamento: skills de plataforma (`openshift`/`azure-devops`) complementam as genéricas; `security` (app) e `devsecops` (pipeline/infra) separadas por audiência

## [0.1.0] - 2026-05-28

### Adicionado

#### Agentes
- `spec-dev` — revisão e validação de especificações de features para desenvolvimento com IA
- `backend-dev` — desenvolvimento backend com boas práticas por linguagem e domínio
- `frontend-dev` — desenvolvimento frontend com foco em componentes, formulários e UX

#### Skills base
- `base/spec-base` — fundamentos de especificação para IA
- `base/backend-base` — arquitetura e padrões backend
- `base/frontend-base` — arquitetura e padrões frontend

#### Skills de domínio
- `domains/spec-review` — critérios de revisão de especificações
- `domains/api-rest` — padrões REST, OpenAPI e respostas HTTP
- `domains/database` — modelagem, queries, transações e controle de acesso
- `domains/security` — OWASP, autenticação, CSRF, CORS e upload seguro
- `domains/forms` — formulários, validação e integração com APIs externas
- `domains/ui-components` — componentes UI, acessibilidade e design tokens
- `domains/user-experience` — UX, fluxos de usuário e boas práticas de interface
- `domains/glpi` — desenvolvimento de plugins GLPI 10.x com sub-skills especializadas:
  - `glpi/ajax-handlers` — padrões de endpoints AJAX no GLPI
  - `glpi/form-templates` — templates de formulários e dropdowns GLPI
  - `glpi/plugin-creation` — estrutura e ciclo de criação de plugins
  - `glpi/vue` — integração Vue.js em plugins GLPI via Twig

#### Skills de linguagem
- `languages/python` — Python moderno, type hints, async e testes
- `languages/php` — PHP 8.3, tipos, padrões e segurança
- `languages/javascript` — ES6+, async, módulos e DOM
- `languages/vue` — Vue.js, Composition API, estado e roteamento
- `languages/twig` — herança de templates, macros e performance
- `languages/html` — semântica, acessibilidade e Bootstrap 5

#### Commands
- `/fullstack-development:review-spec` — revisão completa de especificação de feature
- `/fullstack-development:new-feature` — iniciar desenvolvimento de nova feature
- `/fullstack-development:code-review` — revisão de código fullstack

#### Projeto
- Manifesto do plugin (`plugin.json`) com nome `fullstack-development` v0.1.0
- Documentação do projeto (`CLAUDE.md`) com estrutura, agentes e decisões de design
- Precedência de carregamento de skills: GLPI > Languages > Domains

[0.2.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.2.0
[0.1.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.1.0
