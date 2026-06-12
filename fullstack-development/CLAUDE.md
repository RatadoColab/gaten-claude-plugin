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
agents/                        ← 4 agentes: spec-dev, backend-dev, frontend-dev, devops-cicd
skills/
  base/                        ← 1 skill base por agente
  domains/                     ← 15 skills de domínio (glpi tem 4 sub-skills)
  languages/                   ← 6 skills de linguagem
commands/                      ← 3 slash commands
```

## Versão e Release

- Versão do plugin em `.claude-plugin/plugin.json`; cada release bumpa a versão e adiciona uma entrada em `CHANGELOG.md` (formato Keep a Changelog) + link de release no rodapé.
- Manter o `version:` no frontmatter de cada `SKILL.md` alinhado ao publicar — gotcha: skills ficam defasadas (ex.: `glpi/vue` ficou em `0.1.0` enquanto as demais em `0.2.0`).
- Auditar tamanho dos corpos: `find skills -name SKILL.md -exec wc -w {} \;` (alvo ~1.500–2.000 palavras; ver política de progressive disclosure em Decisões de Design).

## Agentes e Gatilhos

| Agente | Gatilhos típicos | Color |
|--------|-----------------|-------|
| `spec-dev` | "revise esta spec", "valide a especificação" | blue |
| `backend-dev` | "desenvolva o backend", "implemente a API", "crie o endpoint" | green |
| `frontend-dev` | "desenvolva o frontend", "crie o componente", "implemente o formulário" | cyan |
| `devops-cicd` | "crie o pipeline", "configure o CI/CD", "configure o Azure DevOps", "escreva o Dockerfile", "faça deploy no OpenShift", "provisione a infraestrutura" | yellow |

## Organização das Skills

- **Base** (`skills/base/`): carregadas automaticamente por cada agente ao iniciar (inclui `devops-base`)
- **Domínio** (`skills/domains/`): `spec-review`, `api-rest`, `database`, `security`, `forms`, `glpi`, `ui-components`, `user-experience`, `ci-cd`, `containers`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`
  - `glpi` tem sub-skills aninhadas em `skills/domains/glpi/`: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue`
- **Linguagem** (`skills/languages/`): `python`, `php`, `javascript`, `vue`, `twig`, `html`

## Padrão de Carregamento de Skills pelos Agentes

Cada agente instrui explicitamente quais skills carregar via `${CLAUDE_PLUGIN_ROOT}`:

```
${CLAUDE_PLUGIN_ROOT}/skills/base/<agente>-base/SKILL.md        ← sempre
${CLAUDE_PLUGIN_ROOT}/skills/domains/<dominio>/SKILL.md          ← conforme contexto
${CLAUDE_PLUGIN_ROOT}/skills/languages/<linguagem>/SKILL.md      ← conforme stack
```

## Precedência de Carregamento de Skills

Quando múltiplas skills são candidatas, a ordem de prioridade é: **GLPI > Languages > Domains**. Skills de domínio GLPI têm precedência sobre skills de linguagem, que têm precedência sobre domínios genéricos.

As skills de plataforma do domínio devops (`openshift`, `azure-devops`) **complementam** as genéricas, não as substituem: ao detectar OpenShift, carregar `containers` + `openshift`; ao detectar Azure DevOps, carregar `ci-cd` + `azure-devops`. As específicas trazem só as diferenças da plataforma.

### Assimetrias intencionais do conjunto devops

- **GitHub Actions/GitLab CI ficam inline em `ci-cd`**, enquanto **Azure DevOps é skill separada** (`azure-devops`). Não é inconsistência: GitHub/GitLab cabem como exemplo curto do conceito; o Azure DevOps tem modelo próprio rico (environments, service connections, variable groups, deployment jobs) que não cabe inline. Mesma lógica de `openshift` sobre `containers`.
- **`security` (app) e `devsecops` (pipeline/infra) são distintas por audiência:** o `backend-dev` carrega `security` (OWASP Top 10, XSS, CSRF, JWT — segurança de aplicação web/API); o `devops-cicd` carrega `devsecops` (SAST/SCA/DAST no pipeline, IaC/image scanning, SBOM/cosign, OIDC, supply chain). Elas se referenciam mutuamente.

### Gatilhos de split futuro (evitar fragmentação prematura)

Manter unido até o conteúdo amadurecer; extrair quando:
- **`kubernetes`** ← separar de `containers` quando a parte de orquestração (probes, HPA, StatefulSets, Helm/Kustomize, RBAC) passar de ~80 linhas isoladas.
- **`gitops`** ← separar de `iac` se ArgoCD/Flux crescer (App-of-apps, ApplicationSets, progressive sync, multi-cluster).
- **`github-actions`** ← extrair de `ci-cd` se ganhar profundidade equivalente à de `azure-devops` (reusable workflows, OIDC, matrix, environments).

## Decisões de Design

- Skills organizadas em subdirs (`base/`, `domains/`, `languages/`) para separação clara por responsabilidade
- Commands em `commands/` (formato legado, mas intencional para slash commands diretos)
- Skills com conteúdo mínimo — intencionalmente para expansão posterior
- JavaScript cobre backend (Node.js) e frontend no mesmo arquivo de skill
- `authors` no plugin.json (array) em vez de `author` (objeto único)

### Política de progressive disclosure nos SKILL.md

Para conter o consumo de tokens (o corpo do SKILL.md é sempre carregado quando a skill dispara):

- **Alvo de corpo:** ~1.500–2.000 palavras. Catálogos extensos, enumerações e exemplos longos vão para `references/` por tópico, deixando no corpo um resumo + ponteiro `> ... em [\`references/x.md\`](references/x.md)`.
- **Código inline:** no máximo **1 bloco curto (<8 linhas) por seção**; exemplos maiores ou repetidos vão para `references/`.
- **Sem duplicação:** uma informação vive em um único lugar — não repetir no corpo o que já está num reference (nem entre skills). Tópicos transversais têm fonte autoritativa única (ex.: segurança de aplicação → `domains/security`; acessibilidade → `domains/ui-components`); as demais skills apenas apontam.

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>

## Próximos Passos Sugeridos

- Considerar hooks para validação automática de specs antes de commits
