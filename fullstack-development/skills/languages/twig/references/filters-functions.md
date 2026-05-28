# Filters, Functions e Tests — Referência Completa

## Built-in Filters

### Texto

| Filter | Parâmetros | Exemplo | Resultado |
|---|---|---|---|
| `upper` | — | `{{ 'olá'\|upper }}` | `OLÁ` |
| `lower` | — | `{{ 'OLÁ'\|lower }}` | `olá` |
| `capitalize` | — | `{{ 'olá mundo'\|capitalize }}` | `Olá mundo` |
| `title` | — | `{{ 'olá mundo'\|title }}` | `Olá Mundo` |
| `trim` | `[chars]` | `{{ '  texto  '\|trim }}` | `texto` |
| `nl2br` | — | `{{ texto\|nl2br }}` | Substitui `\n` por `<br>` |
| `wordwrap` | `width`, `break`, `cut_long_words` | `{{ texto\|wordwrap(80) }}` | Quebra linha em 80 chars |
| `replace` | `from` (array) | `{{ 'Olá %s'\|replace({'%s': nome}) }}` | `Olá João` |
| `slice` | `start`, `length`, `preserve_keys` | `{{ 'abcdef'\|slice(0, 3) }}` | `abc` |
| `split` | `delimiter`, `limit` | `{{ 'a,b,c'\|split(',') }}` | `['a','b','c']` |
| `striptags` | `[allowable_tags]` | `{{ html\|striptags }}` | Remove tags HTML |

```twig
{# Encadeamento de filters #}
{{ usuario.bio|striptags|trim|slice(0, 150) }}

{# replace com múltiplos pares #}
{{ 'Olá, %nome%! Você tem %msgs% mensagens.'|replace({
    '%nome%': usuario.nome,
    '%msgs%': usuario.totalMensagens
}) }}
```

### Números

| Filter | Parâmetros | Exemplo | Resultado |
|---|---|---|---|
| `number_format` | `decimals`, `dec_point`, `thousands_sep` | `{{ 1234.5\|number_format(2, ',', '.') }}` | `1.234,50` |
| `abs` | — | `{{ -42\|abs }}` | `42` |
| `round` | `precision`, `method` (ceil/floor/common) | `{{ 3.456\|round(2) }}` | `3.46` |
| `floor` | — | `{{ 4.7\|floor }}` | `4` |
| `ceil` | — | `{{ 4.1\|ceil }}` | `5` |
| `format_number` | `attrs`, `style`, `type`, `locale` | `{{ 1234\|format_number(locale='pt_BR') }}` | `1.234` (ICU — Twig 3.x) |
| `format_currency` | `currency`, `attrs`, `locale` | `{{ 99.90\|format_currency('BRL', locale='pt_BR') }}` | `R$ 99,90` (ICU) |

> `format_number` e `format_currency` requerem a extensão `symfony/twig-bridge` com `NumberExtension` ou `twig/extra-bundle`.

### Datas

| Filter | Parâmetros | Exemplo |
|---|---|---|
| `date` | `format`, `timezone` | `{{ agora\|date('d/m/Y H:i') }}` |
| `date_modify` | `modifier` | `{{ agora\|date_modify('+1 day')\|date('d/m/Y') }}` |
| `format_date` | `dateFormat`, `pattern`, `locale`, `timezone` | `{{ agora\|format_date(locale='pt_BR') }}` (ICU) |
| `format_datetime` | `dateFormat`, `timeFormat`, `pattern`, `locale`, `timezone` | `{{ agora\|format_datetime('short', 'short', locale='pt_BR') }}` (ICU) |
| `format_time` | `timeFormat`, `pattern`, `locale`, `timezone` | `{{ agora\|format_time(locale='pt_BR') }}` (ICU) |

```twig
{# Formatos comuns de data #}
{{ publicacao.criadoEm|date('d/m/Y') }}
{{ publicacao.criadoEm|date('d/m/Y \à\s H:i') }}

{# Manipulação de data #}
{% set amanha = "now"|date_modify("+1 day") %}
{{ amanha|date('d/m/Y') }}

{# ICU — localização por locale (requer IntlExtension) #}
{{ evento.data|format_datetime('long', 'short', locale='pt_BR') }}
{# Resultado: 15 de janeiro de 2025 às 10:30 #}
```

