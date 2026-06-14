# Jetpack Compose — State Avançado

## derivedStateOf

Calcula um valor derivado que só recalcula quando suas dependências mudam — evita recomposições excessivas:

```kotlin
@Composable
fun ShoppingCart(items: List<CartItem>) {
    // without derivedStateOf: recalculates on every recomposition
    // with derivedStateOf: recalculates only when items changes
    val totalPrice by remember(items) { derivedStateOf { items.sumOf { it.price * it.qty } } }
    val canCheckout by remember { derivedStateOf { items.isNotEmpty() && items.all { it.qty > 0 } } }

    Text("Total: R$ %.2f".format(totalPrice))
    Button(onClick = { checkout() }, enabled = canCheckout) { Text("Finalizar") }
}
```

Usar `derivedStateOf` apenas quando a derivação é computacionalmente custosa ou quando evita recomposições de outros composables.

---

## snapshotFlow

Converte state do Compose em Flow — útil para reagir a mudanças de estado fora da composição:

```kotlin
@Composable
fun SearchField(viewModel: SearchViewModel) {
    var query by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        snapshotFlow { query }
            .debounce(300)
            .distinctUntilChanged()
            .collectLatest { q -> viewModel.search(q) }
    }

    TextField(value = query, onValueChange = { query = it })
}
```

---

## produceState

Converte código assíncrono (suspend, callback) em State:

```kotlin
@Composable
fun NetworkStatusBanner() {
    val isOnline by produceState(initialValue = true) {
        connectivityManager.observe { isConnected -> value = isConnected }
        awaitDispose { connectivityManager.stopObserving() }
    }

    AnimatedVisibility(!isOnline) {
        Banner("Sem conexão")
    }
}
```

---

## rememberCoroutineScope

Fornece um `CoroutineScope` ligado ao ciclo de vida do composable — usar para lançar coroutines em resposta a eventos:

```kotlin
@Composable
fun SubmitButton(onSubmit: suspend () -> Unit) {
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(false) }

    Button(
        onClick = {
            scope.launch {
                isLoading = true
                try { onSubmit() } finally { isLoading = false }
            }
        },
        enabled = !isLoading
    ) {
        if (isLoading) CircularProgressIndicator(modifier = Modifier.size(16.dp))
        else Text("Enviar")
    }
}
```

---

## Side Effects

| Effect | Quando executar | Disparado por |
|---|---|---|
| `LaunchedEffect(key)` | Suspenso, ligado ao ciclo de vida do composable | Mudança da key |
| `SideEffect { }` | Síncrono, após cada recomposição bem-sucedida | Toda recomposição |
| `DisposableEffect(key)` | Com limpeza no `onDispose { }` | Mudança da key |

```kotlin
// LaunchedEffect — executar uma vez ao entrar na tela
LaunchedEffect(Unit) {
    viewModel.loadData()
}

// LaunchedEffect — reagir a mudança de key
LaunchedEffect(userId) {
    viewModel.loadUserProfile(userId)
}

// DisposableEffect — registrar/desregistrar listener
DisposableEffect(Unit) {
    val listener = SensorEventListener { event -> updateData(event) }
    sensorManager.registerListener(listener, sensor, SENSOR_DELAY_UI)
    onDispose { sensorManager.unregisterListener(listener) }
}

// SideEffect — sincronizar com código não-Compose (ex.: analytics)
SideEffect {
    analytics.setCurrentScreen(screenName)
}
```

---

## rememberUpdatedState

Captura o valor mais recente em um efeito de longa duração sem reiniciá-lo:

```kotlin
@Composable
fun Timer(onTimeout: () -> Unit) {
    // if onTimeout changes (recomposition lambda), the timer is not restarted
    val currentOnTimeout by rememberUpdatedState(onTimeout)

    LaunchedEffect(Unit) {
        delay(5_000)
        currentOnTimeout()  // always calls the most recent version
    }
}
```
