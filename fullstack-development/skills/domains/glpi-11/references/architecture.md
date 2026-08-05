# Arquitetura GLPI 11 — Referência Técnica

> **Nota de confiabilidade da doc oficial:** `plugins/hooks.html` ainda documenta hooks removidos no 11 (`debug_tabs`, `migratetypes`, `ruleImportComputer_*`) e omite ~50 hooks novos; `plugins/objects.html` mostra exemplo de CRUD que não roda no 11 (`include inc/includes.php`, `Html::autocompletionTextField()` removido); `plugins/tutorial.html` ainda declara `MIN_GLPI_VERSION 10.0.0`. Onde este documento e a doc oficial divergem, ele segue `CHANGELOG.md` e `src/Glpi/Plugin/Hooks.php` do core GLPI (branch `11.0/bugfixes`), que são a fonte da verdade.

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
    /** @var string */
    static $rightname = 'plugin_meuplugin_meuitem';

    /** @var string */
    static $table = 'glpi_plugin_meuplugin_meuitem';

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

### Rupturas de assinatura e remoções (GLPI 11)

Não documentadas na doc de plugins — extraídas do `CHANGELOG.md` do core.

**Removidos:**

| Classe/Membro | Nota |
|---|---|
| `CommonGLPI::$type` | Propriedade removida |
| `CommonGLPI::getAvailableDisplayOptions()`, `getDisplayOptions()`, `getDisplayOptionsLink()`, `updateDisplayOptions()`, `showDislayOptions()` | Removidos |
| `CommonDBTM::$fkfield` | Propriedade removida |
| `CommonDBTM::showDebugInfo()`, `hasSavedInput()`, `getCacheKeyForFriendlyName()`, `getSNMPCredential()`, `cleanLockedsOnAdd()` | Removidos |
| `CommonDropdown::$first_level_menu`, `$second_level_menu`, `$third_level_menu`, `displayHeader()` | Removidos |
| `CommonDevice::title()` | Removido |
| `QuerySubQuery`, `QueryUnion` (globais) | Movidas para `Glpi\DBAL\*` |
| `RuleImportComputer`, `RuleImportComputerCollection`, `Netpoint`, `XML`, `MigrationCleaner`, `NetworkPortMigration` | Classes removidas |

**Assinaturas alteradas:**
- `CommonGLPI::$othertabs` virou `private`.
- `CommonGLPI::createTabEntry()` mudou de assinatura.
- `can*()` (`CommonGLPI`/`CommonDBTM`) ganharam type hints estritos em parâmetros e retorno — sobrescritas em subclasses de plugin precisam casar exatamente.
- `CommonITILTask::getItilObjectItemType` virou `static`.
- `CartridgeItem::addCompatibleType()` virou `static`.

**Substituições de itemtype:** `Computer_Item` → `\Glpi\Asset\Asset_PeripheralAsset`; `ComputerAntivirus` → `ItemAntivirus` (depreciado); `ComputerVirtualMachine` → `ItemVirtualMachine` (depreciado); `Pdu_Plug` → `Item_Plug` (depreciado).

**Campos de grupo:** `groups_id` e `groups_id_tech` de assets deixaram de ser inteiros e passaram a ser **arrays**, carregados após `getFromDB`/`getEmpty`; leitura direta no BD exige a tabela de ligação `glpi_groups_items`.

**Trait nova:** classes adicionadas a `$CFG_GLPI['directconnect_types']` devem usar a trait `Glpi\Features\AssignableItem`.

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

Nunca usar PDO diretamente. `$DB->query()` e `$DB->queryOrDie()` são **proibidos** (CHANGELOG: "Usage of `DBmysql::query()` and `DBmysql::queryOrDie()` method are prohibited"). Usar `$DB->request()` para queries construídas via query builder, e `$DB->doQuery()` para SQL self-crafted seguro.

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

Depreciados em `DBmysql`: `deleteOrDie()`, `doQueryOrDie()`, `insertOrDie()`, `updateOrDie()`, `truncate()`, `truncateOrDie()`. Removidos: propriedade `DBmysql::$error`, `getLastQueryWarnings()`, `DBmysql::$allow_myisam`.

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

`Migration::updateRight()` foi **renomeado** para `Migration::replaceRight()`. Depreciados: `addNewMessageArea()`, `displayError()`, `displayTitle()`, `displayWarning()`, `setOutputHandler()`. Aviso permanente: um plugin nunca deve alterar o banco do core.

---

## Sistema de Permissões

**Mecanismo inalterado** em relação ao GLPI 10.

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

## Hooks GLPI 11

Mecanismo `$PLUGIN_HOOKS` **inalterado** — não há EventDispatcher no core; Symfony entra via HttpKernel/Routing, não substituindo hooks.

```php
use Glpi\Plugin\Hooks;

$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = ['Location' => [MinhaClasse::class, 'onItemUpdate']];
$PLUGIN_HOOKS[Hooks::POST_SHOW_ITEM]['meuplugin'] = 'plugin_meuplugin_post_show_item';
```

Mecânica de registro/recepção **inalterada** em relação ao GLPI 10: hooks do grupo CRUD (`item_add`, `item_update`, `pre_item_add`, `item_purge`, etc.) são indexados por itemtype (`$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = ['Location' => [MinhaClasse::class, 'onItemUpdate']]`) e recebem o objeto diretamente no método estático; hooks de formulário/exibição (`post_show_item`, `post_item_form`, `item_transfer`, etc.) são registrados como callable direto (`$PLUGIN_HOOKS[Hooks::POST_SHOW_ITEM]['meuplugin'] = 'plugin_meuplugin_post_show_item'`), recebem `array $params` e o receptor filtra o itemtype manualmente. Na dúvida sobre o grupo de um hook, tratar como o segundo.

