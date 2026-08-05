---
name: glpi-10
description: This skill should be loaded when the target is a GLPI 10.0.x plugin. GLPI 10 identifiers — any is sufficient: `requirements.glpi.min` starting with "10." in setup.php, `include('../../../inc/includes.php')` in front/ or ajax/, `$PLUGIN_HOOKS['csrf_compliant']` present, `$DB->queryOrDie(` in code, or explicit user mention ("plugin GLPI 10", "GLPI 10.0.x"). If instead there are GLPI 11 indicators (a `public/` directory, `src/Controller/` with `#[Route]`, `$DB->doQuery(`, `plugin_<name>_boot()`, or explicit mention of "GLPI 11"), load `domains/glpi-11/SKILL.md` instead. If the GLPI version cannot be determined from the project or the user's message (e.g. a generic "plugin GLPI"/"GLPI module" mention with no version and no project indicators), ask the user which version ("GLPI 10.0.x or GLPI 11?") before generating code — do not assume a default. Exception: for a GLPI 10→11 migration task, load `domains/glpi-11/SKILL.md` as authoritative for the target and use this skill only as reference for the source code. Covers general integration patterns with the GLPI 10 framework — CommonDBTM, permission system, database access via global $DB, and hook registration. Specific sub-skills are available for plugin creation, AJAX handlers, Twig form templates, and Vue integration.
---

# GLPI 10.0.x — Padrões de Desenvolvimento de Plugins

> **Versão-alvo:** esta skill cobre exclusivamente GLPI 10.0.x. Se o projeto tiver indícios de GLPI 11 (diretório `public/`, `src/Controller/` com `#[Route]`, `$DB->doQuery(`), carregar `domains/glpi-11/SKILL.md`. Sem indício algum em nenhuma das duas direções, perguntar ao usuário qual versão antes de gerar código.

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

Diretórios-chave em `plugins/[nome-do-plugin]/`: `setup.php` (bootstrap: versão, hooks, menus) e `hook.php` (install/uninstall) na raiz; `src/` (classes PHP, uma por arquivo); `front/` (páginas: listagem + `*.form.php`); `ajax/` (endpoints JSON); `templates/` (Twig); `js/`, `css/`, `locales/` (`.po`/`.mo`) e `tests/units/` (PHPUnit). Árvore completa anotada em `plugin-creation/SKILL.md`.

## Nomenclatura

| Elemento | Convenção |
|---|---|
| Diretório do plugin | minúsculas, sem espaços (ex.: `meuplugin`) |
| Tabelas | `glpi_plugin_[nomedoplugin]_[entidade]` — minúsculas, sem hífen |
| Classes | `Entidade` (PascalCase, sem prefixo `Plugin`) em `src/Entidade.php` |
| Direitos (`$rightname`) | `plugin_[nomedoplugin]_[entidade]` |
| Funções de hooks/setup | `plugin_[nomedoplugin]_[hookname]` em `hook.php`/`setup.php` |

## CommonDBTM — Model + Repository

Toda entidade de dados de um plugin estende `CommonDBTM`. Não criar repositórios separados.

```php
class MeuItem extends CommonDBTM
{
    static $rightname = 'plugin_meuplugin_meuitem';

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

Para referência completa de métodos, hooks de ciclo de vida e exemplos de JOIN, consultar **`references/architecture.md`**.

## Sistema de Permissões

Verificar permissões **no início** de todo arquivo `front/` e `ajax/`, usando `Session::checkRight()` (lança exceção) ou `Session::haveRight()` (retorna bool). Constantes disponíveis: `READ`, `UPDATE`, `CREATE`, `DELETE`, `PURGE`, `ALLSTANDARDRIGHT`.

Exemplos completos de verificação em **`references/architecture.md`**.

## Cabeçalho Obrigatório em `front/` e `ajax/`

```php
<?php

include('../../../inc/includes.php');
Session::checkLoginUser(); // ou Session::checkRight() conforme necessário
```

## Acesso ao Banco de Dados

Usar sempre `$DB` global.

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

Exemplos de JOIN, contagem e critérios compostos em **`references/architecture.md`**.

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

Hooks disponíveis listados em **`references/architecture.md`**.

## Segurança

Aplicar sempre que houver input de usuário: cast explícito em IDs (`(int) $_POST['id']`), sanitização com `Toolbox::addslashes_deep()`, remoção de HTML com `strip_tags()`, salvamento de HTML com `Sanitizer::sanitize()`.

Exemplos completos em **`references/architecture.md`**.

## Internacionalização

Todo texto visível ao usuário deve usar as funções de tradução:

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

Tabela completa com tipos em **`references/architecture.md`**.

## Sub-skills Disponíveis

Carregar conforme a tarefa específica:

| Tarefa | Skill a carregar |
|---|---|
| Criar um novo plugin do zero | `domains/glpi-10/plugin-creation/SKILL.md` |
| Criar ou editar handlers em `ajax/` | `domains/glpi-10/ajax-handlers/SKILL.md` |
| Criar ou editar formulários Twig em `templates/` | `domains/glpi-10/form-templates/SKILL.md` |
| Adicionar interface Vue em templates Twig (aba/SPA no plugin) | `domains/glpi-10/vue/SKILL.md` |

## Restrições Absolutas em Plugins GLPI

- Usar `declare(strict_types=1)` em todo arquivo PHP
- Nunca implementar autenticação ou sessão própria — usar `Session::checkRight()`
- Nunca usar PDO diretamente — usar `$DB->request()` ou `$DB->queryOrDie()`
- Nunca criar estrutura `src/Domain/Application/Infrastructure/` — usar `front/`, `ajax/`, `src/`, `install/`
- Sempre marcar o plugin como CSRF-compliant: `$PLUGIN_HOOKS['csrf_compliant']['meuplugin'] = true`
- Nunca usar strings hardcoded visíveis ao usuário — usar `__()` ou `_n()`

## Licença

Todo arquivo PHP deve conter o cabeçalho GPLv3 com copyright IBGE. O template completo está em **`references/architecture.md`**.
