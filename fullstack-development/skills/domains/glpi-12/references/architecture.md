# Arquitetura GLPI 12 — Referência Técnica

> **Conferido contra o GLPI 12.0.0 GA (2026-10-07):** este documento foi extraído da comparação direta do código-fonte do GLPI 12.0.0 com o 11.0.x. Não há documentação oficial de plugins para o 12. Onde este documento e a doc oficial (escrita para o 11) divergem, ele segue o código-fonte do 12 e a seção *API changes* do `CHANGELOG.md`.
>
> **Escopo:** cobre os **deltas** em relação ao GLPI 11. Para padrões que não mudaram (query builder, Firewall, Controllers, `public/`, PSR-4, ciclo de vida de `CommonDBTM`), `domains/glpi-11/references/architecture.md` continua válido.

## Licença Obrigatória

Todo arquivo PHP deve conter o cabeçalho abaixo como comentário de licença GPLv3 — **inalterado** em relação ao GLPI 10:

```php
<?php

/**
 * ---------------------------------------------------------------------
 *
 * [nomedoplugin] plugin for GLPI
 *
 * http://glpi-project.org
 *
 * @copyright 2024-2026 IBGE GLPI Development Team.
 * @copyright 2015-2026 Teclib' and contributors.
 * @licence   https://www.gnu.org/licenses/gpl-3.0.html
 *
 * ---------------------------------------------------------------------
 *
 * LICENSE
 *
 * This file is part of GLPI.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 * ---------------------------------------------------------------------
 */

declare(strict_types=1);
```

---

## CommonDBTM — Model + Repository Unificado

`CommonDBTM` continua sendo a classe base de todos os objetos de dados no GLPI. Nenhuma classe base foi removida ou renomeada no 11.

```php
<?php

/**
 * [License header aqui]
 */

declare(strict_types=1);

namespace GlpiPlugin\Meuplugin;

class MeuItem extends \CommonDBTM
{
    public static string $rightname = 'plugin_meuplugin_meuitem';   // tipada: sem tipo = erro fatal no 12

    public static function getTypeName($nb = 0): string
    {
        return _n('Meu Item', 'Meus Itens', $nb, 'meuplugin');
    }
}
```

### Hierarquia de herança

Idêntica ao GLPI 10: `CommonDBTM` (entidade comum), `CommonDropdown` (listas de seleção), `CommonDBChild` (1:N com pai), `CommonDBRelation` (N:N), `CommonGLPI` (abas/páginas sem tabela própria).

### Métodos de acesso a dados (herdados de CommonDBTM)

| Método | Descrição |
|---|---|
| `getFromDB(int $id)` | Carrega um registro pelo ID; retorna `true/false` |
| `add(array $input)` | Insere registro; retorna ID ou `false` |
| `update(array $input)` | Atualiza registro (requer `$input['id']`) |
| `delete(array $input)` | Deleta registro |
| `deleteByCriteria(array $crit)` | Deleta múltiplos registros por critério |
| `find(array $crit, $order = [], $limit = null)` | Retorna array de registros |
| `countElementsInTable(string $table, array $crit)` | Conta registros |

### Rupturas de assinatura e remoções — delta 11 → 12

As rupturas do 11 (`CommonGLPI::$type`, `CommonDBTM::$fkfield`, `CommonDropdown::displayHeader()`, `Computer_Item` → `Asset_PeripheralAsset`, `groups_id` como array, trait `AssignableItem`) **permanecem**. Novidades do 12, extraídas do `CHANGELOG.md` e do código:

**Assinaturas alteradas:**
- `can($ID, int $right, ?array &$input = null, null &$reauth_needed = null): bool` — 4º parâmetro novo, by-ref. `canGlobal(int $right, null &$reauth_needed = null): bool` idem. Sobrescritas em subclasses de plugin devem casar exatamente.
- `Session::haveRight(string $module, int $right): bool` — tipada; retorna somente booleano.
- Todos os parâmetros de `CommonGLPI` e `CommonDBTM` ganharam tipo PHP nativo.
- `countElementsInTable()`, `countDistinctElementsInTable()`, `getAllDataFromTable()` (e equivalentes em `DbUtils`) — assinaturas alteradas; `DbUtils` inteira com tipos estritos; parâmetro `$order` de `getAllDataFromTable()` removido.

