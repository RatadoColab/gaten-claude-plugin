---
name: glpi
description: Esta skill deve ser carregada quando o projeto for um plugin GLPI 10.0.x. Identificadores de contexto GLPI: presença de setup.php + hook.php na raiz do projeto, ou menção explícita do usuário ("plugin GLPI", "módulo GLPI", "GLPI 10", "CommonDBTM"). Cobre os padrões gerais de integração com o framework GLPI — CommonDBTM, sistema de permissões, acesso ao banco via $DB global e registro de hooks. Sub-skills específicas estão disponíveis para criação de plugins e handlers AJAX.
version: 0.2.0
---

# GLPI 10.0.x — Padrões de Desenvolvimento de Plugins

## Diferenças Fundamentais em Relação ao Backend Genérico

Plugins GLPI não seguem a arquitetura tradicional de camadas (Controller → Service → Repository). O framework impõe convenções próprias que devem ser respeitadas:

| Camada genérica | Equivalente no GLPI |
|---|---|
| Controller | `front/item.php` — chama `Html::header()` / `Html::footer()` |
| Service | Métodos na própria classe `CommonDBTM` |
| Repository | `CommonDBTM` integrado — `getFromDB()`, `add()`, `update()`, `delete()` |
| Auth / AuthZ | `Session::checkRight('rightname', READ\|WRITE)` |
| Migration | `install/install.php` com `$DB->queryOrDie()` |

## Estrutura Padrão de um Plugin

```
plugins/[nome-do-plugin]/
├── setup.php                  ← bootstrap: versão, constantes, registro de hooks e menus
├── hook.php                   ← install/uninstall: criação e remoção de tabelas
├── src/                       ← classes PHP (uma classe por arquivo, PascalCase)
│   └── MinhaClasse.php
├── front/                     ← páginas acessadas diretamente pelo browser
│   ├── minhaclasse.php        ← listagem
│   └── minhaclasse.form.php   ← formulário de criação/edição
├── ajax/                      ← endpoints AJAX (retornam JSON)
│   └── minhaclasse.php
├── templates/                 ← templates Twig (GLPI 10.x)
│   └── minhaclasse.form.html.twig
├── js/                        ← JavaScript do plugin
├── css/                       ← CSS do plugin
├── locales/                   ← traduções
│   ├── pt_BR.po
│   └── pt_BR.mo
└── tests/
    └── units/                 ← testes PHPUnit
```

## Nomenclatura

| Elemento | Convenção |
|---|---|
| Tabelas | `glpi_plugin_[nomedoplugin]_[entidade]` — minúsculas, sem hífen |
| Classes | `Entidade` (PascalCase) em `src/Entidade.php` |
| Direitos | `plugin_[nomedoplugin]_[entidade]` |
| Funções de hooks | `plugin_[nomedoplugin]_[hookname]` em `hook.php` |

## CommonDBTM — Model + Repository

Toda entidade de dados de um plugin estende `CommonDBTM`. Não criar repositórios separados.

```php
<?php

declare(strict_types=1);

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
        return _n('Item', 'Itens', $nb, 'meuplugin');
    }
}
```

**Hierarquia de herança conforme o tipo de entidade:**

| Tipo de entidade | Classe base |
|---|---|
| Entidade comum | `CommonDBTM` |
| Dropdown (lista de seleção) | `CommonDropdown` |
| Entidade filho de outra | `CommonDBChild` |
| Relação entre duas entidades | `CommonDBRelation` |
| Interfaces/páginas sem dados | `CommonGLPI` |

Métodos de acesso a dados disponíveis via herança: `getFromDB()`, `add()`, `update()`, `delete()`, `find()`, `deleteByCriteria()`.

Para referência completa de métodos, hooks de ciclo de vida e exemplos de JOIN, consultar **`references/glpi-architecture.md`**.

## Sistema de Permissões

Verificar permissões **no início** de todo arquivo `front/` e `ajax/`. Plugins nunca implementam autenticação própria. Usar `Session::checkRight()` (lança exceção) ou `Session::haveRight()` (retorna bool). Constantes disponíveis: `READ`, `UPDATE`, `CREATE`, `DELETE`, `PURGE`, `ALLSTANDARDRIGHT`.

Exemplos completos de verificação em **`references/glpi-architecture.md`**.

## Cabeçalho Obrigatório em `front/` e `ajax/`

```php
<?php

include('../../../inc/includes.php');
Session::checkLoginUser(); // ou Session::checkRight() conforme necessário
```

## Acesso ao Banco de Dados

