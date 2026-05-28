---
name: glpi-ajax-handlers
description: >
  This skill should be used when the user asks to "create an AJAX handler",
  "add an ajax endpoint", "create a file in ajax/", "handle an AJAX request",
  "return JSON from PHP in GLPI", "create a dropdown handler", or mentions
  the ajax/ directory in a GLPI plugin context.
version: 0.1.0
---

# GLPI — Handlers AJAX

## Visão Geral

Handlers AJAX são arquivos PHP em `ajax/` que respondem a requisições JavaScript, retornando JSON ou HTML parcial. Seguem uma estrutura de inicialização obrigatória e delegam autenticação inteiramente ao framework GLPI.

---

## 1. Ordem de Inicialização (Obrigatória)

Todo handler AJAX deve seguir exatamente esta sequência:

```php
<?php

// 1. Flag que indica ao GLPI que este é um endpoint AJAX
$AJAX_INCLUDE = 1;

// 2. CSRF token ANTES do includes.php (apenas se receber $_POST['_glpi_csrf_token'])
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';

// 3. Bootstrap do framework
include('../../../inc/includes.php');

// 4. Content-Type apropriado
header('Content-Type: application/json; charset=UTF-8');
// ou: header('Content-Type: text/html; charset=UTF-8');

// 5. Impede cache
Html::header_nocache();

// 6. Verificação de ambiente
if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

// 7. Verificação de plugin ativo
if (!Plugin::isPluginActive('nomedoplugin')) {
    http_response_code(503);
    die('Plugin not installed or activated');
}

// 8. Verificação de sessão/permissões — SEMPRE antes de processar qualquer lógica
Session::checkCentralAccess();
```

> O passo 2 (CSRF token) só é necessário quando o handler recebe `$_POST['_glpi_csrf_token']`. O passo 7 é opcional quando o handler é genérico ao GLPI.

---

## 2. Verificação de Sessão

Nunca implementar autenticação própria. Usar sempre um dos métodos abaixo:

| Método | Quando usar |
|--------|-------------|
| `Session::checkCentralAccess()` | Padrão para a maioria dos handlers — exige login de usuário central |
| `Session::checkLoginUser()` | Quando qualquer usuário logado pode acessar (incluindo self-service) |
| `Session::checkRight($rightname, READ)` | Quando a operação exige um direito específico do plugin |
| `Session::haveRight($rightname, UPDATE)` | Quando a permissão é verificada condicionalmente (retorna bool) |

```php
// Exemplos
Session::checkCentralAccess();
Session::checkLoginUser();
Session::checkRight(MinhaClasse::$rightname, CREATE);

// Verificação condicional
if (!Session::haveRight('ticket', UPDATE)) {
    http_response_code(403);
    die();
}
```

> **Sessão expirada em AJAX:** `Session::checkCentralAccess()` e `Session::checkLoginUser()` fazem **redirect HTML** para a tela de login quando o usuário não está autenticado — comportamento correto para páginas `front/`, mas que quebra parsing JSON em chamadas AJAX. O cliente JS deve verificar se a resposta é HTML (indica sessão expirada) e redirecionar o usuário: `if (typeof data === 'string' && data.includes('<html')) { window.location.reload(); }`. Não há como retornar `401` diretamente porque o GLPI intercepta antes.

---

## 3. Validação de Parâmetros

Sempre usar `filter_input` com cast explícito. Nunca acessar `$_POST` ou `$_GET` diretamente sem sanitização.

```php
// Inteiros (IDs, flags numéricas)
$id       = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);
$entities = (int) filter_input(INPUT_POST, 'entities_id', FILTER_SANITIZE_NUMBER_INT);
$rand     = (int) filter_input(INPUT_POST, 'rand', FILTER_SANITIZE_NUMBER_INT);

// Strings (tipos, operações)
$type = (string) filter_input(INPUT_POST, 'type');
$op   = (string) filter_input(INPUT_GET, 'op');

// Com fallback
$operation = (string) (filter_input(INPUT_POST, 'operation') ?: 'default');

// Validação de JSON (parâmetro GET complexo)
$actors = filter_input(INPUT_GET, '_actors', FILTER_DEFAULT, FILTER_NULL_ON_FAILURE);
if (!empty($actors)) {
    $actors = Toolbox::jsonDecode(urldecode($actors), true);
}
if (!is_array($actors)) {
    $actors = null;
}

// Rejeitar IDs inválidos
if ($id <= 0) {
    http_response_code(400);
    die();
}
```

---

## 4. Padrões de Operação

### 4.1 Operações CRUD via POST

```php
if (isset($_POST['add'])) {
    Session::checkRight(MinhaClasse::$rightname, CREATE);
    $obj   = new MinhaClasse();
    $newID = $obj->add($_POST);

    if ($newID === false) {
        http_response_code(400);
        die();
    }

    echo json_encode(['success' => true, 'id' => $newID]);
    exit;
}

if (isset($_POST['update'])) {
    // ...
}

if (isset($_POST['delete'])) {
    // ...
}
```

### 4.2 Operações múltiplas via parâmetro `op`

```php
$op = (string) filter_input(INPUT_POST, 'op');

switch ($op) {
    case 'get_dropdown':
        header('Content-Type: text/html; charset=UTF-8');
        // renderiza HTML de dropdown
        break;

    case 'search':
        header('Content-Type: application/json; charset=UTF-8');
        // retorna array JSON
        break;

    case 'update_status':
        // lógica de atualização
        break;

    default:
        http_response_code(400);
        die();
}
```

---

## 5. Respostas

### 5.1 JSON vs HTML

