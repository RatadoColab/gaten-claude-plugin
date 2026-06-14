# Jetpack Compose — Performance

## Entendendo Recomposição

Compose recompõe apenas os composables cujo estado lido mudou. O problema surge quando composables instáveis são recompostos desnecessariamente.

```kotlin
// Unstable — Compose does not know UserData is immutable
data class UserData(val name: String, val email: String)

// Stable — explicit annotation
@Immutable
data class UserData(val name: String, val email: String)

// Or @Stable for classes with controlled mutability
@Stable
class CartState(initialItems: List<Item>) {
    var items by mutableStateOf(initialItems)
}
```

---

## Compiler Metrics

> Atualizado (Kotlin 2.0+): o bloco `composeCompiler { }` faz parte do **Compose Compiler Gradle Plugin** (`org.jetbrains.kotlin.plugin.compose`) — não mais de `composeOptions { kotlinCompilerExtensionVersion }`. Adicionar o plugin no `build.gradle.kts` (ver `languages/gradle/SKILL.md`).

Habilitar para inspecionar estabilidade das classes:

```kotlin
// build.gradle.kts — requires alias(libs.plugins.compose.compiler) in the plugins block
composeCompiler {
    reportsDestination = layout.buildDirectory.dir("compose_compiler")
    metricsDestination = layout.buildDirectory.dir("compose_compiler")
}
```

Executar `./gradlew :app:assembleDebug` e checar `build/compose_compiler/app_debug-composables.txt` — linhas marcadas como `restartable skippable` são ideais; `restartable` sem `skippable` indica parâmetros instáveis.

> Atualizado (Kotlin 2.0.20+): **strong skipping mode é default** — lambdas instáveis não disparam recomposição se o valor não mudou. Classes `@Stable`/`@Immutable` ainda são importantes para otimização adicional, mas a urgência diminuiu.

---

## Lambdas e Instabilidade

```kotlin
// Problem: new lambda instance on every parent recomposition
@Composable
fun ProductList(products: List<Product>, viewModel: ProductViewModel) {
    LazyColumn {
        items(products) { product ->
            ProductCard(
                product = product,
                onClick = { viewModel.selectProduct(product.id) }  // new lambda every time
            )
        }
    }
}

// Solution: extract stable lambda
@Composable
fun ProductList(products: List<Product>, onProductClick: (Int) -> Unit) {
    LazyColumn {
        items(products, key = { it.id }) { product ->
            ProductCard(product = product, onClick = { onProductClick(product.id) })
        }
    }
}
// Usage: onProductClick = viewModel::selectProduct (stable reference)
```

---

## Baseline Profiles

Reduz tempo de startup e jank na primeira renderização compilando código AoT:

```kotlin
// build.gradle.kts (:app)
plugins { id("androidx.baselineprofile") }

// build.gradle.kts (:baselineprofile)
plugins { id("androidx.test.screenshot") }

@ExperimentalBaselineProfilesApi
class BaselineProfileGenerator {
    @get:Rule val rule = BaselineProfileRule()

    @Test
    fun generateProfile() = rule.collect("com.example.app") {
        pressHome()
        startActivityAndWait()
        // simulate critical navigation flows
    }
}
```

---

## Shared Element Transitions e LookaheadScope

> Atualizado (Compose 1.8+): **shared element transitions** (`SharedTransitionLayout` + `Modifier.sharedElement`) e **`LookaheadScope`** (layout animado) são estáveis — disponíveis sem API experimental.

```kotlin
SharedTransitionLayout {
    AnimatedContent(targetState = showDetail) { inDetail ->
        if (inDetail) {
            ProductDetail(
                modifier = Modifier.sharedElement(
                    rememberSharedContentState("product-image"),
                    animatedVisibilityScope = this
                )
            )
        } else {
            ProductCard(
                modifier = Modifier.sharedElement(
                    rememberSharedContentState("product-image"),
                    animatedVisibilityScope = this
                )
            )
        }
    }
}
```

---

## Imagens com Coil

> Atualizado (Coil 3): namespace `io.coil-kt.coil3`; suporte KMP; adicionar `coil-network-okhttp` separadamente.

```kotlin
// Dependência: io.coil-kt.coil3:coil-compose + io.coil-kt.coil3:coil-network-okhttp
AsyncImage(
    model = ImageRequest.Builder(LocalContext.current)
        .data(product.imageUrl)
        .crossfade(true)
        .placeholder(R.drawable.placeholder)
        .error(R.drawable.error)
        .build(),
    contentDescription = product.name,
    contentScale = ContentScale.Crop,
    modifier = Modifier.fillMaxWidth().height(200.dp)
)
```

---

## Layout Inspector

Usar o **Compose Layout Inspector** no Android Studio (View > Tool Windows > Layout Inspector):

1. Conectar device/emulator com API 29+
2. Selecionar processo e habilitar Live Updates
3. Inspecionar árvore de composables, contadores de recomposição e highlights em vermelho (alta frequência)

Composables com contador de recomposição alto (destaque vermelho) são candidatos a otimização.

---

## Checklist de Performance

- `key` estável em todos os `items()` de LazyColumn/LazyRow
- `@Immutable`/`@Stable` em data classes de estado de UI
- Lambdas extraídas ou usando referências de método (sem criar lambdas inline no pai)
- `const` em composables sem parâmetros variáveis
- `derivedStateOf` para cálculos custosos derivados de estado
- `AsyncImage` (Coil 3 — `coil3`) para imagens remotas com cache
- Baseline Profile gerado para fluxos críticos
