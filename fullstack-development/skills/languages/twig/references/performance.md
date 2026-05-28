# Performance em Twig — Referência Completa

## Compilação de templates

O Twig compila cada template `.html.twig` para uma classe PHP pura na primeira requisição. As subsequentes usam o arquivo compilado em cache — sem re-parsing.

```
templates/
└── pages/dashboard.html.twig

var/cache/twig/                          ← compilado automaticamente
└── a1/a1b2c3d4e5_dashboard.html.twig.php
```

### Localização do cache

O Twig armazena os arquivos compilados no caminho configurado em `cache`. Sem cache configurado, o template é recompilado a cada requisição.

```php
// Configuração mínima recomendada para produção
use Twig\Environment;
use Twig\Loader\FilesystemLoader;

$loader = new FilesystemLoader('/caminho/para/templates');
$twig   = new Environment($loader, [
    'cache'       => '/caminho/para/var/cache/twig',   // obrigatório para performance
    'debug'       => false,                             // desabilita dump() e outros helpers
    'auto_reload' => false,                             // não verifica se template mudou
    'strict_variables' => true,                         // erro em variável não definida
    'charset'     => 'UTF-8',
]);
```

---

## Produção vs Desenvolvimento

| Opção | Desenvolvimento | Produção |
|---|---|---|
| `cache` | `false` ou path temporário | Path persistente com permissão de escrita |
| `debug` | `true` | `false` |
| `auto_reload` | `true` | `false` |
| `strict_variables` | `true` | `true` (recomendado) |
| DebugExtension | Habilitada | **Desabilitada** |

```php
// Configuração por ambiente
$isDev = $_ENV['APP_ENV'] === 'development';

$twig = new Environment($loader, [
    'cache'            => $isDev ? false : __DIR__ . '/../var/cache/twig',
    'debug'            => $isDev,
    'auto_reload'      => $isDev,
    'strict_variables' => true,
]);

if ($isDev) {
    $twig->addExtension(new \Twig\Extension\DebugExtension());
}
```

> Em produção, `auto_reload: false` significa que Twig **não** verifica se o template mudou no disco. Após deploy, limpe o cache manualmente (`rm -rf var/cache/twig/*`).

---

## Cache de fragmentos com `{% cache %}` tag

A tag `{% cache %}` não é built-in do Twig — está disponível via `twig/cache-extra` ou `symfony/twig-bridge`.

```twig
{# Cache de bloco por 3600 segundos (requer CacheExtension) #}
{% cache 'bloco-noticias-' ~ categoria.id ttl 3600 %}
    {% for noticia in noticias %}
        {% include '_partials/card-noticia.html.twig' with { noticia: noticia } only %}
    {% endfor %}
{% endcache %}
```

**Alternativa sem extensão**: cachear no controller antes de renderizar.

```php
// Cache no controller — mais simples e sem dependência de extensão Twig
$cacheKey = 'noticias_' . $categoriaId;
$noticias = $this->cache->get($cacheKey, function () use ($categoriaId) {
    return $this->noticiaRepository->findByCategoria($categoriaId);
});

return $twig->render('noticias/index.html.twig', ['noticias' => $noticias]);
```

---

## Evitar lógica pesada nos templates

Templates Twig devem receber dados **prontos para exibição**. Toda query, cálculo e transformação deve ocorrer no controller ou service.

```twig
{# Ruim — acessa serviço injetado com query dentro do template #}
{% for usuario in usuarioService.findAll() %}
    {{ usuario.nome }}
{% endfor %}

{# Correto — controller passa a coleção pronta #}
{% for usuario in usuarios %}
    {{ usuario.nome }}
{% endfor %}
```

```twig
{# Ruim — lógica de negócio no template #}
{% set desconto = produto.preco > 100 ? produto.preco * 0.1 : 0 %}
{% set precoFinal = produto.preco - desconto %}

{# Correto — template recebe precoFinal já calculado #}
{{ produto.precoFinal|number_format(2, ',', '.') }}
```

