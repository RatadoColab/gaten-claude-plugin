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
├── inc/
│   └── meuitem.class.php              # Classe principal (CommonDBTM)
├── install/
│   ├── install.php                    # Criação de tabelas
│   └── update.php                     # Atualizações de schema
├── locales/
│   └── pt_BR.po                       # Traduções (opcional)
└── pics/
    └── meuitem.png                    # Ícone do item (opcional, 16x16)
```

---

## `setup.php` — Completo

```php
<?php

/**
 * @return array
 */
function plugin_version_meuplugin(): array
{
    return [
        'name'         => 'Meu Plugin',
        'version'      => '1.0.0',
        'author'       => 'Autor do Plugin',
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

    // Obrigatório: marcar compatibilidade CSRF
    $PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true;

    // Registrar classe principal
    // 'addtabon' adiciona aba nas telas dos itens listados
    Plugin::registerClass('PluginMeupluginMeuitem', [
        'addtabon' => ['Computer', 'User'],
    ]);

    // Hooks globais (implementados em hook.php)
    $PLUGIN_HOOKS['item_add']['meuplugin']    = 'plugin_meuplugin_item_add';
    $PLUGIN_HOOKS['item_update']['meuplugin'] = 'plugin_meuplugin_item_update';

    // Adicionar entrada no menu lateral
    if (Session::haveRight('pluginmeupluginmeuitem', READ)) {
        $PLUGIN_HOOKS['menu_toadd']['meuplugin'] = ['tools' => 'PluginMeupluginMeuitem'];
    }
}
```

---

## `hook.php` — Completo

```php
<?php

/**
 * @param CommonDBTM $item
 * @return void
 */
function plugin_meuplugin_item_add(CommonDBTM $item): void
{
    if (!($item instanceof Computer)) {
        return;
    }
    // Reagir à criação de um Computer
}

/**
 * @param CommonDBTM $item
 * @return void
 */
function plugin_meuplugin_item_update(CommonDBTM $item): void
{
    if (!($item instanceof Computer)) {
        return;
    }
    // Reagir à atualização de um Computer
}

/**
 * Chamado durante instalação do plugin
 * @return bool
 */
function plugin_meuplugin_install(): bool
{
    include_once __DIR__ . '/install/install.php';
    return plugin_meuplugin_install_tables();
}

/**
 * Chamado durante desinstalação do plugin
 * @return bool
 */
function plugin_meuplugin_uninstall(): bool
{
    global $DB;

    $DB->queryOrDie(
        "DROP TABLE IF EXISTS `glpi_plugin_meuplugin_meuitem`",
        'Erro ao remover tabela do plugin'
    );

    // Remover direitos registrados
    $profileRight = new ProfileRight();
    $profileRight->deleteByCriteria(['name' => 'pluginmeupluginmeuitem']);

    return true;
}
```

---

## `inc/meuitem.class.php` — Classe Principal

```php
<?php

/**
 * Classe principal do plugin Meu Plugin
 */
class PluginMeupluginMeuitem extends CommonDBTM
{
    /** @var string */
    static $rightname = 'pluginmeupluginmeuitem';

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
        return 'fas fa-box'; // ícone FontAwesome
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

        Session::haveRight(static::$rightname, READ);

        $iter = $DB->request([
            'FROM'  => static::getTable(),
            'WHERE' => ['computers_id' => $computer->getID(), 'is_deleted' => 0],
        ]);

        // Renderizar conteúdo da aba
        echo '<table class="tab_cadre_fixehov">';
        foreach ($iter as $row) {
            echo '<tr><td>' . htmlspecialchars($row['name']) . '</td></tr>';
        }
        echo '</table>';
    }

    // --- Hooks de ciclo de vida ---

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
 * @return bool
 */
function plugin_meuplugin_install_tables(): bool
{
    global $DB;

    // Criar tabela principal somente se não existir
    if (!$DB->tableExists('glpi_plugin_meuplugin_meuitem')) {
        $DB->queryOrDie(
            "CREATE TABLE `glpi_plugin_meuplugin_meuitem` (
                `id`           INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `name`         VARCHAR(255) NOT NULL DEFAULT '',
                `comment`      TEXT,
                `entities_id`  INT NOT NULL DEFAULT 0,
                `is_recursive` TINYINT NOT NULL DEFAULT 0,
                `is_deleted`   TINYINT NOT NULL DEFAULT 0,
                `computers_id` INT NOT NULL DEFAULT 0,
                `date_mod`     TIMESTAMP NULL DEFAULT NULL,
                `date_creation` TIMESTAMP NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `name`         (`name`),
                KEY `entities_id`  (`entities_id`),
                KEY `computers_id` (`computers_id`),
                KEY `is_deleted`   (`is_deleted`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
            'Erro ao criar tabela glpi_plugin_meuplugin_meuitem'
        );
    }

    // Registrar direitos de acesso em todos os perfis existentes
    $profileRight = new ProfileRight();
    foreach (Profile::getProfiles() as $profileId => $profileName) {
        if (!countElementsInTable('glpi_profilerights', [
            'profiles_id' => $profileId,
            'name'        => 'pluginmeupluginmeuitem',
        ])) {
            $profileRight->add([
                'profiles_id' => $profileId,
                'name'        => 'pluginmeupluginmeuitem',
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

include('../../../inc/includes.php');

// Verificar permissão antes de qualquer output
Session::haveRight('pluginmeupluginmeuitem', READ);

$item = new PluginMeupluginMeuitem();

// Processar ações POST (add, update, delete, purge)
if (isset($_POST['add'])) {
    $item->check(-1, CREATE, $_POST);
    $item->add($_POST);
    Html::back();
} elseif (isset($_POST['update'])) {
    $item->check($_POST['id'], UPDATE, $_POST);
    $item->update($_POST);
    Html::back();
} elseif (isset($_POST['delete'])) {
    $item->check($_POST['id'], DELETE, $_POST);
    $item->delete($_POST);
    Html::redirect(PluginMeupluginMeuitem::getSearchURL());
}

// Exibir página
Html::header(PluginMeupluginMeuitem::getTypeName(Session::getPluralNumber()), $_SERVER['PHP_SELF']);
Search::show('PluginMeupluginMeuitem');
Html::footer();
```

---

## `ajax/meuitem.php` — Handler AJAX

```php
<?php

include('../../../inc/includes.php');

// Verificar permissão — obrigatório em todo handler AJAX
Session::haveRight('pluginmeupluginmeuitem', READ);

// Validar ação recebida
$action = $_REQUEST['action'] ?? '';

header('Content-Type: application/json');

switch ($action) {
    case 'getList':
        $items = (new PluginMeupluginMeuitem())->find(
            ['is_deleted' => 0],
            ['name ASC']
        );
        echo json_encode(array_values($items));
        break;

    case 'getOne':
        $id   = (int) ($_REQUEST['id'] ?? 0);
        $item = new PluginMeupluginMeuitem();
        if ($item->getFromDB($id)) {
            echo json_encode($item->fields);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Item não encontrado']);
        }
        break;

    default:
        http_response_code(400);
        echo json_encode(['error' => 'Ação inválida']);
}
```
