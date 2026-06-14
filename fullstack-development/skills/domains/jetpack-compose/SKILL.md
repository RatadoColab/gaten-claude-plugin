---
name: jetpack-compose
description: This skill should be used when building Android UI with Jetpack Compose. Covers composable functions, state hoisting, remember/mutableStateOf/derivedStateOf, recomposition, Modifier chains, lazy lists (LazyColumn/LazyRow), Compose navigation, theming with MaterialTheme, and performance best practices. Use when the user asks to "create a Composable", "implement Compose screen", "use LazyColumn", "hoist state in Compose", "add Compose navigation", "use remember", "apply MaterialTheme", "optimize recomposition", or "build UI with Jetpack Compose".
---

# Jetpack Compose — UI Declarativa Android

Boas práticas para construção de UI com Jetpack Compose (Material3, Compose BOM — verificar versão atual em [developer.android.com/develop/ui/compose/bom](https://developer.android.com/develop/ui/compose/bom)).

> Atualizado (Compose Multiplatform): Compose é multiplataforma — **CMP (Compose Multiplatform) para iOS** está estável. As APIs de UI são as mesmas; diferenças ficam no acesso a recursos nativos por plataforma.

---

## Fundamentos: Composable Functions

Composables são funções anotadas com `@Composable` que descrevem a UI a partir do estado atual:

```kotlin
@Composable
fun ProductCard(product: Product, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth()
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(text = product.name, style = MaterialTheme.typography.titleMedium)
            Text(text = "R$ %.2f".format(product.price), style = MaterialTheme.typography.bodySmall)
        }
    }
}
```

- **Sempre receber `modifier: Modifier = Modifier`** como parâmetro — permite quem chama posicionar/dimensionar
- Composables devem ser **livres de side effects** — sem escrita em variáveis externas, sem I/O direto
- Nomear com PascalCase (como classes); não retornam valores

---

## Estado e Recomposição

Compose recompõe automaticamente composables cujo estado lido foi alterado.

```kotlin
// Estado local (simples, sem hoist)
@Composable
fun Counter() {
    var count by remember { mutableIntStateOf(0) }  // local state (simple, no hoisting)
    Button(onClick = { count++ }) { Text("Count: $count") }
}
```

| API | Uso |
|---|---|
| `remember { }` | Persiste valor durante recomposições da mesma composição |
| `mutableStateOf(v)` | Cria estado observável — alteração dispara recomposição |
| `mutableIntStateOf` / `mutableLongStateOf` | Otimizados para primitivos |
| `derivedStateOf { }` | Estado derivado — recalculado apenas quando dependências mudam |
| `rememberSaveable { }` | Sobrevive a mudanças de configuração (equivalente a `savedInstanceState`) |

---

## State Hoisting

Elevar o estado para o ancestral comum mais baixo que precisa dele — mantém composables stateless e testáveis.

```kotlin
// Stateless — testable, reusable
@Composable
fun SearchBar(query: String, onQueryChange: (String) -> Unit, modifier: Modifier = Modifier) {
    TextField(value = query, onValueChange = onQueryChange, modifier = modifier, label = { Text("Buscar") })
}

// Stateful — owns and controls the state
@Composable
fun ProductListScreen(viewModel: ProductListViewModel = hiltViewModel()) {
    val query by viewModel.searchQuery.collectAsStateWithLifecycle()
    SearchBar(query = query, onQueryChange = viewModel::updateQuery)
}
```

**Regra:** se o estado for necessário em dois composables irmãos, hoistá-lo para o pai comum.

---

## Modifier

`Modifier` é aplicado em cadeia; a **ordem importa**:

```kotlin
Box(
    modifier = Modifier
        .padding(16.dp)      // outer spacing first
        .fillMaxWidth()
        .background(Color.LightGray)
        .clickable { }
        .padding(8.dp)       // inner spacing after background
)
```

- Passar sempre `modifier` recebido como parâmetro antes de adicionar modificadores internos
- Não criar lambdas anônimas dentro de `Modifier.clickable {}` sem `remember` — recria desnecessariamente

---

## Listas Lazy

```kotlin
@Composable
fun ProductList(products: List<Product>, onProductClick: (Int) -> Unit) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(products, key = { it.id }) { product ->  // stable key prevents full recomposition
            ProductCard(product = product, onClick = { onProductClick(product.id) })
        }
        item { Spacer(Modifier.navigationBarsPadding()) }
    }
}
```

- Sempre usar `key = { item.id }` em `items()` — preserva estado e melhora performance
- Não criar `LazyColumn` dentro de `Column` com `verticalScroll` — conflito de scroll
- Para grids: `LazyVerticalGrid(columns = GridCells.Adaptive(150.dp))`

---

## Navegação com Compose

> Atualizado (Navigation 2.8+): usar **type-safe navigation** com `@Serializable` — rotas por string estão depreciadas. Alinhado com `domains/android-architecture/SKILL.md`.

```kotlin
@Serializable object HomeRoute
@Serializable data class DetailRoute(val id: Int)

NavHost(navController = rememberNavController(), startDestination = HomeRoute) {
    composable<HomeRoute> { HomeScreen(onNavigate = { id -> navController.navigate(DetailRoute(id)) }) }
    composable<DetailRoute> { backStackEntry ->
        val route: DetailRoute = backStackEntry.toRoute()
        DetailScreen(id = route.id)
    }
}
```

- Requer `kotlinx-serialization-json` nas dependências (ver `languages/gradle/references/dependencies.md`)
- Navegar apenas em lambdas de evento, não em `LaunchedEffect` (exceto para eventos one-shot do ViewModel)
- `NavBackStackEntry` tem seu próprio `viewModelScope`; usar `hiltViewModel()` para escopo correto

---

## Theming e Componentes M3

```kotlin
MaterialTheme(
    colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme,
    typography = AppTypography,
    content = content
)

// Consumo
Text(text = "Título", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary)
```

- Definir `ColorScheme` e `Typography` em arquivos dedicados (`ui/theme/`)
- Preferir tokens do `MaterialTheme` a cores/dimensões hardcoded

> Atualizado (Material3 1.4+): novas APIs disponíveis — `SecureTextField` (campo com proteção de tela), `Text` com autoSize, `SegmentedButton` melhorado. Verificar [developer.android.com/develop/ui/compose/components](https://developer.android.com/develop/ui/compose/components).

---

## Performance

| Problema | Causa | Solução |
|---|---|---|
| Recomposição excessiva | Objeto instável passado como parâmetro | Anotar com `@Stable` ou `@Immutable`; usar `data class` |
| Lambda recriada | Lambda sem `remember` em composable pai | `remember { { ... } }` ou função nomeada — ver nota abaixo |
| Layout lento em lista | Composable pesado sem `key` | Adicionar `key` e extrair composables menores |
| Scroll travado | I/O na composição | Operação assíncrona no ViewModel |

> Atualizado (Kotlin 2.0.20+): **strong skipping mode é default** — o compilador Compose evita recomposição quando lambdas instáveis não mudaram de valor. A prática de extrair lambdas continua válida para clareza, mas a urgência de performance diminuiu.

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/state.md`** | derivedStateOf, snapshotFlow, produceState, rememberCoroutineScope, side effects (LaunchedEffect, SideEffect, DisposableEffect) |
| **`references/performance.md`** | Compiler metrics, @Stable/@Immutable, baseline profiles, Coil, layout inspection |

---

## Também consultar

- `domains/android-architecture/SKILL.md` — ViewModels e StateFlow que alimentam os composables
- `languages/kotlin/SKILL.md` — idioms Kotlin usados em Compose (lambdas, scope functions, coroutines)