**Classes removidas no 12:** `ComputerAntivirus` (→ `ItemAntivirus`), `ComputerVirtualMachine` (→ `ItemVirtualMachine`), `Item_Plug`, `Pdu_Plug`, `KnowbaseItemCategory` (+ right `knowbasecategory`), `Timer`, `Glpi\Toolbox\Sanitizer`, `DBSlave`, `XML`. Aliases de raiz `QueryExpression`/`QueryParam`/`QuerySubQuery`/`QueryUnion` **removidos** (no 11 só moveram) — usar `Glpi\DBAL\*`.

**Tornadas `final`:** `KnowbaseItem_Comment`, `KnowbaseItem_Revision`. **Renomeada:** `KnowbaseItem_KnowbaseItemCategory` → `KnowbaseItem_KnowbaseItem`.

**Base de conhecimento:** categorias viraram artigos. Tabela `glpi_knowbaseitems_knowbaseitemcategories` → `glpi_knowbaseitems_knowbaseitems` (colunas `knowbaseitems_id` filho, `knowbaseitems_id_parent` pai). Coluna `knowbaseitemcategories_id` de `ITILCategory`/`TaskCategory` → `knowbaseitems_id`. `KnowbaseItem::getForCategory()` → `getChildrenArticles()`.

### Propriedades tipadas das classes-base (erro fatal se redeclaradas sem tipo)

Ausente do `CHANGELOG.md` do GLPI. No 12.0.0 a subclasse que redeclara sem tipo uma propriedade tipada da classe-base dá `Fatal error: Type of X::$y must be ...` ao carregar a classe.

Exemplos de redeclaração correta:

```php
public bool $dohistory = true;
public static string $rightname = 'plugin_meuplugin_meuitem';
public static string $itemtype = Pai::class;       // CommonDBChild
public static string $items_id = 'pais_id';        // CommonDBChild
public static ?string $itemtype_1 = Pai::class;    // CommonDBRelation (idem items_id_1, itemtype_2, items_id_2)
```

Tipos conferidos em `src/`: `CommonGLPI` — `static string $rightname`, `string $taborientation`, `bool $showdebug/$displaylist/$get_item_to_display_tab`; `CommonDBTM` — `bool $dohistory/$auto_message_on_action/$no_form_page/$get_item_to_display_tab`, `array $fields/$updates/$oldvalues/$history_blacklist`, `false|array $input`, `static bool $notable`, `static array $forward_entity_to`, `bool $usenotepad`, `?int $right`; `CommonDropdown`/`CommonTreeDropdown`/`Location` — `bool $dohistory/$can_be_translated/$must_be_replace/$display_dropdowntitle`; `CommonDBChild` — `static string $itemtype/$items_id`, `static bool $mustBeAttached/$logs_for_parent`, `static int $checkParentRights/$log_history_*`; `CommonDBRelation` — `static ?string $itemtype_N/$items_id_N`, `static bool $take_entity_N/$logs_for_item_N/$mustBeAttached_N/$checkAlwaysBothItems/$check_entity_coherency`, `static int $checkItem_N_Rights/$log_history_N_*`. Não há modo dual: o tipo declarado no filho quebra no GLPI 11 (pai sem tipo). Varrer (triagem, não prova) com aspas simples — em aspas duplas o `\$` vira âncora e o `grep` nunca casa:

```bash
grep -rnE '^\s*((public|protected|private|static|var)\s+)+\$(rightname|taborientation|showdebug|displaylist|get_item_to_display_tab|dohistory|auto_message_on_action|no_form_page|fields|updates|oldvalues|history_blacklist|input|notable|forward_entity_to|usenotepad|right|can_be_translated|must_be_replace|display_dropdowntitle|itemtype|items_id|mustBeAttached|logs_for_parent|checkParentRights|log_history_\w+|(itemtype|items_id|take_entity|logs_for_item|mustBeAttached)_[12]|checkAlwaysBothItems|check_entity_coherency|checkItem_[12]_Rights)\b' src/
```

