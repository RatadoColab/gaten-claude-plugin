---
name: twig
description: This skill should be used when writing, reviewing, or refactoring Twig templates (3.11.x). Covers template syntax and delimiters, inheritance (extends/block/embed/use), variables and scope, built-in filters and functions, macros, control tags, auto-escaping and security, performance best practices, and anti-patterns. Use when the user asks to "write a Twig template", "create a base layout", "add a Twig macro", "use Twig filters", "configure Twig environment", "review Twig code", "add template inheritance", or "fix Twig escaping".
version: 0.2.0
---

# Twig — Convenções e Boas Práticas (3.11.x)

Diretrizes para escrita de templates Twig limpos, reutilizáveis e seguros com base no Twig 3.11.x.

> **Twig 3.x — mudanças relevantes**: suporte a PHP 5 e 7 removido (PHP 8.0+ obrigatório); namespace migrado de `Twig_` para `Twig\`; arrow functions disponíveis em `|map`, `|filter`, `|reduce`; `spaceless` virou tag (`{% apply spaceless %}`); filtros de data internacionalizados via ICU (`format_date`, `format_datetime`, `format_time`).

---

## Delimitadores e Sintaxe

| Delimitador | Tipo | Quando usar |
|---|---|---|
| `{{ expressão }}` | Output | Exibir variável, resultado de filtro ou função |
| `{% tag %}` | Tag de controle | `if`, `for`, `block`, `extends`, `set`, `apply`, etc. |
| `{# comentário #}` | Comentário | Notas que **não** aparecem no HTML renderizado |

```twig
{# Output com filtro — auto-escapado por padrão #}
{{ user.name|upper }}

{# Tag de controle #}
{% if user.isActive %}
    <span>Ativo</span>
{% endif %}

{# Comentário — não aparece no HTML gerado #}
{# TODO: substituir por componente reutilizável #}
```

> Auto-escape está **ativo por padrão** no Twig 3. Todo `{{ }}` escapa HTML automaticamente via `htmlspecialchars`. Usar `|raw` apenas quando o conteúdo for HTML confiável gerado internamente.

---

## Herança de Templates

| Mecanismo | Descrição | Quando usar |
|---|---|---|
| `extends` | Herança vertical — filha herda o layout da pai | Layout de página |
| `block` | Define região substituível/extensível | Dentro de `extends` |
| `{{ parent() }}` | Inclui o conteúdo do bloco pai | Quando precisa acrescentar, não substituir |
| `include` | Inclui um sub-template com contexto | Fragmentos reutilizáveis (header, card) |
| `embed` | Combina `include` + `extends` — inclui e sobrescreve blocos | Componentes configuráveis |
| `use` | Importa blocos de outro template sem herança | Reutilização horizontal de blocos |

```twig
{# Herança simples #}
{% extends 'base.html.twig' %}

{% block title %}Dashboard{% endblock %}

{% block content %}
    <h1>Bem-vindo, {{ user.name }}</h1>
    {# Acrescenta ao bloco pai sem substituir #}
    {% block scripts %}
        {{ parent() }}
        <script src="dashboard.js"></script>
    {% endblock %}
{% endblock %}
```

Para padrões completos de herança, `embed`, `use` e exemplos de `base.html.twig`, consultar **`references/template-inheritance.md`**.

---

## Variáveis e Escopo

```twig
{# Definir variável local #}
{% set titulo = 'Relatório Anual' %}

{# Variável a partir de expressão #}
{% set total = items|length %}

{# Acesso a atributos: dot notation (preferida) #}
{{ user.name }}        {# chama user.name ou user['name'] ou user.getName() #}
{{ user['email'] }}    {# equivalente — útil quando a chave tem caracteres especiais #}

{# Variáveis globais disponíveis: _self, _context, _charset #}
{{ _self.templateName }}   {# nome do template atual #}

{# Bloco with — escopo isolado #}
{% with { mensagem: 'Olá' } %}
    {{ mensagem }}
{% endwith %}
```

| Acesso | Comportamento |
|---|---|
| `obj.prop` | Tenta: `obj.prop`, `obj['prop']`, `obj->prop`, `obj->getProp()`, `obj->isProp()` |
| `obj['prop']` | Acesso direto a array/objeto com chave literal |
| `attribute(obj, 'prop')` | Acesso dinâmico — quando a chave é uma variável |

---

## Filters e Functions Essenciais

Filters mais usados (lista completa — `batch`, `column`, encoding, `format_date` etc. — e arrow functions `map`/`filter`/`reduce` em **`references/filters-functions.md`**):

| Filter | Exemplo | PHP |
|---|---|---|
| `default` | `{{ nome\|default('Anônimo') }}` | `?? 'Anônimo'` |
| `date` | `{{ now\|date('d/m/Y') }}` | `date()` |
| `number_format` | `{{ valor\|number_format(2, ',', '.') }}` | `number_format()` |
| `length` | `{{ lista\|length }}` | `count()`/`strlen()` |
| `join` | `{{ tags\|join(', ') }}` | `implode()` |
| `json_encode` | `{{ dados\|json_encode }}` | `json_encode()` |
| `raw` | `{{ html\|raw }}` | — (desabilita escape) |

Functions mais usadas: `range()` (sequência), `cycle()` (alterna valores), `attribute()` (acesso dinâmico), `block()`/`parent()` (herança), `dump()` (debug), `include()`/`source()`. Detalhes e demais funções em **`references/filters-functions.md`**.

---

## Tags de Controle

```twig
{# for com else — else executado quando a lista é vazia #}
{% for item in lista %}
    <li>{{ item.nome }}</li>
{% else %}
    <li>Nenhum item encontrado.</li>
{% endfor %}

{# Variáveis do loop: loop.index (1-based), loop.index0, loop.first, loop.last, loop.length #}
{% for produto in produtos %}
    {% if loop.first %}<ul>{% endif %}
    <li class="{{ cycle(['par', 'ímpar'], loop.index0) }}">{{ produto.nome }}</li>
    {% if loop.last %}</ul>{% endif %}
{% endfor %}

{# if / elseif / else #}
{% if usuario.papel == 'admin' %}
    <a href="/admin">Painel</a>
{% elseif usuario.papel == 'editor' %}
    <a href="/editor">Editor</a>
{% else %}
    <a href="/perfil">Perfil</a>
{% endif %}

{# apply — aplica filtro a bloco de conteúdo #}
{% apply upper %}
    texto em maiúsculas
{% endapply %}

{# verbatim — evita que Twig processe o conteúdo (útil com Vue/Angular) #}
{% verbatim %}
    {{ variavel_do_vue }}
{% endverbatim %}

{# with — escopo isolado #}
{% with { cor: 'azul', tamanho: 'lg' } only %}
    <div class="btn btn-{{ cor }} btn-{{ tamanho }}">Clique</div>
{% endwith %}
```

---

## Segurança

| Mecanismo | Comportamento |
|---|---|
| Auto-escape (padrão) | Todo `{{ }}` escapa HTML via `htmlspecialchars` |
| `\|raw` | **Desabilita** o escape — usar apenas com HTML gerado internamente |
| `\|escape('js')` | Escapa para contexto JavaScript |
| `\|escape('css')` | Escapa para contexto CSS |
| `\|escape('url')` | Equivale a `urlencode()` |
| Sandbox mode | Restringe tags/filtros/funções em templates não confiáveis |

```twig
{# Seguro — auto-escape ativo #}
{{ user.bio }}

{# Perigoso — desabilita escape; usar SOMENTE se o valor for HTML interno confiável #}
{{ artigo.conteudoHtml|raw }}

{# Escape explícito em contexto JS #}
<script>
    var nome = {{ user.name|json_encode }};
</script>
```

> **Nunca** usar `|raw` com input de usuário. Se precisar permitir HTML do usuário, usar uma biblioteca de sanitização (ex.: `HTMLPurifier`) antes de passar a variável ao template.

Para sandbox mode, `SandboxExtension` e configuração de políticas, consultar **`references/template-inheritance.md`**.

---

## Anti-Patterns

| Anti-Pattern | Problema | Solução |
|---|---|---|
| Lógica de negócio no template | Templates difíceis de testar e manter | Processar no controller/service; passar dados prontos |
| `\|raw` com input de usuário | XSS | Sanitizar antes (ver seção Segurança); nunca confiar no input |
| Acesso profundo `obj.a.b.c.d` | Acoplamento forte ao modelo de dados | Criar variável intermediária com `{% set %}` |
| Queries dentro de template (via serviço injetado) | N+1, lógica de dados no template | Pré-carregar no controller e passar coleção pronta |
| Duplicação de fragmentos sem `include` | Inconsistência ao alterar layout | Extrair para `_partial.html.twig` e usar `include` |
| `{% if x is not null %}` sem verificar `defined` | `Undefined variable` em templates com dados opcionais | Usar `{% if x is defined and x is not null %}` |
| Macros com efeitos colaterais (output direto) | Macros difíceis de reutilizar | Macros devem retornar HTML; controller trata lógica |
| Templates sem herança em projeto grande | Duplicação de `<head>`, `<nav>`, `<footer>` | Criar `base.html.twig` e usar `extends` |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/template-inheritance.md`** | extends, block, parent(), include, embed, use, base.html.twig completo |
| **`references/filters-functions.md`** | Todos os filters e functions built-in, tests, arrow functions |
| **`references/macros.md`** | Definição, importação, escopo, exemplos de componentes com macros |
| **`references/performance.md`** | Cache de templates, produção vs desenvolvimento, profiling, checklist |

---

## Também consultar

- `languages/html/SKILL.md` — estrutura HTML semântica e acessibilidade
- `languages/php/SKILL.md` — PHP moderno para controllers e services que alimentam os templates
