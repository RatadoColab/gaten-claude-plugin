---
name: ui-components
description: This skill should be used when creating, reviewing, or refactoring UI components. Covers component design principles, reusability patterns, props/slots/events API design, responsiveness, and design system integration.
version: 0.1.0
---

# UI Components — Componentes de Interface

## Visão Geral

Diretrizes para criação de componentes reutilizáveis, coesos e alinhados com o design system.

## Princípios Fundamentais

- **Reutilizável:** Parametrizável via props, sem lógica hardcoded específica de um contexto
- **Coeso:** Faz uma coisa bem feita; dividir quando o componente crescer demais
- **Previsível:** Mesmas props produzem mesma saída visual
- **Documentado:** Props, slots e eventos com tipos e valores padrão claros

## API do Componente

- **Props:** Entradas do componente (dados e configurações)
- **Slots:** Conteúdo injetado pelo pai (conteúdo variável)
- **Events/Emits:** Comunicação de ações para o componente pai
- **Expose:** Métodos e propriedades públicas para acesso via ref (usar com moderação)

## Design System

- Usar tokens de design (cores, espaçamento, tipografia) em vez de valores hardcoded
- Manter consistência visual com componentes existentes no projeto
- Variantes via props (ex: `variant="primary"`, `size="lg"`)

## Responsividade

- Mobile-first: estilizar para telas pequenas e sobrescrever para maiores
- Evitar larguras fixas; preferir `%`, `rem`, `fr` ou `max-width`
- Testar nos breakpoints definidos no design system

## Referências

- Ver `domains/user-experience/SKILL.md` para estados e feedback visual
