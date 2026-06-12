# HTML — Acessibilidade (WCAG 2.2 AA)

Referência completa de acessibilidade: WCAG 2.2, ARIA, teclado, contraste e foco.

---

## WCAG 2.2 — Critérios Essenciais (Nível A e AA)

| Critério | Nível | Descrição | Exemplo de código |
|---|---|---|---|
| **1.1.1** Conteúdo não textual | A | Alternativa em texto para todo conteúdo não textual | `<img alt="Gráfico de barras mostrando crescimento de 20%">` |
| **1.3.1** Informação e relacionamentos | A | Estrutura semântica representa a estrutura visual | `<label for="nome">`, `<th scope="col">` |
| **1.3.2** Sequência significativa | A | Ordem de leitura correta no DOM | Conteúdo no DOM na ordem lógica de leitura |
| **1.3.3** Características sensoriais | A | Instruções não dependem só de forma, cor ou posição | "Clique no botão Salvar" em vez de "Clique no botão verde" |
| **1.4.1** Uso da cor | A | Cor não é o único meio de transmitir informação | Ícone + cor em campos inválidos; não só borda vermelha |
| **1.4.3** Contraste (mínimo) | AA | Texto normal ≥ 4.5:1; texto grande ≥ 3:1 | Verificar com ferramenta de contraste |
| **1.4.4** Redimensionar texto | AA | Legível com 200% de zoom sem scroll horizontal | Layout responsivo; usar `rem`/`em` em vez de `px` para fontes |
| **1.4.11** Contraste de componentes | AA | UI e gráficos ≥ 3:1 contra fundo adjacente | Bordas de inputs, ícones informativos |
| **2.1.1** Teclado | A | Toda funcionalidade acessível por teclado | Sem `onmouseover` exclusivo; `onclick` em elementos focáveis |
| **2.1.2** Sem armadilha de teclado | A | Foco não fica preso em um componente | `Esc` fecha modals e menus; foco retorna ao elemento de origem |
| **2.4.3** Ordem de foco | A | Ordem de foco lógica e previsível | DOM em ordem de leitura; `tabindex` positivo evitado |
| **2.4.4** Propósito do link | A | Texto do link descritivo sem contexto externo | "Ver detalhes do produto X" em vez de "clique aqui" |
| **2.4.6** Cabeçalhos e labels | AA | Cabeçalhos descritivos; labels em todos os campos | `<label>` em todo `<input>`; headings hierárquicos |
| **2.4.7** Foco visível | AA | Indicador de foco perceptível | Nunca `outline: none` sem alternativa visível |
| **3.1.1** Idioma da página | A | Idioma definido no elemento `<html>` | `<html lang="pt-BR">` |
| **3.3.1** Identificação de erro | A | Erros descritos em texto, não só por cor | Mensagem textual próxima ao campo + `aria-describedby` |
| **3.3.2** Labels ou instruções | A | Labels ou instruções para campos de entrada | `<label>` + texto de ajuda quando necessário |
| **4.1.2** Nome, função, valor | A | Componentes com nome, função e estado programáticos | `aria-label`, `role`, `aria-expanded`, `aria-checked` |

---

## ARIA Landmark Roles

| Role | Elemento HTML5 equivalente | Uso correto |
|---|---|---|
| `banner` | `<header>` (descendente direto de `<body>`) | Cabeçalho principal da página; apenas um por página |
| `navigation` | `<nav>` | Grupos de links de navegação; usar `aria-label` único em cada |
| `main` | `<main>` | Conteúdo principal; apenas um por página |
| `complementary` | `<aside>` | Conteúdo de suporte relacionado ao principal |
| `contentinfo` | `<footer>` (descendente direto de `<body>`) | Rodapé principal; apenas um por página |
| `search` | *(sem equivalente nativo)* | Formulário ou região de busca |
| `form` | `<form>` com nome acessível | Formulários com propósito identificado; não usar em toda `<form>` |
| `region` | `<section>` com `aria-labelledby` | Seção importante com cabeçalho próprio |

