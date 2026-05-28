---
name: glpi
description: Esta skill deve ser carregada quando o projeto for um plugin GLPI 10.0.x. Identificadores de contexto GLPI: presença de setup.php + hook.php na raiz do projeto, ou menção explícita do usuário ("plugin GLPI", "módulo GLPI", "GLPI 10", "CommonDBTM"). Cobre os padrões gerais de integração com o framework GLPI — CommonDBTM, sistema de permissões, acesso ao banco via $DB global e registro de hooks. Para tarefas específicas, carregar a sub-skill correspondente listada em "Sub-skills Disponíveis".
version: 0.1.0
---

# GLPI 10.0.x — Padrões de Desenvolvimento de Plugins

## Diferenças Fundamentais em Relação ao Backend Genérico

Plugins GLPI não seguem a arquitetura tradicional de camadas (Controller → Service → Repository). O framework impõe convenções próprias que devem ser respeitadas:

| Camada genérica | Equivalente no GLPI |
|---|---|
| Controller | `front/item.php` — chama `Html::header()` / `Html::footer()` |
| Service | Métodos na própria classe `CommonDBTM` |
| Repository | `CommonDBTM` integrado — `getFromDB()`, `add()`, `update()`, `delete()` |
| Auth / AuthZ | `Session::haveRight('rightname', READ\|WRITE)` |
| Migration | `install/install.php` com `$DB->queryOrDie()` |

## CommonDBTM — Model + Repository

Toda entidade de dados de um plugin estende `CommonDBTM`. Não criar repositórios separados.

```php
class PluginMeupluginItem extends CommonDBTM
{
    static $rightname = 'pluginmeupluginitem'; // chave de permissão

    /**
     * @param int $nb
     * @return string
     */
    public static function getTypeName($nb = 0): string
    {
        return _n('Item', 'Itens', $nb, 'meuplugin');
    }
}
```

Métodos de acesso a dados disponíveis via herança: `getFromDB()`, `add()`, `update()`, `delete()`, `find()`, `deleteByCriteria()`.

Para referência completa de métodos, hooks de ciclo de vida (`post_addItem`, `cleanDBonPurge`) e exemplos de JOIN, consultar **`references/glpi-architecture.md`**.

## Sistema de Permissões

Verificar permissões **no início** de todo arquivo `front/` e `ajax/`. Plugins nunca implementam autenticação própria.

```php
// Lança exceção automática se sem acesso
Session::haveRight('pluginmeupluginitem', READ);

// Verifica e redireciona manualmente
if (!Session::haveRight('pluginmeupluginitem', UPDATE)) {
    Html::displayRightError();
    exit;
}

// Qualquer uma das permissões basta
Session::haveRightsOr('pluginmeupluginitem', [CREATE, UPDATE]);
```

Constantes disponíveis: `READ`, `UPDATE`, `CREATE`, `DELETE`, `PURGE`, `ALLSTANDARDRIGHT`.

## Acesso ao Banco de Dados

Usar sempre `$DB` global. Nunca usar PDO diretamente.

```php
global $DB;

// Leitura
$iter = $DB->request([
    'FROM'  => PluginMeupluginItem::getTable(),
    'WHERE' => ['is_deleted' => 0, 'entities_id' => $_SESSION['glpiactive_entity']],
    'ORDER' => ['name ASC'],
]);
foreach ($iter as $row) { /* ... */ }

// DDL em install/
$DB->queryOrDie("CREATE TABLE IF NOT EXISTS `...` (...)", 'Mensagem de erro');
```

Exemplos de JOIN, contagem e critérios compostos em **`references/glpi-architecture.md`**.

## Globais Essenciais

| Global | Uso |
|---|---|
| `$DB` | Acesso ao banco — sempre declarar `global $DB;` antes de usar |
| `$CFG_GLPI` | Configurações do GLPI (paths, URLs, features habilitadas) |
| `$_SESSION['glpiID']` | ID do usuário logado |
| `$_SESSION['glpiactive_entity']` | Entidade ativa — usar em queries para multientidade |
| `$PLUGIN_HOOKS` | Registro de hooks — preencher em `plugin_init_<nome>()` |

## Sub-skills Disponíveis

Carregar conforme a tarefa específica:

| Tarefa | Skill a carregar |
|---|---|
| Criar um novo plugin do zero | `skills/domains/glpi/plugin-creation/SKILL.md` |
| Criar páginas `front/` e integrar menus/abas | `skills/domains/glpi/front-patterns/SKILL.md` *(em breve)* |
| Criar handlers AJAX em `ajax/` | `skills/domains/glpi/ajax-handlers/SKILL.md` *(em breve)* |
| Criar ou estender classe `CommonDBTM` | `skills/domains/glpi/common-dbtm/SKILL.md` *(em breve)* |

## Restrições Absolutas em Plugins GLPI

- Nunca implementar autenticação ou sessão própria — usar `Session::haveRight()`
- Nunca usar PDO diretamente — usar `$DB->request()` ou `$DB->queryOrDie()`
- Nunca usar `declare(strict_types=1)` — o GLPI core não usa e causa incompatibilidades
- Nunca criar estrutura `src/Domain/Application/Infrastructure/` — usar `front/`, `ajax/`, `inc/`, `install/`
- Sempre marcar o plugin como CSRF-compliant: `$PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true`
