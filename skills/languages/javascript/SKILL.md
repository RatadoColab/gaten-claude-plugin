---
name: javascript
description: This skill should be used when writing, reviewing, or refactoring JavaScript code for both frontend and backend (Node.js). Covers ES6+ features, async patterns, module systems, and JavaScript best practices.
version: 0.1.0
---

# JavaScript — Convenções e Boas Práticas

## Visão Geral

Diretrizes para escrita de JavaScript moderno (ES6+), aplicável tanto no frontend quanto no backend (Node.js).

## Convenções

- `const` por padrão; `let` quando reatribuição necessária; nunca `var`
- Funções e variáveis em `camelCase`; classes em `PascalCase`; constantes em `UPPER_SNAKE_CASE`
- Arrow functions para callbacks e funções anônimas
- Template literals para interpolação de strings

## Assincronismo

- Preferir `async/await` a `.then()/.catch()` para legibilidade
- Sempre tratar erros com `try/catch` em blocos `async`
- Evitar callback hell; usar `Promise.all` para operações paralelas

## Módulos

- Usar ES Modules (`import`/`export`) para projetos modernos
- Uma exportação principal por arquivo quando possível
- Named exports para utilitários; default export para componentes/classes

## Práticas Recomendadas

- **Desestruturação:** Para extrair propriedades de objetos e arrays
- **Optional chaining (`?.`):** Para acesso seguro a propriedades aninhadas
- **Nullish coalescing (`??`):** Para valores padrão apenas quando `null`/`undefined`
- **Spread operator:** Para cópia imutável de objetos e arrays

## Referências

- Ver `languages/vue/SKILL.md` para uso no contexto Vue.js
- Ver `domains/security/SKILL.md` para segurança em JavaScript