```html
<!-- múltiplas navegações: diferenciar com aria-label -->
<nav aria-label="Navegação principal">...</nav>
<nav aria-label="Navegação do rodapé">...</nav>

<!-- search role -->
<div role="search">
  <label for="busca">Buscar no site</label>
  <input type="search" id="busca">
  <button type="submit">Buscar</button>
</div>

<!-- region com nome via aria-labelledby -->
<section aria-labelledby="noticias-heading">
  <h2 id="noticias-heading">Últimas Notícias</h2>
  ...
</section>
```

---

## ARIA States e Properties

| Atributo | Tipo | Uso |
|---|---|---|
| `aria-label` | property | Nome acessível quando texto visível está ausente |
| `aria-labelledby` | property | Referencia `id` de elemento que nomeia o componente |
| `aria-describedby` | property | Referencia `id` de elemento que descreve ou explica |
| `aria-hidden` | state | Remove elemento da árvore de acessibilidade (`true`/`false`) |
| `aria-expanded` | state | Estado aberto/fechado de accordion, dropdown, menu |
| `aria-current` | state | Item atual em navegação: `page`, `step`, `location`, `date`, `time`, `true` |
| `aria-required` | property | Campo obrigatório (complementa o atributo HTML `required`) |
| `aria-invalid` | state | Campo com valor inválido (`true`/`false`/`grammar`/`spelling`) |
| `aria-live` | property | Região de atualização dinâmica: `polite` ou `assertive` |
| `aria-atomic` | property | Lê toda a região ao atualizar (`true`) ou só o trecho alterado (`false`) |
| `aria-controls` | property | Referencia `id` do elemento controlado |
| `aria-selected` | state | Item selecionado em tabs, listbox, tree |
| `aria-pressed` | state | Estado toggle de botão: `true`/`false`/`mixed` |
| `aria-disabled` | state | Elemento desabilitado sem remover do foco (`true`/`false`) |

```html
<!-- aria-label: ícone sem texto -->
<button type="button" aria-label="Fechar janela">
  <svg aria-hidden="true" focusable="false">...</svg>
</button>

<!-- aria-describedby: instrução adicional -->
<label for="cpf">CPF</label>
<input type="text" id="cpf" aria-describedby="cpf-hint cpf-error">
<span id="cpf-hint" class="form-text">Somente números, sem pontuação.</span>
<span id="cpf-error" class="invalid-feedback" aria-live="polite"></span>

<!-- aria-expanded em toggle -->
<button type="button" aria-expanded="false" aria-controls="submenu-configuracoes">
  Configurações
</button>
<ul id="submenu-configuracoes" hidden>...</ul>

<!-- aria-live: feedback dinâmico -->
<div role="status" aria-live="polite" aria-atomic="true" class="visually-hidden">
  <!-- mensagens de status injetadas via JS são anunciadas -->
</div>
<div role="alert" aria-live="assertive" aria-atomic="true">
  <!-- erros críticos: anunciados imediatamente -->
</div>
```

---

## Navegação por Teclado

### Tabindex

```html
<!-- tabindex="0": inclui no fluxo natural de tab -->
<div role="button" tabindex="0" onclick="..." onkeydown="handleKey(event)">
  Elemento customizado
</div>

<!-- tabindex="-1": focável via JS, não via Tab -->
<div id="modal-conteudo" tabindex="-1">...</div>

<!-- evitar tabindex positivo (> 0): altera ordem natural de foco -->
<!-- tabindex="1", "2", etc. geram comportamento imprevisível -->
```

### Skip Link (pular para o conteúdo)

```html
<!-- primeiro elemento do <body>: visível apenas ao receber foco -->
<a class="visually-hidden-focusable" href="#main-content">
  Ir ao conteúdo principal
</a>

<header>...</header>

<main id="main-content" tabindex="-1">
  <!-- tabindex="-1" permite que o foco seja movido via JS se necessário -->
  <h1>Título da Página</h1>
</main>
```

### Tratamento de Teclas em Componentes Customizados

