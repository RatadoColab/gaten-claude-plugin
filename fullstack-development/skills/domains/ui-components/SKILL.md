---
name: ui-components
description: This skill should be used when creating, reviewing, or refactoring UI components. Covers component design principles, reusability patterns, props/slots/events API design, responsiveness, accessibility (WCAG 2.2), design tokens, and atomic design.
version: 0.2.0
---

# UI Components — Componentes de Interface

## Visão Geral

Diretrizes para criação de componentes Vue 3 reutilizáveis, acessíveis e alinhados com o design system. Aplicar sempre que criar, revisar ou refatorar componentes de interface.

---

## 1. Princípios Fundamentais

- **Responsabilidade única:** o componente resolve um problema bem delimitado; dividir quando acumular mais de uma responsabilidade distinta.
- **Reutilizável:** parametrizável via props sem lógica hardcoded de contexto específico.
- **Previsível:** as mesmas props produzem sempre a mesma saída visual e comportamental.
- **Acessível por padrão:** acessibilidade é requisito, não ajuste posterior.
- **Documentado:** props, slots, eventos e comportamentos com tipos, valores padrão e exemplos.

---

## 2. Arquitetura — Atomic Design

Organizar componentes por nível de abstração e dependência, não como regra rígida, mas como guia de decisão.

| Nível | Descrição | Exemplos |
|---|---|---|
| **Atom** | Elemento primitivo sem dependência de outros componentes | `BaseButton`, `BaseInput`, `BaseIcon` |
| **Molecule** | Composição de atoms com comportamento próprio | `FormField` (label + input + mensagem de erro) |
| **Organism** | Seção autônoma da interface | `DataTable`, `SidebarNav`, `UserCard` |
| **Template** | Layout sem dados reais | `PageWithSidebar`, `DashboardLayout` |
| **Page** | Template com dados reais injetados | `UserListPage`, `ReportPage` |

**Regras práticas:**
- Atoms devem ser "burros" — recebem props, emitem eventos, não gerenciam estado externo.
- Molecules encapsulam acessibilidade (associação label/input, `aria-*`) e expõem defaults sensatos.
- Organisms podem se conectar a stores (Pinia) ou composables de dados.
- Não pular níveis hierárquicos: um Atom não vira Organism diretamente sem passar por Molecule/Organism intermediário
- Separação de responsabilidades: Organisms não devem conter lógica de negócio — lógica de negócio pertence à camada de Page ou ao composable da feature

---

## 3. API do Componente (Vue 3 — Options API / Global Build)

> **Em plugins GLPI:** usar Vue 3 via **global build** (`vue.global.prod.js`) sem bundler. Não usar `<script setup>` nem SFCs — definir componentes com `Vue.defineComponent({})` ou Options API inline.

### 3.1 Props

- Usar union types literais para props com conjunto fixo de valores (`variant`, `size`, `align`).
- Nunca passar objetos mutáveis direto via prop — preferir passar IDs e deixar o componente buscar no estado.
- Evitar props booleanas com semântica negativa (`noLabel`, `hideIcon`); preferir `showLabel`, `showIcon`.

### 3.2 Emits

- Usar o padrão `update:modelValue` para componentes que funcionam com `v-model`.
- Nomes de eventos em kebab-case.
- Nunca emitir o objeto de evento DOM diretamente quando apenas parte dos dados é relevante.

### 3.3 Slots

- Verificar `$slots.nome` antes de renderizar o wrapper do slot — evita elementos vazios no DOM.
- Usar scoped slots para expor dados internos ao pai quando necessário.

### Fallthrough de Atributos (`inheritAttrs`)

Para componentes que encapsulam um único elemento nativo (`BaseInput`, `BaseSelect`, `BaseButton`), desabilitar o fallthrough automático e aplicar `$attrs` manualmente no elemento correto.

Sem `inheritAttrs: false`, atributos como `id`, `placeholder`, `type` e `aria-*` são aplicados no elemento raiz do componente (geralmente uma `<div>`), causando bugs silenciosos de acessibilidade — o `<label for="id">` não conectará ao `<input>` correto.

---

## 4. Design Tokens

### 4.1 Separação entre tokens primitivos e semânticos

- **Nunca usar valores hardcoded** (`color: #2563eb`) em componentes; referenciar sempre o token semântico.
- Tokens primitivos servem apenas para definir tokens semânticos.
- Tokens semânticos permitem theming em runtime (troca de tema via CSS Custom Properties).

### 4.2 Convenções de nomenclatura

```
--{categoria}-{elemento}-{estado}
--color-button-primary-hover
--spacing-card-padding
--typography-heading-size
--shadow-modal-default
```

### 4.3 Variantes via props mapeadas para tokens

Mapear valores de prop para classes CSS que consomem tokens — sem estilos inline. Em Vue: `const variantClass = computed(() => \`btn--${props.variant}\`)`.

> Ver exemplo completo em [`references/design-tokens.css`](references/design-tokens.css).

