---
description: Realiza revisão de código com consciência fullstack, detectando o tipo do código (backend/frontend/mobile), carregando o agente e skills pertinentes, e avaliando qualidade, segurança e coerência com o contrato da API.
argument-hint: [caminho-do-arquivo-ou-diretório]
allowed-tools: [Read, Grep, Glob]
---

# code-review

Revisar código detectando automaticamente se é backend, frontend ou mobile e aplicando as práticas e padrões relevantes para cada contexto.

## Processo

1. Se nenhum argumento fornecido, usar o diretório atual
2. Ler os arquivos indicados ou fazer listagem do diretório
3. Detectar o tipo de código:
   - **Backend:** PHP, Python, JS (Node.js), SQL, controllers, services, repositories
   - **Frontend:** Vue, HTML, Twig, CSS, componentes, páginas
   - **Mobile Android:** Kotlin, `.kt`, `@Composable`, imports `androidx.*`, `AndroidManifest.xml`
   - **Mobile Flutter:** Dart, `.dart`, `pubspec.yaml`, `flutter/material.dart`
4. Carregar skills pertinentes:
   - `${CLAUDE_PLUGIN_ROOT}/skills/base/<tipo>-base/SKILL.md`
   - Skills de domínio conforme o código analisado
   - Skill de linguagem correspondente
   - **Mobile Android:** `${CLAUDE_PLUGIN_ROOT}/skills/base/mobile-base/SKILL.md` + `kotlin` + `android-architecture` + `jetpack-compose` (se UI Compose) + `gradle` (se build/dependências)
   - **Mobile Flutter:** `${CLAUDE_PLUGIN_ROOT}/skills/base/mobile-base/SKILL.md` + `dart` + `flutter`
   - Compose e Flutter são mutuamente exclusivos — nunca carregar ambos
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
```
