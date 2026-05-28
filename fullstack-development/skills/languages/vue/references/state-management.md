# Vue 3 — State Management com Pinia

---

## Quando usar Pinia vs Composables

| Situação | Solução recomendada |
|---|---|
| Estado local de um componente | `ref` / `reactive` dentro do componente |
| Lógica reutilizável com estado local | Composable (`useXxx`) |
| Estado compartilhado entre componentes próximos | `provide` / `inject` |
| Estado compartilhado entre rotas | Pinia Store |
| Cache de dados remotos entre rotas | Pinia Store com actions de fetch |
| Configurações do usuário (persistidas) | Pinia + plugin de persistência |

---

## Setup Stores (Padrão Preferido)

Mais flexível, melhor inferência de TypeScript, familiar para quem usa Composition API.

```ts
// stores/useCartStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useCartStore = defineStore('cart', () => {
  // state: refs
  const items   = ref<CartItem[]>([])
  const coupon  = ref<string | null>(null)

  // getters: computed
  const subtotal = computed(() =>
    items.value.reduce((sum, item) => sum + item.price * item.qty, 0)
  )
  const discount = computed(() => coupon.value === 'DESC10' ? subtotal.value * 0.1 : 0)
  const total    = computed(() => subtotal.value - discount.value)
  const count    = computed(() => items.value.reduce((n, item) => n + item.qty, 0))

  // actions
  function addItem(product: Product) {
    const existing = items.value.find(i => i.id === product.id)
    if (existing) {
      existing.qty++
    } else {
      items.value.push({ ...product, qty: 1 })
    }
  }

  function removeItem(id: number) {
    items.value = items.value.filter(i => i.id !== id)
  }

  function applyCoupon(code: string) {
    coupon.value = code
  }

  function clear() {
    items.value  = []
    coupon.value = null
  }

  return { items, coupon, subtotal, discount, total, count, addItem, removeItem, applyCoupon, clear }
})
```

---

## Option Stores

Mais verboso, similar ao Vuex. Adequado para quem prefere estrutura explícita.

```ts
export const useCounterStore = defineStore('counter', {
  state:   () => ({ count: 0, name: 'Contador' }),
  getters: {
    doubled:     (state) => state.count * 2,
    displayName: (state) => `${state.name}: ${state.count}`,
  },
  actions: {
    increment() { this.count++ },
    async fetchInitialCount() { this.count = (await api.getCount()).value },
  },
})
```

---

## storeToRefs

Necessário para manter reatividade ao desestruturar uma store.

```vue
<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { useCartStore } from '@/stores/useCartStore'

const cart = useCartStore()

// storeToRefs: desestrutura state e getters como refs reativas
const { items, total, count } = storeToRefs(cart)

// Actions NÃO precisam de storeToRefs — são funções, não refs
const { addItem, removeItem, clear } = cart
</script>
```

---

## Actions Assíncronas com Loading e Error

```ts
// stores/useProductStore.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useProductStore = defineStore('product', () => {
  const items   = ref<Product[]>([])
  const loading = ref(false)
  const error   = ref<string | null>(null)

  // current fetch controller for cancellation
  let controller: AbortController | null = null

  async function fetchAll(categoryId?: number) {
    // cancel previous in-flight request
    controller?.abort()
    controller = new AbortController()

    loading.value = true
    error.value   = null

    try {
      const params = categoryId ? `?category=${categoryId}` : ''
      const res    = await fetch(`/api/products${params}`, { signal: controller.signal })
      if (!res.ok) throw new Error(`Erro ${res.status}`)
      items.value = await res.json()
    } catch (e) {
      if (!(e instanceof DOMException && e.name === 'AbortError')) {
        error.value = (e as Error).message
      }
    } finally {
      loading.value = false
    }
  }

  async function save(product: Partial<Product>) {
    const method = product.id ? 'PUT' : 'POST'
    const url    = product.id ? `/api/products/${product.id}` : '/api/products'

    const res = await fetch(url, {
      method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(product),
    })

    if (!res.ok) throw new Error(`Falha ao salvar: ${res.status}`)

    const saved = await res.json() as Product
    const index = items.value.findIndex(i => i.id === saved.id)
    if (index >= 0) {
      items.value[index] = saved
    } else {
      items.value.push(saved)
    }

    return saved
  }

  return { items, loading, error, fetchAll, save }
})
```

