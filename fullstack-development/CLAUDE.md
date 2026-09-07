# fullstack-development Plugin — Contexto Local

Plugin Claude Code modular para desenvolvimento fullstack. O plugin contém uma forte política de progressive disclosure, com foco em economia de tokens para evitar o carregamento de SKILLs que não fazem parte do contexto do projeto.

## Instalação e Teste

```bash
# Instalar localmente para testar (executar a partir da raiz do plugin — diretório que contém .claude-plugin/)
cc --plugin-dir .

# Verificar agentes carregados
/agents

# Testar gatilho de agente (ex.: devops-cicd)
# "Crie o pipeline de CI/CD para esta aplicação"

# Testar commands disponíveis
/fullstack-development:review-spec
/fullstack-development:new-feature
/fullstack-development:code-review
```

## Estrutura do Plugin

```
.claude-plugin/plugin.json     ← manifesto (nome: fullstack-development)
agents/                        ← 5 agentes: spec-dev, backend-dev, frontend-dev, devops-cicd, mobile-dev
skills/
  base/                        ← 1 skill base por agente (inclui mobile-base)
  domains/                     ← 23 skills de domínio (glpi-10, glpi-11 e glpi-12 têm 4 sub-skills cada; mobile tem 3)
  languages/                   ← 11 skills de linguagem
commands/                      ← 4 slash commands
```

## Versão e Release

- Versão do plugin em `.claude-plugin/plugin.json`; cada release bumpa a versão e adiciona uma entrada em `CHANGELOG.md` (formato Keep a Changelog) + link de release no rodapé.
- **Versionamento centralizado no `plugin.json`** — os `SKILL.md` **não** carregam campo `version:` no frontmatter (apenas `name` + `description`). Decisão tomada para simplificar releases e eliminar o drift de versões entre skills.
- Auditar tamanho dos corpos: `find skills -name SKILL.md -exec wc -w {} \;` (alvo ~1.500–2.000 palavras; ver política de progressive disclosure em Decisões de Design).
- Validar ponteiros após editar skills: todo `references/*` citado em SKILL.md deve existir (atenção: sub-skills GLPI usam a forma `../references/` para apontar para `domains/glpi-10/references/`, `domains/glpi-11/references/` ou `domains/glpi-12/references/`, conforme a árvore).

## Agentes e Gatilhos

| Agente | Gatilhos típicos | Color |
|--------|-----------------|-------|
| `spec-dev` | "revise esta spec", "valide a especificação" | blue |
| `backend-dev` | "desenvolva o backend", "implemente a API", "crie o endpoint" | green |
| `frontend-dev` | "desenvolva o frontend", "crie o componente", "implemente o formulário" | cyan |
| `devops-cicd` | "crie o pipeline", "configure o CI/CD", "configure o Azure DevOps", "escreva o Dockerfile/Containerfile", "crie a unidade Quadlet (Podman)", "crie o manifest Kubernetes", "faça deploy no OpenShift", "provisione a infraestrutura" | yellow |
| `mobile-dev` | "desenvolva o app Android", "crie a tela em Compose", "implemente a ViewModel", "configure o Gradle", "revise o código Kotlin", "crie o app Flutter", "implemente o widget Flutter", "configure o estado no Flutter" | magenta |

## Organização das Skills

- **Base** (`skills/base/`): carregadas automaticamente por cada agente ao iniciar (inclui `devops-base` e `mobile-base`)
- **Domínio** (`skills/domains/`): `spec-review`, `api-rest`, `database`, `security`, `debugging`, `forms`, `glpi-10`, `glpi-11`, `glpi-12`, `ui-components`, `user-experience`, `ci-cd`, `containers`, `podman`, `kubernetes`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`, `android-architecture`, `jetpack-compose`, `flutter`
  - `glpi-10`, `glpi-11` e `glpi-12` têm sub-skills aninhadas em `skills/domains/glpi-10/`, `skills/domains/glpi-11/` e `skills/domains/glpi-12/`, respectivamente: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue` em cada uma — três árvores paralelas completas, carregadas de forma mutuamente exclusiva conforme a versão-alvo detectada
- **Linguagem** (`skills/languages/`): `python`, `php`, `javascript`, `nodejs`, `golang`, `vue`, `twig`, `html`, `kotlin`, `gradle`, `dart`

