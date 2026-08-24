---
description: Realiza revisão de código com consciência fullstack, detectando o tipo do código (backend/frontend/mobile/devops), carregando o agente e skills pertinentes, e avaliando qualidade, segurança e coerência com o contrato da API.
argument-hint: [caminho-do-arquivo-ou-diretório]
allowed-tools: [Read, Grep, Glob]
---

# code-review

Revisar código detectando automaticamente se é backend, frontend ou mobile e aplicando as práticas e padrões relevantes para cada contexto.

## Processo

1. Se nenhum argumento fornecido, usar o diretório atual
2. Ler os arquivos indicados ou fazer listagem do diretório
3. Detectar o tipo de código:
   - **Backend:** PHP, Python, JS/Node.js, Go, SQL, controllers, services, repositories
   - **Frontend:** Vue, HTML, Twig, CSS, componentes, páginas
   - **Mobile Android:** Kotlin, `.kt`, `@Composable`, imports `androidx.*`, `AndroidManifest.xml`
   - **Mobile Flutter:** Dart, `.dart`, `pubspec.yaml`, `flutter/material.dart`
   - **DevOps/Infra:** `Dockerfile`/`Containerfile`; unidades Quadlet (`*.container`/`*.pod`/`*.volume`/`*.network`); YAML com `apiVersion:`+`kind:` (manifests Kubernetes/OpenShift); `Chart.yaml`/`kustomization.yaml`; `.gitlab-ci.yml`/`.github/workflows/`/`azure-pipelines.yml`; `*.tf`
4. Carregar skills pertinentes:
   - `${CLAUDE_PLUGIN_ROOT}/skills/base/<tipo>-base/SKILL.md` (para mobile: `mobile-base`; para DevOps/Infra: `devops-base`)
   - Skills de domínio conforme o código analisado
   - Skill de linguagem correspondente
   - **Backend Node.js:** `javascript` + `nodejs` (carregar as duas juntas)
   - **Mobile Android:** `kotlin` + `android-architecture` + `jetpack-compose` (se UI Compose) + `gradle` (se build/dependências)
   - **Mobile Flutter:** `dart` + `flutter`
   - Compose e Flutter são mutuamente exclusivos — nunca carregar ambos
   - **DevOps/Infra:** `containers` (Dockerfile/Containerfile) e/ou `podman` (unidades Quadlet) e/ou `kubernetes` (manifests/Helm/Kustomize) e/ou `ci-cd`/`iac`/`devsecops` conforme o arquivo — `podman` e `kubernetes` são mutuamente exclusivos, nunca carregar ambos
5. Avaliar o código nas dimensões:
   - **Qualidade:** legibilidade, nomenclatura, responsabilidades
   - **Segurança:** vulnerabilidades, validações, dados expostos
   - **Padrões:** conformidade com as convenções da linguagem (incluindo KDoc/DartDoc para mobile)
   - **Coerência fullstack:** contratos API, tipos consistentes entre camadas; para mobile, avaliar consumo do backend (DTOs, tratamento de erros, timeouts, cancelamento de coroutines/futures)
6. Produzir relatório com problemas por severidade (crítico, aviso, sugestão)

## Dicas de Uso

```
/fullstack-development:code-review src/controllers/UserController.php
/fullstack-development:code-review src/components/UserForm.vue
/fullstack-development:code-review src/
/fullstack-development:code-review app/src/main/java/com/example/ui/ProductsScreen.kt
/fullstack-development:code-review lib/features/products/presentation/products_page.dart
/fullstack-development:code-review k8s/overlays/prod/
```