---

## Tests para variáveis opcionais

Usar o test correto evita erros de "Undefined variable" e comportamentos inesperados.

| Situação | Test recomendado |
|---|---|
| Variável pode não ter sido passada ao template | `is defined` |
| Variável existe mas pode ser `null` | `is not null` |
| Variável existe mas pode ser vazia (string, array) | `is not empty` |
| Verificação segura combinada | `is defined and variavel is not null` |

```twig
{# Verificação segura antes de usar #}
{% if erro is defined and erro is not null %}
    <div class="alert alert-danger">{{ erro }}</div>
{% endif %}

{# Simplificado com default #}
{{ erro|default('') }}

{# Para arrays: empty é mais semântico que length == 0 #}
{% if registros is empty %}
    <p>Nenhum registro encontrado.</p>
{% endif %}

{# Nunca usar variável sem verificar se está definida em strict_variables mode #}
{# Errado: {{ usuario.nome }} — lança erro se usuario não foi passado #}
{# Correto: #}
{% if usuario is defined %}{{ usuario.nome }}{% endif %}
```

---

## `{% verbatim %}` — evitar conflito com frameworks JS

Ao usar Vue.js, Angular ou outros frameworks que usam `{{ }}`, encapsular com `verbatim` para o Twig não processar.

```twig
{# Twig não processa o conteúdo dentro de verbatim #}
{% verbatim %}
<div id="app">
    <p>{{ mensagem }}</p>         {# interpolação do Vue, não do Twig #}
    <ul>
        <li v-for="item in lista">{{ item.nome }}</li>
    </ul>
</div>
{% endverbatim %}

{# Variáveis Twig fora do verbatim — configuradas antes da inicialização do Vue #}
<script>
    const appConfig = {{ configuracaoInicial|json_encode }};
</script>
```

---

## Profiling com Twig Profiler

O `ProfilerExtension` mede o tempo de renderização de cada template e bloco.

```php
// Habilitar profiler (apenas em desenvolvimento)
use Twig\Extension\ProfilerExtension;
use Twig\Profiler\Profile;

$profile = new Profile();
$twig->addExtension(new ProfilerExtension($profile));

// Após renderizar — gerar relatório texto
$dumper = new \Twig\Profiler\Dumper\TextDumper();
echo $dumper->dump($profile);

// Gerar relatório HTML
$dumper = new \Twig\Profiler\Dumper\HtmlDumper();
echo $dumper->dump($profile);

// Integração com Symfony Profiler (automática via symfony/twig-bridge)
// Basta adicionar o TwigBundle — o profiler aparece na barra de debug
```

Saída do texto dump:

```
main (3.04ms)
├── base.html.twig (1.20ms)
│   ├── _partials/header.html.twig (0.23ms)
│   └── _partials/footer.html.twig (0.18ms)
└── pages/dashboard.html.twig (1.84ms)
    └── _partials/card.html.twig × 12 (0.97ms)
```

---

## Checklist de performance para produção

- [ ] `cache` configurado com path com permissão de escrita (`chmod 775`)
- [ ] `debug: false` no ambiente de produção
- [ ] `auto_reload: false` — Twig não verifica timestamps de arquivo
- [ ] `DebugExtension` não adicionada em produção (remove `dump()`)
- [ ] Cache do Twig limpo após cada deploy (`rm -rf var/cache/twig/*`)
- [ ] Templates não chamam serviços ou fazem queries — dados prontos no controller
- [ ] Includes com `only` para fragmentos isolados (evita passar contexto desnecessário)
- [ ] Macros usadas para componentes repetidos em vez de duplicar HTML
- [ ] `|raw` ausente ou justificado — nunca com input de usuário
- [ ] `strict_variables: true` para detectar variáveis não definidas durante desenvolvimento
