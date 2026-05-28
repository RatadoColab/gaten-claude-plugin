# Bootstrap 5 — Layout, Grid e Utilities

Referência completa do sistema de grid e classes utilitárias de layout do Bootstrap 5.

---

## Breakpoints

| Infix | Nome | Largura mínima | Container padrão | Container max |
|---|---|---|---|---|
| *(nenhum)* | Extra small | < 576px | 100% | — |
| `sm` | Small | ≥ 576px | 540px | `container-sm` |
| `md` | Medium | ≥ 768px | 720px | `container-md` |
| `lg` | Large | ≥ 992px | 960px | `container-lg` |
| `xl` | Extra large | ≥ 1200px | 1140px | `container-xl` |
| `xxl` | Extra extra large | ≥ 1400px | 1320px | `container-xxl` |

```html
<!-- container: usa largura máxima do breakpoint atual -->
<div class="container">...</div>

<!-- container-fluid: sempre 100% da viewport -->
<div class="container-fluid">...</div>

<!-- container-md: fluid até md, então usa max-width do md -->
<div class="container-md">...</div>
```

---

## Sistema de Grid (12 colunas)

### Estrutura base

```html
<div class="container">
  <div class="row">
    <div class="col">coluna automática</div>
    <div class="col">coluna automática</div>
  </div>
</div>
```

### Colunas com tamanho explícito

```html
<div class="row">
  <!-- 12 colunas em xs, 8 em md -->
  <div class="col-12 col-md-8">Conteúdo principal</div>
  <!-- 12 colunas em xs, 4 em md -->
  <div class="col-12 col-md-4">Sidebar</div>
</div>
```

### Offset — deslocamento de colunas

```html
<div class="row">
  <!-- col-md-6 começando na 4ª coluna (offset de 3) -->
  <div class="col-md-6 offset-md-3">Centralizado</div>
</div>

<!-- offset diferente por breakpoint -->
<div class="col-sm-8 offset-sm-2 col-md-6 offset-md-0">
  Sem offset em md+
</div>
```

### Order — reordenação visual

```html
<div class="row">
  <!-- aparece primeiro no DOM, mas renderiza por último visualmente -->
  <div class="col order-last order-md-first">Item A</div>
  <div class="col">Item B</div>
  <div class="col order-first order-md-last">Item C</div>
</div>
```

> `order-first` = -1; `order-last` = 6; `order-1` a `order-5` disponíveis.

### Nesting — colunas aninhadas

```html
<div class="row">
  <div class="col-sm-9">
    Conteúdo externo
    <!-- novo row dentro de uma coluna -->
    <div class="row">
      <div class="col-8 col-sm-6">Coluna interna A</div>
      <div class="col-4 col-sm-6">Coluna interna B</div>
    </div>
  </div>
  <div class="col-sm-3">Sidebar</div>
</div>
```

### Gutters (espaçamento entre colunas)

```html
<!-- g-*: gutter em ambas as direções (horizontal e vertical) -->
<div class="row g-3">...</div>

<!-- gx-*: somente gutter horizontal -->
<div class="row gx-5">...</div>

<!-- gy-*: somente gutter vertical -->
<div class="row gy-2">...</div>

<!-- g-0: sem gutter -->
<div class="row g-0">...</div>
```

Escala: 0 = 0px | 1 = 0.25rem | 2 = 0.5rem | 3 = 1rem | 4 = 1.5rem | 5 = 3rem

---

## Flexbox Utilities

### Display

```html
<div class="d-flex">...</div>           <!-- display: flex -->
<div class="d-inline-flex">...</div>    <!-- display: inline-flex -->
<div class="d-flex d-md-block">...</div><!-- flex até md, block depois -->
```

### Direção

```html
<div class="d-flex flex-row">...</div>          <!-- padrão: linha -->
<div class="d-flex flex-column">...</div>        <!-- coluna -->
<div class="d-flex flex-row-reverse">...</div>   <!-- linha invertida -->
<div class="d-flex flex-column-reverse">...</div><!-- coluna invertida -->
```

### Justificação (eixo principal)

| Classe | Comportamento |
|---|---|
| `justify-content-start` | Alinhamento ao início (padrão) |
| `justify-content-end` | Alinhamento ao fim |
| `justify-content-center` | Centralizado |
| `justify-content-between` | Espaço entre os itens |
| `justify-content-around` | Espaço ao redor dos itens |
| `justify-content-evenly` | Espaço uniforme |

```html
<div class="d-flex justify-content-between align-items-center">
  <span>Esquerda</span>
  <span>Direita</span>
</div>
```

### Alinhamento (eixo transversal)

| Classe | Comportamento |
|---|---|
| `align-items-start` | Topo |
| `align-items-end` | Fundo |
| `align-items-center` | Centro |
| `align-items-baseline` | Linha de base do texto |
| `align-items-stretch` | Esticar (padrão) |

