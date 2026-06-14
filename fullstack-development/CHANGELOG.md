# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.3.0] - 2026-06-14

Expansão do plugin para desenvolvimento mobile: novo agente `mobile-dev` com suporte a Android nativo (Kotlin + Jetpack Compose) e Flutter (Dart), acompanhado de skill base, 3 domínios e 3 linguagens com política de progressive disclosure.

### Adicionado

#### Agente
- `mobile-dev` — desenvolvimento mobile Android nativo (Kotlin/Compose) e Flutter (Dart) (color magenta); carregamento mínimo de skills por stack detectada; Compose e Flutter mutuamente exclusivos

#### Skill base
- `base/mobile-base` — fundamentos mobile independentes de stack: Clean Architecture (camadas data/domain/ui), MVVM/MVI, estados obrigatórios (loading/erro/vazio/sucesso), ciclo de vida Android e Flutter, KDoc/DartDoc

#### Skills de domínio mobile
- `domains/android-architecture` — ViewModel + StateFlow, Lifecycle (`repeatOnLifecycle`), Navigation Component, Hilt (DI), Repository pattern, Room (`@Upsert`, Flow, `exportSchema`); refs: `jetpack.md`, `room.md`, `di-hilt.md`
- `domains/jetpack-compose` — composables, state hoisting, `remember`/`derivedStateOf`, Modifier, `LazyColumn`/`LazyRow`, navegação Compose, Material3, performance; refs: `state.md`, `performance.md`
- `domains/flutter` — widget tree, StatelessWidget/StatefulWidget, state management (Provider/Riverpod/BLoC — resumo + referência), GoRouter, layout widgets, FutureBuilder/StreamBuilder; refs: `state-management.md`, `widgets.md`

#### Skills de linguagem mobile
- `languages/kotlin` — null safety, data/sealed classes, extension functions, scope functions, coroutines (visão geral), coleções, anti-patterns; refs: `coroutines-flow.md`, `idioms.md`
- `languages/gradle` — Kotlin DSL vs Groovy, `build.gradle.kts`, version catalog (`libs.versions.toml`), build types, product flavors, signing config, multi-módulo; refs: `build-config.md`, `dependencies.md`
- `languages/dart` — null safety, sound type system, async/await, Futures, Streams, classes/mixins/extensions, coleções, anti-patterns; refs: `async.md`, `language-tour.md`

#### Projeto
- `plugin.json` — versão `0.3.0`; description atualizada para incluir mobile
- `CLAUDE.md` — tabela de agentes atualizada (mobile-dev + magenta); organização de skills atualizada (3 novos domínios, 3 novas linguagens, mobile-base); assimetrias intencionais do conjunto mobile; gatilhos de split futuro (`room`, `flutter-state`)

## [0.2.1] - 2026-06-11

Rodada de otimização de consumo de tokens: redução do vetor de dados externos, carregamento mínimo de skills e aplicação de progressive disclosure nos `SKILL.md` (corpos enxutos + conteúdo detalhado movido para `references/` por tópico, sem perda de informação).

Segunda rodada de otimização de tokens: aplicação integral da regra de código inline (máx. 1 bloco curto por seção), eliminação de duplicações entre skills carregadas juntas e consolidação de fontes autoritativas únicas — preservando a precedência GLPI > Languages > Domains. Economia estimada de ~3.000+ palavras nos corpos carregados em runtime, sem perda de informação (conteúdo movido para `references/`).

### Alterado

#### Agentes
- `devops-cicd` — removida a ferramenta `WebSearch` (elimina o vetor de dados externos do agente); reforço de que as skills de domínio são mutuamente exclusivas por tarefa
- `spec-dev` — `WebSearch` mantido, mas com guardrail: usar apenas quando o usuário pedir explicitamente verificação de versão/documentação online, sem buscas especulativas
- `spec-dev`, `backend-dev`, `frontend-dev`, `devops-cicd` — adicionada diretriz de **carregamento mínimo** (carregar só a base + a skill da stack detectada; `references/` sob demanda)

#### Skills — progressive disclosure (corpos reduzidos)
- `domains/security` (2.683→~950 palavras) — OWASP Top 10 detalhado movido para `references/owasp-top10.md`; defesas web (XSS, CSRF, upload, CORS, secrets, supply chain) para `references/web-defenses.md`
- `domains/user-experience` (2.447→~1.355) — seções 6–12 movidas para `references/mobile-responsive.md`, `motion-darkmode-a11y.md`, `ux-writing-flows.md`; seção de formulários colapsada para ponteiro a `forms`
- `domains/api-rest` (2.385→~1.555) — `references/status-codes.md`, `error-handling.md` (RFC 9457), `advanced-endpoints.md` e `pagination.md`; tabelas de headers movidas para `http-patterns.md`
- `domains/database` (1.943→~1.640) — `references/migrations.md` e `sql-vs-nosql.md`; blocos SQL/Python inline duplicados removidos
- `domains/forms` (1.698→~1.350) — `references/brazilian-inputs.md`, `multi-step-and-upload.md` e `autocomplete.md`; seção de segurança colapsada para ponteiro a `security`
- `domains/glpi/vue` (1.726→~1.630) — modais e ciclo de vida movidos para `references/runtime-patterns.md`; bloco AJAX reduzido com ponteiro a `integration-patterns.md`
- `languages/twig` (1.663→~1.320) — catálogo de filters/functions reduzido a resumo (duplicava `references/filters-functions.md`); regra `|raw`/HTMLPurifier deduplicada
- `languages/html` (1.653→~1.520) — grid/breakpoints reduzidos a resumo (duplicava `references/bootstrap5-layout.md`)

