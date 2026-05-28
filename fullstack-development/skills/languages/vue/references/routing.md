# Vue 3 — Vue Router: Referência Completa

---

## Configuração Inicial

```ts
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw }            from 'vue-router'

// Route meta typing — extend the RouteMeta interface
declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    roles?:        string[]
    title?:        string
  }
}

const routes: RouteRecordRaw[] = [
  {
    path:      '/',
    name:      'home',
    component: () => import('@/views/HomeView.vue'),  // lazy loading
    meta:      { title: 'Início' },
  },
  {
    path:      '/login',
    name:      'login',
    component: () => import('@/views/LoginView.vue'),
  },
]

export const router = createRouter({
  // createWebHistory: URLs limpas (/path). Requer configuração de server-side fallback.
  // createWebHashHistory: hash-based (#/path). Sem configuração de server.
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, from, savedPosition) {
    // restore scroll position on browser back/forward
    if (savedPosition) return savedPosition
    // scroll to anchor if present
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    // scroll to top on navigation
    return { top: 0 }
  },
})
```

---

## Rotas Dinâmicas e Parâmetros

```ts
// routes com parâmetros dinâmicos
{
  path:      '/users/:id',
  name:      'user-detail',
  component: () => import('@/views/UserDetail.vue'),
  // props: true passa params como props do componente
  props:     true,
}
```

```vue
<!-- UserDetail.vue: acessando parâmetros -->
<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()

// Acesso via useRoute — reativo
const userId = computed(() => Number(route.params.id))

// Alternativa: props: true no router config
// const props = defineProps<{ id: string }>()

watch(() => route.params.id, async (newId) => {
  // refetch when :id changes without component remount
  user.value = await fetchUser(Number(newId))
}, { immediate: true })
</script>
```

---

## Nested Routes (Rotas Aninhadas)

```ts
// routes com componente pai e filhos
{
  path:      '/dashboard',
  name:      'dashboard',
  component: () => import('@/layouts/DashboardLayout.vue'),
  meta:      { requiresAuth: true },
  children:  [
    {
      path:      '',          // /dashboard
      name:      'dashboard-home',
      component: () => import('@/views/DashboardHome.vue'),
    },
    {
      path:      'reports',   // /dashboard/reports
      name:      'reports',
      component: () => import('@/views/ReportsView.vue'),
    },
    {
      path:      'settings',  // /dashboard/settings
      name:      'settings',
      component: () => import('@/views/SettingsView.vue'),
    },
  ],
},
```

```vue
<!-- DashboardLayout.vue: RouterView aninhado -->
<template>
  <div class="dashboard">
    <DashboardSidebar />
    <main>
      <!-- Renders the matched child route component -->
      <RouterView />
    </main>
  </div>
</template>
```

---

## Navigation Guards

### Global (em router/index.ts)

```ts
import { useAuthStore } from '@/stores/useAuthStore'

// Runs before every navigation
router.beforeEach(async (to, from) => {
  const auth = useAuthStore()

  // update document title from route meta
  document.title = to.meta.title ? `${to.meta.title} — App` : 'App'

  // check authentication requirement
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }

  // check role requirement
  if (to.meta.roles && !to.meta.roles.includes(auth.user?.role ?? '')) {
    return { name: 'forbidden' }
  }
})

// Runs after every navigation (no control over navigation)
router.afterEach((to) => {
  analytics.trackPageView(to.fullPath)
})
```

### Por Rota (beforeEnter)

```ts
{
  path: '/admin',
  name: 'admin',
  component: () => import('@/views/AdminView.vue'),
  // guard específico desta rota
  beforeEnter: (to, from) => {
    const auth = useAuthStore()
    if (!auth.isAdmin) return { name: 'forbidden' }
  },
}
```

### In-Component (Composition API)

```vue
<script setup lang="ts">
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

const hasUnsavedChanges = ref(false)

// Guard: runs when navigating away from this component
onBeforeRouteLeave((to, from) => {
  if (hasUnsavedChanges.value) {
    const confirmed = window.confirm('Há alterações não salvas. Deseja sair?')
    if (!confirmed) return false  // cancels navigation
  }
})

// Guard: runs when route params change but component stays mounted
onBeforeRouteUpdate(async (to) => {
  // re-fetch data for new params
  await loadData(Number(to.params.id))
})
</script>
```

