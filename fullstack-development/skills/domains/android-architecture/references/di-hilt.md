# Hilt — Referência Detalhada

> **Setup (KSP obrigatório):** Hilt 2.52+ requer KSP — não usar KAPT. Adicionar `alias(libs.plugins.ksp)` e `ksp(libs.hilt.compiler)` no `build.gradle.kts`.
>
> **Alternativas KMP:** para projetos Kotlin Multiplatform, Hilt é Android-only. Alternativas: [Metro](https://github.com/ZacSweers/metro), [kotlin-inject](https://github.com/evant/kotlin-inject). Hilt segue recomendado pelo Google para Android puro.

## Componentes e Escopo

| Componente | Escopo | Vinculado a |
|---|---|---|
| `SingletonComponent` | `@Singleton` | Aplicação inteira |
| `ActivityRetainedComponent` | `@ActivityRetainedScoped` | ViewModel scope |
| `ViewModelComponent` | `@ViewModelScoped` | ViewModel específico |
| `ActivityComponent` | `@ActivityScoped` | Activity |
| `FragmentComponent` | `@FragmentScoped` | Fragment |
| `ServiceComponent` | `@ServiceScoped` | Service |

```kotlin
// Dependência escopada ao ViewModel
@ViewModelScoped
class CartRepository @Inject constructor(private val api: CartApi) {
    // one instance per ViewModel
}

@HiltViewModel
class CartViewModel @Inject constructor(private val repo: CartRepository) : ViewModel()
```

---

## @EntryPoint — Injetar onde Hilt não suporta diretamente

```kotlin
// ContentProvider, BroadcastReceiver sem suporte nativo, ou código legado
@EntryPoint
@InstallIn(SingletonComponent::class)
interface AnalyticsEntryPoint {
    fun analyticsService(): AnalyticsService
}

// Uso em qualquer contexto com ApplicationContext
val entryPoint = EntryPointAccessors.fromApplication(context, AnalyticsEntryPoint::class.java)
val analytics = entryPoint.analyticsService()
```

---

## Qualifiers — Múltiplas Implementações do Mesmo Tipo

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class Authenticated

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class Unauthenticated

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides @Singleton @Authenticated
    fun provideAuthenticatedRetrofit(authInterceptor: AuthInterceptor): Retrofit =
        Retrofit.Builder().addInterceptor(authInterceptor).baseUrl(BuildConfig.BASE_URL).build()

    @Provides @Singleton @Unauthenticated
    fun providePublicRetrofit(): Retrofit =
        Retrofit.Builder().baseUrl(BuildConfig.BASE_URL).build()
}

// Injeção
class ApiRepository @Inject constructor(
    @Authenticated private val authRetrofit: Retrofit,
    @Unauthenticated private val publicRetrofit: Retrofit
)
```

---

## Testando com Hilt

```kotlin
@HiltAndroidTest
class ProductViewModelTest {

    @get:Rule
    val hiltRule = HiltAndroidRule(this)

    @Inject lateinit var repository: ProductRepository  // real or fake via @TestInstallIn

    @Before
    fun setup() = hiltRule.inject()

    @Test
    fun `products load correctly`() = runTest {
        val viewModel = ProductListViewModel(repository)
        viewModel.loadProducts()
        advanceUntilIdle()
        assertThat(viewModel.uiState.value).isInstanceOf(UiState.Success::class.java)
    }
}

// Substituir módulo em testes
@TestInstallIn(components = [SingletonComponent::class], replaces = [NetworkModule::class])
@Module
object FakeNetworkModule {
    @Provides @Singleton
    fun provideFakeRepository(): ProductRepository = FakeProductRepository()
}
```

---

## @Binds vs @Provides

```kotlin
// @Binds — preferir para vincular interface à implementação (mais eficiente)
@Module @InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds @Singleton
    abstract fun bindProductRepo(impl: ProductRepositoryImpl): ProductRepository
}

// @Provides — para instâncias criadas externamente (Retrofit, Room, etc.)
@Module @InstallIn(SingletonComponent::class)
object DatabaseModule {
    @Provides @Singleton
    fun provideDatabase(@ApplicationContext ctx: Context): AppDatabase =
        Room.databaseBuilder(ctx, AppDatabase::class.java, "app.db").build()

    @Provides
    fun provideProductDao(db: AppDatabase): ProductDao = db.productDao()
}
```

> Módulos com `@Binds` devem ser `abstract class`; módulos com `@Provides` devem ser `object`. Não misturar no mesmo arquivo — criar arquivos separados.
