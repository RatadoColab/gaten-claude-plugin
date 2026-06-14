# Gradle Build Config — Referência Avançada

## Convention Plugins (build-logic/)

Para projetos multi-módulo, usar Convention Plugins elimina a duplicação de configuração:

```
root/
├── build-logic/
│   ├── build.gradle.kts            ← configura o includedBuild
│   └── src/main/kotlin/
│       ├── AndroidLibraryConventionPlugin.kt
│       └── ComposeConventionPlugin.kt
├── app/
│   └── build.gradle.kts            ← aplica convenções
├── feature/home/
│   └── build.gradle.kts
└── core/network/
    └── build.gradle.kts
```

```kotlin
// build-logic/src/main/kotlin/AndroidLibraryConventionPlugin.kt
class AndroidLibraryConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            with(pluginManager) {
                apply("com.android.library")
                apply("org.jetbrains.kotlin.android")
            }
            extensions.configure<LibraryExtension> {
                compileSdk = 36
                defaultConfig.minSdk = 26
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
    }
}

// Registro no settings.gradle.kts do build-logic
gradlePlugin {
    plugins {
        register("androidLibrary") {
            id = "convention.android.library"
            implementationClass = "AndroidLibraryConventionPlugin"
        }
    }
}

// Uso em feature/home/build.gradle.kts
plugins {
    id("convention.android.library")
}
```

---

## Gradle Properties

```properties
# gradle.properties — afeta todo o build
org.gradle.jvmargs=-Xmx4g -XX:+UseParallelGC
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configuration-cache=true

android.useAndroidX=true
kotlin.code.style=official
```

Propriedades sensíveis devem ir em `local.properties` (no `.gitignore`):

```properties
# local.properties
sdk.dir=/Users/you/Library/Android/sdk
KEYSTORE_PASSWORD=secretpassword
```

Leitura no script:

```kotlin
val localProps = Properties().apply {
    load(rootProject.file("local.properties").inputStream())
}
val keystorePassword = localProps["KEYSTORE_PASSWORD"] as? String ?: System.getenv("KEYSTORE_PASSWORD")
```

---

## Cache e Performance

- `--build-cache`: reutiliza outputs de builds anteriores (local e remoto)
- `--parallel`: compila módulos independentes em paralelo
- `--configuration-cache`: cacheia a fase de configuração — **estável e recomendado no Gradle 9** (não mais experimental)
- Usar `api` vs `implementation` corretamente evita recompilação desnecessária de dependentes

> Atualizado (Gradle 9): configuration cache deixou de ser experimental. Ativar com `org.gradle.configuration-cache=true` em `gradle.properties`.

---

## Estrutura Multi-Módulo Sugerida

```
:app                          ← módulo de aplicação (compõe features)
:feature:home                 ← feature module (ViewModel, UI, DI)
:feature:profile
:core:network                 ← Retrofit, OkHttp, interceptors
:core:database                ← Room, DAOs, migrations
:core:ui                      ← design tokens, componentes base
:core:domain                  ← entidades, interfaces de repositório (sem Android deps)
:core:testing                 ← fakes, test utilities
```

Cada `:feature` depende de `:core:domain` e `:core:ui`; nunca de outra `:feature`.

---

## Gradle Tasks Úteis

```bash
# Listar tarefas disponíveis
./gradlew tasks --all

# Build de variante específica
./gradlew :app:assembleStagingDebug

# Instalar no device
./gradlew :app:installStagingDebug

# Rodar testes
./gradlew :app:testStagingDebugUnitTest

# Ver árvore de dependências de um módulo
./gradlew :core:network:dependencies --configuration releaseRuntimeClasspath

# Limpar cache
./gradlew clean
```