```html
<div role="button" tabindex="0" id="btnCustom">Ativar</div>

<script>
  /**
   * Handles keyboard activation for custom button elements.
   * @param {KeyboardEvent} event
   */
  function handleKeyActivation(event) {
    // activate on Enter or Space, matching native button behavior
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      event.currentTarget.click();
    }
  }

  document.getElementById('btnCustom').addEventListener('keydown', handleKeyActivation);
</script>
```

### Focus Trap em Modal

```html
<script>
  /**
   * Traps focus within the modal element while it is open.
   * @param {HTMLElement} modal - The modal container element
   */
  function trapFocus(modal) {
    // selects all focusable elements inside the modal
    const focusable = modal.querySelectorAll(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), ' +
      'textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
    );

    const first = focusable[0];
    const last  = focusable[focusable.length - 1];

    modal.addEventListener('keydown', (event) => {
      if (event.key !== 'Tab') return;

      if (event.shiftKey) {
        // shift+Tab: se estiver no primeiro, vai para o último
        if (document.activeElement === first) {
          event.preventDefault();
          last.focus();
        }
      } else {
        // Tab: se estiver no último, vai para o primeiro
        if (document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    });

    // move focus to first focusable element when modal opens
    first?.focus();
  }
</script>
```

---

## Imagens

| Situação | Atributo `alt` correto |
|---|---|
| Imagem informativa | `alt="Descrição do que a imagem mostra"` |
| Imagem decorativa (puro estilo) | `alt=""` (vazio) |
| Imagem funcional (botão/link) | `alt="Ação que o link/botão executa"` |
| Gráfico com dados | `alt="Gráfico de barras: vendas cresceram 20% em 2024"` + dados em tabela adjunta |
| Logo com texto | `alt="Nome da Organização"` |
| Ícone com texto adjacente | `aria-hidden="true"` no ícone (o texto já fornece o nome) |

```html
<!-- informativa -->
<img src="mapa-brasil.jpg" alt="Mapa político do Brasil destacando o estado do RJ">

<!-- decorativa -->
<img src="divider.png" alt="">

<!-- funcional: logo clicável -->
<a href="/">
  <img src="logo.png" alt="IBGE — Ir à página inicial">
</a>

<!-- ícone com texto: ícone oculto do leitor de tela -->
<button type="button">
  <svg aria-hidden="true" focusable="false"><!-- ícone lixeira --></svg>
  Excluir registro
</button>
```

---

## Contraste de Cores

| Tipo de texto | Razão mínima (AA) | Razão recomendada (AAA) |
|---|---|---|
| Texto normal (< 18pt / < 14pt bold) | 4.5:1 | 7:1 |
| Texto grande (≥ 18pt ou ≥ 14pt bold) | 3:1 | 4.5:1 |
| Componentes de UI (inputs, botões) | 3:1 | — |
| Logotipos e texto decorativo | Sem requisito | — |

Ferramentas de verificação:
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Colour Contrast Analyser (app desktop)](https://www.tpgi.com/color-contrast-checker/)
- DevTools do Chrome: painel Accessibility → contraste

---

## Focus Visível

```css
/* NUNCA remover outline sem fornecer alternativa */
/* ❌ proibido */
*:focus { outline: none; }

/* ✅ custom focus style acessível */
:focus-visible {
    /* high contrast outline visible on all backgrounds */
    outline: 3px solid #0d6efd;
    outline-offset: 2px;
    border-radius: 2px;
}

/* remove outline para cliques com mouse, mantém para teclado */
:focus:not(:focus-visible) {
    outline: none;
}

/* Bootstrap 5: customizar via variável CSS */
:root {
    --bs-focus-ring-color: rgba(13, 110, 253, 0.5);
    --bs-focus-ring-width: 3px;
}
```

```html
<!-- skip link: visível apenas ao receber foco via teclado -->
<style>
  .skip-link {
    position: absolute;
    top: -100%;
    left: 1rem;
    background: #000;
    color: #fff;
    padding: 0.5rem 1rem;
    z-index: 9999;
    border-radius: 0 0 4px 4px;
  }
  /* becomes visible when focused */
  .skip-link:focus {
    top: 0;
  }
</style>
<a class="skip-link" href="#main-content">Ir ao conteúdo principal</a>
```
