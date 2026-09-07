# Vue 3 — Componentes: Referência Completa

---

## defineProps com TypeScript

### Reactive Props Destructure (Vue 3.5+ — padrão atual)

```vue
<script setup lang="ts">
interface Props {
  title:    string
  count?:   number
  variant?: 'primary' | 'danger' | 'ghost'
  labels?:  string[]
}

// Destructure com defaults nativos do JS — substitui withDefaults
// Default de tipo mutável (array/objeto) fica como função para evitar
// compartilhamento acidental de referência entre instâncias
const { title, count = 0, variant = 'primary', labels = ['a', 'b'] } = defineProps<Props>()

// O compilador reescreve cada acesso para props.xxx — a reatividade é preservada
watchEffect(() => console.log(count))   // re-roda quando a prop count muda (3.5+)
</script>
```

> Ao passar uma variável desestruturada para um composable ou `watch` que espera uma fonte reativa, envolver em getter: `useDouble(() => count)` — passar `count` cru envia só o valor no momento da chamada.

### withDefaults (alternativa — ainda suportada)

`withDefaults` **não é deprecado** e continua funcionando igual no Vue 3.5+. A doc oficial apenas
recomenda a destructure como forma preferida de declarar defaults. Usar `withDefaults` em código
existente, ou quando o time ainda não adotou a destructure, não é erro — o que se evita é misturar
os dois estilos no mesmo projeto. É o único caminho para defaults em Vue ≤ 3.4.

```vue
<script setup lang="ts">
const props = withDefaults(defineProps<{
  title?:   string
  count?:   number
  variant?: 'primary' | 'danger' | 'ghost'
}>(), { title: 'Sem título', count: 0, variant: 'primary' })
</script>
```

> Props são somente leitura. Nunca mutar `props.xxx` (nem a variável desestruturada) diretamente — usar estado local ou `emit`.

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

## v-model Customizado — defineModel (Vue 3.4+ — padrão atual)

`defineModel()` declara a prop e o evento `update:*` de um `v-model` numa única **ref gravável**.
Mutar a ref emite o evento; o parent atualizando o `v-model` atualiza a ref.

```vue
<!-- InputField.vue -->
<script setup lang="ts">
// Declara a prop modelValue + evento update:modelValue
const model = defineModel<string>({ required: true })
const { label } = defineProps<{ label?: string }>()
</script>

<template>
  <div>
    <label>{{ label }}</label>
    <!-- v-model direto na ref: leitura e escrita -->
    <input v-model="model" />
  </div>
</template>
```

```vue
<!-- Model nomeado: v-model:count no parent -->
<script setup lang="ts">
const count = defineModel<number>('count', { default: 0 })
function inc() { count.value++ }
</script>
```

```vue
<!-- Modificadores: [model, modifiers] com transform no set -->
<script setup lang="ts">
const [name, mods] = defineModel<string, 'trim' | 'uppercase'>('name', {
  set(v) {
    if (mods.trim)      v = v.trim()
    if (mods.uppercase) v = v.toUpperCase()
    return v
  },
})
</script>
```

```vue
<!-- Uso -->
<InputField v-model="name" label="Nome" />
<Counter v-model:count="total" />
<InputField v-model.trim="name" />

<!-- Múltiplos v-model num mesmo componente -->
<UserForm v-model:first-name="first" v-model:last-name="last" />
```

### v-model manual — compatibilidade ≤ 3.3

Antes do `defineModel`, o par prop + evento era escrito à mão. Manter apenas em código que precisa rodar em Vue ≤ 3.3.

```vue
<!-- InputField.vue (≤ 3.3) -->
<script setup lang="ts">
const props = defineProps<{ modelValue: string; label?: string }>()
const emit  = defineEmits<{ 'update:modelValue': [value: string] }>()
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
<!-- UserForm.vue (≤ 3.3): múltiplos v-model manuais -->
<script setup lang="ts">
const props = defineProps<{ firstName: string; lastName: string }>()
const emit  = defineEmits<{
  'update:firstName': [value: string]
  'update:lastName':  [value: string]
}>()
</script>
```

---

## defineSlots (Vue 3.3+)

Tipagem dos slots — nomes válidos e forma das props de scoped slots. Complementa os scoped slots
documentados abaixo, dando autocomplete e checagem no consumidor.

