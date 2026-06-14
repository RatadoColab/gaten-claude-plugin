# Gradle Dependencies — Referência

## Configurações de Dependência

| Configuração | Visibilidade | Quando usar |
|---|---|---|
| `implementation` | Interna ao módulo | Padrão — dependência não vazada para módulos dependentes |
| `api` | Exposta ao consumidor | Somente quando o tipo aparece na API pública do módulo |
| `compileOnly` | Apenas compilação | Anotações processadas em compile time (Room, Hilt) |
| `kapt` / `ksp` | Annotation processing | `kapt` legacy; `ksp` (Kotlin Symbol Processing) preferido |
| `testImplementation` | Apenas testes unitários | JUnit, Mockk, coroutines-test |
| `androidTestImplementation` | Testes instrumentados | Espresso, Compose UI tests, HiltRule |
| `debugImplementation` | Apenas debug | LeakCanary, Flipper |

---

## BOM (Bill of Materials)

BOM garante versões compatíveis entre artefatos de uma mesma família:

```kotlin
dependencies {
    // Compose BOM — pins all Compose artifact versions
    val composeBom = platform(libs.compose.bom)
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")             // no explicit version needed
    implementation("androidx.compose.material3:material3")

    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
}
```

---

## Exclusões e Substituições

```kotlin
// Exclude conflicting transitive dependency
implementation("com.example:library:1.0") {
    exclude(group = "com.conflicting", module = "old-module")
}

// Force a specific version of a transitive dependency
configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:2.x")  // verify current Kotlin 2.x version
    }
}
```

---

## KSP vs KAPT

Preferir **KSP** (Kotlin Symbol Processing) sobre KAPT — KAPT está em **deprecação**:
- KSP é 2–3× mais rápido que KAPT; sem geração de stubs Java
- **KSP2** (estável): compatível com K2, ainda mais rápido; ativar com `ksp.useKSP2=true` em `gradle.properties`
- Suportado por Room 2.7+, Hilt 2.52+, Moshi, Glide

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.ksp)  // version tied to the Kotlin version in the version catalog
}

dependencies {
    ksp(libs.room.compiler)   // was: kapt(libs.room.compiler)
    ksp(libs.hilt.compiler)
}
```

> Atualizado (KSP2): adicionar `ksp.useKSP2=true` no `gradle.properties` para ativar o processador de segunda geração (compatível com K2/Kotlin 2.x).

---

## Dependências Locais

```kotlin
// Arquivo AAR local
implementation(files("libs/my-library.aar"))

// Módulo local
implementation(project(":core:network"))

// Maven local (~/.m2)
repositories { mavenLocal() }
implementation("com.example:local-lib:SNAPSHOT")
```

---

## Dependências Comuns Android (versões de referência)

> Verificar sempre a versão atual no [AndroidX Releases](https://developer.android.com/jetpack/androidx/versions) ou [Maven Central](https://search.maven.org).

```toml
# libs.versions.toml — majors atuais (verificar minor/patch em androix releases)
[versions]
kotlin        = "2.x"    # kotlinlang.org/docs/releases
lifecycle     = "2.x"
room          = "2.x"    # Room 2.7+ suporta KMP
hilt          = "2.x"
compose-bom   = "2025.x" # developer.android.com/develop/ui/compose/bom
navigation    = "2.x"    # type-safe navigation desde 2.8
retrofit      = "3.x"    # breaking: namespace com.squareup.retrofit3; suspend nativo
okhttp        = "5.x"    # breaking: algumas APIs renomeadas
coil          = "3.x"    # breaking: namespace coil3; suporte KMP
coroutines    = "1.x"
serialization = "1.x"    # kotlinx.serialization — recomendado com type-safe nav

[libraries]
# Nota: core-ktx — APIs KTX foram mescladas em androidx.core:core; core-ktx continua funcionando
core-ktx                = { group = "androidx.core",              name = "core-ktx"                                        }
lifecycle-viewmodel     = { group = "androidx.lifecycle",         name = "lifecycle-viewmodel-ktx",   version.ref = "lifecycle" }
lifecycle-runtime       = { group = "androidx.lifecycle",         name = "lifecycle-runtime-ktx",     version.ref = "lifecycle" }
room-runtime            = { group = "androidx.room",              name = "room-runtime",              version.ref = "room" }
room-ktx                = { group = "androidx.room",              name = "room-ktx",                  version.ref = "room" }
room-compiler           = { group = "androidx.room",              name = "room-compiler",             version.ref = "room" }
hilt-android            = { group = "com.google.dagger",          name = "hilt-android",              version.ref = "hilt" }
hilt-compiler           = { group = "com.google.dagger",          name = "hilt-android-compiler",     version.ref = "hilt" }
navigation-compose      = { group = "androidx.navigation",        name = "navigation-compose",        version.ref = "navigation" }
# Atualizado (Retrofit 3): namespace com.squareup.retrofit3; suspend nativo sem CoroutineCallAdapterFactory
retrofit                = { group = "com.squareup.retrofit3",     name = "retrofit",                  version.ref = "retrofit" }
# Recomendado: kotlinx-serialization em vez de converter-gson (combina com type-safe nav e KMP)
retrofit-serialization  = { group = "com.squareup.retrofit3",     name = "converter-kotlinx-serialization", version.ref = "retrofit" }
okhttp-logging          = { group = "com.squareup.okhttp3",       name = "logging-interceptor",       version.ref = "okhttp" }
# Atualizado (Coil 3): namespace coil3; suporte KMP; AsyncImage mantém a mesma API
coil-compose            = { group = "io.coil-kt.coil3",           name = "coil-compose",              version.ref = "coil" }
coil-network-okhttp     = { group = "io.coil-kt.coil3",           name = "coil-network-okhttp",       version.ref = "coil" }
coroutines-android      = { group = "org.jetbrains.kotlinx",      name = "kotlinx-coroutines-android",version.ref = "coroutines" }
coroutines-test         = { group = "org.jetbrains.kotlinx",      name = "kotlinx-coroutines-test",   version.ref = "coroutines" }
kotlinx-serialization   = { group = "org.jetbrains.kotlinx",      name = "kotlinx-serialization-json",version.ref = "serialization" }
```

**Breaking changes nas atualizações de major:**

| Biblioteca | Breaking Change |
|---|---|
| Coil 2→3 | Namespace `io.coil-kt` → `io.coil-kt.coil3`; `ImageLoader` API ajustada; requer `coil-network-okhttp` |
| Retrofit 2→3 | Namespace `com.squareup.retrofit2` → `com.squareup.retrofit3`; `suspend` nativo (sem `CoroutineCallAdapterFactory`) |
| OkHttp 4→5 | Algumas APIs renomeadas; Java 8 mínimo |
