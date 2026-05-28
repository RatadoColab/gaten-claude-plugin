# Estrutura Completa de Plugin GLPI 10.0.x

## Árvore de Arquivos Obrigatória

```
meuplugin/
├── setup.php                          # Obrigatório — registro e metadados
├── hook.php                           # Obrigatório — implementação dos hooks
├── front/
│   └── meuitem.php                    # Página de listagem/formulário
├── ajax/
│   └── meuitem.php                    # Handler AJAX
├── src/
│   └── MeuItem.php                    # Classe principal (CommonDBTM)
├── install/
│   ├── install.php                    # Criação de tabelas
│   └── update.php                     # Atualizações de schema
├── locales/
│   └── pt_BR.po                       # Traduções
└── tests/
    └── units/
        └── MeuItemTest.php            # Testes PHPUnit
```

---

## `setup.php` — Completo

```php
<?php

/**
 * ---------------------------------------------------------------------
 *
 * meuplugin plugin for GLPI
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

/**
 * @return array
 */
function plugin_version_meuplugin(): array
{
    return [
        'name'         => 'Meu Plugin',
        'version'      => '1.0.0',
        'author'       => 'IBGE GLPI Development Team',
        'license'      => 'GPLv3+',
        'homepage'     => 'https://exemplo.com',
        'requirements' => [
            'glpi' => ['min' => '10.0.0', 'max' => '10.1.0'],
            'php'  => ['min' => '8.1'],
        ],
    ];
}

/**
 * @return bool
 */
function plugin_meuplugin_check_prerequisites(): bool
{
    if (version_compare(GLPI_VERSION, '10.0.0', 'lt')) {
        echo 'Este plugin requer GLPI 10.0.0 ou superior.';
        return false;
    }
    return true;
}

/**
 * @param bool $verbose
 * @return bool
 */
function plugin_meuplugin_check_config(bool $verbose = false): bool
{
    return true;
}

/** Registra classes, hooks e configurações do plugin */
function plugin_init_meuplugin(): void
{
    global $PLUGIN_HOOKS;

    $PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true;

    Plugin::registerClass('MeuItem', [
        'addtabon' => ['Computer', 'User'],
    ]);

    // Hooks Grupo 1 — indexados por itemtype, receptor em src/
    $PLUGIN_HOOKS['item_update']['meuplugin'] = [
        'Computer' => ['MeuItem', 'onComputerUpdate'],
    ];

    // Hooks Grupo 2 — callable direto, receptor em hook.php
    $PLUGIN_HOOKS['post_show_item']['meuplugin'] = 'plugin_meuplugin_post_show_item';

    if (Session::haveRight('plugin_meuplugin_meuitem', READ)) {
        $PLUGIN_HOOKS['menu_toadd']['meuplugin'] = ['tools' => 'MeuItem'];
    }
}
```

---

## `hook.php` — Completo

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

/**
 * @param array $params
 * @return void
 */
function plugin_meuplugin_post_show_item(array $params): void
{
    if (!($params['item'] instanceof Computer)) {
        return;
    }
    // Reagir à exibição de um Computer
}

/**
 * @return bool
 */
function plugin_meuplugin_install(): bool
{
    include_once __DIR__ . '/install/install.php';
    return plugin_meuplugin_install_tables();
}

/**
 * @return bool
 */
function plugin_meuplugin_uninstall(): bool
{
    global $DB;

    $DB->queryOrDie(
        "DROP TABLE IF EXISTS `glpi_plugin_meuplugin_meuitem`",
        'Erro ao remover tabela do plugin'
    );

    $profileRight = new ProfileRight();
    $profileRight->deleteByCriteria(['name' => 'plugin_meuplugin_meuitem']);

    return true;
}
```

---

## `src/MeuItem.php` — Classe Principal

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

/**
 * Classe principal do plugin Meu Plugin
 */
class MeuItem extends CommonDBTM
{
    /** @var string */
    static $rightname = 'plugin_meuplugin_meuitem';

    /**
     * @param int $nb
     * @return string
     */
    public static function getTypeName($nb = 0): string
    {
        return _n('Meu Item', 'Meus Itens', $nb, 'meuplugin');
    }

    /**
     * @return array
     */
    public static function getMenuContent(): array
    {
        $menu = [];

        if (static::canView()) {
            $menu['title']           = static::getMenuName();
            $menu['page']            = '/plugins/meuplugin/front/meuitem.php';
            $menu['icon']            = static::getIcon();
            $menu['links']['search'] = '/plugins/meuplugin/front/meuitem.php';

            if (static::canCreate()) {
                $menu['links']['add'] = '/plugins/meuplugin/front/meuitem.form.php';
            }
        }

        return $menu;
    }

    /**
     * @return string
     */
    public static function getIcon(): string
    {
        return 'fas fa-box';
    }

    // --- Hook Grupo 1: receptor de item_update ---

    /**
     * @param CommonDBTM $item
     * @return void
     */
    public static function onComputerUpdate(CommonDBTM $item): void
    {
        // Reagir à atualização de um Computer
        // Ler $item->fields para valores atuais
    }

    // --- Abas em outros objetos GLPI ---

    /**
     * @param CommonGLPI $item
     * @param int        $withtemplate
     * @return string
     */
    public function getTabNameForItem(CommonGLPI $item, $withtemplate = 0): string
    {
        if ($item instanceof Computer) {
            $count = countElementsInTable(
                static::getTable(),
                ['computers_id' => $item->getID(), 'is_deleted' => 0]
            );
            return self::createTabEntry(static::getTypeName(Session::getPluralNumber()), $count);
        }
        return '';
    }

    /**
     * @param CommonGLPI $item
     * @param int        $tabnum
     * @param int        $withtemplate
     * @return bool
     */
    public static function displayTabContentForItem(CommonGLPI $item, $tabnum = 1, $withtemplate = 0): bool
    {
        if ($item instanceof Computer) {
            $self = new self();
            $self->showForComputer($item);
        }
        return true;
    }

    /**
     * @param Computer $computer
     * @return void
     */
    public function showForComputer(Computer $computer): void
    {
        global $DB;

        Session::checkRight(static::$rightname, READ);

        $iter = $DB->request([
            'FROM'  => static::getTable(),
            'WHERE' => ['computers_id' => $computer->getID(), 'is_deleted' => 0],
        ]);

        echo '<table class="tab_cadre_fixehov">';
        foreach ($iter as $row) {
            echo '<tr><td>' . htmlspecialchars($row['name']) . '</td></tr>';
        }
        echo '</table>';
    }

    /** @return void */
    public function post_addItem(): void
    {
        // Executado após inserção bem-sucedida
    }

    /** @return void */
    public function cleanDBonPurge(): void
    {
        // Limpar dados relacionados ao purgar
    }
}
```

