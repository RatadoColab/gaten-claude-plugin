---
name: html
description: This skill should be used when writing, reviewing, or refactoring HTML markup. Covers semantic HTML5 document structure, Bootstrap 5 grid system and utilities, WCAG 2.1 AA accessibility standards, ARIA roles and attributes, native HTML5 form validation, anti-patterns, and best practices. Use when the user asks to "write HTML", "review markup", "add Bootstrap layout", "create a form", "fix accessibility issues", "add ARIA attributes", "use semantic elements", or "structure an HTML page".
version: 0.2.0
---

# HTML — Semântica, Bootstrap 5 e Acessibilidade

Diretrizes para escrita de HTML5 semântico, acessível e responsivo com Bootstrap 5.

---

## Estrutura do Documento HTML5

Template mínimo obrigatório para toda página HTML:

```html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8">
    <!-- viewport: impede zoom automático em mobile -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Descrição da página para SEO">
    <title>Título Descritivo — Nome do Site</title>
    <!-- Bootstrap 5 CSS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
  </head>
  <body>
    <!-- skip link: primeira âncora da página para acessibilidade por teclado -->
    <a class="visually-hidden-focusable" href="#main-content">Ir ao conteúdo principal</a>

    <header role="banner">
      <nav aria-label="Navegação principal">...</nav>
    </header>

    <main id="main-content">
      <h1>Título Principal da Página</h1>
      ...
    </main>

    <footer role="contentinfo">...</footer>

    <!-- Bootstrap 5 JS Bundle (inclui Popper) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>
```

> Sempre definir `lang` na tag `<html>`. Para páginas em português do Brasil: `lang="pt-BR"`.

---

## Elementos Semânticos

| Elemento | Uso correto | Quando NÃO usar |
|---|---|---|
| `<header>` | Cabeçalho da página ou de uma `<section>`/`<article>` | Dentro de `<footer>` ou `<address>` |
| `<nav>` | Agrupamento de links de navegação principal ou secundária | Para um único link isolado |
| `<main>` | Conteúdo principal único da página | Mais de uma vez por página; dentro de `<header>`, `<footer>`, `<aside>` |
| `<footer>` | Rodapé da página ou de seção | Como wrapper genérico de layout |
| `<aside>` | Conteúdo tangencialmente relacionado (sidebar, notas) | Para blocos de layout sem relação semântica |
| `<article>` | Conteúdo autossuficiente e redistribuível (post, notícia, card de produto) | Seções que dependem do contexto da página |
| `<section>` | Agrupamento temático com cabeçalho próprio | Substituindo `<div>` sem agrupamento temático real |
| `<figure>` | Imagem, diagrama ou código com legenda associada | Toda imagem — apenas quando há `<figcaption>` |
| `<figcaption>` | Legenda de `<figure>` | Fora de `<figure>` |
| `<address>` | Informações de contato do autor ou da organização | Endereços físicos genéricos fora de contexto de contato |
| `<time>` | Datas e horários legíveis por máquina (`datetime`) | Texto sobre tempo sem valor semântico |
| `<button>` | Ações que disparam comportamento JS ou submit de formulário | Navegação para outra página (usar `<a>`) |
| `<a>` | Navegação para URL ou âncora na página | Ações que não navegam (usar `<button>`) |
| `<table>` | Dados tabulares com cabeçalhos de linha/coluna | Layout de página; dados não tabulares |

---

## Bootstrap 5 — Grid e Utilities

### Breakpoints

| Infix | Nome | Largura mínima | Container padrão |
|---|---|---|---|
| *(nenhum)* | Extra small | < 576px | 100% |
| `sm` | Small | ≥ 576px | 540px |
| `md` | Medium | ≥ 768px | 720px |
| `lg` | Large | ≥ 992px | 960px |
| `xl` | Extra large | ≥ 1200px | 1140px |
| `xxl` | Extra extra large | ≥ 1400px | 1320px |

### Sistema de Grid (12 colunas)