O erro fatal vem da **ausência de tipo**; a visibilidade explícita (`public`) é só recomendação de estilo — `static string $rightname` sem `public` é PHP válido. A verificação definitiva é um teste unit que carregue as classes-modelo do plugin (`ReflectionProperty`) — o `grep` pode deixar passar propriedades fora da lista.

### Re-autenticação — `Glpi\Security\ReAuth\*` (novo no 12)

Subsistema de "sudo mode": exige confirmação de identidade para ações sensíveis mesmo com sessão ativa.

| Elemento | Papel |
|---|---|
| `ReAuthManager` (singleton, `getInstance()`) | `isReAuthenticated()`, `checkReAuthenticationOrRedirect()`, `verify(Request)`, `authenticate()`, `revoke()`, `registerStrategy()`, `atLeastOneItemTypesRequiresReauthentication(array)` |
| `PasswordReAuthStrategy`, `TOTPReAuthStrategy`, `LdapReAuthStrategy`, `CasReAuthStrategy` (novo no GA), `InPlaceReAuthStrategy`, `FallbackReAuthStrategy` | Estratégias de verificação; `registerStrategy()` permite adicionar. `ReAuthManager::isSelectedStrategy(class-string)` informa se a estratégia é a escolhida para o usuário — endpoint dedicado a uma estratégia deve checá-la (estar disponível não basta) |
| `ReAuthReplayListener` (RequestListener) | Reexecuta a requisição original após confirmação bem-sucedida |
| `CommonGLPI::itemTypeRequiresReauthentication(): bool` (`protected static`) | **Ponto de extensão do plugin** — sobrescrever por itemtype; padrão `false` |
| `CommonGLPI::isUserReauthenticationNeeded(): bool` | **`final`** — não sobrescrever; combina o requisito do itemtype com o estado da sessão (sempre `false` em API/CLI) |
| `CommonGLPI::checkReAuthenticationOrRedirect(): true` | **`final`** — chamar em Controller/aba antes de expor dados sensíveis |
| `can()` / `canGlobal()` `&$reauth_needed` | `true` = permissão OK, falta apenas re-autenticar |

Regra para plugins: nunca implementar prompt próprio; chamar `checkReAuthenticationOrRedirect()` pela classe do itemtype (`MeuItem::…`), nunca pela `CommonGLPI` (a base devolveria o padrão `false`); sobrescrever `itemTypeRequiresReauthentication()` (`isUserReauthenticationNeeded()` é `final` no 12.0.0) e delegar o fluxo ao core.

### Hooks de ciclo de vida

Sobrescrever para reagir a eventos no item — **inalterado**:

```php
/** Executado após inserção bem-sucedida */
public function post_addItem(): void
{
    // Notificações, log, criação de registros relacionados
}

/** Executado após atualização bem-sucedida */
public function post_updateItem(array $history = []): void
{
    // $history contém campos alterados
}

/** Executado ao deletar — limpar dados relacionados */
public function cleanDBonPurge(): void
{
    $relation = new MeuItemRelacao();
    $relation->deleteByCriteria(['meuitem_id' => $this->getID()]);
}

/** Executado antes de deletar — pode abortar com retorno false */
public function pre_deleteItem(): bool
{
    return true; // retornar false cancela a exclusão
}
```

---

## Acesso ao Banco de Dados via `$DB`

Nunca usar PDO diretamente. `$DB->query()` e `$DB->queryOrDie()` seguem **proibidos**. No 12, `query()`, `queryOrDie()`, `doQueryOrDie()`, `insertOrDie()`, `updateOrDie()`, `deleteOrDie()`, `truncate()`, `truncateOrDie()`, `guessTimezone()` foram **removidos** de `DBmysql` (no 11 estavam depreciados). Usar `$DB->request()` para leitura, `$DB->doQuery()` para DDL/DML self-crafted, e `$DB->insert()`/`update()`/`delete()` para escrita simples. `ORDER BY` com lista de campos separada por vírgula está depreciado — passar array.