---

## `install/install.php` — Criação de Tabelas

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

/**
 * @return bool
 */
function plugin_meuplugin_install_tables(): bool
{
    global $DB;

    if (!$DB->tableExists('glpi_plugin_meuplugin_meuitem')) {
        $DB->queryOrDie(
            "CREATE TABLE `glpi_plugin_meuplugin_meuitem` (
                `id`            INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `name`          VARCHAR(255) NOT NULL DEFAULT '',
                `comment`       TEXT,
                `entities_id`   INT NOT NULL DEFAULT 0,
                `is_recursive`  TINYINT NOT NULL DEFAULT 0,
                `is_deleted`    TINYINT NOT NULL DEFAULT 0,
                `computers_id`  INT NOT NULL DEFAULT 0,
                `date_mod`      TIMESTAMP NULL DEFAULT NULL,
                `date_creation` TIMESTAMP NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `name`          (`name`),
                KEY `entities_id`   (`entities_id`),
                KEY `computers_id`  (`computers_id`),
                KEY `is_deleted`    (`is_deleted`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
            'Erro ao criar tabela glpi_plugin_meuplugin_meuitem'
        );
    }

    $profileRight = new ProfileRight();
    foreach (Profile::getProfiles() as $profileId => $profileName) {
        if (!countElementsInTable('glpi_profilerights', [
            'profiles_id' => $profileId,
            'name'        => 'plugin_meuplugin_meuitem',
        ])) {
            $profileRight->add([
                'profiles_id' => $profileId,
                'name'        => 'plugin_meuplugin_meuitem',
                'rights'      => 0,
            ]);
        }
    }

    return true;
}
```

---

## `front/meuitem.php` — Página de Listagem

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

include('../../../inc/includes.php');

Session::checkLoginUser();
Session::checkRight('plugin_meuplugin_meuitem', READ);

$item = new MeuItem();

if (isset($_POST['add'])) {
    $item->check(-1, CREATE, $_POST);
    $item->add($_POST);
    Html::back();
} elseif (isset($_POST['update'])) {
    $item->check((int) $_POST['id'], UPDATE, $_POST);
    $item->update($_POST);
    Html::back();
} elseif (isset($_POST['delete'])) {
    $item->check((int) $_POST['id'], DELETE, $_POST);
    $item->delete($_POST);
    Html::redirect(MeuItem::getSearchURL());
}

Html::header(MeuItem::getTypeName(Session::getPluralNumber()), $_SERVER['PHP_SELF']);
Search::show('MeuItem');
Html::footer();
```

---

## `ajax/meuitem.php` — Handler AJAX

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

include('../../../inc/includes.php');

Session::checkLoginUser();
Session::checkRight('plugin_meuplugin_meuitem', READ);

$action = $_REQUEST['action'] ?? '';

header('Content-Type: application/json');

switch ($action) {
    case 'getList':
        $items = (new MeuItem())->find(
            ['is_deleted' => 0],
            ['name ASC']
        );
        echo json_encode(array_values($items));
        break;

    case 'getOne':
        $id   = (int) ($_REQUEST['id'] ?? 0);
        $item = new MeuItem();
        if ($item->getFromDB($id)) {
            echo json_encode($item->fields);
        } else {
            http_response_code(404);
            echo json_encode(['error' => __('Item não encontrado', 'meuplugin')]);
        }
        break;

    default:
        http_response_code(400);
        echo json_encode(['error' => __('Ação inválida', 'meuplugin')]);
}
```
