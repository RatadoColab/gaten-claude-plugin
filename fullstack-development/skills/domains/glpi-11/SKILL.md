---
name: glpi-11
description: This skill should be loaded when the target is a GLPI 11 plugin. GLPI 11 identifiers — any is sufficient: `requirements.glpi.min` starting with "11." in setup.php, a `public/` directory at the plugin root, `src/Controller/` with a `#[Route]` attribute, `$DB->doQuery(` in code, `plugin_<name>_boot()` defined, or explicit user mention ("GLPI 11", "GLPI 11.0.x", "controller GLPI", "htmlescape"). If instead there are GLPI 10 indicators (`include('../../../inc/includes.php')`, `$PLUGIN_HOOKS['csrf_compliant']`, `$DB->queryOrDie(`, or explicit "GLPI 10" mention), load `domains/glpi-10/SKILL.md` instead. If the GLPI version cannot be determined from the project or the user's message, ask the user which version ("GLPI 10.0.x or GLPI 11?") before generating code — do not assume a default. Exception: for a task that is explicitly a migration from GLPI 10 to GLPI 11, load this skill as authoritative for the target and consult `domains/glpi-10/SKILL.md` only as reference for the source code. Covers GLPI 11 integration patterns — CommonDBTM, Symfony controllers, permission system, query-builder-only database access, and hook registration. Specific sub-skills are available for plugin creation, AJAX handlers/controllers, Twig form templates, and Vue integration.
---

# GLPI 11 — Padrões de Desenvolvimento de Plugins

> **Versão-alvo:** esta skill cobre exclusivamente GLPI 11.0.x. Se o projeto tiver indícios de GLPI 10 (`include('../../../inc/includes.php')`, `$PLUGIN_HOOKS['csrf_compliant']`, `$DB->queryOrDie(`), carregar `domains/glpi-10/SKILL.md`. Sem indício algum em nenhuma das duas direções, perguntar ao usuário qual versão antes de gerar código. Exceção: tarefa de migração 10→11 carrega esta skill como autoritativa do destino (ver `references/migration-10-to-11.md`).

## Diferenças Fundamentais em Relação ao Backend Genérico

Plugins GLPI não seguem a arquitetura tradicional de camadas isolada por diretórios, mas o GLPI 11 introduz Controllers Symfony como caminho recomendado para features novas:

| Camada genérica | Equivalente no GLPI 11 |
|---|---|
| Controller | `src/Controller/*.php` — estende `Glpi\Controller\AbstractController`, roteado por atributo `#[Route]` |
| Service | Métodos na própria classe `CommonDBTM` |
| Repository | `CommonDBTM` integrado — `getFromDB()`, `add()`, `update()`, `delete()` |
| Auth / AuthZ | `Session::checkRight('rightname', READ\|WRITE)` (inalterado) |
| Migration | `install/install.php` com `Migration` + `$DB->doQuery()` |

`front/*.php` e `ajax/*.php` legados continuam funcionando (acesso público via as mesmas URLs), mas **"any new feature added to GLPI ≥11 must use Controllers"** — não escrever `front/`/`ajax/` novos sem justificativa.

## Estrutura Padrão de um Plugin

