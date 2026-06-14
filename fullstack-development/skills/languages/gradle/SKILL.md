---
name: gradle
description: This skill should be used when configuring Android build scripts, managing dependencies, or setting up build variants. Covers Gradle Kotlin DSL (build.gradle.kts), version catalogs (libs.versions.toml), build types (debug/release), product flavors, signing configuration, and multi-module projects. Use when the user asks to "configure Gradle", "add dependency", "create product flavor", "set up signing", "migrate to Kotlin DSL", "configure version catalog", or "set up multi-module Android project".
---

# Gradle — Build Android com Kotlin DSL

Diretrizes para configuração de projetos Android usando Gradle com Kotlin DSL (`build.gradle.kts`).

---

## Kotlin DSL vs Groovy

| Aspecto | Groovy (`build.gradle`) | Kotlin DSL (`build.gradle.kts`) |
|---|---|---|
| Tipagem | Dinâmica | Estática — erros em tempo de compilação |
| IDE support | Autocomplete limitado | Autocomplete e navegação completos |
| Sintaxe | `implementation "..."` | `implementation("...")` |
| Adoção | Legado | **Recomendado** para projetos novos |

Migração: renomear o arquivo (adicionar `.kts`), converter strings Groovy para chamadas de função, converter chamadas de método para atribuições de propriedade (`debuggable true` → `isDebuggable = true`).

---

## Estrutura do `build.gradle.kts` de Módulo

```kotlin
plugins {
    alias(libs.plugins.android.application)      // via version catalog
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.compose.compiler)         // org.jetbrains.kotlin.plugin.compose (Kotlin 2.0+)
    alias(libs.plugins.ksp)                      // replaces kotlin("kapt")
    alias(libs.plugins.hilt)
}

android {
    namespace = "com.example.app"
    // compileSdk: use the latest installed SDK (36 = Android 16 as of 2025); always the highest available
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 26  // minimum supported Android version (project decision)
        // targetSdk controls which behavior changes apply to the app:
        //   34 = Android 14  |  35 = Android 15  |  36 = Android 16
        // Adjust to the API level of the behavior contract the app targets.
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        debug { isDebuggable = true }
        release {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    // Atualizado (Kotlin 2.0): kotlin { compilerOptions } substitui kotlinOptions { }
    // composeOptions { kotlinCompilerExtensionVersion } was REMOVED — managed by the Compose Compiler Plugin
    kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
    buildFeatures { compose = true }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.compose.ui)
    // ...
}
```

---

## Version Catalog (`libs.versions.toml`)

Centraliza versões no arquivo `gradle/libs.versions.toml` — elimina inconsistências entre módulos.

```toml
[versions]
kotlin  = "2.x"     # verificar versão atual em kotlinlang.org
hilt    = "2.x"
room    = "2.x"
ksp     = "2.x-x.x" # segue versão do Kotlin

[libraries]
androidx-core-ktx  = { group = "androidx.core",        name = "core-ktx"          }  # APIs KTX mescladas em core
compose-ui         = { group = "androidx.compose.ui",  name = "ui"                }
hilt-android       = { group = "com.google.dagger",    name = "hilt-android",       version.ref = "hilt" }
room-runtime       = { group = "androidx.room",        name = "room-runtime",       version.ref = "room" }
room-compiler      = { group = "androidx.room",        name = "room-compiler",      version.ref = "room" }

[plugins]
android-application  = { id = "com.android.application",           version = "8.x" }
kotlin-android       = { id = "org.jetbrains.kotlin.android",       version.ref = "kotlin" }
compose-compiler     = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
ksp                  = { id = "com.google.devtools.ksp",             version.ref = "ksp" }
hilt                 = { id = "com.google.dagger.hilt.android",      version.ref = "hilt" }
```

> Atualizado (Kotlin 2.0): o plugin `compose-compiler` substitui `composeOptions { kotlinCompilerExtensionVersion }`. Não há mais entrada `compose-compiler` em `[versions]` separada — o plugin Compose segue a versão do Kotlin.

Acesso no script: `libs.androidx.core.ktx`, `libs.plugins.hilt`, `libs.versions.kotlin.get()`.

---

## Build Types

```kotlin
buildTypes {
    debug {
        applicationIdSuffix = ".debug"
        isDebuggable = true
        buildConfigField("String", "API_URL", "\"https://api.staging.example.com\"")
    }
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        buildConfigField("String", "API_URL", "\"https://api.example.com\"")
    }
}
buildFeatures { buildConfig = true }
```

---

## Product Flavors

Permitem múltiplas variantes do app (ex.: free/paid, staging/production) com código/recursos distintos.

```kotlin
flavorDimensions += "environment"
productFlavors {
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        buildConfigField("String", "BASE_URL", "\"https://api.staging.example.com\"")
    }
    create("production") {
        dimension = "environment"
        buildConfigField("String", "BASE_URL", "\"https://api.example.com\"")
    }
}
```

Variantes geradas: `stagingDebug`, `stagingRelease`, `productionDebug`, `productionRelease`.

---

## Signing Configuration

```kotlin
signingConfigs {
    create("release") {
        storeFile = file(System.getenv("KEYSTORE_PATH") ?: "keystore/release.jks")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

> Nunca commitar keystore ou senhas no repositório. Usar variáveis de ambiente (CI) ou `local.properties` no `.gitignore`.

---

## Multi-Module

Para projetos modulares, usar `settings.gradle.kts` para incluir módulos e `build-logic/` (Convention Plugins) para compartilhar configurações:

```kotlin
// settings.gradle.kts
include(":app", ":feature:home", ":feature:profile", ":core:network", ":core:database")
```

Padrão de módulos sugerido para projetos médios/grandes: `app`, `feature/*`, `core/*` (network, database, ui). Detalhes em **`references/build-config.md`**.

---

## Anti-Patterns

| Anti-Pattern | Problema | Solução |
|---|---|---|
| Versões hardcoded em `build.gradle.kts` | Inconsistência entre módulos | Version catalog (`libs.versions.toml`) |
| Credenciais de signing no código | Vazar secrets | Variáveis de ambiente ou CI secrets |
| Tudo em módulo único `:app` | Build incremental ineficiente | Modularização por feature/camada |
| Groovy em projeto novo | IDE support fraco, sem tipagem | Migrar para Kotlin DSL |
| `buildTypes.debug.signingConfig = null` sem motivo | App não instala em device | Manter signingConfig padrão para debug |

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/build-config.md`** | Convention Plugins, build-logic/, configuração avançada de módulos, Gradle properties, cache e paralelismo |
| **`references/dependencies.md`** | Configurações de dependência (api vs implementation), BOM, exclusões, substituições, snapshot/local builds |

---

## Também consultar

- `languages/kotlin/SKILL.md` — linguagem usada nos scripts Gradle (Kotlin DSL)
- `domains/android-architecture/SKILL.md` — dependências Jetpack (Room, Hilt, Navigation) configuradas no Gradle
