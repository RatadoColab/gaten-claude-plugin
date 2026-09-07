---
name: vue
description: This skill should be used when writing, reviewing, or refactoring Vue.js components or applications. Covers Vue 3 Composition API with <script setup>, reactivity system (ref, reactive, computed, watch), component design (props, emits, slots, expose), the <script setup> macros (defineModel, defineSlots, defineOptions), reactive props destructure, composition utilities (useTemplateRef, useId, onWatcherCleanup), Pinia state management, Vue Router, performance optimization (v-memo, shallowRef, keep-alive, defineAsyncComponent, lazy hydration), and Vue-specific best practices. Use when the user asks to "write a Vue component", "review Vue code", "create a composable", "usar defineModel", "criar v-model customizado", "useTemplateRef", "gerar id acessível no Vue", "desestruturar props", "hidratação lazy", "set up Pinia", "configure Vue Router", "optimize Vue performance", or "migrate from Options API".
---

# Vue.js 3 — Convenções e Boas Práticas

Diretrizes para desenvolvimento com Vue 3, priorizando `<script setup>` com TypeScript e Composition API.

**Versões de referência:** Vue **3.5.x** (estável), Pinia **4.x**, Vue Router **5.x**. Os padrões abaixo assumem 3.5 — recursos por versão estão marcados no texto. Vapor Mode / alien-signals (Vue 3.6, ainda em RC) tratados como horizonte em [`references/performance.md`](references/performance.md); não gerar código Vapor por padrão.

---

## `<script setup>` — Padrão Obrigatório

`<script setup>` é a sintaxe recomendada para todos os componentes Vue 3: sem `return {}` (tudo no escopo é exposto ao template), melhor inferência TypeScript, melhor performance em runtime e menos boilerplate que `defineComponent()`.

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