Diretórios-chave em `plugins/[nome-do-plugin]/`: `setup.php` e `hook.php` na raiz (inalterado); `src/` com namespace PSR-4 `GlpiPlugin\Meuplugin\` (classes de domínio e `src/Controller/` para rotas); `public/` — **novo e obrigatório** — todo asset estático e script PHP web-acessível deve viver aqui (não aparece na URL: `public/css/x.css` → `/plugins/meuplugin/css/x.css`); `front/`/`ajax/` legados (opcional, apenas manutenção); `templates/` (Twig); `locales/`; `tests/units/` (PHPUnit). `inc/` (legado, autoload por convenção `PluginMeupluginFoo` → `inc/foo.class.php`) ainda funciona mas não é recomendado para código novo. Árvore completa anotada em `plugin-creation/SKILL.md`.

## Nomenclatura

| Elemento | Convenção |
|---|---|
| Diretório do plugin | minúsculas, sem espaços (ex.: `meuplugin`) |
| Tabelas | `glpi_plugin_[nomedoplugin]_[entidade]` — minúsculas, sem hífen |
| Classes | `Entidade` (PascalCase, sem prefixo `Plugin`) em `src/Entidade.php`, namespace `GlpiPlugin\Nomedoplugin\` |
| Direitos (`$rightname`) | `plugin_[nomedoplugin]_[entidade]` |
| Funções de hooks/setup | `plugin_[nomedoplugin]_[hookname]` em `hook.php`/`setup.php` |

Igual ao GLPI 10 em tudo, exceto o namespace PSR-4: só a primeira letra da chave do plugin em maiúscula (ex. `Meuplugin`, não `MeuPlugin`), mapeado automaticamente para `src/` pelo core — **não** declarar `autoload.psr-4` no `composer.json` do plugin.

## Requisitos e Versão

GLPI 11 exige **PHP 8.2 a 8.5**. Declarar em `plugin_version_<nome>()`:

```php
'requirements' => [
    'glpi' => ['min' => '11.0.0', 'max' => '11.0.99'],
    'php'  => ['min' => '8.2'],
],
```

A função `plugin_<nome>_boot()` é opcional e nova no 11 — executa antes da sessão carregar e antes da inicialização dos plugins ativos; usar para registrar paths stateless de API (`Glpi\Http\SessionManager::registerPluginStatelessPath()`), não para lógica que dependa de `$_SESSION`.

## CommonDBTM — Model + Repository

Toda entidade de dados de um plugin estende `CommonDBTM`. Hierarquia (`CommonDBTM`, `CommonDropdown`, `CommonDBChild`, `CommonDBRelation`, `CommonGLPI`) **inalterada** em relação ao GLPI 10.

```php
namespace GlpiPlugin\Meuplugin;

class MeuItem extends \CommonDBTM
{
    static $rightname = 'plugin_meuplugin_meuitem';

    public static function getTypeName($nb = 0): string
    {
        return _n('Item', 'Itens', $nb, 'meuplugin');
    }
}
```

Atenção a rupturas ao portar ou estender classes existentes:

| Removido/alterado | Nota |
|---|---|
| `CommonGLPI::$type`, `CommonDBTM::$fkfield` | Propriedades removidas |
| `can*()` (`canView`, `canCreate` etc.) | Assinaturas com **type hints estritos** — sobrescritas devem casar exatamente |
| `Computer_Item` | Substituída por `\Glpi\Asset\Asset_PeripheralAsset` |
| `groups_id`, `groups_id_tech` (assets) | Viraram **arrays** (tabela `glpi_groups_items`), não mais inteiros |
| `CommonDropdown::displayHeader()` | Removido |

Catálogo completo de métodos herdados, hooks de ciclo de vida e demais rupturas de assinatura em **`references/architecture.md`**.

## Sistema de Permissões

**Inalterado.** `Session::checkRight()` / `Session::haveRight()` / `Session::haveRightsOr()` com as mesmas constantes (`READ`, `UPDATE`, `CREATE`, `DELETE`, `PURGE`, `ALLSTANDARDRIGHT`). Único delta: `Migration::updateRight()` foi renomeado para `Migration::replaceRight()` — usar o novo nome em `install/install.php`.

## Controllers e Rotas Legadas

Feature nova em `src/Controller/`, roteada por atributo — sem registro manual, descoberta automática:

```php
namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Symfony\Component\HttpFoundation\{JsonResponse, Response};
use Symfony\Component\Routing\Attribute\Route;

final class MeuItemController extends AbstractController
{
    #[Route("/MeuItem", name: "meuplugin_meuitem", methods: "GET")]
    public function __invoke(): Response
    {
        return new JsonResponse(['data' => []]);
    }
}
```

A rota recebe prefixo automático (`/MeuItem` → `/plugins/meuplugin/MeuItem`) — **não** incluir o prefixo no atributo. `front/`/`ajax/` legados **não** usam mais `include('../../../inc/includes.php')` — o bootstrap roda automaticamente; todo script fica acessível só a usuários autenticados por padrão, exceto se `Firewall::addPluginStrategyForLegacyScripts()` for chamado em `plugin_init_<nome>()` ou `plugin_<nome>_boot()`:

```php
use Glpi\Http\Firewall;

