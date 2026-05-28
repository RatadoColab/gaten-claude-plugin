# Arquitetura GLPI 10.0.x — Referência Técnica

## CommonDBTM — Model + Repository Unificado

`CommonDBTM` é a classe base de todos os objetos de dados no GLPI. Ela combina as responsabilidades de model e repositório.

```php
class MeuItem extends CommonDBTM
{
    // Nome da chave no sistema de permissões
    static $rightname = 'meuitem';

    // Tabela é derivada automaticamente: glpi_meuitem -> nao; usualmente glpi_plugin_<plugin>_<item>
    // Para definir explicitamente:
    static $table = 'glpi_plugin_meuplugin_meuitem';

    /**
     * @return string
     */
    public static function getTypeName($nb = 0): string
    {
        return _n('Meu Item', 'Meus Itens', $nb, 'meuplugin');
    }
}
```

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
    // Remover registros filhos para evitar órfãos
    $relation = new MeuItemRelacao();
    $relation->deleteByCriteria(['meuitem_id' => $this->getID()]);
}

/** Executado antes de deletar — pode abortar com $this->input = false */
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
// Verificação simples
Session::haveRight('meuitem', READ);     // lança exceção se não tiver acesso
Session::haveRight('meuitem', UPDATE);
Session::haveRight('meuitem', CREATE);
Session::haveRight('meuitem', DELETE);
Session::haveRight('meuitem', PURGE);

// Múltiplas permissões (qualquer uma basta)
Session::haveRightsOr('meuitem', [CREATE, UPDATE]);

// Retorna bool em vez de lançar exceção
if (!Session::haveRight('meuitem', READ)) {
    Html::displayRightError();
    exit;
}
```

### Registro do direito

Em `setup.php`, dentro de `plugin_init_<nome>()`:

```php
Plugin::addCapacity(new PluginMeupluginCapacity());
// ou registro manual de direitos em ProfileRight
```

Em `hook.php`, na função `plugin_meuplugin_install()`:

```php
// Inserir direitos padrão para todos os perfis
$profileRight = new ProfileRight();
foreach (Profile::getProfiles() as $profileId) {
    $profileRight->updateProfileRights($profileId, ['meuitem' => ALLSTANDARDRIGHT]);
}
```

---

## Registro via `setup.php`

### Funções obrigatórias

```php
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

    // Registrar classe principal
    Plugin::registerClass('PluginMeupluginMeuitem', [
        // Adicionar aba no Computer
        'addtabon' => ['Computer'],
    ]);

    // Adicionar hook global
    $PLUGIN_HOOKS['item_update']['meuplugin'] = 'plugin_meuplugin_item_update';
}
```

### Hooks disponíveis em `$PLUGIN_HOOKS`

| Hook | Quando dispara |
|---|---|
| `item_add` | Após adicionar qualquer item |
| `item_update` | Após atualizar qualquer item |
| `item_delete` | Após mover item para lixeira |
| `item_purge` | Após purgar item definitivamente |
| `pre_item_add` | Antes de adicionar (pode alterar `$item->input`) |
| `pre_item_update` | Antes de atualizar |
| `menu_toadd` | Adicionar entrada ao menu lateral |
| `use_massive_action` | Registrar ações em massa |
| `csrf_compliant` | Marcar plugin como compatível com CSRF (obrigatório) |

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
