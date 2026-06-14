---
name: html
description: This skill should be used when writing, reviewing, or refactoring HTML markup. Covers semantic HTML5 document structure, Bootstrap 5 grid system and utilities, WCAG 2.2 AA accessibility standards, ARIA roles and attributes, native HTML5 form validation, anti-patterns, and best practices. Use when the user asks to "write HTML", "review markup", "add Bootstrap layout", "create a form", "fix accessibility issues", "add ARIA attributes", "use semantic elements", or "structure an HTML page".
---

# HTML — Semântica, Bootstrap 5 e Acessibilidade

Diretrizes para escrita de HTML5 semântico, acessível e responsivo com Bootstrap 5.

> **Em plugins GLPI:** os templates são fragmentos inseridos no layout do framework. O GLPI já fornece o `<html>`, `<head>` e Bootstrap 5 — nunca reimportar via CDN.

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

| Infix | Largura mínima | Container |
|---|---|---|
| *(nenhum)* | < 576px | 100% |
| `sm` | ≥ 576px | 540px |
| `md` | ≥ 768px | 720px |
| `lg` | ≥ 992px | 960px |
| `xl` | ≥ 1200px | 1140px |
| `xxl` | ≥ 1400px | 1320px |

### Grid (12 colunas)

Estrutura `container > row > col-*`; combinar breakpoints para responsividade (`col-12 col-md-8`); `g-*` controla o gutter. `col` divide igualmente; `col-auto` usa a largura do conteúdo.

```html
<div class="container">
  <div class="row g-3">
    <div class="col-12 col-md-8">Conteúdo principal</div>
    <div class="col-12 col-md-4">Sidebar</div>
  </div>
</div>
```

> Estrutura completa, classes de coluna, offset, order, nesting, flexbox utilities e spacing em **`references/bootstrap5-layout.md`**.

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

### Checklist WCAG 2.2 AA — markup puro

| # | Critério | Nível | Verificação rápida |
|---|---|---|---|
| 1.1.1 | Conteúdo não textual | A | Todo `<img>` tem `alt`; `alt=""` para decorativas |
| 1.3.1 | Informação e relacionamentos | A | Estrutura HTML semântica; `<label>` vinculado |
| 1.4.4 | Redimensionar texto | AA | Conteúdo legível com 200% de zoom sem scroll horizontal |
| 2.4.4 | Propósito do link | A | Texto do link descritivo sem contexto extra |
| 2.4.6 | Cabeçalhos e labels | AA | Cabeçalhos descritivos; labels em todos os campos |
| 3.1.1 | Idioma da página | A | `lang` correto em `<html>` |

Critérios de contraste, foco visível, teclado e alvo de toque: ver `domains/ui-components/SKILL.md` (§Acessibilidade) — fonte autoritativa; identificação de erro em formulários: `domains/forms/SKILL.md` (§Acessibilidade).

> Implementações completas de skip links, focus trap, teclado e contraste em **`references/accessibility.md`**.

---

## Formulários HTML5

### Input Types

Usar sempre o type semanticamente correto — habilita teclado adequado em mobile e validação nativa: `text`, `email`, `tel`, `url`, `number`, `date`, `datetime-local`, `time`, `range`, `color`, `file`, `search`, `password`, `checkbox`, `radio` (+ `select` e `textarea`). Tabela completa com os atributos específicos de cada type em **`references/forms.md`**.

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
| **`references/accessibility.md`** | WCAG 2.2 AA detalhado, ARIA roles/states/properties, teclado, skip links, contraste, focus style |
| **`references/forms.md`** | Input types, validação nativa, Constraint Validation API, Bootstrap 5 feedback, acessibilidade em forms |

---

## Também consultar

- `domains/forms/SKILL.md` — padrões de formulários no contexto do projeto
- `domains/ui-components/SKILL.md` — acessibilidade e comportamento de componentes de interface
- `languages/twig/SKILL.md` — templates Twig com HTML semântico
