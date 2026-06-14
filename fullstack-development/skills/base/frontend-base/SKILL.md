---
name: frontend-base
description: This skill should be used when developing frontend features, components, pages, or templates. Covers component architecture, state management principles, accessibility basics, and general best practices for frontend development.
---

# Frontend Base — Fundamentos de Desenvolvimento Frontend

## Visão Geral

Fornece os princípios de arquitetura e boas práticas gerais aplicáveis ao desenvolvimento frontend, independente do framework.

## Princípios Fundamentais

- **Componentização:** Dividir a interface em unidades reutilizáveis e coesas
- **Props down, events up:** Dados fluem de pai para filho; eventos fluem de filho para pai
- **Single source of truth:** Estado compartilhado em um único lugar
- **Acessibilidade desde o início:** Semântica HTML, ARIA roles, contraste e navegação por teclado
- **Feedback imediato:** O usuário deve sempre saber o que está acontecendo

## Estrutura de Componentes

- **Apresentação:** Recebe dados via props, não tem estado próprio, facilmente testável
- **Container/Smart:** Gerencia estado e lógica, passa dados aos componentes de apresentação
- **Layout:** Define a estrutura visual da página sem lógica de negócio

## Práticas Gerais

- Tratar todos os estados: loading, erro, vazio, sucesso
- Evitar lógica de negócio em templates
- Nomear componentes de forma descritiva e sem abreviações
- Manter estilos escopados ao componente quando possível

## Padrões de Implementação

- Codificar preferencialmente no formato MVVM (Model-View-ViewModel), uso de componentes ou estrutura orientada a objetos, implementando classes e métodos
- Seguir princípios SOLID e DRY para garantir código coeso e de baixo acoplamento

## Documentação

Documentar todas as funções, componentes, classes e métodos:
- **JavaScript/TypeScript/Vue**: JSDoc `/** */`
- **HTML/Twig**: comentários `{# #}` (Twig) ou `<!-- -->` (HTML) para blocos de template

## Segurança

Segurança de frontend (XSS, sanitização, `innerHTML` vs `textContent`, CSP, validação de input): ver `domains/security/SKILL.md` — fonte autoritativa.

## Performance

Lazy loading, code splitting, controle de re-renders e otimização de assets: ver `domains/ui-components/SKILL.md` (§Performance) e, em projetos Vue, `languages/vue/SKILL.md` (§Performance).

## Referências

- Ver `domains/forms/SKILL.md` para implementação de formulários
- Ver `domains/ui-components/SKILL.md` para padrões de componentes
- Ver `domains/user-experience/SKILL.md` para UX e fluxos
