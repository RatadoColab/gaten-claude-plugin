# Vue 3 — Performance: Referência Completa

---

## Visão Geral das Técnicas

| Técnica | Custo de implementação | Ganho típico | Quando aplicar |
|---|---|---|---|
| `v-memo` | Baixo | Alto em listas grandes | Listas com subárvores complexas e dependências estáveis |
| `shallowRef` / `shallowReactive` | Baixo | Médio | Objetos grandes com dados internos que não precisam ser reativos |
| `markRaw` | Baixo | Médio | Instâncias de bibliotecas externas (charts, mapas, editores) |
| `defineAsyncComponent` | Baixo | Alto (bundle size) | Componentes pesados não usados na rota inicial |
| `<keep-alive>` | Baixo | Alto (evita remontagem) | Tabs, wizards, rotas com custo alto de inicialização |
| `v-show` em vez de `v-if` | Trivial | Baixo-médio | Elementos com toggle frequente (dropdowns, painéis) |
| Virtual scrolling | Alto | Muito alto | Listas com 500+ itens renderizados simultaneamente |
| Computed em vez de methods | Trivial | Baixo | Qualquer valor derivado lido no template |

---

## v-memo

Memoriza a renderização de uma subárvore do template. Só re-renderiza quando as dependências listadas mudam.

```vue
<template>
  <!-- Without v-memo: entire row re-renders on any parent state change -->
  <!-- With v-memo: row only re-renders when item or isSelected changes -->
  <div
    v-for="item in largeList"
    :key="item.id"
    v-memo="[item.id, item.updatedAt, isSelected(item.id)]"
  >
    <ItemRow :item="item" :selected="isSelected(item.id)" />
  </div>
</template>
```

> `v-memo="[]"` (array vazio) congela a subárvore completamente — equivale a `v-once`.

**Quando NÃO usar:** listas pequenas (< 100 itens) ou quando os dados mudam frequentemente — o overhead de comparação pode superar o ganho.

---

## shallowRef e shallowReactive

```ts
import { shallowRef, shallowReactive, triggerRef } from 'vue'

// shallowRef: apenas a referência raiz é reativa
// Mutações internas NÃO disparam updates
const bigDataset = shallowRef<Row[]>([])

// Correto: substituir a referência inteira
bigDataset.value = await fetchRows()

// Mutação interna NÃO é detectada automaticamente
bigDataset.value.push(newRow)      // NÃO dispara update
triggerRef(bigDataset)             // necessário para forçar update após mutação interna

// shallowReactive: apenas o primeiro nível é reativo
const state = shallowReactive({
  users:   [] as User[],     // reativo (primeiro nível)
  config:  {} as Config,     // reativo (primeiro nível)
})

state.users = newUsers  // trigger (primeiro nível)
state.users.push(user)  // NÃO é trigger (nível interno)
```

---

## markRaw

```ts
import { ref, shallowRef, markRaw } from 'vue'
import { Chart }  from 'chart.js'
import mapboxgl   from 'mapbox-gl'

// markRaw: impede Vue de tornar o objeto reativo
// Sem markRaw: Vue tenta tornar instâncias de Chart/Map reativas (muito lento)
const chart = shallowRef(markRaw(new Chart(canvas, config)))
const map   = shallowRef(markRaw(new mapboxgl.Map({ container: 'map' })))

// Também útil para dados grandes que são somente leitura
const staticReferenceData = markRaw(hugeJsonImport)

// Pattern: store class instances safely
const editors = ref<Record<string, unknown>>({})
editors.value[id] = markRaw(new QuillEditor(element))
```

---

## defineAsyncComponent

```ts
import { defineAsyncComponent } from 'vue'

// Basic: component is only downloaded when first rendered
const RichTextEditor = defineAsyncComponent(
  () => import('./RichTextEditor.vue')
)

// With full options
const HeavyDashboard = defineAsyncComponent({
  // the loader function
  loader: () => import('./HeavyDashboard.vue'),

  // shown while loading
  loadingComponent: LoadingSpinner,

  // shown on error
  errorComponent: ErrorMessage,

  // delay before showing loading (prevents flash on fast connections)
  delay: 200,

  // timeout before showing error
  timeout: 10_000,

  // suspend: use with <Suspense> instead of loadingComponent
  suspensible: true,
})
```

```vue
<!-- In router config: lazy load entire route views -->
{
  path:      '/reports',
  component: () => import('@/views/ReportsView.vue'),
}

<!-- In template: lazy load heavy component within a view -->
<template>
  <Suspense>
    <template #default>
      <HeavyDashboard />
    </template>
    <template #fallback>
      <LoadingSpinner />
    </template>
  </Suspense>
</template>
```