#### Skills GLPI (precedência preservada)
- `glpi/ajax-handlers` — blocos de inicialização, validação, CRUD/`op`, respostas JSON, delegação e try-catch movidos para `references/patterns.md` (novas seções: Validação de Parâmetros, Operações Múltiplas via `op`, Estruturas de Resposta JSON); mantidos no corpo: sessão expirada em AJAX, nota RFC 9457 (sobrepõe `api-rest` deliberadamente), tabela de códigos HTTP e checklist de segurança
- `glpi/form-templates` — estrutura base e catálogo de macros movidos para `references/layouts.md`; §9 (Regras de UX) agora aponta para `domains/forms` mantendo inline apenas os específicos GLPI (asterisco `<span class="required">`, botão à direita, verbos de ação)
- `glpi` — árvore de estrutura condensada (completa em `plugin-creation`); tabela de Nomenclatura unificada (removida da sub-skill); repetições das Restrições Absolutas removidas das seções do próprio arquivo; bloco CommonDBTM reduzido
- `glpi/vue` — §8 (Compatibilidade) removida por repetir a introdução; bridge de dropdowns reduzido a 1 bloco + ponteiro para `references/integration-patterns.md`

#### Skills de linguagem (sintaxe básica condensada em tabelas)
- `languages/javascript` — exemplos de var/arrow/destructuring/template literals/classes/async reduzidos; classes ES6 movidas para `references/es6-features.md`; `references/modules.md` agora referenciado
- `languages/vue` — exemplos completos delegados a `references/` (composition-api, state-management, performance); tabelas mantidas
- `languages/python` — Boas Práticas Essenciais viraram tabela; estrutura de projeto e tratamento de erros condensados
- `languages/php` — blocos de PSR/tipos/8.3/erros encurtados; Boas Práticas viraram tabela
- `languages/twig` — tags de controle reduzidas a `for/else` + notas (`verbatim`, `apply`, `cycle`)
- `languages/html` — checklist WCAG restrito a markup puro (contraste/foco/teclado → `ui-components`); tabela de Input Types condensada (completa em `references/forms.md`); padronizado WCAG 2.2 (era 2.1)

#### Skills DevOps (criados os primeiros `references/` do conjunto)
- `domains/ci-cd` — YAMLs GitHub Actions/GitLab CI movidos para `references/pipeline-examples.md`; Segurança do Pipeline reduzida a ponteiro para `devsecops`
- `domains/containers` — Dockerfile multi-stage e Deployment movidos para `references/examples.md`
- `domains/azure-devops` — pipeline de ~43 linhas movido para `references/azure-pipelines-openshift.md`
- `domains/openshift` — Route YAML movido para `references/examples.md`
- `domains/iac` — bloco Terraform movido para `references/terraform-examples.md`
- `base/devops-base` — dupla listagem de skills removida das Referências; seção DevSecOps reduzida a ponteiro

#### Deduplicação entre pares carregados juntos
- `base/backend-base` — tabela "Adaptação por Framework" substituída por frase de roteamento (a tabela vive em `domains/glpi`, que prevalece)
- `base/spec-base` ↔ `domains/spec-review` — SCOPE em spec-base reduzido a definições conceituais; checklist operacional só em spec-review
- `base/frontend-base` — seções Segurança e Performance viraram ponteiros (`domains/security`, `ui-components`/`languages/vue`)
- `domains/ui-components` — §8 Performance aponta para `languages/vue`, mantendo só itens específicos de componente; `references/component-api.ts` e `composables.ts` agora referenciados
- `domains/api-rest` — JWT alinhado com `security` (15 min); `Idempotency-Key` consolidado; Caching fundido em 1 bloco; Rate Limiting restrito ao contrato HTTP + ponteiro
- `domains/user-experience` e `domains/database` — ajustes menores de duplicação e ponteiros

#### Agentes e Commands
- `backend-dev` — restrições GLPI substituídas por ponteiro às Restrições Absolutas de `domains/glpi`; alinhado `Session::checkRight()` como padrão em entry points
- `devops-cicd` — restrição security/devsecops encurtada
- `/fullstack-development:new-feature` — reafirmações da condicional DevOps removidas das Fases 4–5

#### Skills — descriptions e versões
- `domains/security`, `api-rest`, `database`, `forms` — adicionadas *trigger phrases* literais à `description` para melhorar a ativação
- `domains/glpi/vue` — `version` da skill alinhada para `0.2.0`

#### Projeto
- `plugin.json` — versão `0.2.1`; `version:` de todos os 29 `SKILL.md` alinhados a `0.2.1`
- `CLAUDE.md` — nova subseção "Política de progressive disclosure nos SKILL.md" (alvo de corpo ~1.500–2.000 palavras, máx. 1 bloco de código curto por seção, fonte autoritativa única por tópico transversal)
- Descriptions com trigger phrases adicionadas: `ui-components`, `spec-base`, `ci-cd`, `containers`, `iac`, `observability`

### Removido
- `domains/forms/references/rhf-zod-example.tsx` (React Hook Form — fora da stack do plugin)
- `domains/ui-components/references/storybook-example.ts` e `testing-examples.ts` (incoerentes com a nota "testes via PHPUnit, sem runner JS")

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

[0.3.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.3.0
[0.2.1]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.2.1
[0.2.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.2.0
[0.1.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.1.0
