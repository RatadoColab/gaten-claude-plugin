---
name: glpi-12
description: This skill should be loaded when the target is a GLPI 12 plugin. GLPI 12 identifiers — any is sufficient: `requirements.glpi.min` starting with "12." in setup.php, no `_glpi_csrf_token` hidden field / `csrf_token()` call in Twig forms that POST, `Glpi\Toolbox\HttpClient` usage, `#[Glpi\Security\Attribute\SecurityStrategy]` combined with absence of `csrf_token()`, or explicit user mention ("GLPI 12", "GLPI 12.0.x", "GLPI 12 RC"). If instead there are GLPI 11 indicators (`csrf_token()` in Twig, `_glpi_csrf_token` fields, `Plugin::getWebDir(`, `requirements.glpi.min` starting with "11."), load `domains/glpi-11/SKILL.md` instead. If there are GLPI 10 indicators (`include('../../../inc/includes.php')`, `$PLUGIN_HOOKS['csrf_compliant']`, `$DB->queryOrDie(`), load `domains/glpi-10/SKILL.md`. If the GLPI version cannot be determined from the project or the user's message, ask the user which version ("GLPI 10.0.x, GLPI 11 or GLPI 12?") before generating code — do not assume a default. Exception: for a task that is explicitly a migration from GLPI 11 to GLPI 12, load this skill as authoritative for the target and consult `domains/glpi-11/SKILL.md` only as reference for the source code. Covers GLPI 12 integration patterns — CommonDBTM, Symfony controllers, permission system, query-builder-only database access, header-based CSRF, re-authentication ("sudo mode"), and hook registration. Specific sub-skills are available for plugin creation, AJAX handlers/controllers, Twig form templates, and Vue integration.
---

# GLPI 12 — Padrões de Desenvolvimento de Plugins

> **Versão-alvo:** esta skill cobre exclusivamente GLPI 12.0.x. Se o projeto tiver indícios de GLPI 11 (`csrf_token()` no Twig, campos `_glpi_csrf_token`, `Plugin::getWebDir(`), carregar `domains/glpi-11/SKILL.md`; indícios de GLPI 10 (`include('../../../inc/includes.php')`, `$PLUGIN_HOOKS['csrf_compliant']`, `$DB->queryOrDie(`) carregam `domains/glpi-10/SKILL.md`. Sem indício algum, perguntar ao usuário qual versão antes de gerar código. Exceção: tarefa de migração 11→12 carrega esta skill como autoritativa do destino (ver `references/migration-11-to-12.md`).
>
> **Base derivada de RC:** o conteúdo foi extraído do código-fonte do GLPI 12.0.0 RC. Os padrões de arquitetura (Firewall, Controllers, hooks, `public/`, PSR-4) são estáveis; assinaturas exatas e a lista final de remoções devem ser revalidadas contra o 12.0.0 GA (previsto para 2026-10-06).

## Herança do GLPI 11

**A arquitetura de plugins não mudou entre GLPI 11 e 12.** Tudo que o GLPI 11 introduziu continua válido no 12 sem alteração: estrutura `src/`/`public/`, namespace PSR-4 `GlpiPlugin\Nomedoplugin\`, Controllers Symfony com `#[Route]`, roteamento legado de `front/`/`ajax/`, `plugin_<nome>_boot()`, `SessionManager::registerPluginStatelessPath()`, `Glpi\Http\Firewall` e suas estratégias, query builder `$DB->request()`, `htmlescape()`/`jsescape()`. O GLPI 12 é uma **release de limpeza**: remove o que o 11 havia depreciado e elimina os tokens de CSRF por requisição. As seções abaixo cobrem apenas os **deltas** em relação ao 11 — para todo o resto, os padrões desta skill são os mesmos de `domains/glpi-11/SKILL.md`.

## Estrutura, Nomenclatura e Camadas