## Padrão de Carregamento de Skills pelos Agentes

Cada agente instrui explicitamente quais skills carregar via `${CLAUDE_PLUGIN_ROOT}`:

```
${CLAUDE_PLUGIN_ROOT}/skills/base/<agente>-base/SKILL.md        ← sempre
${CLAUDE_PLUGIN_ROOT}/skills/domains/<dominio>/SKILL.md          ← conforme contexto
${CLAUDE_PLUGIN_ROOT}/skills/languages/<linguagem>/SKILL.md      ← conforme stack
```

## Precedência de Carregamento de Skills

Quando múltiplas skills são candidatas, a ordem de prioridade é: **GLPI > Languages > Domains**. Skills de domínio GLPI têm precedência sobre skills de linguagem, que têm precedência sobre domínios genéricos. "GLPI" aqui significa a árvore da versão detectada (`glpi-10`, `glpi-11` ou `glpi-12`) — nunca mais de uma simultaneamente, exceto em tarefa explícita de migração (10→11 ou 11→12), onde a árvore de destino é autoritativa e a de origem serve apenas de referência do código-fonte. O salto 10→12 direto não é suportado — a migração passa obrigatoriamente pelo 11.

> O conjunto mobile (`mobile-base`, `kotlin`, `gradle`, `dart`, `android-architecture`, `jetpack-compose`, `flutter`) está **fora deste conflito de precedência**: não há sub-skills GLPI mobile, portanto a regra GLPI > Languages > Domains não se aplica a projetos exclusivamente mobile.

As skills de plataforma do domínio devops (`openshift`, `azure-devops`) **complementam** as genéricas, não as substituem: ao detectar OpenShift, carregar `kubernetes` + `openshift` (+ `containers` se houver build de imagem); ao detectar Azure DevOps, carregar `ci-cd` + `azure-devops`. As específicas trazem só as diferenças da plataforma.

### Sobreposições intencionais das skills GLPI (não deduplicar)

- `glpi-10/ajax-handlers`, `glpi-11/ajax-handlers` e `glpi-12/ajax-handlers`: envelope `{success, code, message, errors}` sobrepõe deliberadamente o RFC 9457 de `api-rest` (handlers/controllers são endpoints internos). Válido nas três versões.
- `glpi-10/form-templates`, `glpi-11/form-templates` e `glpi-12/form-templates`: asterisco `<span class="required">*</span>` prevalece sobre o markup `aria-hidden`+`sr-only` de `domains/forms`. Válido nas três versões.
- Sub-skills GLPI disparam pela própria description, sem garantia da skill pai ou das genéricas em contexto — não remover conteúdo apostando que outra skill estará carregada; usar ponteiro explícito.

### Assimetrias intencionais do conjunto GLPI

