# Herança de Templates — Referência Completa

## extends e block

O mecanismo principal de reutilização no Twig. Um template filho declara `extends` e sobrescreve blocos definidos pelo pai.

```twig
{# base.html.twig — template pai com blocos substituíveis #}
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Site{% endblock %} — IBGE</title>
    {% block meta %}{% endblock %}
    {% block stylesheets %}
        <link rel="stylesheet" href="/css/app.css">
    {% endblock %}
</head>
<body class="{% block body_class %}{% endblock %}">

    {% block header %}
        <header>
            <nav>{% block nav %}{% endblock %}</nav>
        </header>
    {% endblock %}

    <main>
        {% block content %}{% endblock %}
    </main>

    {% block footer %}
        <footer><p>© {{ "now"|date("Y") }} IBGE</p></footer>
    {% endblock %}

    {% block javascripts %}
        <script src="/js/app.js"></script>
    {% endblock %}

</body>
</html>
```

```twig
{# pages/dashboard.html.twig — template filho #}
{% extends 'base.html.twig' %}

{% block title %}Dashboard{% endblock %}

{% block meta %}
    <meta name="description" content="Painel principal do sistema">
{% endblock %}

{% block body_class %}page-dashboard{% endblock %}

{% block content %}
    <h1>Bem-vindo, {{ user.name }}</h1>
    <section class="cards">
        {% for card in cards %}
            <div class="card">{{ card.title }}</div>
        {% endfor %}
    </section>
{% endblock %}

{# parent() acrescenta ao bloco pai sem substituir todo o conteúdo #}
{% block javascripts %}
    {{ parent() }}
    <script src="/js/dashboard.js"></script>
{% endblock %}
```

### Blocos aninhados

Blocos podem ser aninhados. O filho pode sobrescrever tanto o bloco pai quanto os blocos internos.

```twig
{# No pai #}
{% block sidebar %}
    <aside>
        {% block sidebar_nav %}
            <ul><li><a href="/">Início</a></li></ul>
        {% endblock %}
        {% block sidebar_ads %}{% endblock %}
    </aside>
{% endblock %}

{# No filho — sobrescreve apenas o bloco interno #}
{% block sidebar_nav %}
    <ul>
        <li><a href="/dashboard">Dashboard</a></li>
        <li><a href="/relatorios">Relatórios</a></li>
    </ul>
{% endblock %}
```

### Convenção de nomenclatura de blocos

| Bloco | Conteúdo |
|---|---|
| `title` | Título da página (sem sufixo do site) |
| `meta` | Tags `<meta>` específicas da página |
| `stylesheets` | Links CSS adicionais da página |
| `body_class` | Classes CSS do elemento `<body>` |
| `header` | Cabeçalho completo (substituível) |
| `nav` | Navegação principal |
| `content` | Conteúdo principal da página |
| `sidebar` | Barra lateral |
| `footer` | Rodapé completo (substituível) |
| `javascripts` | Scripts JS adicionais da página |

---

## include

Inclui um sub-template passando variáveis de contexto. Ideal para fragmentos reutilizáveis.

```twig
{# Inclusão simples — herda todo o contexto atual #}
{% include '_partials/alert.html.twig' %}

{# Inclusão com variáveis extras passadas via with #}
{% include '_partials/card.html.twig' with { titulo: produto.nome, valor: produto.preco } %}

{# only — isola o contexto; apenas as variáveis passadas em with ficam disponíveis #}
{% include '_partials/card.html.twig' with { titulo: 'Teste' } only %}

{# ignore missing — não lança erro se o arquivo não existir #}
{% include '_partials/banner-topo.html.twig' ignore missing %}

{# ignore missing + with combinados #}
{% include '_partials/anuncio.html.twig' with { pagina: 'home' } only ignore missing %}
```

> Usar `only` para fragmentos que devem ser isolados do contexto global — evita vazamento acidental de variáveis.

---

## embed

Combina `include` e `extends`: inclui um template e permite sobrescrever seus blocos. Útil para componentes configuráveis.

```twig
{# _components/modal.html.twig — template base do modal #}
<div class="modal" id="{{ id|default('modal') }}">
    <div class="modal-header">
        {% block modal_title %}Título{% endblock %}
    </div>
    <div class="modal-body">
        {% block modal_body %}{% endblock %}
    </div>
    <div class="modal-footer">
        {% block modal_footer %}
            <button class="btn btn-secondary" data-dismiss="modal">Fechar</button>
        {% endblock %}
    </div>
</div>

{# Uso com embed — sobrescreve blocos sem criar herança #}
{% embed '_components/modal.html.twig' with { id: 'modal-confirmacao' } %}
    {% block modal_title %}Confirmar exclusão{% endblock %}
    {% block modal_body %}
        <p>Tem certeza que deseja excluir o registro <strong>{{ item.nome }}</strong>?</p>
    {% endblock %}
    {% block modal_footer %}
        <form method="post" action="/itens/{{ item.id }}/excluir">
            <button type="submit" class="btn btn-danger">Excluir</button>
            <button type="button" class="btn btn-secondary">Cancelar</button>
        </form>
    {% endblock %}
{% endembed %}
```

