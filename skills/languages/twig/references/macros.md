# Macros — Referência Completa

Macros são funções reutilizáveis dentro de templates Twig. Recebem parâmetros, têm escopo próprio e retornam HTML. Ideais para componentes de UI repetidos (inputs, botões, cards, paginação).

## Definição de macro

```twig
{# Sintaxe básica — parâmetros com valores padrão #}
{% macro input(name, value = '', type = 'text', label = '', required = false) %}
    {# Macros têm escopo próprio — não acessam variáveis do template que as chama #}
    <div class="form-group">
        {% if label %}
            <label for="{{ name }}">
                {{ label }}
                {% if required %}<span class="required" aria-label="obrigatório">*</span>{% endif %}
            </label>
        {% endif %}
        <input
            type="{{ type }}"
            id="{{ name }}"
            name="{{ name }}"
            value="{{ value }}"
            class="form-control"
            {{ required ? 'required' : '' }}
        >
    </div>
{% endmacro %}
```

> Macros têm escopo isolado: não enxergam variáveis globais do template (como `app`, `user`). Para acessá-las, passe explicitamente como parâmetro.

---

## Chamada no mesmo arquivo

Usar `_self` para chamar macros definidas no mesmo arquivo.

```twig
{% macro badge(texto, tipo = 'secondary') %}
    <span class="badge bg-{{ tipo }}">{{ texto }}</span>
{% endmacro %}

{# Chamada com _self #}
<p>Status: {{ _self.badge(usuario.status, 'success') }}</p>
<p>Papel: {{ _self.badge(usuario.papel) }}</p>
```

---

## Importação de arquivo externo

### Importar todo o arquivo como namespace

```twig
{# Importa todas as macros de forms.html.twig no namespace "forms" #}
{% import 'macros/forms.html.twig' as forms %}

{{ forms.input('nome', usuario.nome, 'text', 'Nome completo', true) }}
{{ forms.select('estado', estados, usuario.estadoId, 'Estado') }}
{{ forms.textarea('bio', usuario.bio, 'Biografia', 3) }}
{{ forms.button('Salvar', 'submit', 'primary') }}
```

### Importação parcial (from)

```twig
{# Importa apenas macros específicas #}
{% from 'macros/forms.html.twig' import input, select, button %}
{% from 'macros/ui.html.twig' import alert, badge, pagination %}

{{ input('email', '', 'email', 'E-mail', true) }}
{{ alert('Operação realizada com sucesso.', 'success') }}
```

---

## Escopo de macros

```twig
{# Variáveis especiais disponíveis dentro de macros #}
{% macro debug_info(nome) %}
    {# _context — acessa o contexto completo como array (use com moderação) #}
    {# _charset — charset atual do ambiente Twig #}
    {# varargs — argumentos posicionais extras além dos declarados #}
    {# caller — o bloco que chamou a macro (se chamada com call) #}

    Nome: {{ nome }}
    Charset: {{ _charset }}
{% endmacro %}

{# Passar variável global explicitamente #}
{% macro saudacao(nome, usuario) %}
    Olá, {{ nome }}! Seu papel é {{ usuario.papel }}.
{% endmacro %}

{# Chamada passando variável global como parâmetro #}
{{ _self.saudacao('Visitante', app.user) }}
```

---

## Exemplo completo: macros/ui.html.twig

