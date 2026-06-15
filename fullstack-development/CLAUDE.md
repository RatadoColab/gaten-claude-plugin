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
  domains/                     ← 18 skills de domínio (glpi tem 4 sub-skills; mobile tem 3)
  languages/                   ← 9 skills de linguagem
commands/                      ← 3 slash commands
```

## Versão e Release

- Versão do plugin em `.claude-plugin/plugin.json`; cada release bumpa a versão e adiciona uma entrada em `CHANGELOG.md` (formato Keep a Changelog) + link de release no rodapé.
- **Versionamento centralizado no `plugin.json`** — os `SKILL.md` **não** carregam campo `version:` no frontmatter (apenas `name` + `description`). Decisão tomada para simplificar releases e eliminar o drift de versões entre skills.
- Auditar tamanho dos corpos: `find skills -name SKILL.md -exec wc -w {} \;` (alvo ~1.500–2.000 palavras; ver política de progressive disclosure em Decisões de Design).
- Validar ponteiros após editar skills: todo `references/*` citado em SKILL.md deve existir (atenção: sub-skills GLPI usam a forma `../references/`).

## Agentes e Gatilhos

| Agente | Gatilhos típicos | Color |
|--------|-----------------|-------|
| `spec-dev` | "revise esta spec", "valide a especificação" | blue |
| `backend-dev` | "desenvolva o backend", "implemente a API", "crie o endpoint" | green |
| `frontend-dev` | "desenvolva o frontend", "crie o componente", "implemente o formulário" | cyan |
| `devops-cicd` | "crie o pipeline", "configure o CI/CD", "configure o Azure DevOps", "escreva o Dockerfile", "faça deploy no OpenShift", "provisione a infraestrutura" | yellow |
| `mobile-dev` | "desenvolva o app Android", "crie a tela em Compose", "implemente a ViewModel", "configure o Gradle", "revise o código Kotlin", "crie o app Flutter", "implemente o widget Flutter", "configure o estado no Flutter" | magenta |

## Organização das Skills

- **Base** (`skills/base/`): carregadas automaticamente por cada agente ao iniciar (inclui `devops-base` e `mobile-base`)
- **Domínio** (`skills/domains/`): `spec-review`, `api-rest`, `database`, `security`, `forms`, `glpi`, `ui-components`, `user-experience`, `ci-cd`, `containers`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`, `android-architecture`, `jetpack-compose`, `flutter`
  - `glpi` tem sub-skills aninhadas em `skills/domains/glpi/`: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue`
- **Linguagem** (`skills/languages/`): `python`, `php`, `javascript`, `vue`, `twig`, `html`, `kotlin`, `gradle`, `dart`

## Padrão de Carregamento de Skills pelos Agentes

Cada agente instrui explicitamente quais skills carregar via `${CLAUDE_PLUGIN_ROOT}`:

```
${CLAUDE_PLUGIN_ROOT}/skills/base/<agente>-base/SKILL.md        ← sempre
${CLAUDE_PLUGIN_ROOT}/skills/domains/<dominio>/SKILL.md          ← conforme contexto
${CLAUDE_PLUGIN_ROOT}/skills/languages/<linguagem>/SKILL.md      ← conforme stack
```

## Precedência de Carregamento de Skills

Quando múltiplas skills são candidatas, a ordem de prioridade é: **GLPI > Languages > Domains**. Skills de domínio GLPI têm precedência sobre skills de linguagem, que têm precedência sobre domínios genéricos.

> O conjunto mobile (`mobile-base`, `kotlin`, `gradle`, `dart`, `android-architecture`, `jetpack-compose`, `flutter`) está **fora deste conflito de precedência**: não há sub-skills GLPI mobile, portanto a regra GLPI > Languages > Domains não se aplica a projetos exclusivamente mobile.

As skills de plataforma do domínio devops (`openshift`, `azure-devops`) **complementam** as genéricas, não as substituem: ao detectar OpenShift, carregar `containers` + `openshift`; ao detectar Azure DevOps, carregar `ci-cd` + `azure-devops`. As específicas trazem só as diferenças da plataforma.

### Sobreposições intencionais das skills GLPI (não deduplicar)

- `glpi/ajax-handlers`: envelope `{success, code, message, errors}` sobrepõe deliberadamente o RFC 9457 de `api-rest` (handlers são endpoints internos).
- `glpi/form-templates`: asterisco `<span class="required">*</span>` prevalece sobre o markup `aria-hidden`+`sr-only` de `domains/forms`.
- Sub-skills GLPI disparam pela própria description, sem garantia da skill pai ou das genéricas em contexto — não remover conteúdo apostando que outra skill estará carregada; usar ponteiro explícito.

### Assimetrias intencionais do conjunto devops

- **GitHub Actions/GitLab CI ficam inline em `ci-cd`**, enquanto **Azure DevOps é skill separada** (`azure-devops`). Não é inconsistência: GitHub/GitLab cabem como exemplo curto do conceito; o Azure DevOps tem modelo próprio rico (environments, service connections, variable groups, deployment jobs) que não cabe inline. Mesma lógica de `openshift` sobre `containers`.
- **`security` (app) e `devsecops` (pipeline/infra) são distintas por audiência:** o `backend-dev` carrega `security` (OWASP Top 10, XSS, CSRF, JWT — segurança de aplicação web/API); o `devops-cicd` carrega `devsecops` (SAST/SCA/DAST no pipeline, IaC/image scanning, SBOM/cosign, OIDC, supply chain). Elas se referenciam mutuamente.

### Assimetrias intencionais do conjunto mobile

- **`android-architecture` e `jetpack-compose` são distintas por camada:** `android-architecture` cobre a camada de dados e domínio (ViewModel, Hilt, Room, Navigation, Repository); `jetpack-compose` cobre exclusivamente a camada de UI (composables, state, Modifier, listas lazy). Carregar ambas em tarefas de tela Android.
- **`flutter` cobre widgets + estado + navegação**, enquanto `dart` (linguagem) cobre null safety, async, Streams e idioms. Compose e Flutter são **mutuamente exclusivos por contexto** — nunca carregar ambos ao mesmo tempo.
- **Room fica inline em `android-architecture`** com reference próprio (`references/room.md`) — não há domínio `database` mobile separado para evitar fragmentação prematura.

### Gatilhos de split futuro (evitar fragmentação prematura)

Manter unido até o conteúdo amadurecer; extrair quando:
- **`kubernetes`** ← separar de `containers` quando a parte de orquestração (probes, HPA, StatefulSets, Helm/Kustomize, RBAC) passar de ~80 linhas isoladas.
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
