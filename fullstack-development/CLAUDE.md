# fullstack-development Plugin — Contexto Local

Plugin Claude Code modular para desenvolvimento fullstack. Construído em maio/2026; a v0.2.0 (junho/2026) adicionou o eixo DevOps/CI-CD — agente `devops-cicd`, skill base `devops-base` e 7 domínios (`ci-cd`, `containers`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`).

## Instalação e Teste

```bash
# Instalar localmente para testar (apontar ao diretório que contém .claude-plugin/)
cc --plugin-dir /home/andre/projetos/IBGE/gaten-claude-plugin/fullstack-development

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

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>

## Próximos Passos Sugeridos

- Expandir o conteúdo de cada `SKILL.md` com `references/` detalhados
- Adicionar `examples/` às skills de linguagem com snippets prontos
- Considerar hooks para validação automática de specs antes de commits
- Testar gatilhos dos agentes em cenários reais de desenvolvimento