- **`glpi-10`, `glpi-11` e `glpi-12` são árvores paralelas completas e deliberadamente duplicadas**, não uma skill compartilhada com variantes — decisão tomada para eliminar o risco de o agente aplicar padrão de uma versão em projeto de outra (ex.: `include inc/includes.php` num plugin GLPI 11+, `$DB->doQuery()` sem query builder num plugin GLPI 10, ou `csrf_token()` num plugin GLPI 12). O custo é a paridade tripla: `form-templates` fica ~95% idêntico entre as três e `glpi-12` deriva de `glpi-11` por deltas (`glpi-12/SKILL.md` só cobre as diferenças 11→12). Correções de conteúdo comum devem ser replicadas manualmente nas três árvores; auditar paridade estrutural com `diff <(cd skills/domains/glpi-11 && find . -type f|sort) <(cd skills/domains/glpi-12 && find . -type f|sort)` (deve acusar só o nome do arquivo de migração).
- **Contrato de detecção de versão:** cada `description` de `glpi-10`/`glpi-11`/`glpi-12` (pai e sub-skills) lista indícios de projeto (`setup.php`, `requirements.glpi.min`, `public/`, `#[Route]`, `$DB->doQuery`/`queryOrDie`, `csrf_compliant`, presença/ausência de `csrf_token()`/`_glpi_csrf_token`, `Glpi\Toolbox\HttpClient`) e menção explícita do usuário. Sem indício em nenhuma direção, o agente **pergunta** qual versão antes de gerar código — nenhuma das três assume um default.
- **Migrações vivem como reference dentro da árvore de destino:** `glpi-11/references/migration-10-to-11.md` e `glpi-12/references/migration-11-to-12.md`, não como skills separadas — migrar *para* uma versão já implica que aquela árvore é a autoritativa a carregar. Não há migração 10→12.
- **`glpi-12` deriva de um RC:** o conteúdo foi extraído do código-fonte do GLPI 12.0.0 RC. Revalidar contra o GA (previsto para 2026-10-06) — ver `PENDENCIAS.md` na raiz do repositório.
- **`name` das sub-skills GLPI é prefixado com a versão** (`glpi-12-vue` no diretório `vue`, etc.), quebrando de propósito a convenção "name = diretório": as três árvores têm sub-skills homônimas e precisam de `name` único, e os agentes carregam essas skills por caminho explícito (`${CLAUDE_PLUGIN_ROOT}/...`), não por auto-discovery. Não reabrir esse ponto em auditorias.
- **Vue por core GLPI** (apurado no código-fonte em 2026-09-07): GLPI 11.0.8 empacota Vue **3.5.35** e GLPI 12.0.0-rc1 **3.5.42**, ambos expostos com namespace completo em `window._vue` — todas as APIs de reatividade/componentes/composição do Vue 3.5 se aplicam, mas **Pinia e Vue Router não vêm do core**. O GLPI 10 **não traz Vue no core**: o plugin embarca o próprio `vue.global.prod.js`, com piso **≥ 3.5.0** recomendado; o global build não tem compilação SFC, logo `<script setup>` e as macros `define*` não valem lá. Reconferir os números do GLPI 12 contra o GA.

### Assimetrias intencionais do conjunto devops

- **GitHub Actions/GitLab CI ficam inline em `ci-cd`**, enquanto **Azure DevOps é skill separada** (`azure-devops`). Não é inconsistência: GitHub/GitLab cabem como exemplo curto do conceito; o Azure DevOps tem modelo próprio rico (environments, service connections, variable groups, deployment jobs) que não cabe inline. Mesma lógica de `openshift` sobre `kubernetes`.
- **`security` (app) e `devsecops` (pipeline/infra) são distintas por audiência:** o `backend-dev` carrega `security` (OWASP Top 10:2025, XSS, CSRF, JWT, supply chain da aplicação, segurança de LLM — segurança de aplicação web/API); o `devops-cicd` carrega `devsecops` (SAST/SCA/DAST no pipeline, IaC/image scanning, SBOM/cosign, OIDC, supply chain do pipeline). Elas se referenciam mutuamente. A cadeia de suprimentos aparece nas duas por ângulos distintos — `security` cobre as dependências da aplicação (A03:2025), `devsecops` cobre a proteção do caminho de entrega.
- **Eixo imagem → runtime → orquestração → plataforma:** `containers` cobre só a imagem OCI (Containerfile/Dockerfile, runtime-agnóstica); `podman` cobre execução em host único via Quadlet/systemd; `kubernetes` cobre orquestração em cluster (workloads, probes, Gateway API, Helm/Kustomize); `openshift` complementa `kubernetes` com as particularidades da plataforma (SCC, Route, S2I). Cada camada soma a anterior — `containers` soma a `podman` ou `kubernetes` quando a tarefa também envolve execução/deploy; quando a demanda for exclusivamente a imagem (Containerfile/Dockerfile), carregar apenas `containers`.
- **`podman` e `kubernetes` são mutuamente exclusivos por contexto** (mesma lógica de Compose × Flutter no conjunto mobile): um host único gerenciado por systemd **ou** um cluster orquestrado — nunca carregar as duas ao mesmo tempo.

### Assimetrias intencionais do conjunto mobile

- **`android-architecture` e `jetpack-compose` são distintas por camada:** `android-architecture` cobre a camada de dados e domínio (ViewModel, Hilt, Room, Navigation, Repository); `jetpack-compose` cobre exclusivamente a camada de UI (composables, state, Modifier, listas lazy). Carregar ambas em tarefas de tela Android.
- **`flutter` cobre widgets + estado + navegação**, enquanto `dart` (linguagem) cobre null safety, async, Streams e idioms. Compose e Flutter são **mutuamente exclusivos por contexto** — nunca carregar ambos ao mesmo tempo.
- **Room fica inline em `android-architecture`** com reference próprio (`references/room.md`) — não há domínio `database` mobile separado para evitar fragmentação prematura.

