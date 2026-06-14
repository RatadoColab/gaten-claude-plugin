# Dart Language Tour — Referência Avançada

## Generics

```dart
// Classe genérica
class Repository<T> {
    final Map<int, T> _cache = {};
    T? findById(int id) => _cache[id];
    void save(int id, T item) => _cache[id] = item;
}

// Bounded type parameter
class NumberBox<T extends num> {
    T value;
    NumberBox(this.value);
    T doubled() => (value * 2) as T;
}

// Generic methods
T first<T>(List<T> items) => items.first;
```

---

## Factory Constructors

```dart
class Config {
    final String baseUrl;
    final int timeout;

    // private default constructor
    const Config._({required this.baseUrl, required this.timeout});

    // factory with validation
    factory Config.fromMap(Map<String, dynamic> map) {
        final url = map['base_url'] as String?;
        if (url == null || url.isEmpty) throw ArgumentError('base_url is required');
        return Config._(baseUrl: url, timeout: map['timeout'] as int? ?? 30);
    }

    // singleton via factory
    static Config? _instance;
    factory Config.instance() => _instance ??= Config._(baseUrl: 'https://api.example.com', timeout: 30);
}
```

---

## Mixins com `on` Clause

A cláusula `on` restringe o mixin a uma classe específica ou seus filhos:

```dart
mixin Animatable on State {
    late final AnimationController animController;

    void initAnimation(Duration duration) {
        animController = AnimationController(vsync: this as TickerProvider, duration: duration);
    }

    @override
    void dispose() {
        animController.dispose();
        super.dispose();
    }
}

class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin, Animatable {
    @override
    void initState() {
        super.initState();
        initAnimation(const Duration(milliseconds: 300));
    }
}
```

---

## Sealed Classes (Dart 3+)

```dart
sealed class AuthState {}

class Unauthenticated extends AuthState {}
class Authenticating extends AuthState {}
class Authenticated extends AuthState {
    final User user;
    Authenticated(this.user);
}
class AuthError extends AuthState {
    final String message;
    AuthError(this.message);
}

// switch expression with compiler-checked exhaustiveness
Widget buildAuth(AuthState state) => switch (state) {
    Unauthenticated()   => LoginScreen(),
    Authenticating()    => const LoadingSpinner(),
    Authenticated(:final user) => HomeScreen(user: user),
    AuthError(:final message)  => ErrorScreen(message: message),
};
```

---

## Records (Dart 3+)

Records são tipos de valor anônimos e imutáveis:

```dart
// Declaração e desestruturação
(String name, int age) getUser() => ('Alice', 30);
final (name, age) = getUser();

// Record com campos nomeados
({String city, double lat, double lng}) location() => (city: 'São Paulo', lat: -23.55, lng: -46.63);
final loc = location();
print(loc.city);  // São Paulo

// multiple return values without a dedicated class
(bool success, String message) validate(String email) {
    if (!email.contains('@')) return (false, 'Email inválido');
    return (true, '');
}
```

---

## Pattern Matching (Dart 3+)

```dart
// switch expression with patterns
final result = switch (response.statusCode) {
    200 => Response.success(response.body),
    401 || 403 => Response.unauthorized(),
    >= 500 => Response.serverError(),
    _ => Response.unknown(response.statusCode),
};

// List patterns
final [first, second, ...rest] = items;

// Map patterns
if (json case {'name': String name, 'age': int age}) {
    print('$name has $age years');
}
```

---

## Extension Types (Dart 3.3+)

Wrappers com custo zero em runtime:

```dart
extension type UserId(int value) implements int {
    bool get isValid => value > 0;
}

extension type Email(String value) {
    bool get isValid => value.contains('@');
    String get domain => value.split('@').last;
}

final id = UserId(42);
final email = Email('user@example.com');
print(email.domain);  // example.com
```

---

## Callable Classes

```dart
class Multiplier {
    final int factor;
    const Multiplier(this.factor);

    int call(int value) => value * factor;
}

final triple = Multiplier(3);
print(triple(7));  // 21 — usa call() implicitamente
```

---

## Macros: Descontinuadas

> Atualizado (Dart 2025): o Dart team **cancelou** o recurso de macros em compilação (previsto para Dart 3.x). A funcionalidade foi descontinuada antes da estabilização.

**Alternativas para geração de código:**
- **`build_runner` + `freezed`** — data classes imutáveis, union types, `copyWith` (padrão atual)
- **`json_serializable`** — serialização/desserialização JSON
- **`riverpod_generator`** — geração de providers Riverpod
- **Augmentations** — recurso substituto em desenvolvimento; acompanhar [dart.dev/language/augmentations](https://dart.dev/language/augmentations)
- **Primary constructors** — recurso futuro para reduzir boilerplate de classes

```yaml
# pubspec.yaml — dependências de geração de código
dev_dependencies:
  build_runner: ^x.x      # verificar versão atual em pub.dev
  freezed: ^x.x
  json_serializable: ^x.x
```