**Idênticas ao GLPI 11.** Controllers Symfony em `src/Controller/*.php` (`#[Route]`, descoberta automática) são o caminho para features novas; `front/`/`ajax/` legados continuam funcionando pelas mesmas URLs. Diretório `public/` obrigatório para todo asset e script web-acessível. Namespace PSR-4 `GlpiPlugin\Nomedoplugin\` mapeado automaticamente para `src/` — não declarar `autoload.psr-4` no `composer.json`. Tabelas `glpi_plugin_[nomedoplugin]_[entidade]`, direitos `plugin_[nomedoplugin]_[entidade]`. Detalhamento em `plugin-creation/SKILL.md` e `references/architecture.md`.

## Requisitos e Versão

**Delta:** GLPI 12 exige **PHP 8.3 a 8.5** (`GLPI_MIN_PHP` subiu de `8.2` para `8.3`). Declarar em `plugin_version_<nome>()`:

```php
'requirements' => [
    'glpi' => ['min' => '12.0.0', 'max' => '12.0.99'],
    'php'  => ['min' => '8.3'],
],
```

`plugin_<nome>_boot()` inalterado — executa antes da sessão carregar; usar para `Glpi\Http\SessionManager::registerPluginStatelessPath()`, nunca para lógica que dependa de `$_SESSION`.

## CommonDBTM — Deltas de Ruptura

Hierarquia (`CommonDBTM`, `CommonDropdown`, `CommonDBChild`, `CommonDBRelation`, `CommonGLPI`) inalterada. Novas rupturas a observar ao portar do 11:

| Removido/alterado no 12 | Nota |
|---|---|
| `can()` / `canGlobal()` | Ganharam 4º parâmetro `null &$reauth_needed = null` (by-ref). Sobrescritas em subclasses devem casar a assinatura exatamente |
| `ComputerAntivirus`, `ComputerVirtualMachine` | Classes removidas — usar `ItemAntivirus` / `ItemVirtualMachine` |
| `Item_Plug`, `Pdu_Plug` | Removidas — usar `PlugType` / `Item_Ola` conforme o caso |
| `KnowbaseItemCategory` + right `knowbasecategory` | Removidos — categorias da KB viraram artigos (árvore via `glpi_knowbaseitems_knowbaseitems`) |
| `Timer` | Classe removida |
| `KnowbaseItem_Comment`, `KnowbaseItem_Revision` | Agora `final` |

`CommonGLPI::$type` e `CommonDBTM::$fkfield` (já removidos no 11) permanecem ausentes. Catálogo completo em **`references/architecture.md`**.

## Sistema de Permissões

`Session::checkRight()` / `haveRightsOr()` inalterados. **Delta:** `Session::haveRight(string $module, int $right): bool` agora é **tipada** e retorna somente booleano — código que dependia de valores não-booleanos precisa ajuste. `Migration::replaceRight()` (renomeado no 11) permanece.

## Re-autenticação — "Sudo Mode" (novo no 12)

Ações sensíveis podem exigir que o usuário confirme a identidade mesmo já logado. O subsistema vive em `Glpi\Security\ReAuth\*`: `ReAuthManager` (singleton) com estratégias `Password`, `TOTP`, `Ldap`, `InPlace`, `Fallback`; após a confirmação, `ReAuthReplayListener` reexecuta a requisição original.

```php
// Marcar um itemtype de plugin como exigindo re-autenticação
public static function isUserReauthenticationNeeded(): bool
{
    return true; // padrão herdado: false
}
```

Regras para plugins: **nunca** implementar prompt de senha próprio — sobrescrever `CommonGLPI::isUserReauthenticationNeeded()` no itemtype e deixar o core cuidar do fluxo; em Controller, chamar `CommonGLPI::checkReAuthenticationOrRedirect()`; ao chamar `can()`/`canGlobal()` manualmente, ler `$reauth_needed` por referência para distinguir "sem permissão" de "só falta re-autenticar". Detalhamento em **`references/architecture.md`**.

## Controllers, Rotas Legadas e Banco de Dados

**Inalterados em relação ao 11.** Controllers em `src/Controller/` com `#[Route]` (prefixo `/plugins/meuplugin` automático), `front/`/`ajax/` legados sem `include('../../../inc/includes.php')`, `Firewall::addPluginStrategyForLegacyScripts()` com as mesmas estratégias, `#[Glpi\Security\Attribute\SecurityStrategy(...)]` para controllers. `$DB->query()`/`queryOrDie()` proibidos; usar `$DB->request()` (array único) e `$DB->doQuery()` para DDL/DML. `AbstractController` ganhou `validateInputHasExactKeys(array $input, array $keys)` para validação de payload. Exemplos completos em **`references/architecture.md`** e `ajax-handlers/SKILL.md`.

