# Dart Async — Referência Detalhada

## Isolates e compute()

Dart é single-threaded por padrão; Isolates são threads independentes com memória isolada (sem memória compartilhada).

```dart
// compute() — runs a function in a separate Isolate (ideal for CPU-bound work)
import 'package:flutter/foundation.dart';

Future<List<Product>> parseProductsIsolate(String jsonString) async {
    return compute(_parseProducts, jsonString);
}

// top-level function (cannot be closure or instance method)
List<Product> _parseProducts(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}
```

Para comunicação bidirecional entre Isolates, usar `Isolate.spawn` com `ReceivePort`/`SendPort`.

---

## Future — Operações Combinadas

```dart
// Paralelo — aguarda todos
final results = await Future.wait([
    api.fetchUser(id),
    api.fetchOrders(id),
]);
final user = results[0] as User;
final orders = results[1] as List<Order>;

// Primeiro a completar
final first = await Future.any([primaryApi.fetch(), fallbackApi.fetch()]);

// Com timeout
final data = await api.fetch().timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException('Request timed out'),
);
```

---

## Stream Operators

```dart
final stream = Stream.periodic(const Duration(seconds: 1), (i) => i).take(10);

// Transformações
stream
    .where((n) => n.isEven)
    .map((n) => n * 2)
    .asyncMap((n) async => await process(n))  // async per element
    .listen(print);

// Agrupar com bufferCount (rxdart)
stream.bufferCount(3).listen((batch) => processBatch(batch));
```

---

## StreamController

```dart
// Single-subscription (padrão)
final controller = StreamController<String>();
controller.sink.add('event');
controller.sink.addError(Exception('oops'));
await controller.close();

// Broadcast — múltiplos listeners
final broadcastController = StreamController<String>.broadcast();

// Dispose obrigatório
@override
void dispose() {
    controller.close();
    super.dispose();
}
```

---

## StreamTransformer

```dart
// Transformer customizado — equivalente a operador Rx
final deduplicate = StreamTransformer<String, String>.fromHandlers(
    handleData: (data, sink) {
        if (data != _last) {
            _last = data;
            sink.add(data);
        }
    },
);

final uniqueStream = rawStream.transform(deduplicate);
```

---

## Debounce e Throttle (com rxdart)

```dart
// pubspec.yaml: rxdart (verify current version at pub.dev/packages/rxdart)

import 'package:rxdart/rxdart.dart';

// Debounce — emite só após 300ms sem novos eventos
final searchStream = _searchController.stream
    .debounceTime(const Duration(milliseconds: 300))
    .distinct()
    .switchMap((query) => searchApi.search(query));

// Throttle — emite no máximo 1 vez por intervalo
final scrollStream = _scrollController.stream
    .throttleTime(const Duration(milliseconds: 100));
```

---

## Cancelamento

```dart
StreamSubscription<Event>? _subscription;

void startListening() {
    _subscription = eventStream.listen((event) => handle(event));
}

@override
void dispose() {
    _subscription?.cancel();  // essential — prevents memory leak
    super.dispose();
}
```

Alternativa com `CancelableOperation` (pacote `async`):

```dart
import 'package:async/async.dart';

CancelableOperation<Data>? _operation;

Future<void> load() async {
    _operation?.cancel();
    _operation = CancelableOperation.fromFuture(api.fetchData());
    final data = await _operation!.value;
    setState(() => _data = data);
}
```