```vue
<script setup lang="ts" generic="T">
defineProps<{ items: T[] }>()

// Cada chave é um slot; o objeto é o payload do scoped slot
defineSlots<{
  default(props: { item: T; index: number }): unknown
  header(props: { count: number }): unknown
  empty(): unknown
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
import { useTemplateRef } from 'vue'
import FocusableInput from './FocusableInput.vue'

// useTemplateRef (3.5+): a string casa com ref="inputRef" no template
const inputRef = useTemplateRef<InstanceType<typeof FocusableInput>>('inputRef')

function openAndFocus() {
  inputRef.value?.focus()
}
</script>

<template>
  <FocusableInput ref="inputRef" />
</template>
```

> Legado (≤ 3.4): `const inputRef = ref()` + `ref="inputRef"` — a variável precisava ter o mesmo nome da string do template, o que não funcionava em composables nem com refs dinâmicas.

---

## useTemplateRef (Vue 3.5+)

Obtém uma referência a um elemento ou componente do template por **string**, casada com o atributo `ref`.
Substitui o padrão antigo de `ref()` casada por nome de variável.

```vue
<script setup lang="ts">
import { useTemplateRef, onMounted } from 'vue'

// Elemento DOM
const scroller = useTemplateRef<HTMLElement>('scroller')

// Lista de refs (v-for com o mesmo ref)
const rows = useTemplateRef<HTMLElement[]>('rows')

onMounted(() => scroller.value?.scrollTo({ top: 0 }))
</script>

<template>
  <div ref="scroller">
    <div v-for="item in items" :key="item.id" ref="rows">{{ item.name }}</div>
  </div>
</template>
```

**Vantagens sobre `ref()` casada por nome:** funciona dentro de composables (o nome não precisa
existir como variável no `<script setup>`), aceita nome dinâmico e deixa explícito que a fonte é o template.

---

## useId (Vue 3.5+)

Gera um ID único e **estável entre SSR e cliente** — elimina hydration mismatch em `id`/`for`/`aria-*`.
Cada chamada retorna um ID distinto; reutilizar o mesmo valor em pares relacionados.

```vue
<script setup lang="ts">
import { useId } from 'vue'

const id   = useId()
const hint = useId()
</script>

<template>
  <label :for="id">E-mail</label>
  <input :id="id" type="email" :aria-describedby="hint" />
  <p :id="hint">Usaremos apenas para recuperação de conta.</p>
</template>
```

> Critérios de acessibilidade (quando `aria-describedby` é obrigatório, associação label/campo, mensagens
> de erro) são autoritativos em `domains/ui-components/SKILL.md` e `domains/forms/SKILL.md` — aqui só o
> mecanismo de geração do ID.

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

### `defer` (Vue 3.5+)

Sem `defer`, o alvo (`to`) precisa existir no DOM quando o `<Teleport>` monta. `defer` adia a
resolução do alvo para depois do ciclo de render atual — permitindo mirar um contêiner declarado
**mais abaixo no mesmo template**.

```vue
<template>
  <Teleport defer to="#late-container">
    <p>Conteúdo teletransportado</p>
  </Teleport>

  <!-- Declarado depois, mas ainda assim válido como alvo -->
  <div id="late-container"></div>
</template>
```

---

## Exemplo Completo: `DataTable.vue`

Demonstra: generic component, props/emits tipados, slots nomeados, scoped slots, defineExpose e seleção múltipla.

```vue
<script setup lang="ts" generic="T extends { id: number | string }">
import { ref, computed } from 'vue'

interface Column<R> { key: keyof R; label: string; sortable?: boolean }

// Reactive props destructure com defaults nativos (3.5+)
const {
  items,
  columns,
  loading = false,
  selectable = false,
} = defineProps<{
  items:      T[]
  columns:    Column<T>[]
  loading?:   boolean
  selectable?: boolean
}>()

const emit = defineEmits<{
  sort:     [key: keyof T]
  select:   [items: T[]]
  rowClick: [item: T]
}>()

const selected     = ref<Set<T['id']>>(new Set())
const selectedItems = computed(() => items.filter(i => selected.value.has(i.id)))

function toggleSelect(item: T) {
  selected.value.has(item.id) ? selected.value.delete(item.id) : selected.value.add(item.id)
  emit('select', selectedItems.value)
}

function toggleAll() {
  if (selected.value.size === items.length) selected.value.clear()
  else items.forEach(i => selected.value.add(i.id))
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