> Para implementação de dark mode via tokens semânticos CSS (`prefers-color-scheme`, variáveis CSS por tema), ver `../user-experience/SKILL.md` — Seção de Dark Mode.

---

## 5. Acessibilidade (WCAG 2.2 — Nível AA)

### 5.1 Checklist obrigatório por componente

**Semântica e estrutura:**
- Usar elementos HTML nativos (`<button>`, `<nav>`, `<dialog>`) antes de recorrer a `role`.
- Não usar `div` clicável; usar `<button>` ou `<a>` com `href`.
- Garantir que o nome acessível do elemento (via `aria-label`, `aria-labelledby` ou texto visível) descreva a função.

**Contraste (WCAG 1.4.3 / 1.4.11):**
- Texto normal: razão mínima de **4,5:1**.
- Texto grande (≥ 18pt ou 14pt negrito): mínima de **3:1**.
- Componentes de UI e gráficos (bordas de inputs, ícones informativos): mínima de **3:1**.

**Foco e teclado (WCAG 2.4.7 / 2.4.11 — novo no 2.2):**
- Todo componente interativo deve ser acessível via teclado.
- O indicador de foco nunca deve ser ocultado por elementos sobrepostos.
- Não remover `:focus-visible` sem fornecer alternativa visível.

**Tamanho de alvo (WCAG 2.5.8 — novo no 2.2):**
- Mínimo normativo WCAG AA: **24×24 px** — requisito de conformidade
- Recomendação prática de usabilidade: **44×44 px** (Apple HIG) / **48×48 px** (Material Design) — usar como padrão do design system
- O mínimo normativo é o piso, não o alvo — preferir sempre o tamanho de usabilidade prático
- Ver `../user-experience/SKILL.md` para diretrizes de toque em mobile

**Movimento e animação (WCAG 2.3.3):**
- Usar `prefers-reduced-motion` para desativar animações não essenciais.

```css
@media (prefers-reduced-motion: reduce) {
  .animated-element {
    animation: none;
    transition: none;
  }
}
```

**ARIA:**
- Usar ARIA apenas quando HTML nativo não atende; ARIA incorreto piora a experiência.
- Estados dinâmicos: `aria-expanded`, `aria-selected`, `aria-checked`, `aria-invalid`.
- Regiões live: `aria-live="polite"` para notificações não urgentes; `aria-live="assertive"` apenas para erros críticos.

### 5.2 Exemplos por componente

> Ver exemplo completo em [`references/accessibility-examples.html`](references/accessibility-examples.html).

---

## 6. Responsividade

- **Mobile-first:** escrever estilos base para telas pequenas e sobrescrever nos breakpoints maiores.
- Evitar larguras fixas em px; preferir `%`, `rem`, `ch`, `fr` ou `clamp()`.
- Usar `clamp()` para tipografia fluida: `font-size: clamp(1rem, 2.5vw, 1.5rem)`.
- Testar nos breakpoints definidos no design system do projeto.
- Imagens e mídias: usar `max-width: 100%` e o atributo `loading="lazy"` quando aplicável.

> Ver exemplo completo em [`references/responsive-patterns.css`](references/responsive-patterns.css).

---

## 7. Componentes Compostos — provide/inject

Quando um componente pai precisa coordenar múltiplos filhos sem prop drilling (Tabs/TabPanel, Accordion/AccordionItem, Select/Option), usar `provide`/`inject`:

- Usar `Symbol` como chave para evitar colisões de nome
- Lançar erro explícito se o filho for usado fora do contexto do pai

> Testes de componentes Vue em plugins GLPI são feitos via **PHPUnit** no lado servidor — não há runner JavaScript separado.

---

## 8. Performance

- Usar `defineAsyncComponent` para componentes pesados carregados condicionalmente.
- Evitar `v-if` + `v-for` no mesmo elemento — separar em componente filho ou usar `computed`.
- Preferir `v-show` a `v-if` para toggles frequentes (evita montagem/desmontagem).
- Usar `shallowRef` para objetos grandes que não precisam de reatividade profunda.
- Aplicar `key` única e estável em listas — nunca usar o índice como `key` em listas que mudam de ordem.
- **`markRaw`**: marcar objetos que não devem ser tornados reativos (instâncias de bibliotecas externas como charts, editores, mapas). Sem `markRaw`, o Vue tenta rastrear as propriedades do objeto, causando bugs de performance ou erros silenciosos.

> Ver exemplo completo em [`references/performance-patterns.ts`](references/performance-patterns.ts).

---

## Referências

- Ver `domains/user-experience/SKILL.md` para estados de UI e feedback visual.
- Ver `domains/glpi/vue/SKILL.md` para padrões de integração Vue 3 Global Build em plugins GLPI.
- [WCAG 2.2 — W3C](https://www.w3.org/WAI/standards-guidelines/wcag/)
- [Atomic Design — Brad Frost](https://bradfrost.com/blog/post/atomic-web-design/)
- [CSS Custom Properties — Design Tokens Guide](https://www.frontendtools.tech/blog/css-variables-guide-design-tokens-theming-2025)
