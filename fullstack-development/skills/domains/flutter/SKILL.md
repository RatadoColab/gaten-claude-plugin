---
name: flutter
description: This skill should be used when building Flutter applications. Covers the widget tree, StatelessWidget vs StatefulWidget, state management approaches (Provider, Riverpod, BLoC), navigation with GoRouter, layout fundamentals (Column, Row, Expanded, Stack, SizedBox), async UI with FutureBuilder/StreamBuilder, and Flutter best practices. Use when the user asks to "build Flutter app", "create Flutter widget", "implement state management Flutter", "add navigation Flutter", "use GoRouter", "implement BLoC", "use Riverpod", "implement Provider", "build Flutter screen", or "implement Flutter layout".
---

# Flutter — Desenvolvimento de Apps com Dart

Boas práticas para construção de aplicações Flutter com foco em estrutura, estado e navegação (Flutter 3.x — verificar versão atual em [flutter.dev](https://flutter.dev)).

> **Flutter 3.x — contexto atual:**
> - **Impeller** é o renderizador padrão (iOS sem Skia desde 3.10; Android API 29+ desde 3.22)
> - **Material 3** é o padrão desde Flutter 3.16 — `useMaterial3: true` já é o default
> - Verificar versão atual: `flutter --version`

---

## Widget Tree

Em Flutter, **tudo é widget**. A UI é uma árvore de widgets imutáveis que é reconstruída quando o estado muda.

```dart
class ProductCard extends StatelessWidget {
    const ProductCard({super.key, required this.product, required this.onTap});

    final Product product;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Card(
            child: ListTile(
                title: Text(product.name),
                subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                onTap: onTap,
            ),
        );
    }
}
```

- Widgets com `const` construtores são **reutilizados** pelo framework — sempre usar quando possível
- O parâmetro `key` identifica o widget na árvore — usar `super.key` em todos os widgets customizados
- Extrair widgets reutilizáveis a funções (método `_buildX`) apenas quando não há estado; caso contrário, criar classe

---

## StatelessWidget vs StatefulWidget

| Tipo | Quando usar | Estado |
|---|---|---|
| `StatelessWidget` | Widget sem estado mutável; renderizado a partir de parâmetros externos | Nenhum |
| `StatefulWidget` | Necessita de estado local efêmero (animações, formulários, toggle) | `State<T>` com `setState()` |

```dart
class ExpandableSection extends StatefulWidget {
    const ExpandableSection({super.key, required this.title, required this.child});
    final String title;
    final Widget child;

    @override
    State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
    bool _isExpanded = false;

    @override
    Widget build(BuildContext context) {
        return Column(children: [
            GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(widget.title),
            ),
            if (_isExpanded) widget.child,
        ]);
    }
}
```

> Para estado de negócio compartilhado entre telas, **nunca usar `StatefulWidget`** — usar gerenciador de estado (Provider/Riverpod/BLoC).

---

## Gerenciamento de Estado

Para detalhes de implementação de cada abordagem, ver **`references/state-management.md`**.

| Biblioteca | Curva | Reatividade | Ideal para |
|---|---|---|---|
| **Provider** | Baixa | Boa | ⚠️ **Legado** — projetos existentes; não recomendado para novos |
| **Riverpod** | Média | Excelente | **Default** — apps novos; type-safe, testável, sem BuildContext |
| **BLoC/Cubit** | Alta | Excelente | Enterprise; separação explícita eventos/estados; auditorias |
| **Signals** | Baixa | Excelente | Emergente — reatividade granular, zero boilerplate |

**Regra de escolha:** usar **Riverpod** como default para novos projetos (type-safe, sem BuildContext, codegen `@riverpod`); **BLoC** quando a equipe exige rastreabilidade explícita de eventos.

> Atualizado (2025): Provider é considerado legado para novos projetos não-triviais. Riverpod 3.0 unificou a API (`Ref`, `Notifier`). Ver `references/state-management.md`.

Exemplo mínimo com Riverpod:

```dart
// Provider
final productsProvider = FutureProvider<List<Product>>((ref) async {
    return ref.read(productRepositoryProvider).getAll();
});

// Consumo
class ProductListScreen extends ConsumerWidget {
    const ProductListScreen({super.key});

    @override
    Widget build(BuildContext context, WidgetRef ref) {
        final products = ref.watch(productsProvider);
        return products.when(
            data: (list) => ProductList(products: list),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => ErrorWidget(message: e.toString()),
        );
    }
}
```

---

## Navegação com GoRouter

GoRouter é a solução oficial recomendada pelo Flutter team para apps com deep linking e shell routes.

```dart
final router = GoRouter(
    initialLocation: '/products',
    routes: [
        GoRoute(
            path: '/products',
            builder: (_, __) => const ProductListScreen(),
            routes: [
                GoRoute(
                    path: ':id',
                    builder: (_, state) => ProductDetailScreen(
                        id: int.parse(state.pathParameters['id']!),
                    ),
                ),
            ],
        ),
    ],
);

// Uso
context.go('/products/42');
context.push('/products/42');  // pushes onto the navigation stack
context.pop();
```

Para bottom navigation com **estado preservado por aba**, usar `StatefulShellRoute.indexedStack` (não `ShellRoute`). Redirecionamento com `redirect:`, deep links e typed routes (`go_router_builder`) em **`references/state-management.md`** (seção Navegação).

> Atualizado (go_router 14.x): `StatefulShellRoute.indexedStack` é o padrão para bottom nav; `ShellRoute` simples perde o estado das abas ao trocar.

---

## Layout Fundamentals

```dart
Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
        Text('Título', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Row(children: [
            Expanded(child: PriceTag(price: product.price)),
            IconButton(icon: const Icon(Icons.favorite_border), onPressed: onFavorite),
        ]),
    ],
)
```

| Widget | Uso |
|---|---|
| `Column` / `Row` | Layout linear vertical/horizontal |
| `Expanded` | Ocupa espaço restante no eixo principal |
| `Flexible` | Ocupa espaço proporcional (flex factor) |
| `Stack` | Widgets sobrepostos |
| `SizedBox` | Espaçamento explícito ou dimensão fixa |
| `Padding` | Espaçamento interno |
| `Align` / `Center` | Posicionamento dentro do pai |

Para listas: `ListView.builder` (rolável, itens sob demanda), `GridView.builder` (grade). Catálogo completo em **`references/widgets.md`**.

---

## Async na UI: FutureBuilder e StreamBuilder

```dart
// FutureBuilder — para Future único
FutureBuilder<User>(
    future: userService.fetchUser(id),
    builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return ErrorWidget(message: '${snapshot.error}');
        return UserCard(user: snapshot.requireData);
    },
)

// StreamBuilder — para Stream contínuo
StreamBuilder<List<Message>>(
    stream: chatService.messageStream(roomId),
    builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        return MessageList(messages: messages);
    },
)
```

> Com Riverpod ou BLoC, `FutureBuilder`/`StreamBuilder` raramente são necessários — o gerenciador de estado já expõe estados de loading/error/data.

---

## Anti-Patterns

| Anti-Pattern | Problema | Solução |
|---|---|---|
| Construtor sem `const` em widget imutável | Builds desnecessários | Adicionar `const` |
| `setState` com lógica de negócio | Acopla UI ao domínio | Riverpod/BLoC/Provider |
| Widget gigante (>200 linhas no `build`) | Dificulta manutenção e performance | Extrair sub-widgets em classes |
| `Navigator.push` hardcoded | Sem deep link, sem shell routes | GoRouter |
| `context` após `await` sem verificar `mounted` | Crash se widget desmontado | `if (!context.mounted) return;` |
| `StreamSubscription` sem `cancel()` | Memory leak | Cancelar no `dispose()` |
| `BuildContext` em providers Riverpod | Acopla lógica à UI | Usar `ref.read/watch` |
| `WillPopScope` | **Removido** — não suporta predictive back do Android | `PopScope(canPop: bool, onPopInvokedWithResult: ...)` |

---

## Referências Detalhadas

| Arquivo | Conteúdo |
|---|---|
| **`references/state-management.md`** | Provider detalhado, Riverpod (providers avançados, family, keepAlive/auto-dispose), BLoC/Cubit (events, states, BlocBuilder), GoRouter avançado |
| **`references/widgets.md`** | Catálogo de widgets de layout, constraint, scroll/Sliver, Material 3, input/forms, animação e acessibilidade |

---

## Também consultar

- `languages/dart/SKILL.md` — null safety, async/await, Streams e idioms usados nos widgets e providers
- `languages/gradle/SKILL.md` — configuração do build Android nativo de projetos Flutter
