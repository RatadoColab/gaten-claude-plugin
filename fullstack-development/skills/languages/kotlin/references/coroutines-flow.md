# Kotlin Coroutines e Flow — Referência Detalhada

## CoroutineScope e Ciclo de Vida

| Scope | Ciclo de vida | Uso |
|---|---|---|
| `viewModelScope` | Destruído com o ViewModel | Operações de negócio no ViewModel |
| `lifecycleScope` | Destruído com o Fragment/Activity | Coleta de Flow na UI |
| `GlobalScope` | Aplicação inteira | **Evitar** — dificulta cancelamento e teste |
| `CoroutineScope(Dispatchers.IO)` | Manual | Testes e serviços que gerenciam o scope |

```kotlin
// Criar scope customizado com supervisor (filho não cancela pai)
private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

// Cancelar ao destruir o componente
override fun onDestroy() {
    super.onDestroy()
    scope.cancel()
}
```

---

## Dispatchers

| Dispatcher | Thread pool | Para que serve |
|---|---|---|
| `Dispatchers.Main` | Main thread | Atualizar UI, interagir com Views |
| `Dispatchers.IO` | Expansível (até 64) | Rede, banco, arquivo |
| `Dispatchers.Default` | CPU-bound (nº de cores) | Cálculos intensivos, ordenação |
| `Dispatchers.Unconfined` | Chamador | Testes; evitar em produção |

```kotlin
viewModelScope.launch {
    val result = withContext(Dispatchers.IO) { repository.fetchData() }
    // De volta ao Main automaticamente
    _state.value = result
}
```

---

## Job e Cancelamento

```kotlin
val job = scope.launch { heavyOperation() }

// Cancelar explicitamente
job.cancel()

// Esperar conclusão
job.join()

// Cooperative cancellation — verificar isActive em loops
suspend fun processItems(items: List<Item>) {
    for (item in items) {
        ensureActive()  // throws CancellationException if cancelled
        process(item)
    }
}
```

`CancellationException` é propagada silenciosamente — não capturar com `catch (e: Exception)` genérico; usar `catch (e: CancellationException) { throw e }` se necessário tratar outros erros.

---

## Parallel Decomposition

```kotlin
// Paralelo com async/await
val (users, products) = coroutineScope {
    val u = async(Dispatchers.IO) { userApi.getAll() }
    val p = async(Dispatchers.IO) { productApi.getAll() }
    u.await() to p.await()
}

// coroutineScope vs supervisorScope
// coroutineScope: a child failure cancels all other children
// supervisorScope: a child failure does not affect siblings
```

---

## Error Handling

```kotlin
// CoroutineExceptionHandler (apenas em launch, não em async)
val handler = CoroutineExceptionHandler { _, throwable ->
    Log.e("Coroutine", "Uncaught exception", throwable)
}
scope.launch(handler) { riskyOperation() }

// Padrão recomendado: runCatching
val result: Result<Data> = runCatching { repository.fetch() }
result.fold(
    onSuccess = { _state.value = UiState.Success(it) },
    onFailure = { _state.value = UiState.Error(it.message ?: "Error") }
)
```

---

## Flow

### Tipos de Flow

| Tipo | Frio/Quente | Estado atual | Múltiplos collectors |
|---|---|---|---|
| `Flow<T>` | Frio | Não | Não (reinicia por collector) |
| `StateFlow<T>` | Quente | Sim (último valor) | Sim |
| `SharedFlow<T>` | Quente | Configurável (replay) | Sim |

### Criação e Operadores

```kotlin
// Flow builder
val flow: Flow<Int> = flow {
    for (i in 1..5) {
        delay(1000)
        emit(i)
    }
}

// Operadores comuns
flow
    .filter { it % 2 == 0 }
    .map { it * 10 }
    .catch { e -> emit(-1) }          // handles errors from upstream
    .onEach { Log.d("Flow", "$it") }
    .flowOn(Dispatchers.IO)           // changes the dispatcher for upstream operators
    .collect { value -> render(value) }
```

### StateFlow e SharedFlow no ViewModel

> O padrão canônico de exposição de `StateFlow`/`SharedFlow` em ViewModels — `stateIn(viewModelScope, WhileSubscribed(5_000), ...)`, eventos one-shot com `SharedFlow`, coleta com `repeatOnLifecycle` — é documentado em **`domains/android-architecture/SKILL.md`** (fonte autoritativa para wiring de ViewModel). Esta referência cobre as mecânicas de Flow (operadores, builders, cold/hot, `flowOn`, `catch`).

---

## Testing Coroutines

```kotlin
@Test
fun `should emit loading then success`() = runTest {
    val viewModel = ProductViewModel(fakeRepository)
    val states = mutableListOf<UiState<List<Product>>>()

    val job = launch { viewModel.uiState.toList(states) }

    advanceUntilIdle()  // processes all pending coroutines
    job.cancel()

    assertThat(states).containsExactly(UiState.Loading, UiState.Success(fakeProducts))
}
```

Dependências de teste: `kotlinx-coroutines-test`, `turbine` (para Flow assertions fluentes).
