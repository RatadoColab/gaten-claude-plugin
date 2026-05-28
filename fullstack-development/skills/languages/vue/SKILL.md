---
name: vue
description: This skill should be used when writing, reviewing, or refactoring Vue.js components or applications. Covers Vue 3 Composition API with <script setup>, reactivity system (ref, reactive, computed, watch), component design (props, emits, slots, expose), Pinia state management, Vue Router, performance optimization (v-memo, shallowRef, keep-alive, defineAsyncComponent), and Vue-specific best practices. Use when the user asks to "write a Vue component", "review Vue code", "create a composable", "set up Pinia", "configure Vue Router", "optimize Vue performance", or "migrate from Options API".
version: 0.2.0
---

# Vue.js 3 — Convenções e Boas Práticas

Diretrizes para desenvolvimento com Vue 3, priorizando `<script setup>` com TypeScript e Composition API.

---

## `<script setup>` — Padrão Obrigatório

`<script setup>` é a sintaxe recomendada para todos os componentes Vue 3. Vantagens:

- Sem `return {}` — tudo declarado no escopo é automaticamente exposto ao template
- Melhor suporte a TypeScript (inferência direta de tipos)
- Melhor performance em runtime (compilado de forma mais eficiente)
- Menor boilerplate comparado a `defineComponent()`

```vue
<script setup lang="ts">
// Imports diretos — sem necessidade de registrar em components: {}
import { ref, computed, onMounted } from 'vue'
import MyButton from './MyButton.vue'

// Props tipadas com TypeScript genérico
const props = defineProps<{
  title: string
  count?: number
}>()

// Emits tipados
const emit = defineEmits<{
  change: [value: number]
  close: []
}>()

// Estado reativo
const localCount = ref(props.count ?? 0)

// Valor derivado com cache
const doubled = computed(() => localCount.value * 2)

// Lifecycle hook
onMounted(() => {
  // initialization after DOM is mounted
})
</script>

<template>
  <div>
    <h1>{{ title }}</h1>
    <MyButton @click="emit('change', localCount)">
      {{ doubled }}
    </MyButton>
  </div>
</template>
```

> Nunca misturar `<script setup>` com Options API (`data()`, `methods`, `computed` como objeto). São mutuamente exclusivos.

---

## Sistema de Reatividade

| API | Quando usar | Mutação | Acesso no template |
|---|---|---|---|
| `ref(value)` | Primitivos, arrays, quando precisar reatribuir | `.value = novo` | Direto: `{{ count }}` |
| `reactive(obj)` | Objetos complexos que nunca serão reatribuídos | Mutação direta | Direto: `{{ obj.name }}` |
| `computed(() => ...)` | Valores derivados de estado reativo | Somente leitura (padrão) | Direto: `{{ fullName }}` |
| `shallowRef(value)` | Objetos grandes onde só a referência muda | `.value = novo` | Direto: `{{ data }}` |

```vue
<script setup lang="ts">
import { ref, reactive, computed, shallowRef } from 'vue'

// ref: primitivo ou quando reatribuição é necessária
const count = ref(0)
count.value++

// reactive: objeto — NUNCA desestruturar diretamente
const form = reactive({ name: '', email: '' })
form.name = 'João'  // reativo
// const { name } = form  // perde reatividade!

// computed: cache automático, só recalcula quando dependências mudam
const summary = computed(() => `${form.name} — ${count.value} itens`)

// shallowRef: apenas a referência raiz é reativa (ideal para listas grandes)
const rows = shallowRef<Row[]>([])
rows.value = await fetchRows()  // trigger de reatividade
</script>
```

---

## Template Directives

