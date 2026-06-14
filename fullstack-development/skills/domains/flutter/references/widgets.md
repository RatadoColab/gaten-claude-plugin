# Flutter Widgets — Catálogo e Referência

## Layout Widgets

| Widget | Eixo principal | Uso |
|---|---|---|
| `Column` | Vertical | Empilha filhos verticalmente |
| `Row` | Horizontal | Distribui filhos horizontalmente |
| `Stack` | Z-axis | Sobrepõe filhos |
| `Wrap` | Horizontal/Vertical | Layout que quebra linha |
| `Flow` | Customizado | Layout com posicionamento manual |

```dart
// Alinhamento e espaçamento em Column/Row
Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,  // main axis alignment
    crossAxisAlignment: CrossAxisAlignment.start,       // cross axis alignment
    mainAxisSize: MainAxisSize.min,                     // shrinks to content
    children: [...],
)
```

---

## Constraint Widgets

```dart
// SizedBox — dimensão fixa ou espaçamento
SizedBox(width: 16, height: 16)
SizedBox.expand()     // fills the parent
SizedBox.shrink()     // 0x0, útil como placeholder

// ConstrainedBox — min/max
ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48, maxWidth: 400),
    child: myWidget,
)

// FractionallySizedBox — porcentagem do pai
FractionallySizedBox(widthFactor: 0.8, child: button)

// AspectRatio — proporção fixa
AspectRatio(aspectRatio: 16 / 9, child: videoPlayer)
```

---

## Scroll Widgets

```dart
// ListView.builder — lista eficiente sob demanda
ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ItemTile(item: items[index]),
    separatorBuilder: (context, index) => const Divider(),
)

// GridView.builder
GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
    ),
    itemCount: products.length,
    itemBuilder: (_, i) => ProductCard(product: products[i]),
)

// CustomScrollView com Slivers
CustomScrollView(slivers: [
    SliverAppBar(expandedHeight: 200, flexibleSpace: FlexibleSpaceBar(title: Text('Produtos'))),
    SliverList(delegate: SliverChildBuilderDelegate((_, i) => ItemTile(item: items[i]), childCount: items.length)),
    SliverToBoxAdapter(child: footer),
])
```

---

## Material Widgets (Material3)

> Atualizado (Flutter 3.16+): **Material 3 é o padrão** — `useMaterial3: true` já é o default em novos projetos. Widgets como `FilledButton`, `NavigationBar`, `SearchBar` e `Card` seguem as especificações M3.

```dart
// Card com ação
Card(
    elevation: 2,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
    ),
)

// Dialog
showDialog(
    context: context,
    builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja excluir este item?'),
        actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(onPressed: () { Navigator.pop(context); onConfirm(); }, child: const Text('Excluir')),
        ],
    ),
);

// BottomSheet
showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // allows dynamic sheet height
    builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (_, controller) => FilterPanel(scrollController: controller),
    ),
);
```

---

## Input Widgets

```dart
TextFormField(
    controller: _nameController,
    focusNode: _nameFocus,
    decoration: const InputDecoration(labelText: 'Nome', hintText: 'Digite seu nome'),
    textInputAction: TextInputAction.next,
    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
    validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
    autovalidateMode: AutovalidateMode.onUserInteraction,
)

// Form com validação
Form(
    key: _formKey,
    child: Column(children: [
        TextFormField(validator: validateEmail),
        ElevatedButton(
            onPressed: () { if (_formKey.currentState!.validate()) submit(); },
            child: const Text('Enviar'),
        ),
    ]),
)
```

---

## Animação

> Atualizado (Flutter 3.x — wide gamut): `Color.withOpacity()` está **deprecated** — usar `Color.withValues(alpha: 0.5)`. Os canais agora são `double` (`.r`, `.g`, `.b`, `.a`) em vez de `int`, suportando wide-gamut (Display P3).

```dart
// Before (deprecated): Colors.blue.withOpacity(0.5)
// After:
Colors.blue.withValues(alpha: 0.5)          // opacity via named param
Color(0xFF2196F3).withValues(alpha: 0.8)    // .r/.g/.b/.a are now double

// AnimatedContainer — transição implícita
AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    width: isExpanded ? 300 : 100,
    color: isExpanded ? Colors.blue : Colors.grey.withValues(alpha: 0.5),
    child: content,
)

// AnimatedSwitcher — troca de widget com animação
AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: isLoading
        ? const CircularProgressIndicator(key: ValueKey('loading'))
        : ContentWidget(key: ValueKey('content')),
)

// AnimationController para animações customizadas
late final AnimationController _controller;
late final Animation<double> _opacity;

@override
void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
}
```

---

## Acessibilidade

```dart
Semantics(
    label: 'Adicionar ${product.name} ao carrinho',
    button: true,
    child: IconButton(icon: const Icon(Icons.add_shopping_cart), onPressed: addToCart),
)

// ExcludeSemantics para elementos puramente decorativos
ExcludeSemantics(child: decorativeImage)
```

`MergeSemantics` agrupa semântica de múltiplos filhos em um único nó para leitores de tela.