```html
<!-- container: largura máxima por breakpoint -->
<div class="container">
  <div class="row">
    <!-- col-md-8: 8/12 colunas a partir de md; col-12 abaixo de md -->
    <div class="col-12 col-md-8">Conteúdo principal</div>
    <div class="col-12 col-md-4">Sidebar</div>
  </div>
</div>

<!-- container-fluid: sempre 100% da largura -->
<div class="container-fluid">
  <div class="row g-3">
    <!-- g-3: gap (gutter) de 1rem entre colunas e linhas -->
    <div class="col-sm-6 col-lg-4">Card</div>
    <div class="col-sm-6 col-lg-4">Card</div>
    <div class="col-sm-12 col-lg-4">Card</div>
  </div>
</div>
```

### Classes de Coluna Rápidas

| Classe | Colunas ocupadas | Largura relativa |
|---|---|---|
| `col-1` | 1 de 12 | ~8.33% |
| `col-3` | 3 de 12 | 25% |
| `col-4` | 4 de 12 | 33.33% |
| `col-6` | 6 de 12 | 50% |
| `col-8` | 8 de 12 | 66.67% |
| `col-12` | 12 de 12 | 100% |
| `col` | Igual entre irmãos | Automático |
| `col-auto` | Largura do conteúdo | Automático |

> Detalhes completos de offset, order, nesting, flexbox utilities e spacing em **`references/bootstrap5-layout.md`**.

---

## Acessibilidade

### ARIA Landmark Roles

| Role | Elemento equivalente | Uso |
|---|---|---|
| `banner` | `<header>` (raiz) | Cabeçalho principal da página |
| `navigation` | `<nav>` | Regiões de navegação |
| `main` | `<main>` | Conteúdo principal |
| `complementary` | `<aside>` | Conteúdo de suporte |
| `contentinfo` | `<footer>` (raiz) | Rodapé principal da página |
| `search` | *(sem equivalente)* | Formulário ou widget de busca |
| `form` | `<form>` (com nome) | Formulário que não é busca |
| `region` | `<section>` (com nome) | Seção com `aria-labelledby` |

### Checklist WCAG 2.1 AA (resumido)

| # | Critério | Nível | Verificação rápida |
|---|---|---|---|
| 1.1.1 | Conteúdo não textual | A | Todo `<img>` tem `alt`; `alt=""` para decorativas |
| 1.3.1 | Informação e relacionamentos | A | Estrutura HTML semântica; `<label>` vinculado |
| 1.4.3 | Contraste (mínimo) | AA | Texto: 4.5:1; texto grande (≥18pt ou 14pt bold): 3:1 |
| 1.4.4 | Redimensionar texto | AA | Conteúdo legível com 200% de zoom sem scroll horizontal |
| 2.1.1 | Teclado | A | Toda funcionalidade acessível por teclado |
| 2.1.2 | Sem armadilha de teclado | A | `Esc` fecha modals; foco não fica preso |
| 2.4.3 | Ordem de foco | A | Foco em ordem lógica de leitura |
| 2.4.4 | Propósito do link | A | Texto do link descritivo sem contexto extra |
| 2.4.6 | Cabeçalhos e labels | AA | Cabeçalhos descritivos; labels em todos os campos |
| 2.4.7 | Foco visível | AA | Indicador de foco visível em todos os interativos |
| 3.1.1 | Idioma da página | A | `lang` correto em `<html>` |
| 3.3.1 | Identificação de erro | A | Erros descritos em texto (não só por cor) |
| 4.1.2 | Nome, função, valor | A | Componentes com `name`, `role` e `state` corretos |

> Implementações completas de skip links, focus trap, teclado e contraste em **`references/accessibility.md`**.

---

## Formulários HTML5

### Input Types

