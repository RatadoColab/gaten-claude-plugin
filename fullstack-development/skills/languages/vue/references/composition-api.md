# Vue 3 — Composition API: Referência Completa

---

## ref vs reactive

| Critério | `ref` | `reactive` |
|---|---|---|
| Tipos suportados | Qualquer valor | Apenas objetos e arrays |
| Acesso no script | `.value` obrigatório | Direto (`obj.name`) |
| Acesso no template | Automático (sem `.value`) | Direto |
| Reatribuição | `ref.value = novo` | Não pode reatribuir o objeto raiz |
| Desestruturação | Segura | Perde reatividade — usar `toRefs()` |
| Quando preferir | Primitivos; quando reatribuição é necessária | Objetos de formulário, state complexo |

```ts
import { ref, reactive, toRefs } from 'vue'

// ref: primitivos e quando reatribuição é necessária
const count = ref(0); count.value++
const list  = ref<string[]>([]); list.value = ['a', 'b']  // safe reassignment

// reactive: objetos com múltiplos campos relacionados
const form = reactive({ username: '', email: '', age: 0 })
form.username = 'João'  // direct mutation

// toRefs: safe destructuring — username remains linked to form
const { username, email } = toRefs(form)
username.value = 'Maria'  // form.username also updates
```

---

## computed

```ts
import { ref, computed } from 'vue'

const firstName = ref('João')
const lastName  = ref('Silva')

// Getter puro: somente leitura, avaliação lazy com cache
const fullName = computed(() => `${firstName.value} ${lastName.value}`)

// Computed gravável (get + set)
const displayName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (value: string) => {
    const [first, ...rest] = value.split(' ')
    firstName.value = first
    lastName.value  = rest.join(' ')
  },
})

// Uso do computed gravável
displayName.value = 'Maria Oliveira'
// firstName.value => 'Maria', lastName.value => 'Oliveira'
```

> `computed` só recalcula quando suas dependências reativas mudam. Nunca coloque efeitos colaterais (fetch, emit) dentro de computed.

---

## watch vs watchEffect

| Critério | `watch` | `watchEffect` |
|---|---|---|
| Dependências | Explícitas (1º argumento) | Automáticas (rastreadas na execução) |
| Execução inicial | Lazy (não roda na montagem) | Eager (roda imediatamente) |
| Acesso a oldValue | Sim (3º argumento do callback) | Não |
| Caso de uso | Reagir a mudança específica, comparar antes/depois | Sincronizar efeitos com múltiplas dependências |

```ts
import { ref, watch, watchEffect } from 'vue'

const userId = ref(1)
const userData = ref<User | null>(null)

// watch: explícito, lazy, tem oldValue
watch(userId, async (newId, oldId) => {
  // only runs when userId changes
  if (newId !== oldId) {
    userData.value = await fetchUser(newId)
  }
}, { immediate: true })  // immediate: true para rodar na montagem

// watch múltiplas fontes
watch([userId, activeTab], ([newId, newTab], [oldId, oldTab]) => {
  // runs when either changes
})

// watchEffect: rastreamento automático de dependências, eager
watchEffect(async (onCleanup) => {
  const controller = new AbortController()
  // cleanup is called before next run or on unmount
  onCleanup(() => controller.abort())

  userData.value = await fetchUser(userId.value, { signal: controller.signal })
})
```

---

## Lifecycle Hooks

```ts
import { onMounted, onBeforeUpdate, onUpdated, onBeforeUnmount, onUnmounted, onErrorCaptured } from 'vue'

// DOM criado — fetch inicial, libs externas, template refs
onMounted(async () => {
  data.value = await fetchData()
  chart = new ChartLibrary(canvasRef.value)
})

// Antes do patch reativo no DOM
onBeforeUpdate(() => {
  savedScrollTop = containerRef.value?.scrollTop ?? 0  // capture scroll before update
})

// Após o patch — DOM atualizado
onUpdated(() => {
  containerRef.value?.scrollTo(0, savedScrollTop)
})

// Antes da destruição — cancelar operações em andamento
onBeforeUnmount(() => {
  clearInterval(intervalId)
  resizeObserver.disconnect()
})

// Após destruição — liberar recursos externos
onUnmounted(() => {
  chart?.destroy()
  eventBus.off('event', handler)
})

// Capturar erros de componentes filhos
onErrorCaptured((error, instance, info) => {
  logError(error, info)
  return false  // false: prevents error from propagating further up
})
```

---

## provide / inject

Mecanismo de injeção de dependência entre componentes ancestral/descendente, sem prop drilling.

```ts
// types/injection-keys.ts
import type { InjectionKey, Ref } from 'vue'

// Typed injection key — garante tipagem no inject
export const ThemeKey: InjectionKey<Ref<'light' | 'dark'>> = Symbol('theme')
export const UserKey: InjectionKey<{ name: string; role: string }> = Symbol('user')
```

```vue
<!-- ParentComponent.vue -->
<script setup lang="ts">
import { ref, provide } from 'vue'
import { ThemeKey, UserKey } from '@/types/injection-keys'

const theme = ref<'light' | 'dark'>('light')

// provide com a typed key — descendentes podem injetar
provide(ThemeKey, theme)
provide(UserKey, { name: 'João', role: 'admin' })
</script>
```

