# Arquitetura GLPI 10.0.x — Referência Técnica

## Licença Obrigatória

Todo arquivo PHP deve conter o cabeçalho abaixo como comentário de licença GPLv3:

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

`CommonDBTM` é a classe base de todos os objetos de dados no GLPI. Ela combina as responsabilidades de model e repositório.

```php
<?php

/**
 * [License header aqui]
 */

declare(strict_types=1);

class MeuItem extends CommonDBTM
{
    /** @var string */
    static $rightname = 'plugin_meuplugin_meuitem';

    /** @var string */
    static $table = 'glpi_plugin_meuplugin_meuitem';

    /**
     * @param int $nb
     * @return string
     */
    public static function getTypeName($nb = 0): string
    {
        return _n('Meu Item', 'Meus Itens', $nb, 'meuplugin');
    }
}
```

### Hierarquia de herança

| Tipo | Classe base | Uso |
|---|---|---|
| Entidade comum | `CommonDBTM` | Objetos independentes |
| Dropdown | `CommonDropdown` | Listas de seleção (Category, Status, etc.) |
| Filho de entidade | `CommonDBChild` | Relacionamento 1:N com pai |
| Relação entre entidades | `CommonDBRelation` | Relacionamento N:N |
| Interface sem dados | `CommonGLPI` | Abas, páginas sem tabela própria |

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

### Hooks de ciclo de vida

Sobrescrever para reagir a eventos no item:

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

Nunca usar PDO diretamente. Usar sempre o objeto global `$DB` (instância de `DBmysql`).

### `$DB->request()` — leitura (retorna iterador)

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
    'SELECT' => ['mi.id', 'mi.name', 'u.name AS user_name'],
    'FROM'   => ['glpi_plugin_meuplugin_meuitem AS mi'],
    'LEFT JOIN' => [
        'glpi_users AS u' => ['FKEY' => ['mi' => 'users_id', 'u' => 'id']],
    ],
    'WHERE'  => ['mi.is_deleted' => 0],
]);

// Contagem
$count = countElementsInTable(MeuItem::getTable(), ['is_active' => 1]);
```

### `$DB->queryOrDie()` — DDL e DML direto

Usar em scripts de instalação/atualização. Em operações de leitura/escrita comuns, preferir `$DB->request()` e os métodos de `CommonDBTM`.

```php
global $DB;

$DB->queryOrDie(
    "CREATE TABLE IF NOT EXISTS `glpi_plugin_meuplugin_meuitem` (
        `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
        `name`        VARCHAR(255) NOT NULL DEFAULT '',
        `entities_id` INT NOT NULL DEFAULT 0,
        `is_deleted`  TINYINT NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        KEY `entities_id` (`entities_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
    'Erro ao criar tabela glpi_plugin_meuplugin_meuitem'
);
```

---

## Sistema de Permissões

### Verificação de acesso

Verificar permissões **no início** de todo arquivo `front/` e `ajax/`:

```php
// Lança exceção se não autorizado (uso preferencial)
Session::checkRight('plugin_meuplugin_meuitem', READ);
Session::checkRight('plugin_meuplugin_meuitem', UPDATE);
Session::checkRight('plugin_meuplugin_meuitem', CREATE);

// Retorna bool para tratamento manual
if (!Session::haveRight('plugin_meuplugin_meuitem', READ)) {
    Html::displayRightError();
    exit;
}

