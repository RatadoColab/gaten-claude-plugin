---
name: vue
description: This skill should be used when writing, reviewing, or refactoring Vue.js components or applications. Covers Composition API, Options API, component design, reactivity system, and Vue-specific best practices.
version: 0.1.0
---

# Vue.js — Convenções e Boas Práticas

## Visão Geral

Diretrizes para desenvolvimento com Vue.js 3, priorizando Composition API e práticas modernas.

## Composition API (padrão para Vue 3)

```vue
<script setup>
import { ref, computed, onMounted } from 'vue'

const count = ref(0)
const doubled = computed(() => count.value * 2)

onMounted(() => {
  // inicialização
})
</script>
```

## Reatividade

- `ref()` para valores primitivos; `reactive()` para objetos complexos
- Nunca desestruturar `reactive()` diretamente (perde reatividade); usar `toRefs()`
- `computed()` para valores derivados (com cache automático)
- `watch()` para efeitos colaterais; `watchEffect()` para tracking automático

## Componentes

- Um componente por arquivo `.vue`
- Nomear componentes em `PascalCase` no script, `kebab-case` no template
- Props com tipos declarados e valores padrão quando aplicável
- `emit` com nomes em `camelCase`, validados com array ou objeto

## Práticas Recomendadas

- `<script setup>` para Composition API (sintaxe mais concisa)
- `v-bind` e `v-on` abreviados como `:` e `@`
- `key` único em listas renderizadas com `v-for`
- Evitar `v-if` e `v-for` no mesmo elemento

## Referências

- Ver `languages/javascript/SKILL.md` para práticas JS gerais
- Ver `domains/ui-components/SKILL.md` para design de componentes
