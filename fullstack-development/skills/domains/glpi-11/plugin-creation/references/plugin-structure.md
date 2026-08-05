# Estrutura Completa de Plugin GLPI 11

## Árvore de Arquivos Obrigatória

```
meuplugin/
├── setup.php                          # Obrigatório — registro, metadados, boot
├── hook.php                           # Obrigatório — implementação dos hooks
├── public/                            # Assets/scripts web-acessíveis (não aparece na URL)
│   └── build/
├── src/
│   ├── MeuItem.php                    # Classe principal (CommonDBTM), namespace GlpiPlugin\Meuplugin\
│   └── Controller/
│       └── MeuItemController.php      # Rota nova (recomendado) — #[Route]
├── front/                             # Legado — opcional, sem include(inc/includes.php)
│   └── meuitem.php
├── ajax/                              # Legado — opcional
│   └── meuitem.php
├── install/
│   ├── install.php                    # Criação de tabelas via Migration + $DB->doQuery
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

use Glpi\Plugin\Hooks;

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
            'glpi' => ['min' => '11.0.0', 'max' => '11.0.99'],
            'php'  => ['min' => '8.2'],
        ],
    ];
}

/**
 * @return bool
 */
function plugin_meuplugin_check_prerequisites(): bool
{
    if (version_compare(GLPI_VERSION, '11.0.0', 'lt')) {
        echo 'Este plugin requer GLPI 11.0.0 ou superior.';
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

/** Executado antes da sessão carregar e antes da inicialização dos plugins ativos */
function plugin_meuplugin_boot(): void
{
    // Registrar aqui rotas de API stateless, se houver
    // \Glpi\Http\SessionManager::registerPluginStatelessPath('meuplugin', '#^/api\.php#');
}

/** Registra classes, hooks e configurações do plugin */
function plugin_init_meuplugin(): void
{
    global $PLUGIN_HOOKS;

    // NÃO declarar $PLUGIN_HOOKS['csrf_compliant'] — hook depreciado no GLPI 11 (@deprecated 11.0.0)

    Plugin::registerClass(\GlpiPlugin\Meuplugin\MeuItem::class, [
        'addtabon' => ['Computer', 'User'],
    ]);

    // Hooks CRUD — indexados por itemtype, receptor em src/
    $PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['meuplugin'] = [
        'Computer' => [\GlpiPlugin\Meuplugin\MeuItem::class, 'onComputerUpdate'],
    ];

    // Hooks formulário/exibição — callable direto, receptor em hook.php
    $PLUGIN_HOOKS[Hooks::POST_SHOW_ITEM]['meuplugin'] = 'plugin_meuplugin_post_show_item';

    if (Session::haveRight('plugin_meuplugin_meuitem', READ)) {
        $PLUGIN_HOOKS[Hooks::MENU_TOADD]['meuplugin'] = ['tools' => \GlpiPlugin\Meuplugin\MeuItem::class];
    }
}
```

---