### `$DB->request()` — leitura (retorna iterador)

Apenas a sintaxe de array único é suportada — a forma de 2 parâmetros (`$DB->request('table', [...])`) está depreciada.

```php
global $DB;

// SELECT simples
$iter = $DB->request([
    'FROM'  => MeuItem::getTable(),
    'WHERE' => ['is_active' => 1, 'entities_id' => $_SESSION['glpiactive_entity']],
    'ORDER' => ['name ASC'],
    'LIMIT' => 50,
]);

foreach ($iter as $row) {
    echo $row['name'];
}

// JOIN
$iter = $DB->request([
    'SELECT'    => ['mi.id', 'mi.name', 'u.name AS user_name'],
    'FROM'      => ['glpi_plugin_meuplugin_meuitem AS mi'],
    'LEFT JOIN' => [
        'glpi_users AS u' => ['ON' => ['mi' => 'users_id', 'u' => 'id']],
    ],
    'WHERE'     => ['mi.is_deleted' => 0],
]);

// Contagem
$count = countElementsInTable(MeuItem::getTable(), ['is_active' => 1]);
```

`Glpi\DBAL\QueryFunction` permite construir chamadas de função SQL de forma abstrata quando necessário.

### `$DB->doQuery()` — DDL e DML direto

Usar em scripts de instalação/atualização. Em leitura/escrita comuns, preferir `$DB->request()` e os métodos de `CommonDBTM`.