---

## Lazy Loading de Rotas

```ts
// All views should use dynamic imports for code splitting
const routes: RouteRecordRaw[] = [
  // Basic lazy load
  {
    path:      '/users',
    component: () => import('@/views/UsersView.vue'),
  },

  // With chunk name (for debugging)
  {
    path:      '/reports',
    component: () => import(/* webpackChunkName: "reports" */ '@/views/ReportsView.vue'),
  },

  // Group related routes in the same chunk
  {
    path:      '/settings/profile',
    component: () => import(/* webpackChunkName: "settings" */ '@/views/ProfileSettings.vue'),
  },
  {
    path:      '/settings/security',
    component: () => import(/* webpackChunkName: "settings" */ '@/views/SecuritySettings.vue'),
  },
]
```

---

## useRoute e useRouter

```vue
<script setup lang="ts">
import { computed }           from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route  = useRoute()   // reactive access to current route
const router = useRouter()  // programmatic navigation

// Reactive access to params and query
const page     = computed(() => Number(route.query.page ?? 1))
const search   = computed(() => String(route.query.q ?? ''))
const recordId = computed(() => Number(route.params.id))

// Always use named routes for type-safe navigation
const goToUser      = (id: number)                       => router.push({ name: 'user-detail', params: { id } })
const applyFilters  = (f: Record<string, string>)        => router.push({ name: 'users', query: f })
const updatePage    = (p: number)                        => router.replace({ query: { ...route.query, page: p } })
</script>
```

---

## `<RouterView>` com Slots e Transições

```vue
<!-- App.vue: transições entre rotas -->
<template>
  <RouterView v-slot="{ Component, route }">
    <Transition :name="route.meta.transition ?? 'fade'" mode="out-in">
      <component :is="Component" :key="route.path" />
    </Transition>
  </RouterView>
</template>

<style>
.fade-enter-active,
.fade-leave-active { transition: opacity 0.2s ease; }
.fade-enter-from,
.fade-leave-to    { opacity: 0; }
</style>
```

---

## Exemplo Completo: Router de SPA com Auth

```ts
// router/index.ts — rotas com auth guard, lazy loading e meta tipado
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw }            from 'vue-router'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    roles?:        ('admin' | 'user' | 'viewer')[]
    title?:        string
    layout?:       'default' | 'auth' | 'blank'
  }
}

const routes: RouteRecordRaw[] = [
  { path: '/login', name: 'login',     component: () => import('@/views/LoginView.vue'),    meta: { layout: 'auth' } },
  {
    path: '/', component: () => import('@/layouts/AppLayout.vue'), meta: { requiresAuth: true },
    children: [
      { path: '',         name: 'home',        component: () => import('@/views/HomeView.vue'),       meta: { title: 'Início' } },
      { path: 'users',    name: 'users',       component: () => import('@/views/UserListView.vue'),   meta: { title: 'Usuários', roles: ['admin'] } },
      { path: 'users/:id', name: 'user-detail', component: () => import('@/views/UserDetailView.vue'), meta: { title: 'Detalhe', roles: ['admin'] }, props: true },
    ],
  },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/views/NotFoundView.vue'), meta: { layout: 'blank' } },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: (to, _from, saved) => saved ?? (to.hash ? { el: to.hash, behavior: 'smooth' } : { top: 0 }),
})

// Global guard: restore session, check auth and roles, set page title
router.beforeEach(async (to) => {
  // dynamic import prevents circular dependency with stores
  const { useAuthStore } = await import('@/stores/useAuthStore')
  const auth = useAuthStore()

  if (auth.token && !auth.user) await auth.fetchProfile()  // restore session on first load

  if (to.meta.requiresAuth && !auth.isAuthenticated)
    return { name: 'login', query: { redirect: to.fullPath } }

  if (to.meta.roles?.length && !to.meta.roles.includes(auth.user?.role ?? ''))
    return { name: 'home' }

  document.title = to.meta.title ? `${to.meta.title} — MyApp` : 'MyApp'
})
```
