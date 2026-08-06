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
  domains/                     ← 21 skills de domínio (glpi-10 e glpi-11 têm 4 sub-skills cada; mobile tem 3)
  languages/                   ← 9 skills de linguagem
commands/                      ← 3 slash commands
```

## Versão e Release

- Versão do plugin em `.claude-plugin/plugin.json`; cada release bumpa a versão e adiciona uma entrada em `CHANGELOG.md` (formato Keep a Changelog) + link de release no rodapé.
- **Versionamento centralizado no `plugin.json`** — os `SKILL.md` **não** carregam campo `version:` no frontmatter (apenas `name` + `description`). Decisão tomada para simplificar releases e eliminar o drift de versões entre skills.
- Auditar tamanho dos corpos: `find skills -name SKILL.md -exec wc -w {} \;` (alvo ~1.500–2.000 palavras; ver política de progressive disclosure em Decisões de Design).
- Validar ponteiros após editar skills: todo `references/*` citado em SKILL.md deve existir (atenção: sub-skills GLPI usam a forma `../references/` para apontar para `domains/glpi-10/references/` ou `domains/glpi-11/references/`, conforme a árvore).

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
- **Domínio** (`skills/domains/`): `spec-review`, `api-rest`, `database`, `security`, `forms`, `glpi-10`, `glpi-11`, `ui-components`, `user-experience`, `ci-cd`, `containers`, `podman`, `kubernetes`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`, `android-architecture`, `jetpack-compose`, `flutter`
  - `glpi-10` e `glpi-11` têm sub-skills aninhadas em `skills/domains/glpi-10/` e `skills/domains/glpi-11/`, respectivamente: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue` em cada uma — árvores paralelas completas, carregadas de forma mutuamente exclusiva conforme a versão-alvo detectada
- **Linguagem** (`skills/languages/`): `python`, `php`, `javascript`, `vue`, `twig`, `html`, `kotlin`, `gradle`, `dart`

## Padrão de Carregamento de Skills pelos Agentes

Cada agente instrui explicitamente quais skills carregar via `${CLAUDE_PLUGIN_ROOT}`:

```
${CLAUDE_PLUGIN_ROOT}/skills/base/<agente>-base/SKILL.md        ← sempre
${CLAUDE_PLUGIN_ROOT}/skills/domains/<dominio>/SKILL.md          ← conforme contexto
${CLAUDE_PLUGIN_ROOT}/skills/languages/<linguagem>/SKILL.md      ← conforme stack
```

## Precedência de Carregamento de Skills

Quando múltiplas skills são candidatas, a ordem de prioridade é: **GLPI > Languages > Domains**. Skills de domínio GLPI têm precedência sobre skills de linguagem, que têm precedência sobre domínios genéricos. "GLPI" aqui significa a árvore da versão detectada (`glpi-10` ou `glpi-11`) — nunca as duas simultaneamente, exceto em tarefa explícita de migração 10→11, onde `glpi-11` é autoritativa e `glpi-10` serve apenas de referência do código de origem.

> O conjunto mobile (`mobile-base`, `kotlin`, `gradle`, `dart`, `android-architecture`, `jetpack-compose`, `flutter`) está **fora deste conflito de precedência**: não há sub-skills GLPI mobile, portanto a regra GLPI > Languages > Domains não se aplica a projetos exclusivamente mobile.

As skills de plataforma do domínio devops (`openshift`, `azure-devops`) **complementam** as genéricas, não as substituem: ao detectar OpenShift, carregar `kubernetes` + `openshift` (+ `containers` se houver build de imagem); ao detectar Azure DevOps, carregar `ci-cd` + `azure-devops`. As específicas trazem só as diferenças da plataforma.

### Sobreposições intencionais das skills GLPI (não deduplicar)

- `glpi-10/ajax-handlers` e `glpi-11/ajax-handlers`: envelope `{success, code, message, errors}` sobrepõe deliberadamente o RFC 9457 de `api-rest` (handlers/controllers são endpoints internos). Válido nas duas versões.
- `glpi-10/form-templates` e `glpi-11/form-templates`: asterisco `<span class="required">*</span>` prevalece sobre o markup `aria-hidden`+`sr-only` de `domains/forms`. Válido nas duas versões.
- Sub-skills GLPI disparam pela própria description, sem garantia da skill pai ou das genéricas em contexto — não remover conteúdo apostando que outra skill estará carregada; usar ponteiro explícito.

### Assimetrias intencionais do conjunto GLPI

- **`glpi-10` e `glpi-11` são árvores paralelas completas e deliberadamente duplicadas**, não uma skill compartilhada com variantes — decisão tomada para eliminar o risco de o agente aplicar padrão de uma versão em projeto da outra (ex.: `include inc/includes.php` num plugin GLPI 11, ou `$DB->doQuery()` sem query builder num plugin GLPI 10). O custo é que `form-templates` fica ~95% idêntico entre as duas — correções de conteúdo comum devem ser replicadas manualmente nas duas árvores; auditar paridade com `diff <(ls skills/domains/glpi-10) <(ls skills/domains/glpi-11)`.
- **Contrato de detecção de versão:** cada `description` de `glpi-10`/`glpi-11` (pai e sub-skills) lista indícios de projeto (`setup.php`, diretório `public/`, `#[Route]`, `$DB->doQuery`/`queryOrDie`, `csrf_compliant`) e menção explícita do usuário. Sem indício em nenhuma direção, o agente **pergunta** qual versão antes de gerar código — nenhuma das duas assume um default.
- **Migração 10→11** vive como reference dentro de `glpi-11` (`glpi-11/references/migration-10-to-11.md`), não como skill separada — migrar *para* o 11 já implica que `glpi-11` é o alvo correto a carregar.

### Assimetrias intencionais do conjunto devops

- **GitHub Actions/GitLab CI ficam inline em `ci-cd`**, enquanto **Azure DevOps é skill separada** (`azure-devops`). Não é inconsistência: GitHub/GitLab cabem como exemplo curto do conceito; o Azure DevOps tem modelo próprio rico (environments, service connections, variable groups, deployment jobs) que não cabe inline. Mesma lógica de `openshift` sobre `kubernetes`.
- **`security` (app) e `devsecops` (pipeline/infra) são distintas por audiência:** o `backend-dev` carrega `security` (OWASP Top 10, XSS, CSRF, JWT — segurança de aplicação web/API); o `devops-cicd` carrega `devsecops` (SAST/SCA/DAST no pipeline, IaC/image scanning, SBOM/cosign, OIDC, supply chain). Elas se referenciam mutuamente.
- **Eixo imagem → runtime → orquestração → plataforma:** `containers` cobre só a imagem OCI (Containerfile/Dockerfile, runtime-agnóstica); `podman` cobre execução em host único via Quadlet/systemd; `kubernetes` cobre orquestração em cluster (workloads, probes, Gateway API, Helm/Kustomize); `openshift` complementa `kubernetes` com as particularidades da plataforma (SCC, Route, S2I). Cada camada soma a anterior — `containers` soma a `podman` ou `kubernetes` quando a tarefa também envolve execução/deploy; quando a demanda for exclusivamente a imagem (Containerfile/Dockerfile), carregar apenas `containers`.
- **`podman` e `kubernetes` são mutuamente exclusivos por contexto** (mesma lógica de Compose × Flutter no conjunto mobile): um host único gerenciado por systemd **ou** um cluster orquestrado — nunca carregar as duas ao mesmo tempo.

### Assimetrias intencionais do conjunto mobile

- **`android-architecture` e `jetpack-compose` são distintas por camada:** `android-architecture` cobre a camada de dados e domínio (ViewModel, Hilt, Room, Navigation, Repository); `jetpack-compose` cobre exclusivamente a camada de UI (composables, state, Modifier, listas lazy). Carregar ambas em tarefas de tela Android.
- **`flutter` cobre widgets + estado + navegação**, enquanto `dart` (linguagem) cobre null safety, async, Streams e idioms. Compose e Flutter são **mutuamente exclusivos por contexto** — nunca carregar ambos ao mesmo tempo.
- **Room fica inline em `android-architecture`** com reference próprio (`references/room.md`) — não há domínio `database` mobile separado para evitar fragmentação prematura.

### Gatilhos de split futuro (evitar fragmentação prematura)

Manter unido até o conteúdo amadurecer; extrair quando:
- **`gateway-api`** ← separar de `kubernetes` se a seção de rede/exposição crescer além do essencial (roteamento avançado, TLS multi-domínio, service mesh).
- **`helm`** ← separar de `kubernetes` se o empacotamento via Helm ganhar profundidade equivalente à de `azure-devops` (templating avançado, hooks, subcharts, testes de chart).
- **`gitops`** ← separar de `iac` se ArgoCD/Flux crescer (App-of-apps, ApplicationSets, progressive sync, multi-cluster).
- **`github-actions`** ← extrair de `ci-cd` se ganhar profundidade equivalente à de `azure-devops` (reusable workflows, OIDC, matrix, environments).
- **`room`** ← separar de `android-architecture` se migrações, FTS, relações e TypeConverters crescerem para além das ~80 linhas atuais de referência.
- **`flutter-state`** ← separar de `flutter` se a seção de gerenciamento de estado (Provider/Riverpod/BLoC) crescer e precisar de skill própria como `azure-devops`.

## Decisões de Design

- Skills organizadas em subdirs (`base/`, `domains/`, `languages/`) para separação clara por responsabilidade
- Commands em `commands/` (formato legado, mas intencional para slash commands diretos)
- Skills com conteúdo mínimo — intencionalmente para expansão posterior
- JavaScript cobre backend (Node.js) e frontend no mesmo arquivo de skill

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
- `agents/frontend-dev.md` não referencia nenhuma sub-skill GLPI hoje — `glpi-10/form-templates`, `glpi-10/vue`, `glpi-11/form-templates` e `glpi-11/vue` não estão ligadas a agente algum (gap pré-existente à divisão glpi-10/glpi-11, fora do escopo da mudança que criou as duas árvores)
