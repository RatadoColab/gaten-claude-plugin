---
name: fullstack-router
description: Índice das skills do plugin fullstack-development (backend, frontend, mobile, DevOps, GLPI). Consultar ANTES de começar qualquer tarefa de código em um projeto — planejar, implementar, revisar código, escrever ou revisar especificação, corrigir bug, segurança, endpoint, tela, formulário, migration, pipeline, Dockerfile, app Android/Flutter. Indica quais SKILL.md ler, conforme a stack e a versão detectadas.
---

# Índice de skills — fullstack-development

Raiz: `${CLAUDE_PLUGIN_ROOT}/skills/` — todos os caminhos da tabela são relativos a ela. Ler com `Read`.

## Como carregar

1. Identificar a stack (seção Detecção). Se o contexto da sessão já trouxer a linha "fullstack-development: stack detectada", partir dela.
2. Ler primeiro a skill **base** da trilha; depois, só as linhas da tabela que casarem com a tarefa.
3. Ler `references/` apenas quando a SKILL.md apontar.
4. Precedência: GLPI > Languages > Domains. Exclusões: Compose × Flutter; podman × kubernetes; uma única árvore GLPI por vez (exceto migração 10→11 ou 11→12: a de destino é autoritativa e a de origem só referência; 10→12 direto não é suportado).
5. Complementos: OpenShift = `kubernetes` + `openshift` (+ `containers` se houver build de imagem); Azure DevOps = `ci-cd` + `azure-devops`; Node = `javascript` + `nodejs`; tela Android = `android-architecture` + `jetpack-compose`.

## Detecção de stack e versão

- **PHP:** `composer.json` (`require.php`, `config.platform.php`) → `.php-version`/`php -v`/Dockerfile → sintaxe (property hooks ou `public private(set)` ⇒ ≥ 8.4; `|>` ou `#[\NoDiscard]` ⇒ ≥ 8.5) → perguntar ao usuário; sem padrão assumido.
- **GLPI:** `setup.php` com `requirements.glpi.min` iniciando em "10.", "11." ou "12.", ou menção explícita do usuário. Indícios de 10: `include('../../../inc/includes.php')`, `$PLUGIN_HOOKS['csrf_compliant']`, `$DB->queryOrDie(`. Indícios de 11: diretório `public/`, `src/Controller/` com `#[Route]`, `$DB->doQuery(`, `csrf_token()`/`_glpi_csrf_token` em Twig. Indício de 12: `Glpi\Toolbox\HttpClient`; a ausência de `csrf_token()`/`_glpi_csrf_token` em formulários POST só corrobora e nunca decide sozinha. **Sem indício em nenhuma direção, perguntar a versão antes de gerar código — nunca assumir padrão.**
- **Mobile:** `pubspec.yaml` ⇒ Flutter; `AndroidManifest.xml`/`build.gradle*` com `.kt` ⇒ Android nativo; `androidx.compose`/`@Composable` ⇒ somar `jetpack-compose`.
- **Demais:** `package.json` (dependência `vue` ⇒ Vue; sem frontend ⇒ Node), `go.mod`, `pyproject.toml`/`requirements.txt` ⇒ Python, arquivos `.twig` ⇒ Twig, `Dockerfile`/`Containerfile`, `.github/workflows`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `*.tf`, manifests Kubernetes/OpenShift.

## Tabela de skills

`<v>` ∈ {10, 11, 12} — a versão GLPI detectada.

| Skill | Quando carregar | Caminho |
|---|---|---|
| backend-base | qualquer trabalho de backend (sempre na trilha) | base/backend-base/SKILL.md |
| frontend-base | UI web: componentes, páginas, templates | base/frontend-base/SKILL.md |
| mobile-base | app Android ou Flutter | base/mobile-base/SKILL.md |
| devops-base | pipeline, container, deploy, infraestrutura | base/devops-base/SKILL.md |
| spec-base | escrever ou revisar especificação | base/spec-base/SKILL.md |
| spec-review | revisão estruturada de spec (checklist, status SCOPE) | domains/spec-review/SKILL.md |
| debugging | bug existente: reproduzir, causa raiz, teste de regressão | domains/debugging/SKILL.md |
| api-rest | endpoint/API REST, status HTTP, paginação, erros | domains/api-rest/SKILL.md |
| database | modelagem, queries, índices, migrations | domains/database/SKILL.md |
| security | vulnerabilidades, OWASP, autenticação, XSS/CSRF | domains/security/SKILL.md |
| forms | formulários, validação, UX de formulário | domains/forms/SKILL.md |
| ui-components | componentes reutilizáveis, acessibilidade, design tokens | domains/ui-components/SKILL.md |
| user-experience | fluxos, estados de loading/vazio/erro, microcopy | domains/user-experience/SKILL.md |
| ci-cd | pipeline CI/CD, GitHub Actions, GitLab CI, estratégia de deploy | domains/ci-cd/SKILL.md |
| azure-devops | Azure Pipelines (soma-se a ci-cd) | domains/azure-devops/SKILL.md |
| containers | Dockerfile/Containerfile, build e scan de imagem | domains/containers/SKILL.md |
| podman | Podman rootless, Quadlet, systemd (exclusivo com kubernetes) | domains/podman/SKILL.md |
| kubernetes | manifests, probes, HPA, Helm/Kustomize (exclusivo com podman) | domains/kubernetes/SKILL.md |
| openshift | Route, SCC, S2I (soma-se a kubernetes) | domains/openshift/SKILL.md |
| iac | Terraform, provisionamento, GitOps | domains/iac/SKILL.md |
| observability | logs, métricas, traces, SLO, alertas | domains/observability/SKILL.md |
| devsecops | scans no pipeline, SBOM, supply chain do pipeline | domains/devsecops/SKILL.md |
| android-architecture | ViewModel, Hilt, Room, Navigation, Repository | domains/android-architecture/SKILL.md |
| jetpack-compose | UI Android em Compose (exclusivo com flutter) | domains/jetpack-compose/SKILL.md |
| flutter | widgets, estado, navegação Flutter (exclusivo com jetpack-compose) | domains/flutter/SKILL.md |
| glpi-<v> | plugin GLPI: CommonDBTM, controllers, permissões, hooks | domains/glpi-<v>/SKILL.md |
| glpi-<v>/plugin-creation | criar plugin GLPI: setup.php, hook.php, estrutura | domains/glpi-<v>/plugin-creation/SKILL.md |
| glpi-<v>/ajax-handlers | ajax/ ou controller GLPI retornando JSON | domains/glpi-<v>/ajax-handlers/SKILL.md |
| glpi-<v>/form-templates | formulário Twig em plugin GLPI | domains/glpi-<v>/form-templates/SKILL.md |
| glpi-<v>/vue | Vue em plugin GLPI | domains/glpi-<v>/vue/SKILL.md |
| php | código PHP (8.3–8.5) | languages/php/SKILL.md |
| python | código Python | languages/python/SKILL.md |
| javascript | sintaxe JavaScript, front e back | languages/javascript/SKILL.md |
| nodejs | runtime Node.js (soma-se a javascript) | languages/nodejs/SKILL.md |
| golang | código Go | languages/golang/SKILL.md |
| vue | componentes Vue 3 | languages/vue/SKILL.md |
| twig | templates Twig | languages/twig/SKILL.md |
| html | marcação HTML, Bootstrap, ARIA | languages/html/SKILL.md |
| kotlin | código Kotlin para Android | languages/kotlin/SKILL.md |
| gradle | build Android, dependências, variants | languages/gradle/SKILL.md |
| dart | código Dart para Flutter | languages/dart/SKILL.md |