| Type | Uso | Atributos específicos |
|---|---|---|
| `text` | Texto livre de linha única | `minlength`, `maxlength`, `pattern` |
| `email` | Endereço de e-mail | Valida formato automaticamente |
| `tel` | Número de telefone | `pattern` (formato varia por país) |
| `url` | URL completa | Valida esquema (http/https) |
| `number` | Valor numérico | `min`, `max`, `step` |
| `date` | Data (YYYY-MM-DD) | `min`, `max` |
| `datetime-local` | Data e hora sem fuso | `min`, `max`, `step` |
| `time` | Horário (HH:MM) | `min`, `max`, `step` |
| `range` | Controle deslizante | `min`, `max`, `step` |
| `color` | Seletor de cor | — |
| `file` | Upload de arquivo | `accept`, `multiple` |
| `search` | Campo de busca | `list` (datalist) |
| `password` | Senha (texto mascarado) | `minlength`, `autocomplete` |
| `checkbox` | Seleção múltipla | `checked`, `indeterminate` (JS) |
| `radio` | Seleção exclusiva em grupo | `checked` |
| `select` | Lista de opções | `multiple`, `size` |
| `textarea` | Texto livre multilinha | `rows`, `cols`, `resize` (CSS) |

### Atributos de Validação Nativa

| Atributo | Tipos compatíveis | Exemplo |
|---|---|---|
| `required` | Todos | `<input required>` |
| `pattern` | text, email, tel, url, password | `pattern="[0-9]{5}-[0-9]{3}"` |
| `min` / `max` | number, date, time, range | `min="0" max="100"` |
| `minlength` / `maxlength` | text, email, tel, url, password, textarea | `minlength="8" maxlength="128"` |
| `step` | number, date, time, range | `step="0.01"` |
| `multiple` | email, file | `<input type="file" multiple>` |

> Validação customizada com Constraint Validation API, integração Bootstrap 5 (`was-validated`, `is-invalid`) e acessibilidade em formulários em **`references/forms.md`**.

---

## Anti-Patterns

| Anti-Pattern | Problema | Solução correta |
|---|---|---|
| `<div>` para navegação | Sem semântica para leitores de tela | `<nav aria-label="...">` |
| `<div>` para botão | Não focável por teclado; sem role | `<button type="button">` |
| `<span>` clicável com `onclick` | Sem role, sem teclado, sem foco | `<button>` ou `<a href>` |
| `<br><br>` para espaçamento | Confunde leitores de tela | Margin/padding via CSS |
| `<table>` para layout | Semântica de dados em estrutura visual | Grid CSS ou Bootstrap |
| Headings fora de ordem (`<h1>` → `<h3>`) | Quebra hierarquia para leitores de tela | Sequência lógica `<h1>` → `<h2>` → `<h3>` |
| `<img>` sem `alt` | Inacessível; falha WCAG 1.1.1 | `alt="descrição"` ou `alt=""` se decorativa |
| `<input>` sem `<label>` | Campo sem nome acessível | `<label for="id">` vinculado |
| `placeholder` como label | Some ao digitar; contraste baixo | `<label>` + `placeholder` apenas como dica |
| `onclick` em elemento não-interativo | Não funciona no teclado | Usar `<button>` ou `<a>` |
| `outline: none` sem alternativa | Remove indicador de foco | Substituir com `outline` customizado |
| IDs duplicados na página | Quebrando `<label for>` e ARIA | IDs únicos por página |
| Atributos ARIA em elementos errados | ARIA incorreto piora acessibilidade | Preferir HTML semântico nativo |

> Regra: **nenhum ARIA é melhor que ARIA errado.** Use o elemento HTML nativo sempre que possível.

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/bootstrap5-layout.md`** | Grid completo, breakpoints com px, offset, order, nesting, flexbox e spacing utilities, layouts prontos |
| **`references/bootstrap5-components.md`** | Navbar, Card, Modal, Alert, Badge, Spinner, Toast, Accordion, Tabs/Pills — exemplos completos |
| **`references/accessibility.md`** | WCAG 2.1 AA detalhado, ARIA roles/states/properties, teclado, skip links, contraste, focus style |
| **`references/forms.md`** | Input types, validação nativa, Constraint Validation API, Bootstrap 5 feedback, acessibilidade em forms |

---

## Também consultar

- `domains/forms/SKILL.md` — padrões de formulários no contexto do projeto
- `domains/ui-components/SKILL.md` — acessibilidade e comportamento de componentes de interface
- `languages/twig/SKILL.md` — templates Twig com HTML semântico