Usar sempre `$DB` global. Nunca usar PDO diretamente.

```php
global $DB;

// Leitura
$iter = $DB->request([
    'FROM'  => MeuItem::getTable(),
    'WHERE' => ['is_deleted' => 0, 'entities_id' => $_SESSION['glpiactive_entity']],
    'ORDER' => ['name ASC'],
]);
foreach ($iter as $row) { /* ... */ }

// DDL em install/
$DB->queryOrDie("CREATE TABLE IF NOT EXISTS `...` (...)", 'Mensagem de erro');
```

Exemplos de JOIN, contagem e critérios compostos em **`references/glpi-architecture.md`**.

## Hooks GLPI 10.x

Os hooks se dividem em dois grupos com formas de registro e receptores distintos:

**Grupo 1 — CRUD** (`item_add`, `item_update`, `pre_item_add`, `item_purge`, etc.)
- Registro indexado por itemtype: `['Location' => [MinhaClasse::class, 'metodo']]`
- Receptor: método estático em `src/`, recebe o objeto diretamente
- `pre_`-hooks: ler/escrever `$item->input` | post-hooks: ler `$item->fields`

**Grupo 2 — Formulário/exibição** (`post_show_item`, `post_item_form`, `item_transfer`, etc.)
- Registro: callable direto, sem indexação por itemtype
- Receptor: função em `hook.php`, convenção `plugin_[nomedoplugin]_[hookname]`
- Recebe `array $params` — filtrar itemtype manualmente dentro da função
- Na dúvida sobre o grupo de um hook, tratar como Grupo 2

Hooks disponíveis listados em **`references/glpi-architecture.md`**.

## Segurança

Aplicar sempre que houver input de usuário: cast explícito em IDs (`(int) $_POST['id']`), sanitização com `Toolbox::addslashes_deep()`, remoção de HTML com `strip_tags()`, salvamento de HTML com `Sanitizer::sanitize()`. CSRF obrigatório: `$PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true`.

Exemplos completos em **`references/glpi-architecture.md`**.

## Internacionalização

Todo texto visível ao usuário deve usar as funções de tradução. Nunca usar strings hardcoded:

```php
__('texto', 'nomedoplugin')
_n('singular', 'plural', $n, 'nomedoplugin')
```

## Frontend JavaScript

- Priorizar AJAX/REST sem reload de página
- **Sempre perguntar antes de gerar código JS**: Javascript puro, Vue.js ou jQuery?
- jQuery já disponível no GLPI core (sem necessidade de importar)
- URLs de endpoints via `CFG_GLPI.root_doc + '/plugins/[nome]/ajax/...'`

## Testes

- Framework: PHPUnit
- Local dos testes: `plugins/[nome]/tests/units/`
- Nomenclatura: `[NomeDaClasse]Test.php`
- Para cada feature implementada, entregar o arquivo de teste correspondente

## Globais Essenciais

Principais: `$DB` (acesso ao banco — declarar `global $DB;` antes de usar), `$CFG_GLPI` (configurações), `$_SESSION['glpiID']` (usuário logado), `$_SESSION['glpiactive_entity']` (entidade ativa), `$PLUGIN_HOOKS` (registro de hooks).

Tabela completa com tipos em **`references/glpi-architecture.md`**.

## Sub-skills Disponíveis

Carregar conforme a tarefa específica:

| Tarefa | Skill a carregar |
|---|---|
| Criar um novo plugin do zero | `skills/domains/glpi/plugin-creation/SKILL.md` |
| Criar ou editar handlers em `ajax/` | `skills/domains/glpi/ajax-handlers/SKILL.md` |
| Criar ou editar formulários Twig em `templates/` | `skills/domains/glpi/form-templates/SKILL.md` |

## Restrições Absolutas em Plugins GLPI

- Usar `declare(strict_types=1)` em todo arquivo PHP
- Nunca implementar autenticação ou sessão própria — usar `Session::checkRight()`
- Nunca usar PDO diretamente — usar `$DB->request()` ou `$DB->queryOrDie()`
- Nunca criar estrutura `src/Domain/Application/Infrastructure/` — usar `front/`, `ajax/`, `src/`, `install/`
- Sempre marcar o plugin como CSRF-compliant: `$PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true`
- Nunca usar strings hardcoded visíveis ao usuário — usar `__()` ou `_n()`

## Licença

Todo arquivo PHP deve conter o cabeçalho GPLv3 com copyright IBGE. O template completo está em **`references/glpi-architecture.md`**.
