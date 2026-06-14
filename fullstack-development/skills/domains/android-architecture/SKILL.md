---
name: android-architecture
description: This skill should be used when implementing Android app architecture with Jetpack components. Covers ViewModel, StateFlow/SharedFlow, Lifecycle, Navigation Component, dependency injection with Hilt, Repository pattern, and Room persistence. Use when the user asks to "implement ViewModel", "set up Hilt", "configure Room database", "add Navigation component", "implement repository pattern", "set up dependency injection Android", "create DAO", "configure Room entities", or "implement clean architecture Android", or "set up type-safe navigation".
---

# Android Architecture — Jetpack e Clean Architecture

Boas práticas de arquitetura para apps Android com Jetpack, Hilt e Room.

---

## Camadas da Arquitetura

```
ui/
  screens/        ← Composables ou Fragments
  viewmodels/     ← ViewModels (Jetpack)
  components/     ← Composables reutilizáveis
domain/
  usecases/       ← Lógica de negócio (opcional em apps simples)
  models/         ← Entidades de domínio (data classes)
  repositories/   ← Interfaces de repositório
data/
  repositories/   ← Implementações de repositório
  remote/         ← API clients, DTOs, mappers
  local/          ← Room DAOs, entidades, database
  di/             ← Módulos Hilt
```

- UI nunca acessa `data` diretamente — sempre via ViewModel → UseCase (se houver) → Repository
- Entidades de domínio são POKOs (plain Kotlin objects); DTOs e Room entities são mapeados separadamente

---

## ViewModel

```kotlin
@HiltViewModel
class ProductListViewModel @Inject constructor(
    private val getProducts: GetProductsUseCase
) : ViewModel() {

    // Expose immutable StateFlow to UI
    private val _uiState = MutableStateFlow<UiState<List<Product>>>(UiState.Loading)
    val uiState: StateFlow<UiState<List<Product>>> = _uiState.asStateFlow()

    // stateIn — for data-layer flows; avoids re-launching the coroutine per collector
    val products: StateFlow<List<Product>> = getProducts()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init { loadProducts() }

    fun loadProducts() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            getProducts()
                .onSuccess { _uiState.value = UiState.Success(it) }
                .onFailure { _uiState.value = UiState.Error(it.message ?: "Unknown error") }
        }
    }
}
```

- `viewModelScope` cancela automaticamente ao destruir o ViewModel
- Expor apenas `StateFlow` imutável à UI — `MutableStateFlow` permanece privado
- `SharedFlow` para eventos one-shot (navegação, snackbar): `MutableSharedFlow(replay = 0)`

---

## Coletando State no Compose / Fragment

```kotlin
// Compose
val uiState by viewModel.uiState.collectAsStateWithLifecycle()

// Fragment
viewLifecycleOwner.lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.uiState.collect { state -> render(state) }
    }
}
```

> Sempre usar `repeatOnLifecycle(STARTED)` em Fragments — evita coleta em background (app em segundo plano ou tela desligada).

---

## Navigation Component

