# fullstack-development

> Versão 0.7.1

Plugin Claude Code modular para desenvolvimento fullstack e mobile. Fornece agentes especializados em especificação, backend, frontend, DevOps/CI-CD e mobile (Android/Flutter), com skills organizadas por domínio e linguagem de programação.

## Agentes

| Agente | Função |
|--------|--------|
| `spec-dev` | Revisão e validação de especificações para desenvolvimento em IA |
| `backend-dev` | Desenvolvimento backend com boas práticas por linguagem e domínio |
| `frontend-dev` | Desenvolvimento frontend com foco em componentes, formulários e UX |
| `devops-cicd` | DevOps, CI/CD, containerização, infraestrutura como código e observabilidade |
| `mobile-dev` | Desenvolvimento mobile Android nativo (Kotlin/Compose) e Flutter (Dart) |

## Skills

### Base
Carregadas automaticamente ao ativar cada agente:
- `base/spec-base` — fundamentos de especificações para IA
- `base/backend-base` — arquitetura e padrões backend
- `base/frontend-base` — arquitetura e padrões frontend
- `base/devops-base` — fundamentos de DevOps, princípios transversais e métricas DORA
- `base/mobile-base` — fundamentos mobile: Clean Architecture (camadas data/domain/ui), MVVM/MVI, estados obrigatórios (loading/erro/vazio/sucesso), KDoc/DartDoc

### Domínios
Carregadas conforme o contexto da tarefa:
- `domains/spec-review` — revisão de specs
- `domains/api-rest` — padrões REST
- `domains/database` — modelagem e queries
- `domains/security` — segurança de aplicação (OWASP Top 10:2025, autenticação, supply chain, LLM)
- `domains/debugging` — método de diagnóstico de bug: reprodução determinística, hipótese/refutação, `git bisect`, classes recorrentes de defeito, correção mínima × estrutural, teste de regressão fail-before/pass-after
- `domains/forms` — formulários frontend
- `domains/glpi-10` — plugins GLPI 10.0.x (ajax-handlers, form-templates, plugin-creation, vue)
- `domains/glpi-11` — plugins GLPI 11 (ajax-handlers, form-templates, plugin-creation, vue); migração 10→11 em `glpi-11/references/migration-10-to-11.md`
- `domains/glpi-12` — plugins GLPI 12 (ajax-handlers, form-templates, plugin-creation, vue); migração 11→12 em `glpi-12/references/migration-11-to-12.md`. Derivado do 12.0.0 RC — revalidar contra o GA
- `domains/ui-components` — componentes UI
- `domains/user-experience` — UX e fluxos de usuário
- `domains/ci-cd` — pipelines, gates de qualidade e estratégias de deploy
- `domains/containers` — imagens OCI (Containerfile/Dockerfile) runtime-agnósticas (Docker/Podman)
- `domains/podman` — runtime daemonless/rootless, Quadlet + systemd em produção
- `domains/kubernetes` — workloads, probes, HPA/PDB, Pod Security Standards, Gateway API, Helm/Kustomize
- `domains/openshift` — especificidades do OpenShift (Route, SCC, BuildConfig, S2I, `oc`)
- `domains/azure-devops` — Azure Pipelines (stages, service connections, environments)
- `domains/iac` — infraestrutura como código e GitOps (Terraform, ArgoCD/Flux)
- `domains/observability` — métricas, logs, traces, SLI/SLO e alerting
- `domains/devsecops` — segurança no pipeline e na infraestrutura (SAST/SCA/DAST, SBOM, supply chain)
- `domains/android-architecture` — ViewModel + StateFlow, Hilt, Room, Navigation Component, Repository pattern
- `domains/jetpack-compose` — composables, state hoisting, Modifier, listas lazy, Material3, performance
- `domains/flutter` — widget tree, state management (Provider/Riverpod/BLoC), GoRouter, FutureBuilder/StreamBuilder

### Linguagens
Carregadas conforme a stack identificada:
- `languages/python` — Python 3.14: tipos (PEP 695, PEP 649), t-strings, asyncio, free-threading, uv/ruff
- `languages/php` — PHP 8.3–8.5 (backend); detecta a versão-alvo do projeto antes de gerar código
- `languages/javascript` — JavaScript (backend + frontend)
- `languages/nodejs` — runtime Node.js: ESM, TypeScript nativo, test runner, permission model
- `languages/golang` — Go: erros, concorrência, `net/http`, `log/slog`
- `languages/vue` — Vue 3.5 (frontend): `defineModel`, reactive props destructure, utilitários de composição, lazy hydration
- `languages/twig` — Twig (frontend)
- `languages/html` — HTML (frontend)
- `languages/kotlin` — null safety, coroutines, data/sealed classes, scope functions
- `languages/gradle` — Kotlin DSL, version catalog, build types, product flavors, multi-módulo
- `languages/dart` — null safety, async/await, Futures, Streams, classes/mixins/extensions

## Commands

| Comando | Uso |
|---------|-----|
| `/fullstack-development:review-spec <arquivo>` | Revisão completa de especificação |
| `/fullstack-development:new-feature <nome>` | Iniciar desenvolvimento de nova feature |
| `/fullstack-development:new-bugfix <id>` | Corrigir um bug com fluxo diagnóstico-first (reprodução → causa raiz → revisão de domínio → correção com teste de regressão) |
| `/fullstack-development:code-review [path]` | Revisão de código fullstack |

## Instalação

```bash
cc --plugin-dir /caminho/para/fullstack-development
```

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>