**Delta de query builder:** os aliases de raiz `QueryExpression`, `QueryParam`, `QuerySubQuery`, `QueryUnion` foram **removidos** (no 11 apenas moveram) — só `Glpi\DBAL\*` funciona. Assinaturas de `countElementsInTable()`, `countDistinctElementsInTable()`, `getAllDataFromTable()` mudaram; toda a `DbUtils` passou a ter tipos estritos. `ORDER BY` com lista separada por vírgula está depreciado — usar array.

## Hooks GLPI 12

Mecanismo `$PLUGIN_HOOKS` inalterado — usar constantes de `Glpi\Plugin\Hooks`. **Deltas:**

- **Removidas** as constantes `Hooks::CSRF_COMPLIANT` (`csrf_compliant`) e `Hooks::SHOW_IN_TIMELINE` (`show_in_timeline`) — no 11 estavam apenas depreciadas. Usar `Hooks::TIMELINE_ITEMS`.
- **Novos:** `Hooks::POST_PREPAREUPDATE` (`post_prepareupdate`, análogo a `post_prepareadd`), `Hooks::GET_CONTENT_TEMPLATE_PARAMETER`, `Hooks::GET_CONTENT_TEMPLATE_VALUE` (variáveis em mensagens de notificação), `Hooks::INVENTORY_GET_CONFIGURATION` (plugins de inventário).

Fonte da verdade: `src/Glpi/Plugin/Hooks.php` do core. Tabela completa em **`references/architecture.md`**.

## Segurança — CSRF por Header (delta principal)

Auto-sanitização de `$_GET`/`$_POST` permanece removida; `htmlescape()`/`jsescape()` obrigatórios em toda saída dinâmica; erro HTTP sempre via exceção `Glpi\Exception\Http\*` em Controller.

**A grande mudança do 12:** a proteção CSRF deixou de usar token por requisição e passou a ser **validação de header no kernel** (`CheckCsrfListener`), que confere `Sec-Fetch-Site`/`Origin` em todo método com corpo (POST/PUT/PATCH/DELETE), com isenção para recursos stateless. Consequências para plugins:

- **Remover** todo campo `_glpi_csrf_token` de formulários e todo header `X-Glpi-Csrf-Token` de chamadas AJAX — o navegador envia os headers protegidos automaticamente.
- **Não** chamar mais `csrf_token()` no Twig, `fields.csrfField()`, nem `getAjaxCsrfToken()` no JS (todos depreciados, removidos no GLPI 13).
- Nenhuma ação necessária para POSTs same-origin normais: passam a validação sem código adicional.

## Frontend JavaScript e URLs

**Delta:** `Plugin::getWebDir()` foi **removida** (era depreciada no 11) — usar caminho literal `/plugins/meuplugin/...` (PHP/JS) e `path('/plugins/meuplugin/...')` (Twig). `escapeMarkupText()` depreciada. Libs JS removidas do core: `jquery.fancytree` (usar `Wunderbaum`), `diff-match-patch`, `hotkeys-js`, `jquery-prettytextdiff`, `jquery.rateit`. Libs PHP removidas: `league/csv` (usar `phpoffice/phpspreadsheet`), `guzzlehttp/guzzle` (usar `Glpi\Toolbox\HttpClient`). Vue continua fornecido pelo core via `window._vue` / `window.Vue`, sem mudança — ver `vue/SKILL.md`.