Firewall::addPluginStrategyForLegacyScripts('meuplugin', '#^/front/faq\.php$#', Firewall::STRATEGY_FAQ_ACCESS);
```

Estratégias disponíveis: `STRATEGY_NO_CHECK`, `STRATEGY_AUTHENTICATED` (padrão), `STRATEGY_CENTRAL_ACCESS`, `STRATEGY_HELPDESK_ACCESS`, `STRATEGY_FAQ_ACCESS`. Para controllers, o equivalente é o atributo `#[Glpi\Security\Attribute\SecurityStrategy(...)]`. Exemplo de controller completo e bug de métodos ≠GET antes de 11.0.7 em **`plugin-creation/references/plugin-structure.md`**; regra do prefixo `/ajax` (necessária apenas para rotas chamadas repetidamente via POST sem reload de página, ver `ajax-handlers/SKILL.md`) em **`ajax-handlers/SKILL.md`**.

## Acesso ao Banco de Dados

`$DB->query()` e `$DB->queryOrDie()` estão **proibidos** (não apenas depreciados). Usar `$DB->request()` (query builder, apenas sintaxe de array único) para leitura, e `$DB->doQuery()` para DDL/DML self-crafted em `install/`.

```php
global $DB;

$iter = $DB->request([
    'FROM'  => MeuItem::getTable(),
    'WHERE' => ['is_deleted' => 0, 'entities_id' => $_SESSION['glpiactive_entity']],
    'ORDER' => ['name ASC'],
]);
foreach ($iter as $row) { /* ... */ }

$DB->doQuery("CREATE TABLE IF NOT EXISTS `...` (...) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC");
```

Classes `QueryExpression`, `QueryParam`, `QuerySubQuery`, `QueryUnion` moveram para `Glpi\DBAL\*` — atualizar `use`. Exemplos de JOIN, `Glpi\DBAL\QueryFunction` e `Migration` completa em **`references/architecture.md`**.

## Hooks GLPI 11

Mecanismo `$PLUGIN_HOOKS` **inalterado** — sem EventDispatcher no core. Usar as constantes de `Glpi\Plugin\Hooks` em vez de strings soltas:

```php
use Glpi\Plugin\Hooks;

$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = ['Location' => [MinhaClasse::class, 'onItemUpdate']];
```

Removidos: `debug_tabs`, `migratetypes`, `planning_scheduler_key`. Depreciado: `csrf_compliant` — **não declarar mais** este hook. Renomeado: `show_in_timeline` → `timeline_items`. ~50 hooks novos (dashboards, kanban, API, inventário). **A página oficial `plugins/hooks.html` está desatualizada** — usar `src/Glpi/Plugin/Hooks.php` do core como fonte da verdade. Tabela completa e grupos de hooks em **`references/architecture.md`**.

## Segurança

Auto-sanitização de `$_GET`/`$_POST`/`$_REQUEST` foi **removida** — todo dado chega bruto. `Toolbox::addslashes_deep()` **corrompe dados** em vez de proteger; não usar. Proteção contra SQL injection é automática ao construir queries via `$DB->request()`. Proteção XSS passa a ser responsabilidade explícita do código:

```php
echo '<p>' . htmlescape($content) . '</p>';
$(body).append("' . jsescape('<p>' . htmlescape($content) . '</p>') . '");
```

`htmlescape()` e `jsescape()` são funções globais de transição — aplicar em **toda** saída HTML/JS dinâmica. Em Controller, sinalizar erro HTTP sempre via exceção, nunca `http_response_code()` + `exit()`:

```php
if (!$item->getFromDB((int) $_GET['id'])) {
    throw new \Glpi\Exception\Http\NotFoundHttpException();
}
```

Em handler `ajax/` legado ainda não migrado, `http_response_code()` + `echo json_encode(...)` + `exit` continua sendo o padrão aceitável — a exceção `Glpi\Exception\Http\*` só se propaga automaticamente dentro de um Controller. Ver `ajax-handlers/SKILL.md`.

