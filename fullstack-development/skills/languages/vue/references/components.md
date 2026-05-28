# Vue 3 — Componentes: Referência Completa

---

## defineProps com TypeScript

```vue
<script setup lang="ts">
// Generic syntax (Vue 3.3+): TypeScript infers prop types directly
const props = defineProps<{
  title:    string
  count?:   number
  variant:  'primary' | 'danger' | 'ghost'
  items:    string[]
}>()

// withDefaults: provide defaults for optional props
const props = withDefaults(defineProps<{
  title?:   string
  count?:   number
  variant?: 'primary' | 'danger' | 'ghost'
}>(), { title: 'Sem título', count: 0, variant: 'primary' })
</script>
```

> Props são somente leitura. Nunca mutar `props.xxx` diretamente — usar estado local ou `emit`.

---

## defineEmits com TypeScript

```vue
<script setup lang="ts">
// Tipagem de eventos com payload
const emit = defineEmits<{
  // event name: [payload types]
  change:  [value: string]
  select:  [item: Item, index: number]
  close:   []                           // sem payload
  'update:modelValue': [value: string]  // para v-model
}>()

// Uso
emit('change', 'novo valor')
emit('select', item, 0)
emit('close')
</script>
```

---

## v-model Customizado

```vue
<!-- InputField.vue: componente que aceita v-model -->
<script setup lang="ts">
const props = defineProps<{
  modelValue: string     // prop padrão do v-model
  label?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()
</script>

<template>
  <div>
    <label>{{ label }}</label>
    <input
      :value="modelValue"
      @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    />
  </div>
</template>
```

```vue
<!-- Uso: v-model mapeia para modelValue + update:modelValue -->
<InputField v-model="name" label="Nome" />

<!-- Múltiplos v-model (Vue 3.4+) -->
<UserForm v-model:firstName="first" v-model:lastName="last" />
```

```vue
<!-- UserForm.vue: múltiplos v-model -->
<script setup lang="ts">
const props = defineProps<{
  firstName: string
  lastName:  string
}>()

const emit = defineEmits<{
  'update:firstName': [value: string]
  'update:lastName':  [value: string]
}>()
</script>
```

---

## Slots Nomeados e Scoped Slots

```vue
<!-- Card.vue: define slots -->
<template>
  <div class="card">
    <!-- Named slot with default content -->
    <header>
      <slot name="header">
        <span>Título padrão</span>
      </slot>
    </header>

    <!-- Default slot -->
    <main>
      <slot />
    </main>

    <!-- Scoped slot: expõe dados para o parent -->
    <footer>
      <slot name="actions" :loading="loading" :save="save" />
    </footer>
  </div>
</template>
```

```vue
<!-- Consumo dos slots -->
<Card>
  <!-- Slot nomeado -->
  <template #header>
    <h2>Título personalizado</h2>
  </template>

  <!-- Slot padrão (conteúdo direto) -->
  <p>Conteúdo do card</p>

  <!-- Scoped slot: destructure dos dados expostos pelo componente filho -->
  <template #actions="{ loading, save }">
    <button :disabled="loading" @click="save">Salvar</button>
  </template>
</Card>
```

---

## defineExpose

Por padrão, `<script setup>` fecha o componente — o parent não acessa nada via template ref.
Use `defineExpose` apenas quando necessário (modais, inputs com focus, etc.).

```vue
<!-- FocusableInput.vue -->
<script setup lang="ts">
import { ref } from 'vue'

const inputRef = ref<HTMLInputElement>()

// Expose only what the parent needs — keep the rest private
defineExpose({
  focus: () => inputRef.value?.focus(),
  clear: () => { if (inputRef.value) inputRef.value.value = '' },
})
</script>
```

```vue
<!-- Parent.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import FocusableInput from './FocusableInput.vue'

// Template ref tipado com o tipo exposto
const inputRef = ref<InstanceType<typeof FocusableInput>>()

function openAndFocus() {
  inputRef.value?.focus()
}
</script>

<template>
  <FocusableInput ref="inputRef" />
</template>
```

---

## defineOptions

Disponível no Vue 3.3+. Permite definir opções do componente sem sair do `<script setup>`.

```vue
<script setup lang="ts">
// Define component name and other options without exiting script setup
defineOptions({
  name:        'MySpecialButton',   // útil para DevTools e keep-alive
  inheritAttrs: false,              // controla herança de atributos
})
</script>
```