### Assimetrias intencionais do conjunto JavaScript/Node

- **`javascript` cobre a sintaxe da linguagem** (ES6+, async/await, classes, DOM) para backend e frontend no mesmo arquivo; **`nodejs` cobre exclusivamente o runtime** (ESM/resolução de módulos, APIs `node:`, type stripping de TypeScript, test runner nativo, permission model, npm/supply chain, deploy). Divisão análoga a `containers`/`podman`/`kubernetes` no conjunto devops: cada skill soma a camada anterior, não a substitui.
- **Carregar as duas juntas em projeto Node** — `nodejs` pressupõe a sintaxe de `javascript` já carregada e não a repete; código Node gerado só com `javascript` carregada fica sem orientação de runtime (ESM, graceful shutdown, `node:test`).
- **Vue/frontend continuam carregando só `javascript`** — `nodejs` não se aplica a código que roda no browser.

### Assimetrias intencionais de `domains/debugging`

- **`debugging` cobre o método de diagnóstico** (reprodução determinística, hipótese/refutação, bissecção, leitura de evidência, classes recorrentes de defeito, correção mínima × estrutural, teste de regressão), transversal a todas as linguagens e stacks. É a skill sempre carregada pelo command `new-bugfix` (Fase 1), análoga ao papel de `spec-base` no `review-spec`.
- **Fronteira com `domains/observability`:** `observability` é a fonte autoritativa de **como produzir** os sinais (logs estruturados, traces, métricas); `debugging` apenas **os consome** para localizar a causa. Não duplicar instrumentação em `debugging`.
- **Fronteira com `languages/*/references/testing.md`:** `debugging` cobre *o que* testar e em que nível da pirâmide; a sintaxe e o runner de cada linguagem continuam nos `references/testing.md` de `python`/`php`/`golang`/`nodejs`, apontados por `debugging/references/regression-tests.md` via `../../../languages/`. Não há `domains/testing` — seria fragmentação prematura (ver gatilho de split abaixo).
- **Fronteira com `domains/security`:** vulnerabilidade é uma classe de defeito, mas seu diagnóstico e mitigação seguem `security` (OWASP Top 10:2025); `debugging` só a cita como classe.
- **Precedência:** entra como domínio genérico — `GLPI > Languages > Domains` aplica-se, `debugging` fica no último nível.

### Gatilhos de split futuro (evitar fragmentação prematura)

Manter unido até o conteúdo amadurecer; extrair quando:
- **`gateway-api`** ← separar de `kubernetes` se a seção de rede/exposição crescer além do essencial (roteamento avançado, TLS multi-domínio, service mesh).
- **`helm`** ← separar de `kubernetes` se o empacotamento via Helm ganhar profundidade equivalente à de `azure-devops` (templating avançado, hooks, subcharts, testes de chart).
- **`gitops`** ← separar de `iac` se ArgoCD/Flux crescer (App-of-apps, ApplicationSets, progressive sync, multi-cluster).
- **`github-actions`** ← extrair de `ci-cd` se ganhar profundidade equivalente à de `azure-devops` (reusable workflows, OIDC, matrix, environments).
- **`room`** ← separar de `android-architecture` se migrações, FTS, relações e TypeConverters crescerem para além das ~80 linhas atuais de referência.
- **`flutter-state`** ← separar de `flutter` se a seção de gerenciamento de estado (Provider/Riverpod/BLoC) crescer e precisar de skill própria como `azure-devops`.
- **`typescript`** ← separar de `nodejs` se a seção de type stripping/`tsconfig.json` crescer além do essencial (hoje cabe em §TypeScript Nativo + `references/typescript-runtime.md`); relevante também se TypeScript passar a ser usado fora do runtime Node (ex.: build para frontend).
- **`ai-security`** ← extrair de `domains/security` se `references/llm-security.md` (OWASP Top 10 for LLM Applications) crescer além do essencial — RAG, agentes/tool calling, guardrails, avaliação adversarial. Hoje cabe como reference único apontado pela §Segurança de Aplicações com LLM.
- **`php-migration`** ← extrair de `languages/php` se `references/migration-83-to-84.md` e `references/migration-84-to-85.md` crescerem a ponto de justificar skill própria (com gatilhos de detecção e checklist executável, à moda de `glpi-11/references/migration-10-to-11.md`). Hoje cabem como dois references sob demanda, apontados pela §Recursos por Versão do `SKILL.md`.
- **`python-concurrency`** ← extrair de `languages/python` se as seções de free-threading (PEP 779) e subinterpretadores (PEP 734) de `references/concurrency.md` crescerem além do essencial — thread-safety de estruturas compartilhadas, canais entre interpretadores, benchmarking do build `python3.14t`, estado de cobertura de wheels. Hoje cabem como duas seções no fim de `concurrency.md`, ao lado do conteúdo de asyncio.
- **`testing`** ← separar de `domains/debugging` se a estratégia de testes (pirâmide, cobertura, test doubles, dados de teste, testes de contrato) crescer além do recorte "teste de regressão de bug" hoje em `debugging/references/regression-tests.md`. Gatilho natural: a criação de um command `/write-tests` com profundidade própria. Hoje o método transversal de testes vive só como Fase 6 de `debugging` + os `references/testing.md` por linguagem.

