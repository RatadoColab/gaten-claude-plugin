# Flutter State Management — Referência Detalhada

## Provider

> ⚠️ **Legado para projetos novos.** Provider é adequado para manutenção de apps existentes ou projetos didáticos; para novos projetos não-triviais, preferir **Riverpod** ou **BLoC**. Ver tabela de escolha em `flutter/SKILL.md`.

Solução oficial leve — adequada para apps pequenos/médios:

```dart
// Model com ChangeNotifier
class CartModel extends ChangeNotifier {
    final List<Product> _items = [];
    List<Product> get items => List.unmodifiable(_items);
    int get count => _items.length;

    void add(Product p) {
        _items.add(p);
        notifyListeners();
    }

    void remove(Product p) {
        _items.remove(p);
        notifyListeners();
    }
}

// Registro na raiz
MultiProvider(
    providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        Provider<ProductRepository>(create: (_) => ProductRepositoryImpl()),
    ],
    child: const MyApp(),
)

// Consumo
Consumer<CartModel>(
    builder: (_, cart, __) => Badge(label: Text('${cart.count}')),
)
// Or, to access without triggering a rebuild:
final cart = context.read<CartModel>();
cart.add(product);
```

---

## Riverpod

> Atualizado (Riverpod 3.0): `Ref` e `Notifier` unificados — não há mais distinção entre `ProviderRef`/`WidgetRef` na assinatura dos providers codegen. APIs legadas (`StateNotifierProvider`, `ChangeNotifierProvider`) movidas para `package:riverpod/legacy.dart`. `riverpod_lint` gerencia auto-dispose automaticamente. Guia de migração: [riverpod.dev/docs/3.0_migration](https://riverpod.dev/docs/3.0_migration).

Type-safe, testável, sem dependência de `BuildContext` nos providers:

```dart
// pubspec.yaml: flutter_riverpod, riverpod_annotation, build_runner, riverpod_generator, riverpod_lint

// Repository provider (Riverpod 3.0 — Ref unificado)
@riverpod
ProductRepository productRepository(Ref ref) => ProductRepositoryImpl();

// FutureProvider com família
@riverpod
Future<Product> product(Ref ref, int id) async {
    return ref.read(productRepositoryProvider).findById(id);
}

// Notifier para estado mutável (substitui StateNotifierProvider)
@riverpod
class CartNotifier extends _$CartNotifier {
    @override
    List<CartItem> build() => [];

    void add(Product product) => state = [...state, CartItem(product: product, qty: 1)];
    void remove(int productId) => state = state.where((i) => i.product.id != productId).toList();
}

// ConsumerWidget
class ProductDetailScreen extends ConsumerWidget {
    final int productId;
    const ProductDetailScreen({super.key, required this.productId});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final productAsync = ref.watch(productProvider(productId));
        return productAsync.when(
            data: (p) => ProductView(product: p),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => ErrorView(message: e.toString()),
        );
    }
}
```

Modificadores úteis: `.family` (parâmetros), `ref.invalidate(provider)` (força reload); `riverpod_lint` sugere `keepAlive: true` onde necessário (substitui `.autoDispose` manual).

---

## BLoC / Cubit

> Atualizado (flutter_bloc 9.x): listeners (`BlocListener`, `BlocConsumer`) verificam `context.mounted` automaticamente antes de executar callbacks — não é mais necessário verificar manualmente.

Separação explícita de eventos e estados; rastreabilidade total:

```dart
// pubspec.yaml: flutter_bloc (verificar versão atual em pub.dev)

// Cubit (BLoC simplificado — sem eventos)
class CounterCubit extends Cubit<int> {
    CounterCubit() : super(0);
    void increment() => emit(state + 1);
    void decrement() => emit(state - 1);
}

// BLoC completo com eventos
abstract class ProductEvent {}
class LoadProducts extends ProductEvent {}
class RefreshProducts extends ProductEvent {}

abstract class ProductState {}
class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState { final List<Product> items; ProductLoaded(this.items); }
class ProductError extends ProductState { final String message; ProductError(this.message); }

class ProductBloc extends Bloc<ProductEvent, ProductState> {
    ProductBloc(this._repository) : super(ProductInitial()) {
        on<LoadProducts>(_onLoad);
        on<RefreshProducts>(_onRefresh, transformer: restartable());
    }

    final ProductRepository _repository;

    Future<void> _onLoad(LoadProducts event, Emitter<ProductState> emit) async {
        emit(ProductLoading());
        try {
            final items = await _repository.getAll();
            emit(ProductLoaded(items));
        } catch (e) {
            emit(ProductError(e.toString()));
        }
    }
}

// UI
BlocBuilder<ProductBloc, ProductState>(
    builder: (context, state) => switch (state) {
        ProductLoading()       => const CircularProgressIndicator(),
        ProductLoaded(:final items) => ProductList(items: items),
        ProductError(:final message) => ErrorWidget(message: message),
        _ => const SizedBox.shrink(),
    },
)
```

---

## Navegação com GoRouter (Avançado)

> Atualizado (go_router 14.x): usar **`StatefulShellRoute.indexedStack`** para bottom navigation com **preservação de estado por aba** — `ShellRoute` simples não preserva o estado ao trocar de aba.

```dart
// StatefulShellRoute.indexedStack — estado preservado por aba
final router = GoRouter(
    routes: [
        StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                ScaffoldWithNavBar(navigationShell: navigationShell),
            branches: [
                StatefulShellBranch(routes: [
                    GoRoute(path: '/home',    builder: (_, __) => const HomeScreen()),
                ]),
                StatefulShellBranch(routes: [
                    GoRoute(path: '/search',  builder: (_, __) => const SearchScreen()),
                ]),
                StatefulShellBranch(routes: [
                    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
                ]),
            ],
        ),
    ],
);

// ScaffoldWithNavBar — trocar aba via navigationShell.goBranch(index)
class ScaffoldWithNavBar extends StatelessWidget {
    final StatefulNavigationShell navigationShell;
    const ScaffoldWithNavBar({super.key, required this.navigationShell});

    @override
    Widget build(BuildContext context) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(i,
                initialLocation: i == navigationShell.currentIndex),
            destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
            ],
        ),
    );
}

// Redirecionamento baseado em autenticação
redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = ref.read(authProvider).isAuthenticated;
    final isOnLogin = state.matchedLocation == '/login';
    if (!isLoggedIn && !isOnLogin) return '/login';
    if (isLoggedIn && isOnLogin) return '/home';
    return null;  // no redirect
},

// Deep links — configurar no AndroidManifest e Info.plist
GoRoute(
    path: '/product/:id',
    builder: (_, state) => ProductScreen(id: state.pathParameters['id']!),
),
```
