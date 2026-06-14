---
name: mobile-base
description: This skill should be used when developing mobile applications for Android (Kotlin/Jetpack Compose) or Flutter (Dart). Covers fundamental architecture principles (MVVM/MVI, clean architecture layers), state management, lifecycle awareness, error handling, and documentation standards. Load as base for all mobile development tasks before loading domain or language-specific skills.
---

# Mobile Base — Fundamentos de Desenvolvimento Mobile

## Visão Geral

Princípios de arquitetura e boas práticas gerais aplicáveis ao desenvolvimento mobile, independente de stack (Android nativo ou Flutter).

## Arquitetura Recomendada

### Camadas (Clean Architecture simplificada)

| Camada | Responsabilidade | Exemplos |
|---|---|---|
| **UI / Presentation** | Estado visual, interação do usuário | Composables, Widgets, ViewModels, BLoC/Cubit |
| **Domain** | Regras de negócio puras, independente de plataforma | UseCases, entidades, interfaces de repositório |
| **Data** | Acesso a dados externos (API, banco local, prefs) | Repositories, DAOs, DataSources, API clients |

- **Fluxo:** UI → ViewModel/BLoC → UseCase → Repository → DataSource
- **Dependência:** camadas externas dependem das internas; domain nunca importa data ou UI
- **Testabilidade:** domain e data testáveis sem framework de UI

### Padrão por Stack

| Stack | Padrão de apresentação | Gerência de estado |
|---|---|---|
| Android nativo | MVVM | ViewModel + StateFlow / SharedFlow |
| Flutter | MVVM ou BLoC | Riverpod / BLoC+Cubit / Provider |

## Gerenciamento de Estado

- Estado **imutável** — nunca mutar a instância; emitir novo objeto
- **Single source of truth:** ViewModel/BLoC como dono do estado; UI apenas observa e despacha eventos
- Separar **UI state** (o que renderizar) de **UI events** (navegação, snackbars — consumir uma vez após exibir)

## Tratamento de Estados Obrigatórios

Toda tela deve tratar explicitamente os quatro estados:

| Estado | Representação sugerida |
|---|---|
| **Loading** | Skeleton, shimmer ou spinner central |
| **Erro** | Mensagem descritiva + botão de retry quando aplicável |
| **Vazio** | Ilustração + call-to-action (nunca tela em branco) |
| **Sucesso** | Conteúdo renderizado |

Modelar com sealed class em Kotlin ou classe selada/union em Dart:

```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
```

## Ciclo de Vida

**Android:**
- Coletar Flows com `repeatOnLifecycle(Lifecycle.State.STARTED)` — evita coletas em background
- Preferir `viewLifecycleOwner` a `this` em Fragments
- Cancelar jobs filhos ao destruir o componente via `viewModelScope`

**Flutter:**
- Chamar `dispose()` para cancelar `StreamSubscription`, `AnimationController` e `TextEditingController`
- Nunca chamar `setState()` após `dispose()` — verificar `mounted` antes de atualizar estado assíncrono

**Regra geral:** não vazar referências a contextos/atividades; toda operação I/O em coroutine ou async.

## Documentação

- **Kotlin:** KDoc (`/** */`) em classes, funções públicas e propriedades não-óbvias
- **Dart:** DartDoc (`///`) em classes, métodos e propriedades públicos
- Comentários de implementação em inglês com `//` por linha (sem blocos `/* */`)
- Docstring descreve o contrato (o quê retorna, pré-condições), não a implementação

## Princípios Gerais

- **SOLID e DRY:** classes coesas, responsabilidade única, sem duplicação de lógica
- **Nomes descritivos:** sem abreviações; PascalCase para tipos, camelCase para funções e variáveis
- **Funções puras em helpers:** sem side effects; facilita teste unitário
- **UI thread livre:** toda I/O em coroutine (Android) ou async/await (Dart); UI sempre responsiva

## Referências por Domínio e Linguagem

| Contexto | Skill a carregar |
|---|---|
| Telas Android com Compose | `domains/jetpack-compose/SKILL.md` |
| ViewModel, Hilt, Room, Navigation Android | `domains/android-architecture/SKILL.md` |
| Linguagem Kotlin (idioms, coroutines, sealed classes) | `languages/kotlin/SKILL.md` |
| Build Android (Gradle, flavors, signing) | `languages/gradle/SKILL.md` |
| App Flutter (widgets, navegação, estado) | `domains/flutter/SKILL.md` |
| Linguagem Dart (null safety, async, streams) | `languages/dart/SKILL.md` |