### Arrays e Coleções

| Filter | Parâmetros | Exemplo |
|---|---|---|
| `length` | — | `{{ lista\|length }}` |
| `first` | — | `{{ lista\|first }}` |
| `last` | — | `{{ lista\|last }}` |
| `sort` | `arrow` | `{{ lista\|sort }}`  |
| `reverse` | `preserve_keys` | `{{ lista\|reverse }}` |
| `merge` | `arr` | `{{ a\|merge(b) }}` |
| `join` | `glue`, `and` | `{{ tags\|join(', ', ' e ') }}` |
| `batch` | `size`, `fill` | `{{ lista\|batch(3, '') }}` |
| `column` | `name` | `{{ usuarios\|column('nome') }}` |
| `map` | `arrow` | `{{ lista\|map(i => i.nome) }}` (Twig 3.x) |
| `filter` | `arrow` | `{{ lista\|filter(i => i.ativo) }}` (Twig 3.x) |
| `reduce` | `arrow`, `initial` | `{{ nums\|reduce((acc, v) => acc + v, 0) }}` (Twig 3.x) |
| `unique` | `arrow` | `{{ lista\|unique }}`|
| `min` | — | `{{ lista\|min }}` |
| `max` | — | `{{ lista\|max }}` |

```twig
{# Arrow functions — Twig 3.x #}
{% set nomes = usuarios|map(u => u.nome) %}
{% set ativos = usuarios|filter(u => u.ativo and u.verificado) %}
{% set somaIdades = usuarios|reduce((acc, u) => acc + u.idade, 0) %}

{# sort com arrow function #}
{% set ordenados = produtos|sort((a, b) => a.preco <=> b.preco) %}

{# batch — divide lista em grupos de N itens #}
{% for linha in produtos|batch(3, null) %}
    <div class="row">
        {% for produto in linha %}
            {% if produto %}
                <div class="col">{{ produto.nome }}</div>
            {% endif %}
        {% endfor %}
    </div>
{% endfor %}

{# join com "e" no último separador #}
{{ categorias|column('nome')|join(', ', ' e ') }}
{# Resultado: Tecnologia, Ciência e Cultura #}
```

### Encoding e Escape

| Filter | Parâmetros | Uso |
|---|---|---|
| `escape` / `e` | `strategy` (html/js/css/url) | Escape explícito por contexto |
| `url_encode` | — | Codifica para URL |
| `json_encode` | `options` | Serializa para JSON |
| `convert_encoding` | `to`, `from` | Converte charset |
| `raw` | — | **Desabilita escape** — usar com cautela |

```twig
{# Escape por contexto (quando auto-escape não é suficiente) #}
<a href="/busca?q={{ termo|url_encode }}">Buscar</a>
<script>var config = {{ configuracao|json_encode }};</script>

{# json_encode com opções #}
{{ dados|json_encode(constant('JSON_PRETTY_PRINT') b-or constant('JSON_UNESCAPED_UNICODE')) }}

{# raw — SOMENTE para HTML gerado internamente confiável #}
{{ artigo.corpoHtml|raw }}
```

### Debug

```twig
{# dump — requer o DebugExtension habilitado #}
{{ dump() }}           {# dump de todas as variáveis do contexto #}
{{ dump(usuario) }}    {# dump de uma variável específica #}
```

---

## Built-in Functions

