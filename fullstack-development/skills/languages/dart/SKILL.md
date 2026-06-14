---
name: dart
description: This skill should be used when writing, reviewing, or refactoring Dart code for Flutter applications. Covers Dart null safety, sound type system, async/await, Futures, Streams, classes, mixins, extensions, and idiomatic Dart patterns. Use when the user asks to "write Dart", "review Dart code", "implement async in Dart", "use mixin", "add extension", "implement Stream", "handle Future", or "refactor to idiomatic Dart".
---

# Dart — Convenções e Boas Práticas para Flutter

Diretrizes para escrita de Dart idiomático com foco em desenvolvimento Flutter (Dart 3.x, null safety obrigatório).

---

## Null Safety

O sistema de null safety do Dart é **sound** — o compilador garante ausência de `null` em tipos não-anuláveis.

| Sintaxe | Significado |
|---|---|
| `String name` | Nunca `null` — obrigatório ter valor |
| `String? name` | Pode ser `null` |
| `name!` | Assert non-null — lança se `null` em runtime |
| `name ?? 'default'` | Fallback se `null` |
| `name?.length` | Acesso seguro — `null` se `name` for `null` |
| `late String name` | Não-nullable, inicializado tardiamente (antes do primeiro acesso) |

```dart
String greet(String? name) => 'Hello, ${name ?? 'Guest'}';
```

> `late` é útil para injeção ou inicialização em `initState()`; garantir que seja inicializado antes do uso ou haverá `LateInitializationError`.

---

## Sistema de Tipos

Dart usa tipagem estática com inferência de tipos:

```dart
var count = 0;        // inferred int
final name = 'Ana';   // inferred String, non-reassignable
const pi = 3.14159;   // double, compile-time constant

// explicit typing preferred in public APIs
int add(int a, int b) => a + b;
```

| Keyword | Mutabilidade | Avaliação |
|---|---|---|
| `var` | Reatribuível | Runtime |
| `final` | Não-reatribuível (binding) | Runtime |
| `const` | Imutável profundo | Compile-time |

Preferir `final` para variáveis locais que não mudam; `const` para constantes e widgets sem estado.

---

## Classes, Mixins e Extensions

**Classes** em Dart suportam herança simples; `abstract class` define contratos.

```dart
abstract class Repository<T> {
    Future<T> findById(int id);
    Future<List<T>> findAll();
}
```

**Mixins** compartilham comportamento sem herança:

```dart
mixin Loggable {
    void log(String msg) => print('[${runtimeType}] $msg');
}

class UserService with Loggable {
    Future<void> create(User user) async {
        log('Creating user ${user.id}');
        // ...
    }
}
```

**Extensions** adicionam métodos a tipos existentes:

```dart
extension StringUtils on String {
    String toTitleCase() => split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    bool get isValidEmail => contains('@') && contains('.');
}
```

Para mixins avançados (`on` clause), factory constructors e classes genéricas, ver **`references/language-tour.md`**.

---

## Async / Await e Futures

```dart
// Future — valor único assíncrono
Future<User> fetchUser(int id) async {
    final response = await http.get(Uri.parse('/users/$id'));
    if (response.statusCode != 200) throw ApiException(response.statusCode);
    return User.fromJson(jsonDecode(response.body));
}

// Tratar erros com try/catch
Future<void> loadUser(int id) async {
    try {
        final user = await fetchUser(id);
        state = UiState.success(user);
    } on ApiException catch (e) {
        state = UiState.error('Erro ${e.statusCode}');
    }
}
```

> Nunca deixar `Future` sem `await` ou `.then/.catchError` — erros silenciosos são a causa mais comum de bugs assíncronos em Dart.

Combinadores comuns:

| API | Uso |
|---|---|
| `Future.wait([f1, f2])` | Aguardar múltiplos Futures em paralelo |
| `Future.any([f1, f2])` | Primeiro Future a completar |
| `Future.delayed(duration, fn)` | Delay com valor |

---

## Streams

Streams emitem múltiplos valores ao longo do tempo (equivalente ao `Flow` do Kotlin).

```dart
// Stream simples com async*
Stream<int> countdown(int from) async* {
    for (var i = from; i >= 0; i--) {
        yield i;
        await Future.delayed(const Duration(seconds: 1));
    }
}

// StreamController para broadcast manual
final _controller = StreamController<String>.broadcast();
Stream<String> get events => _controller.stream;
void emit(String event) => _controller.add(event);
```

- **Single-subscription** (padrão): um único listener; adequado para leituras de arquivo, HTTP.
- **Broadcast**: múltiplos listeners; adequado para eventos de UI e notificações.
- Cancelar `StreamSubscription.cancel()` no `dispose()` do widget para evitar memory leaks.

Para operadores de Stream (`map`, `where`, `asyncMap`, `debounce`) e StreamTransformer, ver **`references/async.md`**.

---

## Coleções

```dart
final names = ['Alice', 'Bob', 'Carol'];

final upper = names.map((n) => n.toUpperCase()).toList();
final long  = names.where((n) => n.length > 3).toList();
final total = [1, 2, 3].fold(0, (acc, n) => acc + n);

// Spread e collection-if
final items = [
    ...baseItems,
    if (isAdmin) adminItem,
    for (var tag in tags) TagWidget(tag),
];
```

`List`, `Set` e `Map` possuem equivalentes imutáveis: `List.unmodifiable`, `Map.unmodifiable`. Preferir imutabilidade para objetos de estado.

---

## Anti-Patterns

| Anti-Pattern | Problema | Padrão Dart correto |
|---|---|---|
| `name!` indiscriminado | `LateInitializationError`/`Null check operator` em runtime | `??`, `?.` ou tratamento explícito de null |
| `dynamic` em código novo | Perde benefícios do null safety e tipagem | Tipos explícitos ou genéricos |
| `var` em APIs públicas | Reduz legibilidade e type safety | Tipos explícitos em assinaturas |
| `Future` sem await nem `.then` | Erros silenciosos | `await` + `try/catch` |

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/async.md`** | Isolates, compute(), Stream operators, StreamTransformer, debounce/throttle, cancelamento |
| **`references/language-tour.md`** | Generics, factory constructors, mixins com `on`, sealed classes (Dart 3), records, patterns |

---

## Também consultar

- `domains/flutter/SKILL.md` — uso de Dart no contexto Flutter (widgets, state, build method)