```html
<!-- alinhamento individual de um item -->
<div class="d-flex">
  <div class="align-self-start">Topo</div>
  <div class="align-self-center">Centro</div>
  <div class="align-self-end">Fundo</div>
</div>
```

### Wrap e Grow/Shrink

```html
<div class="d-flex flex-wrap">...</div>       <!-- permite quebra de linha -->
<div class="d-flex flex-nowrap">...</div>     <!-- sem quebra -->

<div class="flex-grow-1">ocupa espaço restante</div>
<div class="flex-shrink-0">não encolhe</div>
```

---

## Spacing Utilities

Formato: `{propriedade}{lados}-{breakpoint}-{tamanho}`

### Propriedades

| Letra | CSS |
|---|---|
| `m` | margin |
| `p` | padding |

### Lados

| Letra | Lados |
|---|---|
| `t` | top |
| `b` | bottom |
| `s` | start (esquerda em LTR) |
| `e` | end (direita em LTR) |
| `x` | start + end |
| `y` | top + bottom |
| *(nenhum)* | todos os lados |

### Escala de tamanhos

| Valor | Tamanho |
|---|---|
| `0` | 0 |
| `1` | 0.25rem (4px) |
| `2` | 0.5rem (8px) |
| `3` | 1rem (16px) |
| `4` | 1.5rem (24px) |
| `5` | 3rem (48px) |
| `auto` | automático (margin) |

```html
<!-- margin bottom 3 (1rem) -->
<div class="mb-3">...</div>

<!-- padding horizontal 4 (1.5rem) -->
<div class="px-4">...</div>

<!-- margin top 2 em md+, 0 em menor -->
<div class="mt-0 mt-md-2">...</div>

<!-- gap em containers flex/grid -->
<div class="d-flex gap-3">
  <div>Item A</div>
  <div>Item B</div>
</div>
```

---

## Layouts Prontos

### Sidebar + Conteúdo

```html
<div class="container-fluid">
  <div class="row min-vh-100">
    <!-- sidebar: largura fixa em lg+, oculta em mobile -->
    <aside class="col-lg-3 col-xl-2 bg-dark text-white d-none d-lg-flex flex-column p-3"
           aria-label="Menu lateral">
      <nav aria-label="Navegação do sistema">
        <ul class="nav flex-column">
          <li class="nav-item">
            <a class="nav-link text-white" href="/dashboard">Dashboard</a>
          </li>
          <li class="nav-item">
            <a class="nav-link text-white" href="/relatorios">Relatórios</a>
          </li>
        </ul>
      </nav>
    </aside>

    <!-- conteúdo principal: ocupa restante -->
    <main class="col-lg-9 col-xl-10 p-4" id="main-content">
      <h1>Título da Seção</h1>
      <!-- conteúdo -->
    </main>
  </div>
</div>
```

### Cards Grid Responsivo

```html
<section aria-labelledby="cards-heading">
  <h2 id="cards-heading">Resultados</h2>

  <div class="row row-cols-1 row-cols-sm-2 row-cols-lg-3 row-cols-xl-4 g-4">
    <!-- row-cols-*: define quantas colunas por linha no breakpoint -->
    <div class="col">
      <article class="card h-100">
        <img src="imagem.jpg" class="card-img-top" alt="Descrição da imagem">
        <div class="card-body d-flex flex-column">
          <h3 class="card-title">Título do Card</h3>
          <p class="card-text flex-grow-1">Descrição do item.</p>
          <a href="/item/1" class="btn btn-primary mt-auto">Ver detalhes</a>
        </div>
      </article>
    </div>
    <!-- repetir .col para cada card -->
  </div>
</section>
```

### Navbar + Hero

```html
<header>
  <nav class="navbar navbar-expand-lg bg-body-tertiary" aria-label="Navegação principal">
    <div class="container">
      <a class="navbar-brand" href="/">
        <img src="logo.svg" alt="Nome da Organização" height="32">
      </a>
      <button class="navbar-toggler" type="button"
              data-bs-toggle="collapse" data-bs-target="#navMenu"
              aria-controls="navMenu" aria-expanded="false"
              aria-label="Abrir menu de navegação">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navMenu">
        <ul class="navbar-nav ms-auto">
          <li class="nav-item">
            <a class="nav-link active" aria-current="page" href="/">Início</a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="/sobre">Sobre</a>
          </li>
        </ul>
      </div>
    </div>
  </nav>
</header>

<!-- hero section -->
<section class="py-5 text-center bg-body-secondary" aria-labelledby="hero-heading">
  <div class="container py-5">
    <h1 id="hero-heading" class="display-5 fw-bold">Título Principal</h1>
    <p class="col-lg-6 mx-auto fs-5 text-body-secondary">
      Subtítulo descritivo da proposta de valor.
    </p>
    <div class="d-flex justify-content-center gap-2 flex-wrap">
      <a href="/acao" class="btn btn-primary btn-lg">Ação Principal</a>
      <a href="/saiba-mais" class="btn btn-outline-secondary btn-lg">Saiba mais</a>
    </div>
  </div>
</section>
```