```twig
{# range — sequência numérica ou de letras #}
{% for i in range(1, 5) %}{{ i }}{% endfor %}
{# 1 2 3 4 5 #}

{% for i in range(0, 10, 2) %}{{ i }} {% endfor %}
{# 0 2 4 6 8 10 #}

{% for letra in range('a', 'e') %}{{ letra }}{% endfor %}
{# a b c d e #}

{# cycle — alterna entre valores #}
{% for i in range(1, 6) %}
    <tr class="{{ cycle(['par', 'ímpar'], loop.index0) }}">
{% endfor %}

{# attribute — acesso dinâmico a propriedade/método #}
{% set campo = 'nome' %}
{{ attribute(usuario, campo) }}
{{ attribute(objeto, 'metodo', [arg1, arg2]) }}

{# block — renderiza conteúdo de um bloco nomeado #}
{{ block('titulo') }}

{# parent — conteúdo do bloco pai (apenas dentro de block que usa extends) #}
{% block scripts %}
    {{ parent() }}
    <script src="extra.js"></script>
{% endblock %}

{# include como função — retorna string em vez de renderizar diretamente #}
{{ include('_partials/card.html.twig', { titulo: 'Teste' }) }}

{# source — retorna código-fonte do template sem renderizar #}
{{ source('email/template.txt.twig') }}

{# template_from_string — cria template a partir de string (evitar em produção) #}
{% set tmpl = template_from_string('Olá {{ nome }}!') %}
{{ include(tmpl) }}

{# random — valor aleatório #}
{{ random(['maçã', 'banana', 'uva']) }}   {# item aleatório do array #}
{{ random(10) }}                           {# inteiro entre 0 e 10 #}
{{ random() }}                             {# inteiro aleatório #}

{# min e max #}
{{ min(1, 3, 2) }}        {# 1 #}
{{ max([4, 2, 8, 1]) }}   {# 8 #}

{# date — cria objeto DateTime a partir de string ou timestamp #}
{% set data = date('2025-01-15') %}
{% set agora = date() %}
{% if publicacao.criadoEm < date('-1 week') %}
    <span>Publicado há mais de uma semana</span>
{% endif %}

{# dump — inspeciona variáveis (requer DebugExtension) #}
{{ dump(usuario, produtos) }}
```

---

## Tests (is / is not)

Tests verificam condições sobre valores. Usados com `is` ou `is not`.

| Test | Uso | Equivalente PHP |
|---|---|---|
| `defined` | `{% if x is defined %}` | `isset($x)` |
| `null` | `{% if x is null %}` | `$x === null` |
| `empty` | `{% if lista is empty %}` | `empty($lista)` |
| `iterable` | `{% if x is iterable %}` | `is_array($x) \|\| ($x instanceof Traversable)` |
| `divisible by` | `{% if loop.index is divisible by 3 %}` | `$i % 3 === 0` |
| `same as` | `{% if status is same as true %}` | `$x === true` |
| `odd` | `{% if n is odd %}` | `$n % 2 !== 0` |
| `even` | `{% if n is even %}` | `$n % 2 === 0` |

```twig
{# Padrão seguro para variáveis opcionais #}
{% if variavel is defined and variavel is not null %}
    {{ variavel }}
{% endif %}

{# Alternativa com default #}
{{ variavel|default('valor padrão') }}

{# Verificar tipo iterável antes de fazer for #}
{% if dados is iterable %}
    {% for item in dados %}...{% endfor %}
{% endif %}

{# Linhas alternadas na tabela #}
{% for linha in tabela %}
    <tr class="{{ loop.index is even ? 'par' : 'ímpar' }}">
{% endfor %}

{# Divisor — separador a cada 3 itens #}
{% for item in lista %}
    {{ item.nome }}
    {% if not loop.last and loop.index is divisible by 3 %}
        <hr>
    {% endif %}
{% endfor %}
```

---

## Arrow Functions em Filters (Twig 3.x)

Arrow functions tornam `|map`, `|filter`, `|reduce` e `|sort` muito mais expressivos.

```twig
{# map — transforma cada elemento #}
{% set titulos = artigos|map(a => a.titulo) %}
{% set pares = numeros|map(n => n * 2) %}

{# filter — seleciona elementos que satisfazem condição #}
{% set ativos = usuarios|filter(u => u.ativo) %}
{% set caros = produtos|filter(p => p.preco > 100) %}

{# reduce — acumula valor a partir de coleção #}
{% set total = carrinho|reduce((acc, item) => acc + item.preco * item.qtd, 0) %}
{% set maior = numeros|reduce((acc, n) => n > acc ? n : acc, 0) %}

{# sort com comparador customizado #}
{% set ordenados = produtos|sort((a, b) => a.preco <=> b.preco) %}
{% set ordenadosDesc = usuarios|sort((a, b) => b.nome <=> a.nome) %}

{# Encadeamento #}
{% set resultado = usuarios
    |filter(u => u.ativo)
    |sort((a, b) => a.nome <=> b.nome)
    |map(u => u.nome)
    |join(', ')
%}
```