## `src/Controller/MeuItemController.php` — Rota Nova (Recomendado)

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Glpi\Exception\Http\BadRequestHttpException;
use Glpi\Exception\Http\NotFoundHttpException;
use GlpiPlugin\Meuplugin\MeuItem;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class MeuItemController extends AbstractController
{
    // Prefixo /plugins/meuplugin é aplicado automaticamente — não incluir aqui.
    // Métodos != GET só casam corretamente a partir da 11.0.7; em versões
    // anteriores, declarar 'GET' e checar $request->isMethod('POST') manualmente.
    #[Route("/MeuItem/{id}", name: "meuplugin_meuitem_get", methods: "GET")]
    public function show(int $id): Response
    {
        $item = new MeuItem();
        if (!$item->getFromDB($id)) {
            throw new NotFoundHttpException();
        }

        return new JsonResponse($item->fields);
    }

    #[Route("/MeuItem", name: "meuplugin_meuitem_create", methods: ["GET", "POST"])]
    public function create(Request $request): Response
    {
        if (!$request->isMethod('POST')) {
            throw new BadRequestHttpException();
        }

        $item = new MeuItem();
        $id   = $item->add($request->request->all());

        if ($id === false) {
            throw new BadRequestHttpException();
        }

        return new JsonResponse(['id' => $id], 201);
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

    $DB->doQuery("DROP TABLE IF EXISTS `glpi_plugin_meuplugin_meuitem`");

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

namespace GlpiPlugin\Meuplugin;

use CommonDBTM;
use CommonGLPI;
use Computer;
use Session;

/**
 * Classe principal do plugin Meu Plugin
 */
class MeuItem extends CommonDBTM
{
    /** @var string */
    static $rightname = 'plugin_meuplugin_meuitem';

    public static function getTypeName($nb = 0): string
    {
        return _n('Meu Item', 'Meus Itens', $nb, 'meuplugin');
    }

    public static function getMenuContent(): array
    {
        $menu = [];

        if (static::canView()) {
            $menu['title']           = static::getMenuName();
            $menu['page']            = '/plugins/meuplugin/MeuItem';
            $menu['icon']            = static::getIcon();
            $menu['links']['search'] = '/plugins/meuplugin/MeuItem';
        }

        return $menu;
    }

    public static function getIcon(): string
    {
        return 'fas fa-box';
    }

    // --- Hook CRUD: receptor de item_update ---

    public static function onComputerUpdate(CommonDBTM $item): void
    {
        // Reagir à atualização de um Computer
        // Ler $item->fields para valores atuais
    }

    // --- Abas em outros objetos GLPI ---

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

    public static function displayTabContentForItem(CommonGLPI $item, $tabnum = 1, $withtemplate = 0): bool
    {
        if ($item instanceof Computer) {
            $self = new self();
            $self->showForComputer($item);
        }
        return true;
    }

    public function showForComputer(Computer $computer): void
    {
        global $DB;

        Session::checkRight(static::$rightname, READ);

        $iter = $DB->request([
            'FROM'  => static::getTable(),
            'WHERE' => ['computers_id' => $computer->getID(), 'is_deleted' => 0],
        ]);

        echo '<table class="table">';
        foreach ($iter as $row) {
            echo '<tr><td>' . htmlescape($row['name']) . '</td></tr>';
        }
        echo '</table>';
    }

    /** Executado após inserção bem-sucedida */
    public function post_addItem(): void
    {
    }

    /** Limpar dados relacionados ao purgar */
    public function cleanDBonPurge(): void
    {
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

    $migration = new Migration(100);

    if (!$DB->tableExists('glpi_plugin_meuplugin_meuitem')) {
        $DB->doQuery(
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC"
        );
    }

    $migration->executeMigration();

    // ProfileRight::addProfileRights() já itera todos os perfis existentes e
    // ignora quem já tem o direito registrado — não é necessário loop manual
    // sobre Profile::getProfiles() (ver domains/glpi-11/references/architecture.md § Permissões)
    ProfileRight::addProfileRights(['plugin_meuplugin_meuitem']);

    return true;
}
```

---

## `front/meuitem.php` — Página de Listagem (Legado)

Manter apenas por compatibilidade — para páginas novas, preferir Controller. Sem `include('../../../inc/includes.php')`: o bootstrap roda automaticamente.

```php
<?php

/**
 * [License header]
 */

declare(strict_types=1);

Session::checkLoginUser();
Session::checkRight('plugin_meuplugin_meuitem', READ);

$item = new \GlpiPlugin\Meuplugin\MeuItem();

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
    Html::redirect(\GlpiPlugin\Meuplugin\MeuItem::getSearchURL());
}

Html::header(\GlpiPlugin\Meuplugin\MeuItem::getTypeName(Session::getPluralNumber()));
Search::show(\GlpiPlugin\Meuplugin\MeuItem::class);
Html::footer();
```

## Referência cruzada

Para o handler AJAX legado completo (quando não migrar para Controller), ver `domains/glpi-11/ajax-handlers/references/patterns.md`.
