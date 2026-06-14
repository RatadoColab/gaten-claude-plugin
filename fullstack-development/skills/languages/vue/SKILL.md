---
name: vue
description: This skill should be used when writing, reviewing, or refactoring Vue.js components or applications. Covers Vue 3 Composition API with <script setup>, reactivity system (ref, reactive, computed, watch), component design (props, emits, slots, expose), Pinia state management, Vue Router, performance optimization (v-memo, shallowRef, keep-alive, defineAsyncComponent), and Vue-specific best practices. Use when the user asks to "write a Vue component", "review Vue code", "create a composable", "set up Pinia", "configure Vue Router", "optimize Vue performance", or "migrate from Options API".
---

# Vue.js 3 — Convenções e Boas Práticas

Diretrizes para desenvolvimento com Vue 3, priorizando `<script setup>` com TypeScript e Composition API.

---

## `<script setup>` — Padrão Obrigatório

`<script setup>` é a sintaxe recomendada para todos os componentes Vue 3: sem `return {}` (tudo no escopo é exposto ao template), melhor inferência TypeScript, melhor performance em runtime e menos boilerplate que `defineComponent()`.

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{ title: string; count?: number }>()
const emit = defineEmits<{ change: [value: number] }>()
const localCount = ref(props.count ?? 0)
const doubled = computed(() => localCount.value * 2)
</script>
```

> Nunca misturar `<script setup>` com Options API (`data()`, `methods`, `computed` como objeto). São mutuamente exclusivos. Exemplo completo de componente (props, emits, lifecycle, template) em `references/components.md`.

---

## Sistema de Reatividade

| API | Quando usar | Mutação | Acesso no template |
|---|---|---|---|
| `ref(value)` | Primitivos, arrays, quando precisar reatribuir | `.value = novo` | Direto: `{{ count }}` |
| `reactive(obj)` | Objetos complexos que nunca serão reatribuídos | Mutação direta | Direto: `{{ obj.name }}` |
| `computed(() => ...)` | Valores derivados de estado reativo | Somente leitura (padrão) | Direto: `{{ fullName }}` |
| `shallowRef(value)` | Objetos grandes onde só a referência muda | `.value = novo` | Direto: `{{ data }}` |

> **Nunca desestruturar `reactive()` diretamente** — perde a reatividade; usar `toRefs()` ou `ref()`. Exemplos comparativos e `watch` vs `watchEffect` em `references/composition-api.md`.

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

**Nunca usar `v-if` e `v-for` no mesmo elemento** — mover o `v-if` para um `<template>` pai ou filtrar via computed. `v-show` para toggle frequente; `v-if` para condições estáveis.

---

## Ciclo de Vida

| Hook | Momento | Casos de uso típicos |
|---|---|---|
| `onBeforeMount` | Antes do DOM ser criado | Raramente necessário |
| `onMounted` | DOM criado e acessível | Fetch inicial, refs de DOM, bibliotecas externas |
| `onBeforeUpdate` | Antes do patch reativo | Capturar estado do DOM antes da atualização |
| `onUpdated` | Após o patch reativo | Atualizar biblioteca externa após mudança |
| `onBeforeUnmount` | Antes de destruir o componente | Cancelar timers, remover listeners |
| `onUnmounted` | Componente destruído | Liberar recursos, WebSocket, observers |
| `onErrorCaptured` | Erro em componente filho | Logging, fallback de UI |

Exemplos de uso (fetch em `onMounted`, cleanup em `onBeforeUnmount`) em `references/composition-api.md` (§Lifecycle Hooks).

---

## Composables

Composables são funções reutilizáveis que encapsulam lógica com estado reativo. Convenção: prefixo `use`.

**Regras:**
- Só podem ser chamados dentro de `setup()` ou `<script setup>`
- Podem chamar outros composables
- Retornar sempre refs (não valores brutos) para manter reatividade ao desestruturar

```ts
// Desestruturação mantém reatividade porque o composable retorna refs
const { count, increment, reset } = useCounter(0)
const { data, loading, error } = useFetch<User[]>('/api/users')
```

Para implementação e padrões completos de composables (fetch, formulário, localStorage, paginação), consultar **`references/composition-api.md`**.

---

## Pinia — Estado Global

Pinia é a solução oficial de state management para Vue 3.

**Quando usar Store vs Composable:**
- Composable: estado local a um componente ou árvore de componentes
- Pinia Store: estado compartilhado entre rotas/componentes não relacionados

Preferir **Setup Stores** (função com `ref`/`computed`/actions retornados) — mais flexíveis e com melhor suporte a TypeScript que Option Stores. Ao consumir: **`storeToRefs(store)` para desestruturar estado/getters sem perder reatividade**; actions podem ser desestruturadas diretamente.

Implementações completas (setup/option stores, persistência, testing) em **`references/state-management.md`**.

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

Exemplos de cada técnica, profiling e checklist pré-deploy em **`references/performance.md`**.

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
| **`references/composition-api.md`** | ref vs reactive, computed gravável, watch vs watchEffect, lifecycle, provide/inject, composables reutilizáveis |
| **`references/components.md`** | defineProps/defineEmits tipados, v-model customizado, slots, expose, defineAsyncComponent, Teleport |
| **`references/state-management.md`** | Pinia setup/option stores, getters, actions assíncronas, storeToRefs, persistência, testing |
| **`references/routing.md`** | createRouter, rotas dinâmicas, nested routes, guards, lazy loading, route meta tipado |
| **`references/performance.md`** | v-memo, shallowRef, markRaw, keep-alive, virtual scrolling, profiling, checklist |

---

## Também Consultar

- `languages/javascript/SKILL.md` — práticas JS/TS gerais aplicáveis em componentes Vue
- `domains/ui-components/SKILL.md` — design de componentes, acessibilidade e design system