---

## Store Composição

```ts
// stores/useOrderStore.ts — usa authStore e cartStore internamente
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './useAuthStore'
import { useCartStore } from './useCartStore'

export const useOrderStore = defineStore('order', () => {
  const orders = ref<Order[]>([])

  async function checkout() {
    // Using other stores inside a store is allowed
    const auth = useAuthStore()
    const cart = useCartStore()

    if (!auth.isAuthenticated) throw new Error('Login necessário')

    const order = await api.createOrder({
      userId: auth.user!.id,
      items:  cart.items,
      total:  cart.total,
    })

    orders.value.push(order)
    cart.clear()  // clear cart after successful checkout

    return order
  }

  return { orders, checkout }
})
```

---

## Persistência com pinia-plugin-persistedstate

```ts
// main.ts
import { createApp }    from 'vue'
import { createPinia }  from 'pinia'
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'

const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)

createApp(App).use(pinia).mount('#app')
```

```ts
// stores/useAuthStore.ts — com persistência seletiva
export const useAuthStore = defineStore('auth', () => {
  const token   = ref<string | null>(null)
  const user    = ref<User | null>(null)
  const role    = ref<string>('guest')

  return { token, user, role }
}, {
  persist: {
    // persist only safe fields — never persist sensitive data in localStorage
    pick: ['token', 'role'],
    // omit sensitive user details
    // omit: ['user.password', 'user.securityQuestion'],
  },
})
```

---

## Testing de Stores

```ts
// tests/stores/useCartStore.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia }       from 'pinia'
import { useCartStore }                      from '@/stores/useCartStore'

describe('useCartStore', () => {
  // create a fresh pinia for each test — prevents state leakage between tests
  beforeEach(() => setActivePinia(createPinia()))

  it('adds item to cart', () => {
    const cart = useCartStore()
    cart.addItem({ id: 1, name: 'Produto A', price: 10.0 })
    expect(cart.items).toHaveLength(1)
    expect(cart.count).toBe(1)
  })

  it('increments qty for existing item', () => {
    const cart = useCartStore()
    const p    = { id: 1, name: 'A', price: 5.0 }
    cart.addItem(p); cart.addItem(p)
    expect(cart.items[0].qty).toBe(2)
  })

  it('applies coupon discount', () => {
    const cart = useCartStore()
    cart.addItem({ id: 1, name: 'A', price: 100, qty: 1 })
    cart.applyCoupon('DESC10')
    expect(cart.discount).toBe(10)
    expect(cart.total).toBe(90)
  })
})
```

---

## Exemplo Completo: `useAuthStore.ts`

Setup store com login, logout, token refresh e persistência seletiva.

```ts
// stores/useAuthStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

interface User { id: number; name: string; email: string; role: 'admin' | 'user' | 'viewer' }

export const useAuthStore = defineStore('auth', () => {
  const token   = ref<string | null>(localStorage.getItem('token'))
  const user    = ref<User | null>(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin         = computed(() => user.value?.role === 'admin')

  async function login(email: string, password: string) {
    loading.value = true
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      })
      if (!res.ok) throw new Error('Credenciais inválidas')
      const data  = await res.json()
      token.value = data.token; user.value = data.user
      localStorage.setItem('token', data.token)
    } finally { loading.value = false }
  }

  async function refreshToken() {
    if (!token.value) return
    try {
      const res = await fetch('/api/auth/refresh', {
        method: 'POST', headers: { Authorization: `Bearer ${token.value}` },
      })
      if (!res.ok) { logout(); return }
      token.value = (await res.json()).token
      localStorage.setItem('token', token.value!)
    } catch { logout() }
  }

  async function fetchProfile() {
    if (!token.value) return
    const res = await fetch('/api/auth/me', { headers: { Authorization: `Bearer ${token.value}` } })
    if (!res.ok) { logout(); return }
    user.value = await res.json()
  }

  function logout() {
    token.value = null; user.value = null
    localStorage.removeItem('token')
  }

  return { token, user, loading, isAuthenticated, isAdmin, login, logout, refreshToken, fetchProfile }
}, {
  // persist only the token — never persist sensitive user data
  persist: { pick: ['token'] },
})
```