| Retornar JSON | Retornar HTML |
|---------------|---------------|
| Operações CRUD (add, update, delete) | Dropdown para injetar em `div` via `$.html()` |
| Respostas com metadados (id, redirecturl) | Fragmentos de formulário carregados dinamicamente |
| Status de sucesso/erro | Conteúdo de wizard steps |

### 5.2 Estrutura JSON de sucesso

```php
// Operação genérica (GET/PUT/PATCH) — HTTP 200
echo json_encode([
    'success'     => true,
    'id'          => $newID,
    'message'     => __('Item atualizado com sucesso', 'nomedoplugin'),
    'redirecturl' => $CFG_GLPI['root_doc'] . "/front/item.form.php?id={$newID}",
]);
exit;

// Criação de recurso — HTTP 201 quando o cliente precisa descobrir o Location
http_response_code(201);
header('Location: ' . $CFG_GLPI['root_doc'] . "/front/item.form.php?id={$newID}");
echo json_encode(['success' => true, 'id' => $newID]);
exit;
```

> Em AJAX puro (JS injeta HTML na mesma página), `200 + id` é suficiente. Use `201 + Location` apenas quando o JS precisar conhecer a URL canônica do recurso criado.

### 5.3 Estrutura JSON de erro

```php
http_response_code(403);
echo json_encode([
    'success' => false,
    'code'    => 'FORBIDDEN',               // constante para decisão programática no JS
    'message' => __('Acesso não permitido', 'nomedoplugin'),
    'errors'  => [],                         // array de erros campo a campo (opcional)
]);
exit;

// Com erros de validação granulares (422)
http_response_code(422);
echo json_encode([
    'success' => false,
    'code'    => 'VALIDATION_ERROR',
    'message' => __('Dados inválidos', 'nomedoplugin'),
    'errors'  => [
        ['field' => 'name',       'message' => __('Nome é obrigatório', 'nomedoplugin')],
        ['field' => 'entities_id','message' => __('Entidade não existe', 'nomedoplugin')],
    ],
]);
exit;
```

> **Nota sobre RFC 9457:** A api-rest recomenda Problem Details (RFC 9457) com `type`, `title`, `status`, `detail`. Handlers AJAX do GLPI são **endpoints internos** consumidos apenas pelo próprio frontend JS do plugin — não são APIs públicas. O envelope `{success, code, message, errors}` é compatível com o padrão existente nos plugins IBGE e dispensa o overhead do RFC 9457.

### 5.4 Tabela de códigos HTTP

| Código | Situação | Distinção importante |
|--------|----------|---------------------|
| `200` | Sucesso (leitura, atualização, delete) | — |
| `201` | Recurso criado — incluir `Location` no header | Usar quando o cliente precisa da URL canônica |
| `400` | Parâmetro malformado ou ausente | Formato errado, ID não inteiro, campo obrigatório faltando |
| `403` | Autenticado, mas sem permissão no recurso | Diferente de sessão expirada (ver seção 2) |
| `404` | Recurso não encontrado (ID válido, mas não existe) | Não confundir com 400 — o parâmetro era válido |
| `422` | Dados corretos, mas falha em regra de negócio | `$obj->add()` retornou false, validação de integridade |
| `500` | Erro interno inesperado (exceção não tratada) | Não usar 400 para exceções — mascara a origem |
| `503` | Plugin não instalado ou inativo | — |

---

## 6. Delegação para Classe de Negócio

Preferir delegar lógica complexa para métodos da classe `CommonDBTM` em vez de implementar inline no handler.

```php
// Handler leve — apenas valida entrada e delega
$id     = (int) filter_input(INPUT_POST, 'tickets_id', FILTER_SANITIZE_NUMBER_INT);
$input  = filter_input(INPUT_POST, null, FILTER_DEFAULT, FILTER_REQUIRE_ARRAY) ?? [];

$ticket = new Ticket();
$result = $ticket->processCloneRequest($input);

echo json_encode(['success' => $result !== false, 'id' => $result]);
exit;
```

Lógica inline é aceitável apenas para handlers simples (consultas `$DB`, renderização de dropdown).

---

## 7. Tratamento de Erros

```php
// Try-catch para erros inesperados — usar 500, não 400
try {
    $result = MinhaClasse::processForm($_POST);
} catch (ErrorException $e) {
    http_response_code(500);
    // Nunca expor $e->getMessage() em produção
    echo json_encode(['success' => false, 'code' => 'INTERNAL_ERROR', 'message' => '']);
    exit;
}

// Mensagens para o usuário após redirect (não para AJAX puro)
if ($success) {
    Session::addMessageAfterRedirect(__('Operação realizada', 'nomedoplugin'), true);
}
```

---

## 8. Globais Disponíveis

```php
global $DB;          // Acesso ao banco — sempre declarar global antes de usar
global $CFG_GLPI;    // Configurações (root_doc, etc.)
```

---

## 9. Segurança — Checklist

- [ ] `$AJAX_INCLUDE = 1` na primeira linha
- [ ] CSRF compliant declarado em `setup.php`: `$PLUGIN_HOOKS['csrf_compliant']['nomedoplugin'] = true`
- [ ] Parâmetros sanitizados com `filter_input` + cast
- [ ] IDs validados (`> 0`) antes de usar
- [ ] Permissão verificada antes de qualquer lógica
- [ ] Verificação de entidade ao acessar recursos de outras entidades
- [ ] Nunca expor mensagens de exceção em produção

---

## Recursos Adicionais

- **`references/patterns.md`** — Templates completos anotados e exemplos reais de handlers por tipo de operação