```php
global $DB;

$DB->doQuery(
    "CREATE TABLE IF NOT EXISTS `glpi_plugin_meuplugin_meuitem` (
        `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `name`        VARCHAR(255) NOT NULL DEFAULT '',
        `entities_id` INT NOT NULL DEFAULT 0,
        `is_deleted`  TINYINT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `entities_id` (`entities_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC"
);
```

Nota: `ENGINE=InnoDB` + `utf8mb4`/`utf8mb4_unicode_ci` + `ROW_FORMAT=DYNAMIC` substituem `MyISAM`/`utf8`/`utf8_unicode_ci` do GLPI 10.

Removidos no 12 (eram depreciados no 11): `deleteOrDie()`, `doQueryOrDie()`, `insertOrDie()`, `updateOrDie()`, `truncate()`, `truncateOrDie()`, `guessTimezone()`. Depreciados no 12: `DBmysql::$slave`, `isSlave()`, `DBConnection::switchToMaster()`/`switchToSlave()` (réplica de leitura descontinuada).

### `Migration` — instalação/atualização

```php
function plugin_meuplugin_install() {
   global $DB;
   $migration = new Migration(100);

   if (!$DB->tableExists('glpi_plugin_meuplugin_configs')) {
      $DB->doQuery("CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC");
   }

   if ($DB->tableExists('glpi_plugin_meuplugin_configs')) {
      $migration->addField('glpi_plugin_meuplugin_configs', 'value', 'string');
      $migration->addKey('glpi_plugin_meuplugin_configs', 'name');
   }

   $migration->executeMigration();
   return true;
}
```

`Migration::replaceRight()` (renomeado no 11) permanece. **Removidos no 12** (eram depreciados no 11): `addNewMessageArea()`, `displayError()`, `displayTitle()`, `displayWarning()`, `setOutputHandler()` — usar `$migration->addMessage()`. Aviso permanente: um plugin nunca deve alterar o banco do core.

---

## Sistema de Permissões

Mecanismo inalterado. **Delta do 12:** `Session::haveRight(string $module, int $right): bool` é tipada e retorna somente booleano — código que dependia de valores não-booleanos precisa ajuste. Para ações sensíveis, combinar com re-autenticação (ver § Re-autenticação).

### Verificação de acesso

```php
// Lança exceção se não autorizado (uso preferencial)
Session::checkRight('plugin_meuplugin_meuitem', READ);
Session::checkRight('plugin_meuplugin_meuitem', UPDATE);
Session::checkRight('plugin_meuplugin_meuitem', CREATE);

// Retorna bool para tratamento manual
if (!Session::haveRight('plugin_meuplugin_meuitem', READ)) {
    throw new \Glpi\Exception\Http\AccessDeniedHttpException();
}

// Múltiplas permissões (qualquer uma basta)
Session::haveRightsOr('plugin_meuplugin_meuitem', [CREATE, UPDATE]);
```

Constantes: `READ=1`, `UPDATE=2`, `CREATE=4`, `DELETE=8`, `PURGE=16`, `ALLSTANDARDRIGHT=31`, `READNOTE=32`, `UPDATENOTE=64`, `UNLOCK=128`. Carregadas automaticamente via `src/autoload/constants.php` — `inc/define.php`, onde a doc oficial ainda as localiza, foi **removido**.

### Registro do direito

```php
static function getAllRights($all = false) {
    return [[
        'itemtype' => MeuItem::class,
        'label'    => MeuItem::getTypeName(),
        'field'    => 'plugin_meuplugin_meuitem',
    ]];
}
```

Em `hook.php`:

```php
foreach (MeuPluginProfile::getAllRights() as $right) {
    ProfileRight::addProfileRights([$right['field']]);      // install
    ProfileRight::deleteProfileRights([$right['field']]);   // uninstall
}
```

`ProfileRight::updateProfileRightAsOtherRight()` e `updateProfileRightsAsOtherRights()` foram **removidos** no 11. Não existe hook `rights` em `$PLUGIN_HOOKS` — direitos são sempre registrados via `ProfileRight`.

---

## Hooks GLPI 12

Mecanismo `$PLUGIN_HOOKS` **inalterado** — não há EventDispatcher no core; Symfony entra via HttpKernel/Routing, não substituindo hooks. Deltas do 12: `Hooks::CSRF_COMPLIANT` e `Hooks::SHOW_IN_TIMELINE` **removidas** (no 11 só depreciadas); novas: `Hooks::POST_PREPAREUPDATE`, `Hooks::GET_CONTENT_TEMPLATE_PARAMETER`, `Hooks::GET_CONTENT_TEMPLATE_VALUE`, `Hooks::INVENTORY_GET_CONFIGURATION`.

```php
use Glpi\Plugin\Hooks;

$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = ['Location' => [MinhaClasse::class, 'onItemUpdate']];
$PLUGIN_HOOKS[Hooks::POST_SHOW_ITEM]['meuplugin'] = 'plugin_meuplugin_post_show_item';
```

Mecânica de registro/recepção **inalterada** em relação ao GLPI 10: hooks do grupo CRUD (`item_add`, `item_update`, `pre_item_add`, `item_purge`, etc.) são indexados por itemtype (`$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = ['Location' => [MinhaClasse::class, 'onItemUpdate']]`) e recebem o objeto diretamente no método estático; hooks de formulário/exibição (`post_show_item`, `post_item_form`, `item_transfer`, etc.) são registrados como callable direto (`$PLUGIN_HOOKS[Hooks::POST_SHOW_ITEM]['meuplugin'] = 'plugin_meuplugin_post_show_item'`), recebem `array $params` e o receptor filtra o itemtype manualmente. Na dúvida sobre o grupo de um hook, tratar como o segundo.

### Tabela de hooks disponíveis em `$PLUGIN_HOOKS` (GLPI 12)

| Hook | Status | Nota |
|---|---|---|
| `item_add`, `item_update`, `item_delete`, `item_purge`, `pre_item_add`, `pre_item_update` | Inalterado | Grupo CRUD |
| `post_show_item`, `post_item_form`, `item_transfer` | Inalterado | Grupo formulário/exibição |
| `menu_toadd`, `use_massive_action` | Inalterado | — |
| `csrf_compliant` (`Hooks::CSRF_COMPLIANT`) | **Removido no 12** | Constante eliminada — remover do código |
| `show_in_timeline` (`Hooks::SHOW_IN_TIMELINE`) | **Removido no 12** | Usar `Hooks::TIMELINE_ITEMS` / `timeline_items` |
| `debug_tabs`, `migratetypes`, `planning_scheduler_key` | **Removidos (desde 11)** | — |
| `ruleImportComputer_*` | **Renomeados (11)** → `ruleImportAsset_*` | — |
| `post_prepareupdate` (`Hooks::POST_PREPAREUPDATE`) | **Novo (12)** | Após modificar input, antes de gravar update; setar `input` para `false` cancela |
| `get_content_template_parameter`, `get_content_template_value` | **Novo (12)** | Variáveis extras em mensagens de notificação |
| `inventory_get_configuration` (`Hooks::INVENTORY_GET_CONFIGURATION`) | **Novo (12)** | Plugins de inventário/deploy fornecem config ao agente |
| `pre_itil_info_section`, `post_itil_info_section`, `pre_item_list`, `post_item_list` | **Novo (11)** | — |
| `pre/post_kanban_panel_content`, `pre/post_kanban_panel_main_content` | **Novo (11)** | Kanban |
| `display_service_catalog`, `set_item_impact_icon`, `timeline_items`, `stats`, `default_display_prefs`, `javascript` | **Novo (11)** | Display/UI/Assets |
| `api_controllers`, `api_middleware`, `redefine_api_schemas` | **Novo (11)** | High-Level API (v3.0.0 no 12) |
| `dashboard_defaults`, `dashboard_palettes`, `pre_inventory`, `post_inventory` | **Novo (11)** | Dashboards / Inventário |
| `mail_server_protocols`, `assign_to_ticket`, `use_rules`, `add_default_join`, `add_default_where` | **Novo (11)** | Diversos |

`Glpi\Plugin\HookManager` (não documentado na doc oficial de plugins) oferece uma fachada tipada alternativa (`registerJavascriptFile()`, `registerItemHook()`, `registerSecureFields()`) que valida o hook e lança `LogicException` se inválido — usar quando disponível, mas o `$PLUGIN_HOOKS` direto continua sendo o caminho documentado.

---

## Registro via `setup.php`

### Funções obrigatórias e boot

```php
<?php

/**
 * [License header aqui]
 */

declare(strict_types=1);

function plugin_version_meuplugin(): array
{
    return [
        'name'         => 'Meu Plugin',
        'version'      => '1.0.0',
        'author'       => 'Autor',
        'license'      => 'GPLv3+',
        'homepage'     => '',
        'requirements' => [
            'glpi' => ['min' => '12.0.0', 'max' => '12.0.99'],
            'php'  => ['min' => '8.3'],
        ],
    ];
}

function plugin_meuplugin_check_prerequisites(): bool
{
    if (version_compare(GLPI_VERSION, '12.0', 'lt')) {
        echo 'Requer GLPI 12.0 ou superior.';
        return false;
    }
    return true;
}

function plugin_meuplugin_check_config(bool $verbose = false): bool
{
    return true;
}

/** Executado antes da sessão carregar e antes da inicialização dos plugins ativos */
function plugin_meuplugin_boot(): void
{
    \Glpi\Http\SessionManager::registerPluginStatelessPath('meuplugin', '#^/api\.php#');
}

/** Registra classes, hooks e capacidades */
function plugin_init_meuplugin(): void
{
    global $PLUGIN_HOOKS;

    Plugin::registerClass(\GlpiPlugin\Meuplugin\MeuItem::class, [
        'addtabon' => ['Computer'],
    ]);

    $PLUGIN_HOOKS[\Glpi\Plugin\Hooks::ITEM_UPDATE]['meuplugin'] = [
        'Computer' => [\GlpiPlugin\Meuplugin\MeuItem::class, 'onComputerUpdate'],
    ];
}
```

Nota: `$PLUGIN_HOOKS['csrf_compliant']` não aparece — a constante `Hooks::CSRF_COMPLIANT` foi **removida** no 12. Não há mais token de CSRF por requisição: a proteção é validação de header no kernel (ver § Segurança). `plugin_meuplugin_check_config()` (não `check_prerequisites`) segue opcional.

### Firewall e sessão

Por padrão, todo script legado (`front/`, `ajax/`, `report/`) só é acessível a usuários autenticados. Para liberar acesso público/parcial:

```php
use Glpi\Http\Firewall;

function plugin_init_meuplugin(): void
{
    Firewall::addPluginStrategyForLegacyScripts('meuplugin', '#^/front/faq\.php$#', Firewall::STRATEGY_FAQ_ACCESS);
}
```

Estratégias: `STRATEGY_NO_CHECK`, `STRATEGY_AUTHENTICATED` (padrão), `STRATEGY_CENTRAL_ACCESS`, `STRATEGY_HELPDESK_ACCESS`, `STRATEGY_FAQ_ACCESS`. Para controllers, usar o atributo `#[Glpi\Security\Attribute\SecurityStrategy(...)]` em vez de registrar por regex.

---

## CronTask — comportamento novo no 12

Ação que falha 5 vezes seguidas vai para o status `ERROR` (exige intervenção manual: editar a ação para "Programada"; `glpi:task:unlock` só destrava `RUNNING`); ação encerrada externamente fica `ABORTED` e é reagendada de imediato; o reagendamento após falha usa backoff (1 min dobrando até 30 min). O agendamento usa a coluna nova `next_run` (vem `NULL` após o upgrade → toda ação roda na 1ª execução). `CronTask::getStateName()` não mapeia `ERROR`/`ABORTED` (aparecem como `???` no 12.0.0). O runner é `php front/cron.php [--force] [nome]` — não existe `glpi:cron`/`glpi:task:run`. Crons de plugin devem ser idempotentes e não estourar o tempo.

---

## Segurança

Auto-sanitização de `$_GET`/`$_POST`/`$_REQUEST` permanece **removida** — dado bruto. Cast explícito em IDs obrigatório. Proteção SQL automática no query builder. `htmlescape()`/`jsescape()` em toda saída dinâmica. `Toolbox::addslashes_deep()`/`stripslashes_deep()` **removidos** no 12; `Glpi\Toolbox\Sanitizer` **removida**. Erros HTTP via exceção `Glpi\Exception\Http\*`, nunca `exit()`/`die()`/`http_response_code()` em Controller. `Html::displayNotFoundError()`/`displayRightError()` **removidos** — lançar `NotFoundHttpException`/`AccessDeniedHttpException`.

### CSRF por header (delta principal do 12)

Token por requisição eliminado. `CheckCsrfListener` (`src/Glpi/Kernel/Listener/ControllerListener/`) valida no kernel, antes da rota:

1. Recursos stateless e sub-requests: isentos.
2. Métodos sem corpo (`GET`, `HEAD`, `OPTIONS`, `TRACE`): sem checagem.
3. Demais: header `Sec-Fetch-Site` (enviado por todos os navegadores desde 2023, não spoofável) deve indicar `same-origin` ou `none` (`same-site` e `cross-site` são **rejeitados**); fallback para `Origin` vs `Host` em navegadores antigos. Falha → `AccessDeniedHttpException`.

Para o plugin: **remover** `_glpi_csrf_token` (campos), `X-Glpi-Csrf-Token` (headers AJAX), `csrf_token()` (Twig), `fields.csrfField()` (macro), `getAjaxCsrfToken()` (JS). Depreciados também: `Session::getNewCSRFToken()`, `validateCSRF()`, `checkCSRF()`, `cleanCSRFTokens()`. POSTs same-origin passam sem código adicional. Sem `Sec-Fetch-Site` e sem `Origin` (cliente não-browser) **não há checagem**; `front/` e `ajax/` legados passam pelo mesmo listener. Manter `X-Requested-With` (o core ainda o usa em `Toolbox::isAjax()`); `csrf_token()`/`getNewCSRFToken()` ainda existem mas devolvem `""` com `Toolbox::deprecated()`; proxy que reescreve `Host` quebra a validação por `Origin`.

### HTTP client

`Toolbox::callCurl()`, `getURLContent()`, `getGuzzleClient()` **removidos**. Usar `Glpi\Toolbox\HttpClient`:

```php
use Glpi\Toolbox\HttpClient;

$client = new HttpClient();                 // ou new HttpClient($context, $options)
$response = $client->get('https://exemplo.internal/api');
$data = json_decode($response->getContent(), true);
```

Métodos: `request(string $method, string $uri, array $options)`, `get()`, `post()`, `stream()`. Retorna `Symfony\Contracts\HttpClient\ResponseInterface`.

O `HttpClient` **bloqueia rede privada** fora de `GLPI_SERVERSIDE_URL_ALLOWED_PRIVATE_NETWORKS_CONTEXTS` (constante da instalação, em `config/local_define.php`; o plugin não consegue se auto-registrar), ao contrário do `Toolbox::callCurl()` do 11 — integração com serviço interno exige ajuste de ambiente. `guzzlehttp/guzzle` deixou de ser dependência direta do core (só transitiva).

---

## Toolbox e Html — sobreviventes e removidos no 12

**`Html::` que permanecem** (uso comum em plugins): `header`, `header_nocache`, `footer`, `redirect`, `back`, `submit`, `scriptBlock`, `hidden`, `closeForm`, `helpHeader`, `helpFooter`, `showSimpleForm`, `showCheckbox`, `requireJs`. **Removidos no 12:** `displayNotFoundError`, `displayRightError`, `colourNameLookup`, `ajaxFooter`, `progressBar` e família, `entities_deep`/`entity_decode_deep`, `cleanInputText`, `cleanPostForTextArea`, `jsGetDropdownValue`, `jsSetDropdownValue`. **Depreciado:** `Html::link()`.

**`Toolbox::` que permanecem:** `logInFile`, `logDebug`, `isCommonDBTM`, `append_params`, `prepareArrayForInput`, `decodeArrayFromInput`, `deleteDir`, `strtolower`, `stripTags`, `jsonDecode`, `isAPIDeprecated`. **Removidos no 12:** `callCurl`, `getURLContent`, `getGuzzleClient`, `isUrlSafe`, `seems_utf8`, `sendFile`, `addslashes_deep`, `stripslashes_deep`, `logError`, `logWarning`, `logNotice`, `logSqlError`/`logSqlWarning`/`logSqlDebug`, `clean_cross_side_scripting_deep`, `endsWith`/`startsWith`, `sodiumEncrypt`/`sodiumDecrypt`. Para log, usar `Toolbox::logInFile('plugin_meuplugin', $msg)` ou o logger PSR do core.

---

## Globais Essenciais

| Global | Tipo | Uso |
|---|---|---|
| `$DB` | `DBmysql` | Acesso ao banco — leitura e escrita |
| `$CFG_GLPI` | `array` | Configurações globais do GLPI |
| `$_SESSION['glpiID']` | `int` | ID do usuário logado |
| `$_SESSION['glpiactive_entity']` | `int` | Entidade ativa |
| `$PLUGIN_HOOKS` | `array` | Registro de hooks do plugin |

`$GLPI` e `$LANG` seguem **removidas** — não referenciá-las. Removidas desde o 11: `GLPI_USE_CSRF_CHECK`, `GLPI_USE_IDOR_CHECK`, `GLPI_DEMO_MODE`, `GLPI_SQL_DEBUG`, `$AJAX_INCLUDE`, `$SECURITY_STRATEGY`, `$USEDBREPLICATE`, `$_SESSION['glpiroot']`, etc.; `PLUGINS_DIRECTORIES` → `GLPI_PLUGINS_DIRECTORIES`. Removidas no 12: `$DEBUG_SQL`, `$SQL_TOTAL_REQUEST`, `$TIMER_DEBUG`, `$TIMER` globais; `$CFG_GLPI['debug_sql']`/`['debug_vars']`; `GLPI_SERVERSIDE_URL_ALLOWLIST` (→ `GLPI_SERVERSIDE_URL_ALLOWED_PRIVATE_NETWORKS_CONTEXTS`). Novas constantes de proxy reverso: `GLPI_TRUSTED_REVERSE_PROXIES`, `GLPI_REVERSE_PROXY_HEADERS`.

Sempre declarar `global $DB;` antes de usar `$DB` em métodos de classe.
