# Jetpack Components — Referência

## Lifecycle Observers

```kotlin
class AnalyticsObserver(private val analytics: Analytics) : DefaultLifecycleObserver {
    override fun onResume(owner: LifecycleOwner) = analytics.trackScreenView()
    override fun onPause(owner: LifecycleOwner) = analytics.trackScreenExit()
}

// Registro em Fragment
lifecycle.addObserver(AnalyticsObserver(analytics))
```

---

## SavedStateHandle

Preserva estado de ViewModel em morte de processo:

```kotlin
@HiltViewModel
class DetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: ProductRepository
) : ViewModel() {

    // Lido do backstack entry (Navigation)
    private val productId: Int = checkNotNull(savedStateHandle["productId"])

    // Persistido automaticamente
    val searchQuery = savedStateHandle.getStateFlow("query", "")

    fun updateQuery(q: String) { savedStateHandle["query"] = q }
}
```

---

## DataStore (substituto do SharedPreferences)

```kotlin
// Arquivo: di/DataStoreModule.kt
val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

@Module @InstallIn(SingletonComponent::class)
object DataStoreModule {
    @Provides @Singleton
    fun provideDataStore(@ApplicationContext ctx: Context) = ctx.dataStore
}

// Repositório de preferências
class SettingsRepository @Inject constructor(private val dataStore: DataStore<Preferences>) {
    private val THEME_KEY = stringPreferencesKey("theme")

    val themeFlow: Flow<String> = dataStore.data
        .catch { emit(emptyPreferences()) }
        .map { it[THEME_KEY] ?: "system" }

    suspend fun setTheme(theme: String) {
        dataStore.edit { it[THEME_KEY] = theme }
    }
}
```

---

## WorkManager

Para tarefas em background que devem sobreviver a morte do processo:

```kotlin
// Worker
class SyncWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        runCatching { syncRepository.sync() }
            .fold(onSuccess = { Result.success() }, onFailure = { Result.retry() })
    }
}

// Enfileirar
val workRequest = PeriodicWorkRequestBuilder<SyncWorker>(1, TimeUnit.HOURS)
    .setConstraints(Constraints(requiredNetworkType = NetworkType.CONNECTED))
    .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "sync",
    ExistingPeriodicWorkPolicy.KEEP,
    workRequest
)
```

---

## Paging 3

```kotlin
// PagingSource
class ProductPagingSource(private val api: ProductApi) : PagingSource<Int, Product>() {
    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, Product> {
        val page = params.key ?: 1
        return runCatching {
            val response = api.getProducts(page = page, size = params.loadSize)
            LoadResult.Page(
                data = response.items,
                prevKey = if (page == 1) null else page - 1,
                nextKey = if (response.items.isEmpty()) null else page + 1
            )
        }.getOrElse { LoadResult.Error(it) }
    }

    override fun getRefreshKey(state: PagingState<Int, Product>) =
        state.anchorPosition?.let { state.closestPageToPosition(it)?.prevKey?.plus(1) }
}

// ViewModel
val products: Flow<PagingData<Product>> = Pager(PagingConfig(pageSize = 20)) {
    ProductPagingSource(api)
}.flow.cachedIn(viewModelScope)

// Composable
val items = products.collectAsLazyPagingItems()
LazyColumn { items(items) { product -> ProductCard(product ?: return@items) } }
```