// Múltiplas permissões (qualquer uma basta)
Session::haveRightsOr('plugin_meuplugin_meuitem', [CREATE, UPDATE]);
```

### Registro do direito

Em `install/install.php`, registrar direitos para todos os perfis:

```php
$profileRight = new ProfileRight();
foreach (Profile::getProfiles() as $profileId) {
    $profileRight->updateProfileRights($profileId, ['plugin_meuplugin_meuitem' => ALLSTANDARDRIGHT]);
}
```

---

## Hooks GLPI 10.x

### Grupo 1 — CRUD (`item_add`, `item_update`, `pre_item_add`, `item_purge`, etc.)

Registro indexado por itemtype em `plugin_init_<nome>()`:

```php
$PLUGIN_HOOKS['item_update']['meuplugin'] = [
    'Location' => [MinhaClasse::class, 'onItemUpdate'],
];
```

Receptor: método estático em `src/`, recebe o objeto diretamente:

```php
// src/MinhaClasse.php
public static function onItemUpdate(CommonDBTM $item): void
{
    // pre-hooks: ler/escrever $item->input
    // post-hooks: ler $item->fields
}
```

### Grupo 2 — Formulário/exibição (`post_show_item`, `post_item_form`, `item_transfer`, etc.)

Registro com callable direto (sem indexação por itemtype):

```php
$PLUGIN_HOOKS['post_show_item']['meuplugin'] = 'plugin_meuplugin_post_show_item';
```

Receptor: função em `hook.php`, filtrar itemtype manualmente:

```php
// hook.php
function plugin_meuplugin_post_show_item(array $params): void
{
    if (!($params['item'] instanceof Computer)) {
        return;
    }
    // processar
}
```

Na dúvida sobre o grupo de um hook, tratar como Grupo 2.

### Tabela de hooks disponíveis em `$PLUGIN_HOOKS`

| Hook | Grupo | Quando dispara |
|---|---|---|
| `item_add` | 1 | Após adicionar qualquer item |
| `item_update` | 1 | Após atualizar qualquer item |
| `item_delete` | 1 | Após mover item para lixeira |
| `item_purge` | 1 | Após purgar item definitivamente |
| `pre_item_add` | 1 | Antes de adicionar (pode alterar `$item->input`) |
| `pre_item_update` | 1 | Antes de atualizar |
| `post_show_item` | 2 | Após exibir item |
| `post_item_form` | 2 | Após renderizar formulário |
| `item_transfer` | 2 | Ao transferir item entre entidades |
| `menu_toadd` | — | Adicionar entrada ao menu lateral |
| `use_massive_action` | — | Registrar ações em massa |
| `csrf_compliant` | — | Marcar plugin como compatível com CSRF (obrigatório) |

---

## Registro via `setup.php`

### Funções obrigatórias

```php
<?php

/**
 * [License header aqui]
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
        'author'       => 'Autor',
        'license'      => 'GPLv3+',
        'homepage'     => '',
        'requirements' => [
            'glpi' => ['min' => '10.0', 'max' => '10.1'],
            'php'  => ['min' => '8.1'],
        ],
    ];
}

/**
 * @return bool
 */
function plugin_meuplugin_check_prerequisites(): bool
{
    if (version_compare(GLPI_VERSION, '10.0', 'lt')) {
        echo 'Requer GLPI 10.0 ou superior.';
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

/** Registra classes, hooks e capacidades */
function plugin_init_meuplugin(): void
{
    global $PLUGIN_HOOKS;

    $PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true;

    Plugin::registerClass('MeuItem', [
        'addtabon' => ['Computer'],
    ]);

    $PLUGIN_HOOKS['item_update']['meuplugin'] = [
        'Computer' => ['MeuItem', 'onComputerUpdate'],
    ];
}
```

---

## Segurança

Aplicar sempre que houver input de usuário:

```php
// Cast explícito em IDs — obrigatório
$id = (int) $_POST['id'];

// Sanitização de strings
$name = Toolbox::addslashes_deep($_POST['name']);

// Remoção de HTML indesejado
$description = strip_tags($_POST['description']);

// Salvar HTML no banco (preserva formatação de forma segura)
$content = Sanitizer::sanitize($_POST['content']);
```

---

## Globais Essenciais

| Global | Tipo | Uso |
|---|---|---|
| `$DB` | `DBmysql` | Acesso ao banco — leitura e escrita |
| `$CFG_GLPI` | `array` | Configurações globais do GLPI |
| `$GLPI` | `GLPI` | Instância principal da aplicação |
| `$_SESSION['glpiID']` | `int` | ID do usuário logado |
| `$_SESSION['glpiactive_entity']` | `int` | Entidade ativa |
| `$PLUGIN_HOOKS` | `array` | Registro de hooks do plugin |

Sempre declarar `global $DB;` antes de usar `$DB` em métodos de classe.
