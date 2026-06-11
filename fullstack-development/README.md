# fullstack-development

Plugin Claude Code modular para desenvolvimento fullstack. Fornece agentes especializados em especificação, backend, frontend e DevOps/CI-CD, com skills organizadas por domínio e linguagem de programação.

## Agentes

| Agente | Função |
|--------|--------|
| `spec-dev` | Revisão e validação de especificações para desenvolvimento em IA |
| `backend-dev` | Desenvolvimento backend com boas práticas por linguagem e domínio |
| `frontend-dev` | Desenvolvimento frontend com foco em componentes, formulários e UX |
| `devops-cicd` | DevOps, CI/CD, containerização, infraestrutura como código e observabilidade |

## Skills

### Base
Carregadas automaticamente ao ativar cada agente:
- `base/spec-base` — fundamentos de especificações para IA
- `base/backend-base` — arquitetura e padrões backend
- `base/frontend-base` — arquitetura e padrões frontend
- `base/devops-base` — fundamentos de DevOps, princípios transversais e métricas DORA

### Domínios
Carregadas conforme o contexto da tarefa:
- `domains/spec-review` — revisão de specs
- `domains/api-rest` — padrões REST
- `domains/database` — modelagem e queries
- `domains/security` — segurança (OWASP, autenticação)
- `domains/forms` — formulários frontend
- `domains/glpi` — plugins GLPI 10.x (ajax-handlers, form-templates, plugin-creation, vue)
- `domains/ui-components` — componentes UI
- `domains/user-experience` — UX e fluxos de usuário
- `domains/ci-cd` — pipelines, gates de qualidade e estratégias de deploy
- `domains/containers` — Docker e Kubernetes
- `domains/openshift` — especificidades do OpenShift (Route, SCC, BuildConfig, S2I, `oc`)
- `domains/azure-devops` — Azure Pipelines (stages, service connections, environments)
- `domains/iac` — infraestrutura como código e GitOps (Terraform, ArgoCD/Flux)
- `domains/observability` — métricas, logs, traces, SLI/SLO e alerting
- `domains/devsecops` — segurança no pipeline e na infraestrutura (SAST/SCA/DAST, SBOM, supply chain)

### Linguagens
Carregadas conforme a stack identificada:
- `languages/python` — Python (backend)
- `languages/php` — PHP (backend)
- `languages/javascript` — JavaScript (backend + frontend)
- `languages/vue` — Vue.js (frontend)
- `languages/twig` — Twig (frontend)
- `languages/html` — HTML (frontend)

## Commands

| Comando | Uso |
|---------|-----|
| `/fullstack-development:review-spec <arquivo>` | Revisão completa de especificação |
| `/fullstack-development:new-feature <nome>` | Iniciar desenvolvimento de nova feature |
| `/fullstack-development:code-review [path]` | Revisão de código fullstack |

## Instalação

```bash
cc --plugin-dir /caminho/para/fullstack-development
```

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>