## Twig Components (novo no 12, opcional)

O core passou a expor componentes Twig reutilizáveis em `templates/twig_components/` (`Alert` — `Info`/`Success`/`Warning`/`Danger` — e `Mfa/CodeInput`). Disponíveis para uso em templates de plugin quando fizer sentido; não são obrigatórios.

## Inalterados

Internacionalização (`__()`, `_n()`), testes (PHPUnit em `tests/units/`), globais essenciais (`$DB`, `$CFG_GLPI`, `$_SESSION['glpiID']`, `$_SESSION['glpiactive_entity']`, `$PLUGIN_HOOKS`; `$GLPI`/`$LANG` seguem removidas) — tudo como no GLPI 11. Tabela completa em **`references/architecture.md`**.

## Sub-skills Disponíveis

Carregar conforme a tarefa específica:

| Tarefa | Skill a carregar |
|---|---|
| Criar um novo plugin do zero | `domains/glpi-12/plugin-creation/SKILL.md` |
| Criar ou editar controller / handler em `ajax/` | `domains/glpi-12/ajax-handlers/SKILL.md` |
| Criar ou editar formulários Twig em `templates/` | `domains/glpi-12/form-templates/SKILL.md` |
| Adicionar interface Vue em templates Twig (aba/SPA no plugin) | `domains/glpi-12/vue/SKILL.md` |
| Migrar um plugin existente de GLPI 11 para GLPI 12 | `references/migration-11-to-12.md` (nesta skill) |

## Restrições Absolutas em Plugins GLPI 12

- Usar `declare(strict_types=1)` em todo arquivo PHP
- Nunca implementar autenticação ou sessão própria — usar `Session::checkRight()`; para ações sensíveis, `CommonGLPI::isUserReauthenticationNeeded()` + fluxo do core, nunca prompt próprio
- Nunca usar PDO ou `$DB->query()`/`$DB->queryOrDie()` — usar `$DB->request()` (query builder) ou `$DB->doQuery()`
- Nunca usar `Toolbox::addslashes_deep()` — corrompe dados; sanitização SQL já é automática no query builder
- Nunca emitir campo `_glpi_csrf_token`, header `X-Glpi-Csrf-Token`, `csrf_token()`, `fields.csrfField()` ou `getAjaxCsrfToken()` — CSRF é validação de header no kernel
- Nunca usar `Toolbox::callCurl()`/`getURLContent()`/`getGuzzleClient()` — usar `Glpi\Toolbox\HttpClient`
- Nunca usar `Html::displayNotFoundError()`/`displayRightError()` — lançar `NotFoundHttpException`/`AccessDeniedHttpException`
- Nunca referenciar `Plugin::getWebDir()` — removida; usar caminho literal `/plugins/meuplugin/...`
- Sempre aplicar `htmlescape()` em saída HTML dinâmica e `jsescape()` em saída JS dinâmica
- Nunca criar estrutura `src/Domain/Application/Infrastructure/` — usar `src/Controller/`, `src/`, `public/`, `install/`
- Assets estáticos e scripts web-acessíveis sempre em `public/`
- Em Controller, nunca usar `exit()`/`die()`/`http_response_code()` para sinalizar erro HTTP — lançar `Glpi\Exception\Http\*Exception`; em handler `ajax/` legado ainda não migrado, `http_response_code()` + `exit` continua aceitável
- Nunca usar strings hardcoded visíveis ao usuário — usar `__()` ou `_n()`

## Migração de GLPI 11

Para atualizar um plugin existente de GLPI 11 para GLPI 12, consultar o checklist agrupado por severidade em **`references/migration-11-to-12.md`**. O salto pelo GLPI 11 é **obrigatório** — não migrar direto do 10.

## Licença

Todo arquivo PHP deve conter o cabeçalho GPLv3 com copyright IBGE — template inalterado, disponível em **`references/architecture.md`**.
