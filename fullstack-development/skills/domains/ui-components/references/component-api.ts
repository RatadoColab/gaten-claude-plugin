// Referência: domains/ui-components/SKILL.md — Seção API do Componente
// Quando usar: padrões de API de componentes Vue 3 (props, emits, slots, expose, v-model)

// --- Props tipadas com withDefaults ---
// Good: typed, documented, with defaults
const props = withDefaults(defineProps<{
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  label: string
}>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
})

// --- Emits tipados com defineEmits ---
// Good: explicit, typed emits
const emit = defineEmits<{
  'update:modelValue': [value: string]
  'change': [value: string]
  'blur': [event: FocusEvent]
}>()

// --- v-model múltiplos (Vue 3) ---
// Props
const propsMultiModel = defineProps<{
  modelValue: string        // v-model
  modifier: 'upper' | 'lower'  // v-model:modifier
}>()

const emitMultiModel = defineEmits<{
  'update:modelValue': [value: string]
  'update:modifier': [value: 'upper' | 'lower']
}>()

// Usage in template:
// <MyInput v-model="text" v-model:modifier="textModifier" />

// --- defineExpose ---
// Only expose what the parent genuinely needs
defineExpose({ focus, reset })

// --- inheritAttrs: false + $attrs ---
// Without this, attrs (id, placeholder, type, aria-*) fall through to the root <div>
defineOptions({ inheritAttrs: false })

// Template usage:
// <div class="input-wrapper">
//   <!-- attrs applied to the native element, not the wrapper -->
//   <input v-bind="$attrs" class="input" />
// </div>