### include vs embed — quando usar cada um

| Situação | Usar |
|---|---|
| Fragmento fixo sem variações de estrutura (ex.: rodapé) | `include` |
| Fragmento com regiões variáveis por contexto (ex.: modal, card) | `embed` |
| Layout que envolve todo o conteúdo da página | `extends` |
| Reutilizar blocos sem herança de layout | `use` |

---

## use — reutilização horizontal de blocos

Importa blocos de outro template sem estabelecer herança. Útil para mixins de blocos.

```twig
{# _blocks/paginacao.html.twig #}
{% block paginacao %}
    <nav class="paginacao">
        {% if pagina > 1 %}
            <a href="?pagina={{ pagina - 1 }}">Anterior</a>
        {% endif %}
        <span>Página {{ pagina }} de {{ totalPaginas }}</span>
        {% if pagina < totalPaginas %}
            <a href="?pagina={{ pagina + 1 }}">Próxima</a>
        {% endif %}
    </nav>
{% endblock %}

{# Importando o bloco em outro template #}
{% extends 'base.html.twig' %}
{% use '_blocks/paginacao.html.twig' %}

{% block content %}
    {% for item in itens %}...{% endfor %}
    {{ block('paginacao') }}
{% endblock %}
```

---

## Sandboxing de includes

O Sandbox mode restringe quais tags, filtros e funções podem ser usados em templates carregados de fontes não confiáveis (ex.: templates editados pelo usuário final).

```php
// Configuração do ambiente Twig com sandbox
use Twig\Environment;
use Twig\Extension\SandboxExtension;
use Twig\Sandbox\SecurityPolicy;
use Twig\Loader\FilesystemLoader;

$tags      = ['if', 'for', 'set'];           // tags permitidas
$filters   = ['upper', 'lower', 'date'];     // filtros permitidos
$methods   = [];                              // métodos de objeto permitidos
$properties = [];                             // propriedades permitidas
$functions = ['range', 'cycle'];              // funções permitidas

$policy = new SecurityPolicy($tags, $filters, $methods, $properties, $functions);
$sandbox = new SandboxExtension($policy);
$twig->addExtension($sandbox);

// Renderiza template de usuário em modo sandbox
$template = $twig->load('user_template.html.twig');
// Qualquer tag/filtro fora da policy lança Twig\Sandbox\SecurityError
```

```twig
{# Template confiável pode incluir um template não confiável em sandbox #}
{% sandbox %}
    {% include template_do_usuario %}
{% endsandbox %}
```

---

## Exemplo completo: base.html.twig

```twig
{# templates/base.html.twig #}
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">

    <title>{% block title %}Sistema{% endblock %} | IBGE</title>

    {% block meta %}
        <meta name="robots" content="noindex, nofollow">
    {% endblock %}

    {% block stylesheets %}
        <link rel="stylesheet" href="/css/bootstrap.min.css">
        <link rel="stylesheet" href="/css/app.css">
    {% endblock %}
</head>
<body class="layout-default {% block body_class %}{% endblock %}">

    {% block header %}
        <header class="site-header">
            <div class="container">
                <a href="/" class="logo">IBGE</a>
                {% block nav %}
                    <nav>
                        <a href="/dashboard">Dashboard</a>
                        <a href="/relatorios">Relatórios</a>
                    </nav>
                {% endblock %}
                {% if app.user is defined %}
                    <span class="user-info">{{ app.user.name }}</span>
                {% endif %}
            </div>
        </header>
    {% endblock %}

    {% block flash_messages %}
        {% for type, messages in app.flashes %}
            {% for message in messages %}
                <div class="alert alert-{{ type }}">{{ message }}</div>
            {% endfor %}
        {% endfor %}
    {% endblock %}

    <main class="site-main">
        <div class="container">
            {% block content %}{% endblock %}
        </div>
    </main>

    {% block footer %}
        <footer class="site-footer">
            <p>© {{ "now"|date("Y") }} IBGE — Todos os direitos reservados.</p>
        </footer>
    {% endblock %}

    {% block javascripts %}
        <script src="/js/bootstrap.bundle.min.js"></script>
        <script src="/js/app.js"></script>
    {% endblock %}

</body>
</html>
```

## Exemplo completo: página extendendo a base

```twig
{# templates/pages/relatorios/index.html.twig #}
{% extends 'base.html.twig' %}

{% block title %}Relatórios{% endblock %}

{% block meta %}
    {{ parent() }}
    <meta name="description" content="Listagem de relatórios disponíveis">
{% endblock %}

{% block body_class %}page-relatorios{% endblock %}

{% block content %}
    <h1>Relatórios</h1>

    {% if relatorios is empty %}
        <p class="empty-state">Nenhum relatório disponível no momento.</p>
    {% else %}
        <div class="grid">
            {% for relatorio in relatorios %}
                {% include '_partials/card-relatorio.html.twig' with { relatorio: relatorio } only %}
            {% endfor %}
        </div>
    {% endif %}
{% endblock %}

{% block javascripts %}
    {{ parent() }}
    <script src="/js/relatorios.js"></script>
{% endblock %}
```