```vue
<!-- DeepChildComponent.vue -->
<script setup lang="ts">
import { inject } from 'vue'
import { ThemeKey, UserKey } from '@/types/injection-keys'

// inject tipado automaticamente pela InjectionKey
const theme = inject(ThemeKey)         // Ref<'light' | 'dark'> | undefined
const user  = inject(UserKey)          // { name: string; role: string } | undefined

// Com valor padrão (remove undefined do tipo)
const currentTheme = inject(ThemeKey, ref('light'))
</script>
```

---

## toRef / toRefs / toValue

```ts
import { reactive, toRef, toRefs, toValue, ref } from 'vue'

const state = reactive({ count: 0, name: 'Vue' })

// toRef: cria uma ref ligada a uma propriedade de reactive
const count = toRef(state, 'count')
count.value++      // state.count também muda
state.count = 10   // count.value também muda

// toRefs: converte todas as propriedades de reactive em refs
const { count: countRef, name: nameRef } = toRefs(state)
// Ideal para retornar de composables que usam reactive internamente

// toValue: unwrap ref OU chama getter — útil em composables genéricos
function useDouble(value: number | Ref<number>) {
  // toValue handles both raw values and refs
  return computed(() => toValue(value) * 2)
}

useDouble(5)           // funciona com número
useDouble(ref(5))      // funciona com ref
```

---

## Composables Reutilizáveis

### Padrão base

```ts
// composables/useFetch.ts
import { ref, watchEffect } from 'vue'

// Generic composable for data fetching with loading and error state
export function useFetch<T>(url: string | Ref<string>) {
  const data    = ref<T | null>(null)
  const loading = ref(false)
  const error   = ref<Error | null>(null)

  watchEffect(async (onCleanup) => {
    const controller = new AbortController()
    onCleanup(() => controller.abort())

    loading.value = true
    error.value   = null

    try {
      const res = await fetch(toValue(url), { signal: controller.signal })
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      data.value = await res.json() as T
    } catch (e) {
      if (!(e instanceof DOMException && e.name === 'AbortError')) {
        error.value = e as Error
      }
    } finally {
      loading.value = false
    }
  })

  return { data, loading, error }
}
```

### Composable de formulário e localStorage

```ts
// composables/useForm.ts — generic form with loading and error state
export function useForm<T extends Record<string, unknown>>(initialValues: T) {
  const fields  = reactive({ ...initialValues })
  const errors  = reactive<Partial<Record<keyof T, string>>>({})
  const loading = ref(false)

  function reset() {
    Object.assign(fields, initialValues)
    Object.keys(errors).forEach(k => delete errors[k as keyof T])
  }

  async function submit(handler: (data: T) => Promise<void>) {
    loading.value = true
    try { await handler({ ...fields } as T); reset() }
    finally { loading.value = false }
  }

  return { fields, errors, loading, reset, submit }
}

// composables/useLocalStorage.ts — syncs a ref with localStorage
export function useLocalStorage<T>(key: string, defaultValue: T) {
  const stored = localStorage.getItem(key)
  const value  = ref<T>(stored ? (JSON.parse(stored) as T) : defaultValue)

  watch(value, (v) => {
    if (v == null) localStorage.removeItem(key)
    else           localStorage.setItem(key, JSON.stringify(v))
  }, { deep: true })

  return value
}
```

---

## Exemplo Completo: `useDataTable.ts`

Composable com paginação, busca e ordenação — demonstra watch múltiplo e estado estruturado.

```ts
// composables/useDataTable.ts
import { ref, computed, watch } from 'vue'

type SortDir = 'asc' | 'desc'
interface FetchParams { page: number; pageSize: number; search: string; sortBy: string; sortDir: SortDir }
interface PagedResult<T> { items: T[]; total: number }

// Composable for paginated, searchable, sortable data tables
export function useDataTable<T>(
  fetchFn: (p: FetchParams) => Promise<PagedResult<T>>,
  pageSize = 20,
) {
  const page    = ref(1)
  const search  = ref('')
  const sortBy  = ref('id')
  const sortDir = ref<SortDir>('asc')
  const items   = ref<T[]>([])
  const total   = ref(0)
  const loading = ref(false)
  const error   = ref<Error | null>(null)

  const totalPages = computed(() => Math.ceil(total.value / pageSize))
  const hasNext    = computed(() => page.value < totalPages.value)
  const hasPrev    = computed(() => page.value > 1)

  async function load() {
    loading.value = true; error.value = null
    try {
      const r = await fetchFn({ page: page.value, pageSize, search: search.value, sortBy: sortBy.value, sortDir: sortDir.value })
      items.value = r.items as T[]; total.value = r.total
    } catch (e) { error.value = e as Error }
    finally     { loading.value = false }
  }

  function setSort(field: string) {
    // toggle direction when clicking the same column
    sortDir.value = sortBy.value === field && sortDir.value === 'asc' ? 'desc' : 'asc'
    sortBy.value  = field
    page.value    = 1
  }

  watch(search, () => { page.value = 1 })
  watch([page, search, sortBy, sortDir], load, { immediate: true })

  return { page, search, sortBy, sortDir, items, total, loading, error, totalPages, hasNext, hasPrev, load, setSort }
}
```
