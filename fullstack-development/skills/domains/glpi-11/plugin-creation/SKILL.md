---
name: glpi-11-plugin-creation
description: This skill should be loaded when the user asks to "create a GLPI plugin", "start a new plugin", "scaffold a GLPI module", "generate the initial plugin structure", "create setup.php", "create hook.php", "create install.php", "create the plugin main class", or "create a GLPI controller" — and the target is GLPI 11 (explicit "GLPI 11" mention, `public/` directory present, or confirmed 11.x when asked). For GLPI 10.0.x targets, use `domains/glpi-10/plugin-creation/SKILL.md` instead. If the GLPI version cannot be determined from the project or the user's message, ask which version before generating code — do not assume a default. Provides a complete step-by-step guide for creating a valid GLPI 11 plugin from scratch, including required files, PSR-4 namespace, controller routing, hook registration, initial CommonDBTM class, and install script.
---

# Criação de Plugin GLPI 11

> **Versão-alvo:** GLPI 11. Para GLPI 10.0.x, usar `domains/glpi-10/plugin-creation/SKILL.md`.

## Estrutura Obrigatória de Arquivos

Todo plugin GLPI 11 válido requer no mínimo:

```
<nome-do-plugin>/          ← diretório em plugins/
├── setup.php              ← obrigatório: versão, prerequisites, init (+ boot opcional)
├── hook.php               ← obrigatório: install, uninstall e callbacks dos hooks
├── src/
│   └── <Entidade>.php     ← classe principal (CommonDBTM), namespace GlpiPlugin\Nomedoplugin\
└── install/
    └── install.php        ← criação de tabelas (Migration + $DB->doQuery) e direitos
```

Arquivos adicionais conforme a funcionalidade:

```
├── public/                    ← OBRIGATÓRIO para assets/scripts web-acessíveis; não aparece na URL
│   └── build/
├── src/
│   └── Controller/
│       └── <Entidade>Controller.php   ← caminho recomendado para features novas (#[Route])
├── front/                     ← legado, opcional — sem include(inc/includes.php)
│   ├── <entidade>.php
│   └── <entidade>.form.php
├── ajax/                      ← legado, opcional — handlers AJAX antigos
│   └── <entidade>.php
├── templates/                 ← templates Twig
├── locales/                   ← arquivos de tradução .po/.mo
└── tests/
    └── units/                 ← testes PHPUnit
```

## Convenções de Nomenclatura

Seguir a tabela **Nomenclatura** da skill pai (`domains/glpi-11/SKILL.md`): diretório, tabelas, direitos e funções de hooks/setup são idênticas ao GLPI 10. Diferença: a classe em `src/` recebe o namespace `GlpiPlugin\Nomedoplugin\` (só a primeira letra da chave do plugin maiúscula), sem necessidade de declarar `autoload.psr-4` no `composer.json`.

## Passo a Passo

### 1. Criar `setup.php`

Três funções obrigatórias + `plugin_<nome>_boot()` opcional + `declare(strict_types=1)` + cabeçalho de licença:

```php
function plugin_version_<nome>(): array            // metadados e requisitos (glpi min 11.0.0, php min 8.2)
function plugin_<nome>_check_prerequisites(): bool  // valida versão GLPI/PHP
function plugin_init_<nome>(): void                 // registra classes e hooks
function plugin_<nome>_boot(): void                 // opcional: roda antes da sessão carregar
```

Em `plugin_init_<nome>()`:
- **Não** setar `$PLUGIN_HOOKS['csrf_compliant']` — o hook está depreciado no 11 (`@deprecated 11.0.0`)
- Registrar classes com `Plugin::registerClass()`
- Registrar hooks com constantes de `Glpi\Plugin\Hooks` (`$PLUGIN_HOOKS[Hooks::ITEM_UPDATE]['<nome>'] = [...]`)
- Se scripts legados precisarem de acesso não padrão, chamar `Firewall::addPluginStrategyForLegacyScripts()`

### 2. Criar `hook.php`

Implementar as funções referenciadas nos hooks:
- `plugin_<nome>_install()` — chama `install/install.php`
- `plugin_<nome>_uninstall()` — remove tabelas e direitos
- Callbacks dos hooks de formulário/exibição registrados (ex.: `plugin_<nome>_post_show_item()`)

### 3. Criar a classe em `src/<Entidade>.php`

Namespace `GlpiPlugin\Nomedoplugin\`; a classe estende `\CommonDBTM` (ou `\CommonDropdown`, `\CommonDBChild`, `\CommonDBRelation` conforme o tipo) e define:
- `static $rightname` — chave de permissão
- `getTypeName()` — nome exibido na interface
- `getMenuContent()` — entrada no menu lateral (se houver página dedicada)
- `getTabNameForItem()` + `displayTabContentForItem()` — para exibir aba em outros itens GLPI

Sobrescritas de `can*()` devem casar exatamente com os type hints estritos do 11 — ver `../references/architecture.md`.

### 4. Criar um Controller (recomendado) ou handler legado

Para uma nova rota, preferir `src/Controller/<Entidade>Controller.php` com `#[Route]` — ver `references/plugin-structure.md` para o template completo, incluindo o bug de métodos ≠GET antes da 11.0.7. Só usar `front/`/`ajax/` legados para manter compatibilidade com código já existente.

### 5. Criar `install/install.php`

- Verificar `$DB->tableExists()` antes de `CREATE TABLE`; usar `$DB->doQuery()`, nunca `queryOrDie()`
- `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC`
- Incluir sempre as colunas padrão: `id`, `name`, `entities_id`, `is_recursive`, `is_deleted`, `date_mod`, `date_creation`
- Registrar direitos em `glpi_profilerights` para todos os perfis existentes

### 6. Registrar o Plugin no GLPI

Copiar o diretório para `glpi/plugins/<nome>/` e acessar **Configuração → Plugins** para instalar.

## Checklist — Plugin Mínimo Funcional

- [ ] Cabeçalho de licença GPLv3 (IBGE) em todo arquivo PHP
- [ ] `declare(strict_types=1)` em todo arquivo PHP
- [ ] `setup.php` com as 3 funções obrigatórias (+ `boot` se necessário)
- [ ] **Sem** `$PLUGIN_HOOKS['csrf_compliant']` — hook depreciado no 11
- [ ] `hook.php` com `plugin_<nome>_install()` e `plugin_<nome>_uninstall()`
- [ ] Classe principal em `src/` com namespace PSR-4, estendendo `\CommonDBTM`
- [ ] `install/install.php` usando `$DB->doQuery()` (nunca `queryOrDie()`) e registrando direitos
- [ ] Assets estáticos/scripts web-acessíveis em `public/`
- [ ] Plugin instalável via interface GLPI sem erros
- [ ] Permissão verificada com `Session::checkRight()` em todo controller/`front/`/`ajax/`
- [ ] Nenhum `include('../../../inc/includes.php')` em código novo
- [ ] Arquivo de teste PHPUnit criado em `tests/units/`

## Recursos de Referência

- **`references/plugin-structure.md`** — código completo de cada arquivo: `setup.php`, `hook.php`, classe `CommonDBTM`, `install.php`, Controller com `#[Route]`, `front/`/`ajax/` legados
- **`../references/architecture.md`** — CommonDBTM, `$DB`, `Session`, hooks disponíveis, Firewall, segurança, licença
- **`../references/migration-10-to-11.md`** — ao converter um plugin GLPI 10 existente em vez de criar do zero