### Tabela de hooks disponíveis em `$PLUGIN_HOOKS` (GLPI 11)

| Hook | Status | Nota |
|---|---|---|
| `item_add`, `item_update`, `item_delete`, `item_purge`, `pre_item_add`, `pre_item_update` | Inalterado | Grupo CRUD |
| `post_show_item`, `post_item_form`, `item_transfer` | Inalterado | Grupo formulário/exibição |
| `menu_toadd`, `use_massive_action` | Inalterado | — |
| `csrf_compliant` | **Depreciado** (`@deprecated 11.0.0`) | Não declarar mais |
| `debug_tabs` | **Removido** | Aba de debug não existe mais |
| `migratetypes` | **Removido** | — |
| `planning_scheduler_key` | **Removido** | — |
| `show_in_timeline` | **Renomeado** → `timeline_items` | Mesmo uso |
| `ruleImportComputer_addGlobalCriteria`, `ruleImportComputer_getSqlRestriction` | **Renomeados** → `ruleImportAsset_*` | Coerente com remoção de `RuleImportComputer` |
| `pre_itil_info_section`, `post_itil_info_section` | **Novo (11)** | Recebem `<section>` |
| `pre_item_list`, `post_item_list` | **Novo (11)** | — |
| `pre_kanban_panel_content`, `post_kanban_panel_content`, `pre/post_kanban_panel_main_content` | **Novo (11)** | Kanban |
| `display_service_catalog`, `set_item_impact_icon`, `timeline_items`, `stats`, `default_display_prefs` | **Novo (11)** | Display/UI |
| `javascript` (`Hooks::JAVASCRIPT`) | **Novo (11)** | Assets |
| `api_controllers`, `api_middleware`, `redefine_api_schemas` | **Novo (11)** | High-Level API |
| `dashboard_defaults`, `dashboard_palettes` | **Novo (11)** | Dashboards |
| `pre_inventory`, `post_inventory` | **Novo (11)** | Inventário |
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
            'glpi' => ['min' => '11.0.0', 'max' => '11.0.99'],
            'php'  => ['min' => '8.2'],
        ],
    ];
}

function plugin_meuplugin_check_prerequisites(): bool
{
    if (version_compare(GLPI_VERSION, '11.0', 'lt')) {
        echo 'Requer GLPI 11.0 ou superior.';
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

Nota: `$PLUGIN_HOOKS['csrf_compliant']` **não** aparece mais no exemplo — o hook está depreciado desde o 11 (`@deprecated 11.0.0`), não deve mais ser declarado. O token continua obrigatório nos formulários/AJAX via `csrf_token()`; a checagem em si deixou de ser opt-in por plugin — ver `domains/glpi-11/ajax-handlers/SKILL.md` (§ Validação de CSRF no Servidor).

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

## Segurança

Auto-sanitização de `$_GET`/`$_POST`/`$_REQUEST` foi **removida** no 11 — todo dado chega em estado bruto, seja de formulário, banco ou API.

```php
// Cast explícito em IDs — obrigatório, inalterado
$id = (int) $_POST['id'];

// Proteção SQL é automática na construção da query — não sanitizar manualmente
$item->add($properties); // NÃO usar Toolbox::addslashes_deep($properties)

// Proteção XSS é responsabilidade explícita do código
echo '<p>' . htmlescape($description) . '</p>';

// Para JS, escapar duas vezes
echo "$(body).append('<p>' . jsescape('<p>' . htmlescape($content) . '</p>') . '</p>');";
```

`Toolbox::addslashes_deep()` e `Toolbox::stripslashes_deep()` foram depreciados e **corrompem dados** se usados no 11. Toda a família `Glpi\Toolbox\Sanitizer::*` (`sanitize`, `unsanitize`, `dbEscape`, `encodeHtmlSpecialChars`) também foi depreciada. `htmlescape()`/`jsescape()` são funções globais de transição — usar em toda saída dinâmica.

Erros HTTP via exceção, nunca `exit()`/`die()`/`http_response_code()`:

```php
if (!$item->getFromDB((int) $_GET['id'])) {
    throw new \Glpi\Exception\Http\NotFoundHttpException();
}
```

---

## Globais Essenciais

| Global | Tipo | Uso |
|---|---|---|
| `$DB` | `DBmysql` | Acesso ao banco — leitura e escrita |
| `$CFG_GLPI` | `array` | Configurações globais do GLPI |
| `$_SESSION['glpiID']` | `int` | ID do usuário logado |
| `$_SESSION['glpiactive_entity']` | `int` | Entidade ativa |
| `$PLUGIN_HOOKS` | `array` | Registro de hooks do plugin |

`$GLPI` e `$LANG` foram **removidas** no 11 — não referenciá-las. Constantes/globais adicionais removidas: `GLPI_USE_CSRF_CHECK`, `GLPI_USE_IDOR_CHECK`, `GLPI_DEMO_MODE`, `GLPI_DUMP_DIR`, `GLPI_SQL_DEBUG`, `$AJAX_INCLUDE`, `$CFG_GLPI_PLUGINS`, `$SECURITY_STRATEGY`, `$SQLLOGGER`, `$DBCONNECTION_REQUIRED`, `$USEDBREPLICATE`, `$PLUGINS_EXCLUDED`, `$PLUGINS_INCLUDED`, `$_SESSION['glpiroot']`. `PLUGINS_DIRECTORIES` foi renomeada para `GLPI_PLUGINS_DIRECTORIES`.

Sempre declarar `global $DB;` antes de usar `$DB` em métodos de classe.
