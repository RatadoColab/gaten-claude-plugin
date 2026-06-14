---
name: kotlin
description: This skill should be used when writing, reviewing, or refactoring Kotlin code for Android development. Covers Kotlin null safety, data classes, sealed classes, extension functions, scope functions (let/run/with/apply/also), coroutines basics, Flow, and idiomatic Kotlin patterns. Use when the user asks to "write Kotlin", "review Kotlin code", "implement with coroutines", "use sealed class", "refactor to idiomatic Kotlin", "implement Flow", or "add extension function".
---

# Kotlin — Convenções e Boas Práticas para Android

Diretrizes para escrita de Kotlin idiomático com foco em desenvolvimento Android (Kotlin 2.x; verificar versão atual em [kotlinlang.org/docs/releases](https://kotlinlang.org/docs/releases.html)).

---

## Compilador K2

O compilador K2 é o padrão desde o Kotlin 2.0 — nenhuma flag necessária. Benefícios principais:

- **Smart-casts mais precisos** em condições compostas e lambdas
- Compilação **2× mais rápida** em projetos grandes (benchmarks JetBrains)
- Base unificada para futuros recursos de linguagem

> Atualizado (Kotlin 2.0): `kotlinCompilerExtensionVersion` (Compose) foi substituído pelo plugin Compose Compiler Gradle separado — ver `languages/gradle/SKILL.md`.

---

## Null Safety

O sistema de tipos do Kotlin distingue tipos anuláveis (`String?`) de não-anuláveis (`String`) em tempo de compilação.

| Operador | Comportamento | Quando usar |
|---|---|---|
| `?.` | Acesso seguro — retorna `null` se o receptor for `null` | Encadeamento em tipos anuláveis |
| `?:` | Elvis — valor de fallback quando `null` | Definir default sem `if` |
| `!!` | Non-null assertion — lança `NullPointerException` se `null` | **Evitar** — preferir `?: error("msg")` |
| `let` | Executa bloco apenas se não-null | Operação condicional em nullable |

```kotlin
val city = user?.address?.city ?: "Unknown"
user?.let { sendNotification(it) }
```

> `!!` é aceitável apenas quando a nulidade for impossível por invariante de negócio e não houver API alternativa.

---

## Data Classes

Data classes geram automaticamente `equals`, `hashCode`, `toString` e `copy`.

```kotlin
data class User(val id: Long, val name: String, val email: String)

// Immutable update — copy preserva o restante
val updated = user.copy(name = "João")
```

- Usar para DTOs, estados de UI e entidades simples
- **Não usar** quando a classe precisar de herança (data classes são `final` por padrão)
- Parâmetros do construtor primário sempre com `val` (imutabilidade preferida)

---

## Sealed Classes e Sealed Interfaces

Sealed types restringem a herança ao mesmo arquivo/pacote — o compilador garante exhaustividade no `when`.

```kotlin
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val exception: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

// exhaustive when — no else needed
when (result) {
    is Result.Success -> render(result.data)
    is Result.Error   -> showError(result.exception)
    Result.Loading    -> showLoading()
}
```

Usar sealed classes/interfaces para: estados de UI, resultados de operações, eventos de navegação.

**Guard conditions em `when`** (Kotlin 2.x):

```kotlin
when (result) {
    is Result.Success if (result.data.isNotEmpty()) -> render(result.data)
    is Result.Success -> showEmpty()
    is Result.Error   -> showError(result.exception)
    Result.Loading    -> showLoading()
}
```

> Atualizado (Kotlin 2.x): `is X if (condição) ->` substitui o padrão de `is X -> if (condição) { ... }` aninhado.

---

## Extension Functions

Adicionam comportamento a classes existentes sem herança. Resolvidas estaticamente — não sobrescrevem membros originais.

```kotlin
fun String.toSlug(): String = lowercase().replace(" ", "-").replace(Regex("[^a-z0-9-]"), "")

fun View.visible(show: Boolean) { visibility = if (show) View.VISIBLE else View.GONE }
```

- Definir em arquivos de extensão dedicados (`UserExtensions.kt`, `ViewExtensions.kt`)
- Não usar para lógica de negócio complexa — preferir UseCases ou funções top-level com parâmetros explícitos

---

## Scope Functions

| Função | Receptor (`this`/`it`) | Retorna | Uso típico |
|---|---|---|---|
| `let` | `it` | resultado do bloco | Transformação; operação em nullable |
| `run` | `this` | resultado do bloco | Bloco de inicialização com retorno |
| `with` | `this` | resultado do bloco | Múltiplas operações em objeto (não nullable) |
| `apply` | `this` | o próprio objeto | Configuração de objeto (builder-style) |
| `also` | `it` | o próprio objeto | Side effect (logging, validação) |

```kotlin
val dialog = AlertDialog.Builder(context).apply {
    setTitle("Confirmar")
    setMessage("Deseja continuar?")
    setPositiveButton("Sim") { _, _ -> onConfirm() }
}.create()
```

> Evitar scope functions aninhadas em mais de 2 níveis — prejudica legibilidade.

---

## Coroutines — Visão Geral

Para detalhes de implementação (CoroutineScope, Dispatchers, Job, Flow avançado, error handling, cancelamento), ver **`references/coroutines-flow.md`**.

| Conceito | Resumo |
|---|---|
| `suspend fun` | Função que pode ser pausada e retomada sem bloquear thread |
| `CoroutineScope` | Define o ciclo de vida das coroutines (`viewModelScope`, `lifecycleScope`) |
| `Dispatchers.IO` | Para I/O (rede, banco); `Dispatchers.Main` para UI |
| `Flow<T>` | Stream frio e reativo; coletar com `collect {}` ou `collectLatest {}` |
| `StateFlow` | `Flow` com estado atual; substitui `LiveData` em ViewModels modernos |
| `SharedFlow` | Para eventos de navegação/snackbar (sem replay por padrão) |

```kotlin
// Lançar em viewModelScope — cancelado automaticamente quando o ViewModel é destruído
viewModelScope.launch(Dispatchers.IO) {
    val result = repository.fetchUser(id)
    withContext(Dispatchers.Main) { _uiState.value = result }
}
```

---

## Coleções

Preferir operações funcionais (`map`, `filter`, `fold`) a loops imperativos:

```kotlin
val activeUsers = users.filter { it.isActive }.sortedBy { it.name }
val totalPoints = scores.fold(0) { acc, score -> acc + score }
val byId = users.associateBy { it.id }
```

| Operação | Retorna | Uso |
|---|---|---|
| `map` | `List<R>` | Transformação 1-para-1 |
| `filter` | `List<T>` | Seleção por predicado |
| `fold` / `reduce` | `R` | Agregação |
| `groupBy` | `Map<K, List<T>>` | Agrupamento |
| `associateBy` | `Map<K, T>` | Lookup por chave |
| `flatMap` | `List<R>` | Transformação 1-para-N e achatamento |

Para lazy evaluation em coleções grandes, usar `asSequence()` antes da cadeia de operações.

---

## Anti-Patterns

| Anti-Pattern | Problema | Padrão Kotlin correto |
|---|---|---|
| `if (x != null) x.foo()` | Verboso | `x?.foo()` |
| `x!!.foo()` indiscriminado | NPE em runtime | `x?.foo() ?: return` ou `requireNotNull(x)` |
| Mutable `var` desnecessário | Dificulta raciocínio | `val` + `copy()` em data classes |
| `object : Runnable { ... }` | Verboso | Lambda `{ ... }` (SAM) |
| `Thread { ... }.start()` | Thread não gerenciada | `viewModelScope.launch` |
| `.apply { return@apply ... }` | Retorno confuso | `also { ... }` ou função separada |
| `when` com `else` em sealed | Perde exhaustividade | Remover `else`; compilador verifica |
| Coleção mutável exposta | Quebra encapsulamento | `_list: MutableList` (privado) + `list: List` (público) |

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/coroutines-flow.md`** | CoroutineScope, Dispatchers, Job, Flow operators, StateFlow vs SharedFlow, error handling, cancelamento, testing |
| **`references/idioms.md`** | Idioms avançados: delegated properties, object declarations, inline functions, reified generics, DSL builders |

---

## Também consultar

- `domains/android-architecture/SKILL.md` — ViewModel, Hilt, Room, Navigation com Kotlin
- `domains/jetpack-compose/SKILL.md` — uso de Kotlin no contexto Compose (remember, state, recomposição)
