# Room — Referência Detalhada

> Atualizado (Room 2.7+): Room suporta **KMP (Kotlin Multiplatform)** via drivers `androidx.sqlite` KMP-native — o mesmo DAO pode ser compartilhado entre Android, iOS e Desktop. **KSP2** é o processador recomendado (ver `languages/gradle/references/dependencies.md`).

## Migrations

```kotlin
// Incrementar version ao alterar o schema
@Database(entities = [UserEntity::class, ProductEntity::class], version = 2, exportSchema = true)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun productDao(): ProductDao

    companion object {
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE users ADD COLUMN avatar_url TEXT")
            }
        }
    }
}

// Fornecer migrations ao construir o banco
Room.databaseBuilder(context, AppDatabase::class.java, "app.db")
    .addMigrations(AppDatabase.MIGRATION_1_2)
    .build()
```

`exportSchema = true` gera arquivos JSON em `schemas/` — commitar esses arquivos permite auditoria de migrações.

---

## TypeConverters

```kotlin
class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Date? = value?.let { Date(it) }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? = date?.time

    @TypeConverter
    fun fromStringList(value: String?): List<String>? =
        value?.let { Json.decodeFromString<List<String>>(it) }  // kotlinx.serialization.json.Json

    @TypeConverter
    fun toStringList(list: List<String>?): String? = list?.let { Json.encodeToString(it) }
}

// Registrar no banco
@Database(entities = [...], version = 1)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase()
```

---

## Relacionamentos

```kotlin
// One-to-Many
data class UserWithOrders(
    @Embedded val user: UserEntity,
    @Relation(parentColumn = "id", entityColumn = "user_id")
    val orders: List<OrderEntity>
)

@Transaction
@Query("SELECT * FROM users WHERE id = :userId")
suspend fun getUserWithOrders(userId: Int): UserWithOrders?

// Many-to-Many via Junction
@Entity(primaryKeys = ["product_id", "tag_id"])
data class ProductTagCrossRef(val productId: Int, val tagId: Int)

data class ProductWithTags(
    @Embedded val product: ProductEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(ProductTagCrossRef::class, parentColumn = "product_id", entityColumn = "tag_id")
    )
    val tags: List<TagEntity>
)
```

---

## FTS (Full-Text Search)

```kotlin
@Entity(tableName = "products_fts")
@Fts4(contentEntity = ProductEntity::class)
data class ProductFts(val name: String, val description: String)

@Dao
interface ProductDao {
    @Query("SELECT products.* FROM products JOIN products_fts ON products.rowid = products_fts.rowid WHERE products_fts MATCH :query")
    fun search(query: String): Flow<List<ProductEntity>>
}
```

---

## Testes com Banco In-Memory

```kotlin
@RunWith(AndroidJUnit4::class)
class ProductDaoTest {
    private lateinit var db: AppDatabase
    private lateinit var dao: ProductDao

    @Before
    fun setup() {
        db = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).allowMainThreadQueries().build()
        dao = db.productDao()
    }

    @After
    fun teardown() = db.close()

    @Test
    fun insertAndRetrieve() = runTest {
        val product = ProductEntity(id = 1, name = "Widget", price = 9.99)
        dao.upsertAll(listOf(product))
        val result = dao.findById(1)
        assertThat(result?.name).isEqualTo("Widget")
    }
}
```