// Reactive props destructure (3.5+): defaults nativos do JS
const { title, count = 0 } = defineProps<{ title: string; count?: number }>()
const emit = defineEmits<{ change: [value: number] }>()
const localCount = ref(count)   // local seed; does not re-sync if the prop changes
const doubled = computed(() => localCount.value * 2)
</script>
```

> Nunca misturar `<script setup>` com Options API (`data()`, `methods`, `computed` como objeto). São mutuamente exclusivos. Exemplo completo de componente (props, emits, lifecycle, template) em `references/components.md`.
>
> Ao passar uma prop desestruturada para uma função que espera reatividade (composable, `watch`), envolver em getter: `useFoo(() => count)`. `withDefaults` segue suportado e não-deprecado — a destructure é o padrão recomendado para defaults; ver `references/components.md`.

---

## Macros de `<script setup>`

Macros são compiladas — não precisam de `import`. Disponíveis apenas dentro de `<script setup>`.

| Macro | Papel | Desde |
|---|---|---|
| `defineProps` | Declara props (com destructure reativa e defaults nativos em 3.5+) | 3.0 / destructure 3.5 |
| `defineEmits` | Declara eventos emitidos, tipados com payload | 3.0 |
| `defineModel` | Declara prop + evento `update:*` de um `v-model` numa única ref gravável | 3.4 |
| `defineSlots` | Tipagem dos slots (nomes e props de scoped slots) | 3.3 |
| `defineOptions` | Define `name`, `inheritAttrs` etc. sem sair do `<script setup>` | 3.3 |
| `defineExpose` | Expõe seletivamente métodos/estado ao parent via template ref | 3.0 |

> Assinaturas, `defineModel` com model nomeado e modificadores, e `defineSlots` tipado em **`references/components.md`**.

---

## Sistema de Reatividade

| API | Quando usar | Mutação | Acesso no template |
|---|---|---|---|
| `ref(value)` | Primitivos, arrays, quando precisar reatribuir | `.value = novo` | Direto: `{{ count }}` |
| `reactive(obj)` | Objetos complexos que nunca serão reatribuídos | Mutação direta | Direto: `{{ obj.name }}` |
| `computed(() => ...)` | Valores derivados de estado reativo | Somente leitura (padrão) | Direto: `{{ fullName }}` |
| `shallowRef(value)` | Objetos grandes onde só a referência muda | `.value = novo` | Direto: `{{ data }}` |

> **Nunca desestruturar `reactive()` diretamente** — perde a reatividade; usar `toRefs()` ou `ref()`. Exemplos comparativos e `watch` vs `watchEffect` em `references/composition-api.md`.

### Utilitários de composição (3.5+)

| API | Uso |
|---|---|
| `useTemplateRef('nome')` | Template ref por string — casa com `ref="nome"`, funciona em composables e com refs dinâmicas |
| `useId()` | ID único e estável entre SSR e cliente — para `label[for]`, `aria-describedby`, `aria-controls` |
| `onWatcherCleanup(fn)` | Registra cleanup dentro de um `watch`/`watchEffect` — chamada **síncrona**, antes de qualquer `await` |
| `watch(...)` → `WatchHandle` | Retorno é a função de parada, com `.pause()` / `.resume()` / `.stop()` — pausa e retoma um watcher sem recriá-lo |

> Exemplos em `references/composition-api.md` (watchers) e `references/components.md` (`useTemplateRef`, `useId`).

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
| Virtual scrolling | Listas com 500+ itens renderizados simultaneamente |

Exemplos de cada técnica, profiling e checklist pré-deploy em **`references/performance.md`**.

---

## Anti-Patterns

| Padrão Ruim | Padrão Vue 3 Correto |
|---|---|
| Options API em projetos novos | `<script setup>` com Composition API |
| `v-if` + `v-for` no mesmo elemento | `v-if` em `<template>` pai ou propriedade computada filtrada |
| Mutação direta de props | `defineModel()` para `v-model`; senão estado local inicializado da prop |
| `modelValue` + `emit('update:modelValue')` escritos à mão | `const model = defineModel()` (3.4+) |
| Misturar `withDefaults` e destructure de props no mesmo projeto | Padronizar num só — a destructure com defaults nativos é a recomendada em 3.5+ (`withDefaults` não é erro) |
| Desestruturar `reactive()` | `toRefs(obj)` ou usar `ref()` direto |
| `reactive()` para primitivos | `ref()` para strings, numbers, booleans |
| `watch` sem cleanup | `onWatcherCleanup(fn)` no callback (síncrono, antes do `await`) ou o argumento `onCleanup` do `watchEffect` |
| Acesso direto ao DOM sem `ref` | `const el = useTemplateRef('el')` casado com `ref="el"` (3.5+) |
| `ref()` casada por nome (`ref="inputRef"` + `const inputRef = ref()`) | `useTemplateRef('inputRef')` |
| `id` fixo ou `Math.random()` em `label[for]` / `aria-describedby` | `useId()` |
| Store monolítica única | Múltiplas stores por domínio (auth, cart, ui) |
| `router.push` com string concatenada | `router.push({ name: 'route-name', params: { id } })` |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/composition-api.md`** | ref vs reactive, computed gravável, watch vs watchEffect, `onWatcherCleanup`, `WatchHandle`, lifecycle, provide/inject, composables reutilizáveis |
| **`references/components.md`** | props destructure vs `withDefaults`, `defineModel` (model nomeado, modificadores), `defineSlots`, `useTemplateRef`, `useId`, slots, expose, Teleport (`defer`) |
| **`references/state-management.md`** | Pinia 4 (ESM-only), setup/option stores, getters, actions assíncronas, storeToRefs, persistência, testing |
| **`references/routing.md`** | Vue Router 5, createRouter, rotas dinâmicas, nested routes, guards, lazy loading, roteamento por arquivos, Data Loaders, route meta tipado |
| **`references/performance.md`** | v-memo, shallowRef, markRaw, keep-alive, virtual scrolling, lazy hydration (SSR), profiling, checklist, horizonte Vue 3.6 (Vapor Mode) |

---

## Também Consultar

- `languages/javascript/SKILL.md` — práticas JS/TS gerais aplicáveis em componentes Vue
- `domains/ui-components/SKILL.md` — design de componentes, acessibilidade e design system