```twig
{# templates/macros/ui.html.twig #}

{# ============================================================
   Input field with label and optional required marker
   ============================================================ #}
{% macro input(name, value = '', type = 'text', label = '', required = false, placeholder = '') %}
    <div class="mb-3">
        {% if label %}
            <label class="form-label" for="{{ name }}">
                {{ label }}{% if required %} <span class="text-danger">*</span>{% endif %}
            </label>
        {% endif %}
        <input
            type="{{ type }}"
            class="form-control"
            id="{{ name }}"
            name="{{ name }}"
            value="{{ value|e }}"
            {{ placeholder ? 'placeholder="' ~ placeholder|e ~ '"' : '' }}
            {{ required ? 'required' : '' }}
        >
    </div>
{% endmacro %}

{# ============================================================
   Select/dropdown with options array
   options: array of {value, label} or flat array
   ============================================================ #}
{% macro select(name, options, selected = '', label = '', required = false) %}
    <div class="mb-3">
        {% if label %}
            <label class="form-label" for="{{ name }}">
                {{ label }}{% if required %} <span class="text-danger">*</span>{% endif %}
            </label>
        {% endif %}
        <select class="form-select" id="{{ name }}" name="{{ name }}" {{ required ? 'required' : '' }}>
            <option value="">Selecione...</option>
            {% for option in options %}
                {% if option.value is defined %}
                    <option value="{{ option.value }}" {{ option.value == selected ? 'selected' : '' }}>
                        {{ option.label }}
                    </option>
                {% else %}
                    <option value="{{ option }}" {{ option == selected ? 'selected' : '' }}>
                        {{ option }}
                    </option>
                {% endif %}
            {% endfor %}
        </select>
    </div>
{% endmacro %}

{# ============================================================
   Textarea with auto-resize rows
   ============================================================ #}
{% macro textarea(name, value = '', label = '', rows = 4, required = false) %}
    <div class="mb-3">
        {% if label %}
            <label class="form-label" for="{{ name }}">
                {{ label }}{% if required %} <span class="text-danger">*</span>{% endif %}
            </label>
        {% endif %}
        <textarea
            class="form-control"
            id="{{ name }}"
            name="{{ name }}"
            rows="{{ rows }}"
            {{ required ? 'required' : '' }}
        >{{ value|e }}</textarea>
    </div>
{% endmacro %}

{# ============================================================
   Button with variant and optional icon
   ============================================================ #}
{% macro button(label, type = 'button', variant = 'primary', icon = '', attrs = '') %}
    <button type="{{ type }}" class="btn btn-{{ variant }}" {{ attrs|raw }}>
        {% if icon %}<i class="{{ icon }}"></i> {% endif %}
        {{ label }}
    </button>
{% endmacro %}

{# ============================================================
   Alert/notification box
   type: success | danger | warning | info
   ============================================================ #}
{% macro alert(mensagem, type = 'info', dismissible = false) %}
    <div class="alert alert-{{ type }}{% if dismissible %} alert-dismissible fade show{% endif %}" role="alert">
        {{ mensagem }}
        {% if dismissible %}
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Fechar"></button>
        {% endif %}
    </div>
{% endmacro %}

{# ============================================================
   Badge/pill label
   ============================================================ #}
{% macro badge(texto, variant = 'secondary', pill = false) %}
    <span class="badge bg-{{ variant }}{% if pill %} rounded-pill{% endif %}">{{ texto }}</span>
{% endmacro %}

{# ============================================================
   Pagination component
   pagina: current page (1-based)
   totalPaginas: total pages
   baseUrl: URL without ?pagina= parameter
   ============================================================ #}
{% macro pagination(pagina, totalPaginas, baseUrl = '') %}
    {% if totalPaginas > 1 %}
        <nav aria-label="Paginação">
            <ul class="pagination justify-content-center">
                <li class="page-item {% if pagina <= 1 %}disabled{% endif %}">
                    <a class="page-link" href="{{ baseUrl }}?pagina={{ pagina - 1 }}" aria-label="Anterior">
                        <span aria-hidden="true">&laquo;</span>
                    </a>
                </li>

                {% for p in range([1, pagina - 2]|max, [totalPaginas, pagina + 2]|min) %}
                    <li class="page-item {% if p == pagina %}active{% endif %}">
                        <a class="page-link" href="{{ baseUrl }}?pagina={{ p }}">{{ p }}</a>
                    </li>
                {% endfor %}

                <li class="page-item {% if pagina >= totalPaginas %}disabled{% endif %}">
                    <a class="page-link" href="{{ baseUrl }}?pagina={{ pagina + 1 }}" aria-label="Próxima">
                        <span aria-hidden="true">&raquo;</span>
                    </a>
                </li>
            </ul>
        </nav>
    {% endif %}
{% endmacro %}
```

### Uso do arquivo de macros

```twig
{# templates/pages/usuarios/form.html.twig #}
{% extends 'base.html.twig' %}

{% from 'macros/ui.html.twig' import input, select, textarea, button, alert %}

{% block content %}
    <h1>{{ usuario.id ? 'Editar' : 'Novo' }} Usuário</h1>

    {% if erros is defined and erros is not empty %}
        {{ alert('Corrija os erros abaixo antes de continuar.', 'danger') }}
    {% endif %}

    <form method="post" action="/usuarios/{{ usuario.id ? usuario.id ~ '/editar' : 'novo' }}">
        {{ input('nome', usuario.nome|default(''), 'text', 'Nome completo', true) }}
        {{ input('email', usuario.email|default(''), 'email', 'E-mail', true) }}
        {{ select('papel', papeis, usuario.papel|default(''), 'Papel', true) }}
        {{ textarea('bio', usuario.bio|default(''), 'Biografia', 4) }}
        {{ button('Salvar', 'submit', 'primary', 'bi bi-save') }}
        {{ button('Cancelar', 'button', 'secondary', '', 'onclick="history.back()"') }}
    </form>
{% endblock %}
```

---

## Macros como componentes reutilizáveis

### Macro de card

```twig
{% macro card(titulo, corpo, rodape = '', variante = '') %}
    <div class="card {% if variante %}border-{{ variante }}{% endif %} mb-3">
        <div class="card-header">{{ titulo }}</div>
        <div class="card-body">{{ corpo|raw }}</div>
        {% if rodape %}
            <div class="card-footer text-muted">{{ rodape }}</div>
        {% endif %}
    </div>
{% endmacro %}
```

### Macro de tabela com cabeçalho

```twig
{% macro tabela(colunas, linhas, caption = '') %}
    <div class="table-responsive">
        <table class="table table-striped table-hover">
            {% if caption %}
                <caption>{{ caption }}</caption>
            {% endif %}
            <thead class="table-dark">
                <tr>
                    {% for coluna in colunas %}
                        <th>{{ coluna }}</th>
                    {% endfor %}
                </tr>
            </thead>
            <tbody>
                {% for linha in linhas %}
                    <tr>
                        {% for celula in linha %}
                            <td>{{ celula }}</td>
                        {% endfor %}
                    </tr>
                {% else %}
                    <tr>
                        <td colspan="{{ colunas|length }}" class="text-center text-muted">
                            Nenhum registro encontrado.
                        </td>
                    </tr>
                {% endfor %}
            </tbody>
        </table>
    </div>
{% endmacro %}
```