---

## keep-alive

Mantém a instância do componente em memória ao invés de destruí-la quando desmontada.

```vue
<template>
  <!-- Cache all tab components — avoids re-fetching on tab switch -->
  <keep-alive>
    <component :is="activeTabComponent" />
  </keep-alive>

  <!-- Cache only specific components by name -->
  <keep-alive include="UserList,ProductList" :max="5">
    <RouterView />
  </keep-alive>

  <!-- Exclude from cache -->
  <keep-alive exclude="CheckoutForm">
    <component :is="currentView" />
  </keep-alive>
</template>
```

```vue
<!-- Component that uses keep-alive lifecycle hooks -->
<script setup lang="ts">
import { onActivated, onDeactivated } from 'vue'

// Called when component is re-shown from cache (not re-mounted)
onActivated(() => {
  // refresh data that may have changed while component was cached
  refreshData()
})

// Called when component is hidden but stays in cache
onDeactivated(() => {
  // pause non-essential operations
  pausePolling()
})
</script>
```

---

## v-show vs v-if

```vue
<template>
  <!-- v-show: element stays in DOM, only CSS display changes -->
  <!-- Use for: frequent toggling (dropdowns, accordions, tabs) -->
  <Dropdown v-show="isOpen" />

  <!-- v-if: element is created/destroyed from DOM -->
  <!-- Use for: rarely-changed conditions, conditional rendering of heavy trees -->
  <AdminPanel v-if="user.isAdmin" />

  <!-- Anti-pattern: v-if + v-for on same element -->
  <!-- BAD: v-if evaluated on every iteration -->
  <li v-for="item in items" v-if="item.active" :key="item.id">...</li>

  <!-- GOOD: filter in computed, or wrap with template -->
  <template v-for="item in activeItems" :key="item.id">
    <li>{{ item.name }}</li>
  </template>
</template>

<script setup lang="ts">
// Computed filter is cached — only recalculates when items change
const activeItems = computed(() => items.value.filter(i => i.active))
</script>
```

---

## Virtual Scrolling

Para listas com 500+ itens, renderizar apenas os elementos visíveis no viewport.

```bash
# Biblioteca recomendada
npm install vue-virtual-scroller
```

```vue
<script setup lang="ts">
import { RecycleScroller } from 'vue-virtual-scroller'
import 'vue-virtual-scroller/dist/vue-virtual-scroller.css'

// Large list — only renders visible items
const allItems = ref<Item[]>([])
</script>

<template>
  <!-- RecycleScroller renders only items visible in the viewport -->
  <RecycleScroller
    class="scroller"
    :items="allItems"
    :item-size="64"
    key-field="id"
    v-slot="{ item }"
  >
    <ItemRow :item="item" />
  </RecycleScroller>
</template>

<style scoped>
.scroller { height: 600px; overflow-y: auto; }
</style>
```

**Alternativas:** `@tanstack/vue-virtual` para controle mais granular.

---

## Profiling

### Vue DevTools

1. Instalar extensão Vue DevTools no browser
2. Aba **Performance** → gravar interação → inspecionar tempo de render por componente
3. Componentes que aparecem frequentemente com tempo alto são candidatos a otimização

### Vite Bundle Analysis

```bash
# Analyze bundle composition
npm run build -- --mode analyze
npx vite-bundle-visualizer
```

Procurar por:
- Dependências grandes não-lazy (devem estar em chunks separados)
- Código duplicado entre chunks
- Componentes que deveriam usar `defineAsyncComponent`

### Performance API (runtime)

```ts
// Measure component render time in development
if (import.meta.env.DEV) {
  const app = createApp(App)
  app.config.performance = true  // enables browser performance marks
}
```

---

## Checklist de Performance Pré-Deploy

- [ ] Todas as rotas usam lazy loading (`() => import(...)`)
- [ ] Componentes pesados usam `defineAsyncComponent`
- [ ] Tabs e wizards usam `<keep-alive>`
- [ ] Listas com mais de 200 itens usam virtual scrolling
- [ ] Instâncias de bibliotecas externas envolvidas em `markRaw`
- [ ] Objetos grandes sem necessidade de reatividade profunda usam `shallowRef`
- [ ] Nenhum `v-if` combinado com `v-for` no mesmo elemento
- [ ] Valores derivados no template são `computed`, não `methods`
- [ ] `v-memo` aplicado em listas de renderização complexa
- [ ] Bundle analisado e sem dependências grandes no chunk principal