---

## defineAsyncComponent

```ts
// router/index.ts ou em componentes pai
import { defineAsyncComponent } from 'vue'

// Basic async component — loaded only when first rendered
const HeavyEditor = defineAsyncComponent(() => import('./HeavyEditor.vue'))

// With loading and error states
const AsyncDashboard = defineAsyncComponent({
  loader:           () => import('./Dashboard.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent:   ErrorMessage,
  delay:            200,   // ms antes de mostrar loading (evita flash)
  timeout:          5000,  // ms antes de mostrar error
})
```

```vue
<!-- Uso com Suspense para melhor controle -->
<template>
  <Suspense>
    <AsyncDashboard />
    <template #fallback>
      <LoadingSpinner />
    </template>
  </Suspense>
</template>
```

---

## Teleport

Renderiza o conteúdo em outro nó do DOM, fora da hierarquia do componente.
Ideal para modais, tooltips e notificações que precisam escapar de `overflow: hidden`.

```vue
<script setup lang="ts">
const isOpen = ref(false)
</script>

<template>
  <button @click="isOpen = true">Abrir modal</button>

  <!-- Teleport renders the modal directly into <body> -->
  <Teleport to="body">
    <div v-if="isOpen" class="modal-overlay" @click.self="isOpen = false">
      <div class="modal">
        <slot />
        <button @click="isOpen = false">Fechar</button>
      </div>
    </div>
  </Teleport>
</template>
```

---

## Exemplo Completo: `DataTable.vue`

Demonstra: generic component, props/emits tipados, slots nomeados, scoped slots, defineExpose e seleção múltipla.

```vue
<script setup lang="ts" generic="T extends { id: number | string }">
import { ref, computed } from 'vue'

interface Column<R> { key: keyof R; label: string; sortable?: boolean }

const props = withDefaults(defineProps<{
  items:      T[]
  columns:    Column<T>[]
  loading?:   boolean
  selectable?: boolean
}>(), { loading: false, selectable: false })

const emit = defineEmits<{
  sort:     [key: keyof T]
  select:   [items: T[]]
  rowClick: [item: T]
}>()

const selected     = ref<Set<T['id']>>(new Set())
const selectedItems = computed(() => props.items.filter(i => selected.value.has(i.id)))

function toggleSelect(item: T) {
  selected.value.has(item.id) ? selected.value.delete(item.id) : selected.value.add(item.id)
  emit('select', selectedItems.value)
}

function toggleAll() {
  if (selected.value.size === props.items.length) selected.value.clear()
  else props.items.forEach(i => selected.value.add(i.id))
  emit('select', selectedItems.value)
}

// expose only what parent needs
defineExpose({ clearSelection: () => selected.value.clear() })
</script>

<template>
  <div class="data-table">
    <!-- Toolbar slot: parent injects search, filters and bulk actions -->
    <slot name="toolbar" :selected="selectedItems" />

    <table>
      <thead>
        <tr>
          <th v-if="selectable">
            <input type="checkbox"
              :checked="selected.size === items.length && items.length > 0"
              @change="toggleAll" />
          </th>
          <th v-for="col in columns" :key="String(col.key)"
              :class="{ sortable: col.sortable }"
              @click="col.sortable && emit('sort', col.key)">
            <!-- Named slot per column header for custom rendering -->
            <slot :name="`header-${String(col.key)}`" :column="col">{{ col.label }}</slot>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-if="loading"><td :colspan="columns.length"><slot name="loading">Carregando...</slot></td></tr>
        <tr v-else-if="!items.length"><td :colspan="columns.length"><slot name="empty">Sem resultados.</slot></td></tr>
        <tr v-else v-for="item in items" :key="item.id"
            :class="{ selected: selected.has(item.id) }"
            @click="emit('rowClick', item)">
          <td v-if="selectable">
            <input type="checkbox" :checked="selected.has(item.id)" @change.stop="toggleSelect(item)" />
          </td>
          <!-- Scoped slot per cell: parent can override rendering -->
          <td v-for="col in columns" :key="String(col.key)">
            <slot :name="`cell-${String(col.key)}`" :item="item" :value="item[col.key]">
              {{ item[col.key] }}
            </slot>
          </td>
        </tr>
      </tbody>
    </table>

    <slot name="pagination" />
  </div>
</template>
```
