# Bootstrap 5 — Componentes

Exemplos completos dos principais componentes do Bootstrap 5.

---

## Navbar

```html
<nav class="navbar navbar-expand-lg bg-body-tertiary" aria-label="Navegação principal">
  <div class="container-fluid">
    <!-- marca/logo -->
    <a class="navbar-brand" href="/">
      <img src="logo.svg" alt="Nome do Sistema" height="30" class="d-inline-block align-text-top">
    </a>

    <!-- botão toggler para mobile -->
    <button class="navbar-toggler" type="button"
            data-bs-toggle="collapse" data-bs-target="#navbarMain"
            aria-controls="navbarMain" aria-expanded="false"
            aria-label="Abrir menu de navegação">
      <span class="navbar-toggler-icon"></span>
    </button>

    <!-- itens de navegação colapsáveis -->
    <div class="collapse navbar-collapse" id="navbarMain">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item">
          <!-- aria-current="page" na página ativa -->
          <a class="nav-link active" aria-current="page" href="/">Início</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="/relatorios">Relatórios</a>
        </li>
        <!-- dropdown -->
        <li class="nav-item dropdown">
          <a class="nav-link dropdown-toggle" href="#" role="button"
             data-bs-toggle="dropdown" aria-expanded="false">
            Configurações
          </a>
          <ul class="dropdown-menu">
            <li><a class="dropdown-item" href="/perfil">Meu Perfil</a></li>
            <li><hr class="dropdown-divider"></li>
            <li><a class="dropdown-item" href="/logout">Sair</a></li>
          </ul>
        </li>
      </ul>
      <!-- formulário de busca à direita -->
      <form class="d-flex" role="search">
        <label class="visually-hidden" for="busca-global">Buscar</label>
        <input id="busca-global" class="form-control me-2" type="search"
               placeholder="Buscar..." aria-label="Buscar">
        <button class="btn btn-outline-primary" type="submit">Buscar</button>
      </form>
    </div>
  </div>
</nav>
```

> `navbar-expand-{breakpoint}`: abaixo do breakpoint exibe o toggler; acima expande o menu.

---

## Card

```html
<article class="card" style="max-width: 20rem;">
  <!-- imagem no topo do card -->
  <img src="foto.jpg" class="card-img-top" alt="Descrição significativa da imagem">

  <div class="card-body">
    <h5 class="card-title">Título do Card</h5>
    <p class="card-text text-body-secondary">
      Descrição resumida do conteúdo representado por este card.
    </p>
    <div class="d-flex gap-2">
      <a href="/detalhes/1" class="btn btn-primary">Ver detalhes</a>
      <button type="button" class="btn btn-outline-secondary">Salvar</button>
    </div>
  </div>

  <div class="card-footer text-body-secondary">
    <small>Atualizado em <time datetime="2024-06-15">15 de jun. 2024</time></small>
  </div>
</article>

<!-- card-group: altura uniforme lado a lado -->
<div class="card-group">
  <div class="card">...</div>
  <div class="card">...</div>
  <div class="card">...</div>
</div>
```

---

## Modal

```html
<!-- botão de abertura -->
<button type="button" class="btn btn-danger"
        data-bs-toggle="modal" data-bs-target="#modalConfirmacao">
  Excluir registro
</button>

<!-- estrutura do modal -->
<div class="modal fade" id="modalConfirmacao" tabindex="-1"
     aria-labelledby="modalConfirmacaoLabel" aria-modal="true" role="dialog">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">

      <div class="modal-header">
        <h5 class="modal-title" id="modalConfirmacaoLabel">Confirmar exclusão</h5>
        <!-- botão de fechamento com texto oculto para leitores de tela -->
        <button type="button" class="btn-close" data-bs-dismiss="modal"
                aria-label="Fechar"></button>
      </div>

      <div class="modal-body">
        <p>Tem certeza que deseja excluir este registro? Esta ação não pode ser desfeita.</p>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
          Cancelar
        </button>
        <button type="button" class="btn btn-danger" id="btnConfirmarExclusao">
          Excluir
        </button>
      </div>

    </div>
  </div>
</div>

<script>
  // open/close via JavaScript
  const modal = new bootstrap.Modal(document.getElementById('modalConfirmacao'));
  modal.show();
  modal.hide();
</script>
```

> Sempre definir `aria-labelledby` apontando para o `id` do `<h*>` dentro do modal.

---

## Alert

```html
<!-- variantes de cor: primary | secondary | success | danger | warning | info | light | dark -->
<div class="alert alert-success" role="alert">
  Operação realizada com sucesso.
</div>

<!-- alert com título -->
<div class="alert alert-warning" role="alert">
  <h4 class="alert-heading">Atenção</h4>
  <p>Verifique os dados antes de prosseguir.</p>
  <hr>
  <p class="mb-0">Esta ação afetará todos os registros selecionados.</p>
</div>

<!-- alert descartável -->
<div class="alert alert-info alert-dismissible fade show" role="alert">
  Você tem 3 notificações pendentes.
  <button type="button" class="btn-close" data-bs-dismiss="alert"
          aria-label="Fechar alerta"></button>
</div>
```

