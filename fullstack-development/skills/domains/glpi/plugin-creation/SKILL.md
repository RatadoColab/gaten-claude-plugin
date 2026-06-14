---
name: glpi-plugin-creation
description: This skill should be loaded when the user asks to "create a GLPI plugin", "start a new plugin", "scaffold a GLPI module", "generate the initial plugin structure", "create setup.php", "create hook.php", "create install.php", or "create the plugin main class". Provides a complete step-by-step guide for creating a valid GLPI 10.0.x plugin from scratch, including required files, hook registration, initial CommonDBTM class, and install script.
---

# Criação de Plugin GLPI 10.0.x

## Estrutura Obrigatória de Arquivos

Todo plugin GLPI válido requer no mínimo:

```
<nome-do-plugin>/          ← diretório em plugins/ ou marketplace/
├── setup.php              ← obrigatório: versão, prerequisites, init
├── hook.php               ← obrigatório: install, uninstall e callbacks dos hooks
├── src/
│   └── <Entidade>.php     ← classe principal (CommonDBTM), PascalCase
└── install/
    └── install.php        ← criação de tabelas e direitos
```

Arquivos adicionais conforme a funcionalidade:

```
├── front/
│   ├── <entidade>.php         ← página de listagem (Search::show)
│   └── <entidade>.form.php    ← formulário de criação/edição
├── ajax/
│   └── <entidade>.php         ← handlers AJAX (retornam JSON)
├── templates/                 ← templates Twig (GLPI 10.x)
├── locales/                   ← arquivos de tradução .po/.mo
└── tests/
    └── units/                 ← testes PHPUnit
```

## Convenções de Nomenclatura

Seguir a tabela **Nomenclatura** da skill pai (`domains/glpi/SKILL.md`): diretório, tabelas, classes, direitos e funções de hooks/setup.

## Passo a Passo

### 1. Criar `setup.php`

Três funções obrigatórias + `declare(strict_types=1)` + cabeçalho de licença:

```php
function plugin_version_<nome>(): array        // metadados e requisitos
function plugin_<nome>_check_prerequisites(): bool  // valida versão GLPI/PHP
function plugin_init_<nome>(): void            // registra classes e hooks
```

Em `plugin_init_<nome>()`:
- Sempre setar `$PLUGIN_HOOKS['csrf_compliant']['<nome>'] = true`
- Registrar classes com `Plugin::registerClass()`
- Registrar hooks com `$PLUGIN_HOOKS['<evento>']['<nome>'] = [...]`

### 2. Criar `hook.php`

Implementar as funções referenciadas nos hooks:
- `plugin_<nome>_install()` — chama `install/install.php`
- `plugin_<nome>_uninstall()` — remove tabelas e direitos
- Callbacks dos hooks do Grupo 2 registrados (ex.: `plugin_<nome>_post_show_item()`)

### 3. Criar a classe em `src/<Entidade>.php`

A classe estende `CommonDBTM` (ou `CommonDropdown`, `CommonDBChild`, `CommonDBRelation` conforme o tipo) e define:
- `static $rightname` — chave de permissão
- `getTypeName()` — nome exibido na interface
- `getMenuContent()` — entrada no menu lateral (se houver página dedicada)
- `getTabNameForItem()` + `displayTabContentForItem()` — para exibir aba em outros itens GLPI

### 4. Criar `install/install.php`

- Verificar `$DB->tableExists()` antes de `CREATE TABLE`
- Incluir sempre as colunas padrão: `id`, `name`, `entities_id`, `is_recursive`, `is_deleted`, `date_mod`, `date_creation`
- Registrar direitos em `glpi_profilerights` para todos os perfis existentes

### 5. Registrar o Plugin no GLPI

Copiar o diretório para `glpi/plugins/<nome>/` (desenvolvimento) ou `glpi/marketplace/<nome>/` (produção) e acessar **Configuração → Plugins** para instalar.

## Checklist — Plugin Mínimo Funcional

- [ ] Cabeçalho de licença GPLv3 (IBGE) em todo arquivo PHP
- [ ] `declare(strict_types=1)` em todo arquivo PHP
- [ ] `setup.php` com as 3 funções obrigatórias
- [ ] `$PLUGIN_HOOKS['csrf_compliant']` definido em `plugin_init_`
- [ ] `hook.php` com `plugin_<nome>_install()` e `plugin_<nome>_uninstall()`
- [ ] Classe principal em `src/` estendendo `CommonDBTM`
- [ ] `install/install.php` criando a tabela e registrando direitos
- [ ] Plugin instalável via interface GLPI sem erros
- [ ] Permissão verificada com `Session::checkRight()` em todo `front/` e `ajax/`
- [ ] Cabeçalho `include('../../../inc/includes.php'); Session::checkLoginUser();` em `front/` e `ajax/`
- [ ] Arquivo de teste PHPUnit criado em `tests/units/`

## Recursos de Referência

- **`references/plugin-structure.md`** — código completo de cada arquivo: `setup.php`, `hook.php`, classe `CommonDBTM`, `install.php`, `front/` e `ajax/`
- **`../references/glpi-architecture.md`** — CommonDBTM, `$DB`, `Session`, hooks disponíveis, segurança, licença
