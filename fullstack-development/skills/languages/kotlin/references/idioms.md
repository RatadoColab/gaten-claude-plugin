# Kotlin Idioms Avançados — Referência

## Delegated Properties

```kotlin
// Standard library delegates
val lazyValue: String by lazy { expensiveComputation() }   // computed on first access
var observed: String by Delegates.observable("initial") { prop, old, new ->
    println("$old → $new")
}

// Custom delegate
class Prefs(context: Context) {
    private val prefs = context.getSharedPreferences("app", Context.MODE_PRIVATE)

    var theme: String by object : ReadWriteProperty<Any?, String> {
        override fun getValue(thisRef: Any?, property: KProperty<*>) =
            prefs.getString(property.name, "light") ?: "light"
        override fun setValue(thisRef: Any?, property: KProperty<*>, value: String) =
            prefs.edit().putString(property.name, value).apply()
    }
}
```

---

## Object Declarations e Companion Objects

```kotlin
// Singleton
object NetworkConfig {
    const val BASE_URL = "https://api.example.com"
    const val TIMEOUT_SECONDS = 30L
}

// Companion object — static members + factory
class User private constructor(val id: Long, val name: String) {
    companion object {
        fun create(name: String): User {
            require(name.isNotBlank()) { "Name cannot be blank" }
            return User(id = generateId(), name = name.trim())
        }
    }
}
val user = User.create("Ana")
```

---

## Inline Functions e Reified Generics

```kotlin
// inline avoids lambda overhead and allows non-local returns
inline fun measureTime(block: () -> Unit): Long {
    val start = System.currentTimeMillis()
    block()
    return System.currentTimeMillis() - start
}

// reified — access generic type at runtime (only in inline functions)
inline fun <reified T> parseJson(json: String): T = Gson().fromJson(json, T::class.java)
inline fun <reified T : Activity> Context.startActivity() {
    startActivity(Intent(this, T::class.java))
}

val user: User = parseJson(jsonString)
startActivity<DetailActivity>()
```

---

## DSL Builders

```kotlin
// Builder with receiver lambdas
class HtmlBuilder {
    private val sb = StringBuilder()
    fun div(content: HtmlBuilder.() -> Unit) { sb.append("<div>"); content(); sb.append("</div>") }
    fun p(text: String) { sb.append("<p>$text</p>") }
    fun build(): String = sb.toString()
}

fun html(init: HtmlBuilder.() -> Unit): String = HtmlBuilder().apply(init).build()

val page = html {
    div {
        p("Hello, Kotlin!")
    }
}
```

---

## Destructuring e Component Functions

```kotlin
// Data class automatically generates component functions
val (id, name, email) = user

// In loops
val map = mapOf("a" to 1, "b" to 2)
for ((key, value) in map) { println("$key = $value") }

// Custom component functions
operator fun Response.component1() = statusCode
operator fun Response.component2() = body
val (code, body) = response
```

---

## Contratos (contracts)

```kotlin
// Informs the compiler about post-conditions (experimental — requires opt-in)
@OptIn(ExperimentalContracts::class)
fun requireAuthenticated(user: User?) {
    contract { returns() implies (user != null) }  // must be the first statement in the function
    if (user == null) throw UnauthorizedException()
}

fun process(user: User?) {
    requireAuthenticated(user)
    user.doSomething()  // compiler knows user is non-null here
}
```

**Context Parameters** (Kotlin 2.x — substitui context receivers experimentais):

```kotlin
// Declares a context dependency with an explicit parameter name (Kotlin 2.x)
context(logger: Logger)
fun processOrder(order: Order) {
    logger.log("Processing ${order.id}")  // access via named context parameter
    // ...
}

// Calling requires Logger in scope
with(logger) { processOrder(order) }
```

> Atualizado (Kotlin 2.x): context parameters usam nome explícito (`context(logger: Logger)`) — diferente dos context receivers experimentais (1.6.20) onde o tipo era suficiente sem nome. Chamadas ainda usam `with(value) { }`.

---

## Outras Funções Úteis da stdlib

```kotlin
// Quick measurement
val elapsed = measureTimeMillis { heavyTask() }

// Repetition
repeat(3) { i -> println("Attempt $i") }

// check and require — preconditions with message
require(age >= 0) { "Age must be non-negative, got $age" }
check(isInitialized) { "Call init() first" }
error("Unreachable state")  // throws IllegalStateException

// takeIf and takeUnless
val result = value.takeIf { it > 0 }   // returns value or null
val name = input.takeUnless { it.isBlank() }

// stable UUID (Kotlin 2.x — no external dependency needed)
val id: kotlin.uuid.Uuid = kotlin.uuid.Uuid.random()
val fromString = kotlin.uuid.Uuid.parse("550e8400-e29b-41d4-a716-446655440000")
```

> Atualizado (Kotlin 2.x): `kotlin.uuid.Uuid` é estável na stdlib — não requer `java.util.UUID` nem dependências externas.
