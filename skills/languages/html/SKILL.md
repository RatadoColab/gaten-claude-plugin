---
name: html
description: This skill should be used when writing or reviewing HTML markup. Covers semantic HTML, accessibility standards, document structure, ARIA attributes, and HTML best practices.
version: 0.1.0
---

# HTML — Semântica e Boas Práticas

## Visão Geral

Diretrizes para escrita de HTML semântico, acessível e bem estruturado.

## Semântica

Usar elementos HTML pelo seu significado, não pela aparência:
- `<header>`, `<main>`, `<footer>`, `<nav>`, `<aside>` para estrutura de página
- `<section>`, `<article>` para agrupamento de conteúdo
- `<h1>`–`<h6>` em hierarquia lógica (não pular níveis)
- `<button>` para ações, `<a>` para navegação
- `<table>` apenas para dados tabulares, nunca para layout

## Acessibilidade

- Atributo `alt` descritivo em todas as imagens (vazio `alt=""` para imagens decorativas)
- `<label>` vinculado a cada input via `for`/`id` ou envolvendo o input
- Contraste de cor mínimo de 4.5:1 para texto normal (WCAG AA)
- Foco visível em todos os elementos interativos
- `aria-label` ou `aria-labelledby` quando o texto do elemento não é suficiente

## Estrutura

```html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Título da Página</title>
  </head>
  <body>
    <header>...</header>
    <main>...</main>
    <footer>...</footer>
  </body>
</html>
```

## Práticas Recomendadas

- `lang` correto na tag `<html>` para leitores de tela
- Atributos booleanos sem valor: `<input required>` (não `required="required"`)
- IDs únicos por página; classes para estilização e reutilização

## Referências

- Ver `domains/forms/SKILL.md` para HTML semântico em formulários
- Ver `domains/ui-components/SKILL.md` para acessibilidade em componentes