---

## Badge, Spinner e Toast

```html
<!-- badge: indicador numérico ou de estado -->
<span class="badge text-bg-primary">Novo</span>
<span class="badge text-bg-danger rounded-pill">42</span>

<!-- badge dentro de botão com texto oculto para leitores de tela -->
<button type="button" class="btn btn-primary">
  Notificações
  <span class="badge text-bg-secondary ms-1">7</span>
  <span class="visually-hidden">notificações não lidas</span>
</button>

<!-- spinner: indica carregamento -->
<div class="spinner-border" role="status" aria-label="Carregando">
  <span class="visually-hidden">Carregando...</span>
</div>
<div class="spinner-grow text-primary" role="status" aria-label="Carregando">
  <span class="visually-hidden">Carregando...</span>
</div>

<!-- toast: notificação temporária -->
<div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
  <div class="toast-header">
    <strong class="me-auto">Sistema</strong>
    <small>agora mesmo</small>
    <button type="button" class="btn-close" data-bs-dismiss="toast"
            aria-label="Fechar"></button>
  </div>
  <div class="toast-body">
    Dados salvos com sucesso.
  </div>
</div>
```

---

## Accordion

```html
<div class="accordion" id="accordionFAQ">

  <div class="accordion-item">
    <h2 class="accordion-header">
      <!-- data-bs-parent: fecha outros itens ao abrir este -->
      <button class="accordion-button" type="button"
              data-bs-toggle="collapse" data-bs-target="#faq1"
              aria-expanded="true" aria-controls="faq1">
        Como faço para redefinir minha senha?
      </button>
    </h2>
    <div id="faq1" class="accordion-collapse collapse show"
         data-bs-parent="#accordionFAQ">
      <div class="accordion-body">
        Acesse a página de login e clique em "Esqueci minha senha".
      </div>
    </div>
  </div>

  <div class="accordion-item">
    <h2 class="accordion-header">
      <button class="accordion-button collapsed" type="button"
              data-bs-toggle="collapse" data-bs-target="#faq2"
              aria-expanded="false" aria-controls="faq2">
        Posso alterar meu e-mail cadastrado?
      </button>
    </h2>
    <div id="faq2" class="accordion-collapse collapse"
         data-bs-parent="#accordionFAQ">
      <div class="accordion-body">
        Sim. Acesse "Meu Perfil" e edite o campo de e-mail.
      </div>
    </div>
  </div>

</div>
```

> `data-bs-parent="#accordionFAQ"` garante que apenas um item fique aberto por vez.

---

## Tabs e Pills

```html
<!-- tabs -->
<div>
  <ul class="nav nav-tabs" role="tablist" aria-label="Seções do painel">
    <li class="nav-item" role="presentation">
      <button class="nav-link active" id="tab-dados" type="button"
              data-bs-toggle="tab" data-bs-target="#painel-dados"
              role="tab" aria-controls="painel-dados" aria-selected="true">
        Dados gerais
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="tab-historico" type="button"
              data-bs-toggle="tab" data-bs-target="#painel-historico"
              role="tab" aria-controls="painel-historico" aria-selected="false">
        Histórico
      </button>
    </li>
    <li class="nav-item" role="presentation">
      <button class="nav-link" id="tab-anexos" type="button"
              data-bs-toggle="tab" data-bs-target="#painel-anexos"
              role="tab" aria-controls="painel-anexos" aria-selected="false">
        Anexos
      </button>
    </li>
  </ul>

  <div class="tab-content border border-top-0 p-3">
    <div class="tab-pane fade show active" id="painel-dados"
         role="tabpanel" aria-labelledby="tab-dados" tabindex="0">
      <h3>Dados Gerais</h3>
      <p>Conteúdo da aba de dados gerais.</p>
    </div>
    <div class="tab-pane fade" id="painel-historico"
         role="tabpanel" aria-labelledby="tab-historico" tabindex="0">
      <h3>Histórico de alterações</h3>
    </div>
    <div class="tab-pane fade" id="painel-anexos"
         role="tabpanel" aria-labelledby="tab-anexos" tabindex="0">
      <h3>Arquivos Anexados</h3>
    </div>
  </div>
</div>

<!-- pills: visual diferente, mesma estrutura de acessibilidade -->
<ul class="nav nav-pills" role="tablist">
  <li class="nav-item" role="presentation">
    <button class="nav-link active" data-bs-toggle="pill"
            data-bs-target="#pill-1" role="tab" aria-selected="true">
      Opção 1
    </button>
  </li>
</ul>
```

> Sempre adicionar `tabindex="0"` nos painéis (`tab-pane`) para que sejam focáveis por teclado.