## Baselines das skills (situação de set/2026)

Versão-alvo de cada skill que acompanha um ecossistema externo. Atualizadas na 0.7.0.

| Skill | Baseline | Detecção de versão-alvo |
|---|---|---|
| `languages/python` | **3.14** (era 3.11) | §"Runtime e Versões"; `from __future__ import annotations` agora é anti-pattern (PEP 649); genéricos na sintaxe PEP 695. References `patterns.md` (ex-`modern-features.md`) e `concurrency.md` (ex-`async-patterns.md`) |
| `languages/php` | **8.3–8.5** (era 8.3 fixo) | §"Detecção de Versão-Alvo" (`composer.json` → ambiente → sintaxe → pergunta, sem default); recursos por versão em `references/php8{4,5}-features.md` + guias de migração |
| `languages/vue` | **3.5.x** (era ~3.3) | linha "Versões de referência" no `SKILL.md`; Vue 3.6 / Vapor Mode só como nota de horizonte (RC, não usar em produção) — ver `PENDENCIAS.md` |
| `domains/security` (+ `devsecops`, `api-rest`) | **OWASP Top 10:2025** | SSRF absorvido em A01, supply chain promovida a A03, A10 nova; senhas no NIST SP 800-63B-4; rate limit em `RateLimit`/`RateLimit-Policy` |
| `languages/nodejs` / `languages/golang` | Node **26.x** / Go **1.27.x** | inalteradas desde a 0.6.0 |

## Decisões de Design

- Skills organizadas em subdirs (`base/`, `domains/`, `languages/`) para separação clara por responsabilidade
- Commands em `commands/` (formato legado, mas intencional para slash commands diretos)
- Skills com conteúdo mínimo — intencionalmente para expansão posterior
- `javascript` cobre a sintaxe da linguagem (backend e frontend); `nodejs` cobre exclusivamente o runtime — ver assimetria dedicada abaixo

### Política de progressive disclosure nos SKILL.md

Para conter o consumo de tokens (o corpo do SKILL.md é sempre carregado quando a skill dispara):

- **Alvo de corpo:** ~1.500–2.000 palavras. Catálogos extensos, enumerações e exemplos longos vão para `references/` por tópico, deixando no corpo um resumo + ponteiro `> ... em [\`references/x.md\`](references/x.md)`.
- **Código inline:** no máximo **1 bloco curto (<8 linhas) por seção**; exemplos maiores ou repetidos vão para `references/`.
- **Sem duplicação:** uma informação vive em um único lugar — não repetir no corpo o que já está num reference (nem entre skills). Tópicos transversais têm fonte autoritativa única (ex.: segurança de aplicação → `domains/security`; acessibilidade WCAG 2.2 → `domains/ui-components`; performance Vue → `languages/vue`; UX de formulários → `domains/forms`); as demais skills apenas apontam.

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>

## Próximos Passos Sugeridos

- Considerar hooks para validação automática de specs antes de commits
- `agents/frontend-dev.md` não referencia nenhuma sub-skill GLPI hoje — `form-templates` e `vue` das três árvores (`glpi-10`, `glpi-11`, `glpi-12`) não estão ligadas a agente algum (gap pré-existente, fora do escopo das mudanças que criaram as árvores)
