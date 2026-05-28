---
name: glpi-plugin-creation
description: Esta skill deve ser carregada quando o usuário pedir para "criar um plugin GLPI", "iniciar um novo plugin", "estruturar um módulo GLPI", "gerar a estrutura inicial de um plugin", "criar o setup.php", "criar hook.php", "criar install.php" ou "criar a classe principal do plugin". Fornece o passo a passo completo para criar um plugin GLPI 10.0.x válido do zero, incluindo arquivos obrigatórios, registro de hooks, classe CommonDBTM inicial e script de instalação.
version: 0.1.0
---

# Criação de Plugin GLPI 10.0.x

Carregar esta skill junto com `domains/glpi/SKILL.md` para ter o contexto completo de padrões GLPI.

## Estrutura Obrigatória de Arquivos

Todo plugin GLPI válido requer no mínimo:

```
<nome-do-plugin>/          ← diretório em plugins/ ou marketplace/
├── setup.php              ← obrigatório: versão, prerequisites, init
├── hook.php               ← obrigatório: install, uninstall e callbacks dos hooks
├── inc/
│   └── <item>.class.php   ← classe principal (CommonDBTM)
└── install/
    └── install.php        ← criação de tabelas e direitos
```

Arquivos adicionais conforme a funcionalidade:

```
├── front/
│   ├── <item>.php         ← página de listagem (Search::show)
│   └── <item>.form.php    ← formulário de criação/edição
├── ajax/
│   └── <item>.php         ← handlers AJAX (retornam JSON)
├── locales/               ← arquivos de tradução .po/.mo
└── pics/                  ← ícones 16×16 px
```

## Convenções de Nomenclatura

- **Diretório do plugin:** minúsculas, sem espaços (ex.: `meuplugin`)
- **Classe principal:** `Plugin<NomePlugin><NomeItem>` (ex.: `PluginMeupluginMeuitem`)
- **Tabela:** `glpi_plugin_<nomeplugin>_<nomeitem>` (ex.: `glpi_plugin_meuplugin_meuitem`)
- **Funções em setup.php:** `plugin_<nomeplugin>_<funcao>()` (ex.: `plugin_meuplugin_install()`)
- **Chave de permissão (`$rightname`):** nome da classe em minúsculas (ex.: `pluginmeupluginmeuitem`)
- **Arquivo de classe:** `inc/<nomeitem>.class.php` em minúsculas (ex.: `inc/meuitem.class.php`)

## Passo a Passo

### 1. Criar `setup.php`

Três funções obrigatórias:

```php
function plugin_version_<nome>(): array        // metadados e requisitos
function plugin_<nome>_check_prerequisites(): bool  // valida versão GLPI/PHP
function plugin_init_<nome>(): void            // registra classes e hooks
```

Em `plugin_init_<nome>()`:
- Sempre setar `$PLUGIN_HOOKS['csrf_compliant']['<nome>'] = true`
- Registrar classes com `Plugin::registerClass()`
- Registrar hooks com `$PLUGIN_HOOKS['<evento>']['<nome>'] = '<função>'`

### 2. Criar `hook.php`

Implementar as funções referenciadas nos hooks:
- `plugin_<nome>_install()` — chama `install/install.php`
- `plugin_<nome>_uninstall()` — remove tabelas e direitos
- Callbacks dos hooks registrados (ex.: `plugin_<nome>_item_update()`)

### 3. Criar a classe em `inc/<item>.class.php`

A classe estende `CommonDBTM` e define:
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

- [ ] `setup.php` com as 3 funções obrigatórias
- [ ] `$PLUGIN_HOOKS['csrf_compliant']` definido em `plugin_init_`
- [ ] `hook.php` com `plugin_<nome>_install()` e `plugin_<nome>_uninstall()`
- [ ] Classe principal em `inc/` estendendo `CommonDBTM`
- [ ] `install/install.php` criando a tabela e registrando direitos
- [ ] Plugin instalável via interface GLPI sem erros
- [ ] Permissão `READ` verificada em todo `front/` e `ajax/`

## Recursos de Referência

- **`references/plugin-structure.md`** — código completo de cada arquivo: `setup.php`, `hook.php`, classe `CommonDBTM`, `install.php`, `front/` e `ajax/`
- **`../references/glpi-architecture.md`** — CommonDBTM, `$DB`, `Session`, hooks disponíveis