> Atualizado (Navigation 2.8+): usar **type-safe navigation** com `@Serializable` — rotas por string estão depreciadas. Navigation 3 (experimental) é a direção futura; ver [developer.android.com/guide/navigation/type-safe-destinations](https://developer.android.com/guide/navigation/type-safe-destinations).

```kotlin
// Rotas como data classes serializáveis
@Serializable object ProductListRoute
@Serializable data class ProductDetailRoute(val productId: Int)

// NavHost com type-safe composable<T>()
@Composable
fun AppNavGraph(navController: NavHostController) {
    NavHost(navController, startDestination = ProductListRoute) {
        composable<ProductListRoute> {
            ProductListScreen(onProductClick = { id -> navController.navigate(ProductDetailRoute(id)) })
        }
        composable<ProductDetailRoute> { backStackEntry ->
            val route: ProductDetailRoute = backStackEntry.toRoute()
            ProductDetailScreen(productId = route.productId)
        }
    }
}
```

- Adicionar `kotlinx-serialization-json` nas dependências (ver `languages/gradle/references/dependencies.md`)
- Usar `NavHostController` passado de fora — não criá-lo dentro de composables filhos
- Deep links: definir `deepLinks = [navDeepLink<Route> { uriPattern = "..." }]`

---

## Hilt — Injeção de Dependência

```kotlin
// Módulo de rede
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    // Use kotlinx.serialization — integrates with type-safe navigation and KMP
    @Provides @Singleton
    fun provideRetrofit(): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.BASE_URL)
        .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
        // .addConverterFactory(GsonConverterFactory.create())  // legacy — prefer kotlinx.serialization
        .build()

    @Provides @Singleton
    fun provideProductApi(retrofit: Retrofit): ProductApi = retrofit.create(ProductApi::class.java)
}

// Módulo de repositório
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds @Singleton
    abstract fun bindProductRepository(impl: ProductRepositoryImpl): ProductRepository
}
```

Para configuração avançada (ViewModelComponent, scoped bindings, @EntryPoint, testing), ver **`references/di-hilt.md`**.

---

## Repository Pattern

```kotlin
interface ProductRepository {
    suspend fun getProducts(): Result<List<Product>>
    suspend fun getProduct(id: Int): Result<Product>
}

class ProductRepositoryImpl @Inject constructor(
    private val api: ProductApi,
    private val dao: ProductDao
) : ProductRepository {

    override suspend fun getProducts(): Result<List<Product>> = runCatching {
        val cached = dao.getAll()
        if (cached.isNotEmpty()) return@runCatching cached.toDomain()
        val remote = api.getProducts().map { it.toDomain() }
        dao.insertAll(remote.toEntity())
        remote
    }
}
```

- `runCatching { }` encapsula exceções em `Result<T>` — não expõe exceções raw à UI
- Cache-first strategy acima: fallback para rede se cache vazio

---

## Room — Persistência Local

```kotlin
@Entity(tableName = "products")
data class ProductEntity(
    @PrimaryKey val id: Int,
    val name: String,
    val price: Double,
    val updatedAt: Long = System.currentTimeMillis()
)

@Dao
interface ProductDao {
    @Query("SELECT * FROM products ORDER BY name ASC")
    fun observeAll(): Flow<List<ProductEntity>>  // Flow para reatividade

    @Query("SELECT * FROM products WHERE id = :id")
    suspend fun findById(id: Int): ProductEntity?

    @Upsert
    suspend fun upsertAll(items: List<ProductEntity>)

    @Query("DELETE FROM products")
    suspend fun clear()
}

@Database(entities = [ProductEntity::class], version = 1, exportSchema = true)
abstract class AppDatabase : RoomDatabase() {
    abstract fun productDao(): ProductDao
}
```

- `@Upsert` (Room 2.5+) insere ou atualiza — preferir a `@Insert(onConflict = REPLACE)`
- `exportSchema = true` + `schemas/` no `.gitignore` correto — permite migrações versionadas
- Operações `@Query` suspensas no I/O Dispatcher; `Flow` coletado na UI via `collectAsStateWithLifecycle`

Para migrações (`Migration`), type converters, relações (`@Relation`) e testes com `TestDatabase`, ver **`references/room.md`**.

---

## SDK e Comportamento do Sistema

Os comportamentos do sistema são vinculados ao `targetSdk` declarado no `build.gradle.kts`. Cada nível de API adiciona requisitos; os de nível inferior permanecem válidos.

| Comportamento | Obrigatório a partir de | Detalhes |
|---|---|---|
| **Foreground service types** | **targetSdk 34 (Android 14)** | Declarar `android:foregroundServiceType` no manifest para cada serviço em foreground |
| **`RECEIVER_NOT_EXPORTED`** | **targetSdk 34 (Android 14)** | Todo receiver dinâmico deve passar `RECEIVER_EXPORTED` ou `RECEIVER_NOT_EXPORTED` em `registerReceiver()` |
| **Acesso parcial a mídia** | **API 34** | Permissão `READ_MEDIA_VISUAL_USER_SELECTED` para seleção granular de fotos/vídeos |
| **Edge-to-edge** | **targetSdk 35 (Android 15)** | Obrigatório no 15+; opcional (recomendado) no 14 — ver snippet abaixo |
| **16KB page size** | **Android 15+ (NDK)** | Libs nativas (`.so`) compiladas com alinhamento de 16KB — verificar NDK/dependências |
| **Predictive back default** | **targetSdk 36 (Android 16)** | No 14–15: opt-in via `android:enableOnBackInvokedCallback="true"` no manifest |
| **Java 17+** | — | `sourceCompatibility = JavaVersion.VERSION_17` no Gradle (válido para qualquer targetSdk atual) |

> **Android 14 (API 34):** as mudanças de maior impacto são o `foregroundServiceType` e o flag de `registerReceiver`. Para runtime permissions de mídia, usar `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` (API 33+) e oferecer `READ_MEDIA_VISUAL_USER_SELECTED` como fallback granular. Documentação oficial: [developer.android.com/about/versions/14/behavior-changes-14](https://developer.android.com/about/versions/14/behavior-changes-14).

```kotlin
// Edge-to-edge: obrigatório no targetSdk 35+; recomendado no 34
WindowCompat.setDecorFitsSystemWindows(window, false)
// No Compose — usar Scaffold com contentWindowInsets ou Modifier.safeDrawing
```

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/jetpack.md`** | Lifecycle observers, WorkManager, DataStore, Paging 3, SavedStateHandle |
| **`references/room.md`** | Migrations, TypeConverters, @Relation, @Junction, FTS, testing in-memory |
| **`references/di-hilt.md`** | ViewModelComponent, @EntryPoint, qualifiers, testing with HiltRule, scoped bindings |

---

## Também consultar

- `languages/kotlin/SKILL.md` — null safety, coroutines, sealed classes usadas na arquitetura
- `languages/gradle/SKILL.md` — configurar dependências Jetpack, Hilt e Room no Gradle
- `domains/jetpack-compose/SKILL.md` — UI layer que consome os ViewModels aqui documentados