| Diretiva | Uso | Exemplo |
|---|---|---|
| `v-bind` / `:` | Bind dinâmico de atributo/prop | `:class="{ active: isActive }"` |
| `v-on` / `@` | Listener de evento | `@click="handler"` |
| `v-model` | Two-way binding | `v-model="name"` |
| `v-if` / `v-else-if` / `v-else` | Renderização condicional (desmonta o nó) | `v-if="isLogged"` |
| `v-show` | Visibilidade (mantém o nó no DOM) | `v-show="isVisible"` |
| `v-for` + `:key` | Renderização de lista | `v-for="item in items" :key="item.id"` |
| `v-slot` | Slot nomeado / scoped slot | `v-slot:header` ou `#header` |
| `v-memo` | Memoriza subárvore do template | `v-memo="[dep1, dep2]"` |
| `v-pre` | Ignora compilação Vue (exibir `{{ }}` literal) | `v-pre` |

```vue
<template>
  <!-- NUNCA usar v-if e v-for no mesmo elemento -->
  <!-- Correto: v-if no elemento pai ou usar <template> -->
  <template v-if="items.length">
    <ul>
      <li v-for="item in items" :key="item.id">
        {{ item.name }}
      </li>
    </ul>
  </template>

  <!-- v-show para toggle frequente; v-if para condições estáveis -->
  <Spinner v-show="loading" />
</template>
```

---

## Ciclo de Vida

Hooks disponíveis no Composition API (equivalentes ao Options API entre parênteses):

| Hook | Momento | Casos de uso típicos |
|---|---|---|
| `onBeforeMount` | Antes do DOM ser criado | Raramente necessário |
| `onMounted` | DOM criado e acessível | Fetch inicial, refs de DOM, bibliotecas externas |
| `onBeforeUpdate` | Antes do patch reativo | Capturar estado do DOM antes da atualização |
| `onUpdated` | Após o patch reativo | Atualizar biblioteca externa após mudança |
| `onBeforeUnmount` | Antes de destruir o componente | Cancelar timers, remover listeners |
| `onUnmounted` | Componente destruído | Liberar recursos, WebSocket, observers |
| `onErrorCaptured` | Erro em componente filho | Logging, fallback de UI |

```vue
<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'

const data = ref<Item[]>([])
let intervalId: ReturnType<typeof setInterval>

onMounted(async () => {
  // DOM is available here
  data.value = await fetchItems()
  intervalId = setInterval(refreshData, 30_000)
})

onBeforeUnmount(() => {
  // cleanup before component is destroyed
  clearInterval(intervalId)
})
</script>
```

---

## Composables

Composables são funções reutilizáveis que encapsulam lógica com estado reativo. Convenção: prefixo `use`.

**Regras:**
- Só podem ser chamados dentro de `setup()` ou `<script setup>`
- Podem chamar outros composables
- Retornar sempre refs (não valores brutos) para manter reatividade ao desestruturar

```vue
<script setup lang="ts">
// Composable encapsula lógica reutilizável
import { useCounter } from '@/composables/useCounter'
import { useFetch } from '@/composables/useFetch'

// Desestruturação mantém reatividade porque composable retorna refs
const { count, increment, reset } = useCounter(0)
const { data, loading, error } = useFetch<User[]>('/api/users')
</script>
```

```ts
// composables/useCounter.ts
import { ref } from 'vue'

// Composable: function prefixed with "use", returns reactive state
export function useCounter(initialValue = 0) {
  const count = ref(initialValue)

  function increment() { count.value++ }
  function decrement() { count.value-- }
  function reset()     { count.value = initialValue }

  return { count, increment, decrement, reset }
}
```

Para padrões completos de composables (fetch, formulário, localStorage, paginação), consultar **`references/composition-api.md`**.

---

## Pinia — Estado Global

Pinia é a solução oficial de state management para Vue 3.

**Quando usar Store vs Composable:**
- Composable: estado local a um componente ou árvore de componentes
- Pinia Store: estado compartilhado entre rotas/componentes não relacionados

**Setup Store** (padrão preferido — mais flexível e com melhor suporte a TypeScript):