## Internacionalização

Inalterado: `__('texto', 'nomedoplugin')`, `_n('singular', 'plural', $n, 'nomedoplugin')`.

## Frontend JavaScript e URLs

`Plugin::getWebDir()`, a variável JS `GLPI_PLUGINS_PATH` e a função Twig `get_plugin_web_dir()` estão depreciadas — usar caminhos literais `/plugins/meuplugin/...` (PHP/JS) e `path('/plugins/meuplugin/...')` (Twig). Assets clássicos (CSS, JS não-modular) registrados nos mesmos hooks do 10 (`Hooks::ADD_CSS`, `Hooks::ADD_JAVASCRIPT`), agora relativos a `public/`; bundles ES module (como o do Vue) usam `Hooks::ADD_JAVASCRIPT_MODULE` (hook já existente desde o GLPI 10, não é novidade do 11 — não confundir com o hook novo `javascript`/`Hooks::JAVASCRIPT` do catálogo em `references/architecture.md`). **Sempre perguntar antes de gerar código JS**: puro, Vue.js ou jQuery? Vue no GLPI 11 é fornecido pelo core via `window._vue` — ver `vue/SKILL.md`.

## Testes

Inalterado: PHPUnit em `plugins/[nome]/tests/units/`, nomenclatura `[NomeDaClasse]Test.php`, um arquivo de teste por feature entregue.

## Globais Essenciais

`$DB`, `$CFG_GLPI`, `$_SESSION['glpiID']`, `$_SESSION['glpiactive_entity']`, `$PLUGIN_HOOKS` — inalterados. `$GLPI` e `$LANG` foram **removidas** em 11; não referenciá-las. Tabela completa em **`references/architecture.md`**.

## Sub-skills Disponíveis

Carregar conforme a tarefa específica:

| Tarefa | Skill a carregar |
|---|---|
| Criar um novo plugin do zero | `domains/glpi-11/plugin-creation/SKILL.md` |
| Criar ou editar controller / handler em `ajax/` | `domains/glpi-11/ajax-handlers/SKILL.md` |
| Criar ou editar formulários Twig em `templates/` | `domains/glpi-11/form-templates/SKILL.md` |
| Adicionar interface Vue em templates Twig (aba/SPA no plugin) | `domains/glpi-11/vue/SKILL.md` |
| Migrar um plugin existente de GLPI 10 para GLPI 11 | `references/migration-10-to-11.md` (nesta skill) |

## Restrições Absolutas em Plugins GLPI 11

- Usar `declare(strict_types=1)` em todo arquivo PHP
- Nunca implementar autenticação ou sessão própria — usar `Session::checkRight()`
- Nunca usar PDO ou `$DB->query()`/`$DB->queryOrDie()` — usar `$DB->request()` (query builder) ou `$DB->doQuery()`
- Nunca usar `Toolbox::addslashes_deep()` — corrompe dados; sanitização SQL já é automática no query builder
- Sempre aplicar `htmlescape()` em saída HTML dinâmica e `jsescape()` em saída JS dinâmica
- Nunca criar estrutura `src/Domain/Application/Infrastructure/` — usar `src/Controller/`, `src/`, `public/`, `install/`
- Assets estáticos e scripts web-acessíveis sempre em `public/`
- Em Controller, nunca usar `exit()`/`die()`/`http_response_code()` para sinalizar erro HTTP — lançar `Glpi\Exception\Http\*Exception`; em handler `ajax/` legado ainda não migrado, `http_response_code()` + `exit` continua aceitável
- Nunca usar strings hardcoded visíveis ao usuário — usar `__()` ou `_n()`

## Migração de GLPI 10

Para atualizar um plugin existente de GLPI 10 para GLPI 11, consultar o checklist agrupado por severidade em **`references/migration-10-to-11.md`**.

## Licença

Todo arquivo PHP deve conter o cabeçalho GPLv3 com copyright IBGE — template inalterado em relação ao GLPI 10, disponível em **`references/architecture.md`**.