```ts
// stores/useProductStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useProductStore = defineStore('product', () => {
  // state
  const items = ref<Product[]>([])
  const loading = ref(false)

  // getter (computed)
  const total = computed(() => items.value.length)

  // action
  async function fetchAll() {
    loading.value = true
    try {
      items.value = await api.getProducts()
    } finally {
      loading.value = false
    }
  }

  return { items, loading, total, fetchAll }
})
```

```vue
<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useProductStore } from '@/stores/useProductStore'

const store = useProductStore()

// storeToRefs preserva reatividade ao desestruturar
const { items, loading, total } = storeToRefs(store)

// actions não precisam de storeToRefs
store.fetchAll()
</script>
```

Para setup stores, option stores, persistência e testing, consultar **`references/state-management.md`**.

---

## Performance

| Técnica | Quando aplicar |
|---|---|
| `v-memo="[dep]"` | Listas com muitos itens onde subárvores raramente mudam |
| `shallowRef` / `shallowReactive` | Objetos grandes onde só a referência raiz precisa ser reativa |
| `markRaw(obj)` | Instâncias de classes externas (Chart.js, mapas) que não devem ser rastreadas |
| `defineAsyncComponent` | Componentes pesados carregados sob demanda (lazy loading) |
| `<keep-alive>` | Componentes com custo alto de inicialização trocados frequentemente |
| `v-show` em vez de `v-if` | Elementos que alternam com frequência alta |
| Virtual scrolling | Listas com 1000+ itens renderizados simultaneamente |

```vue
<script setup lang="ts">
import { defineAsyncComponent, markRaw, shallowRef } from 'vue'

// Lazy load: component is only loaded when first rendered
const HeavyChart = defineAsyncComponent(() => import('./HeavyChart.vue'))

// markRaw: prevents Vue from making the object reactive
const mapInstance = shallowRef(markRaw(new ExternalMap()))
</script>

<template>
  <!-- keep-alive caches component instances between route switches -->
  <keep-alive>
    <component :is="activeTab" />
  </keep-alive>

  <Suspense>
    <HeavyChart :data="chartData" />
    <template #fallback>
      <Spinner />
    </template>
  </Suspense>
</template>
```

Para análise detalhada de cada técnica, profiling e checklist pré-deploy, consultar **`references/performance.md`**.

---

## Anti-Patterns

| Padrão Ruim | Padrão Vue 3 Correto |
|---|---|
| Options API em projetos novos | `<script setup>` com Composition API |
| `v-if` + `v-for` no mesmo elemento | `v-if` em `<template>` pai ou propriedade computada filtrada |
| Mutação direta de props | `emit('update:modelValue', valor)` ou estado local inicializado da prop |
| Desestruturar `reactive()` | `toRefs(obj)` ou usar `ref()` direto |
| `reactive()` para primitivos | `ref()` para strings, numbers, booleans |
| `watch` sem cleanup | Usar `watchEffect` com return de cleanup ou `onWatcherCleanup` |
| Acesso direto ao DOM sem `ref` | Template ref com `const el = ref<HTMLElement>()` |
| Store monolítica única | Múltiplas stores por domínio (auth, cart, ui) |
| `router.push` com string concatenada | `router.push({ name: 'route-name', params: { id } })` |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/composition-api.md`** | ref vs reactive, computed gravável, watch vs watchEffect, provide/inject, composables reutilizáveis |
| **`references/components.md`** | defineProps/defineEmits tipados, v-model customizado, slots, expose, defineAsyncComponent, Teleport |
| **`references/state-management.md`** | Pinia setup/option stores, getters, actions assíncronas, storeToRefs, persistência, testing |
| **`references/routing.md`** | createRouter, rotas dinâmicas, nested routes, guards, lazy loading, route meta tipado |
| **`references/performance.md`** | v-memo, shallowRef, markRaw, keep-alive, virtual scrolling, profiling, checklist |

---

## Também Consultar

- `languages/javascript/SKILL.md` — práticas JS/TS gerais aplicáveis em componentes Vue
- `domains/ui-components/SKILL.md` — design de componentes, acessibilidade e design system
