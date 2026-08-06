# GLPI Ajax Handlers — Padrões e Exemplos

## Template Completo Anotado

```php
<?php

/**
 * Handler AJAX para [descrição da operação].
 *
 * -------------------------------------------------------------------------
 * LICENSE
 *
 * This file is part of [Plugin Name].
 *
 * [Plugin Name] is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * [Plugin Name] is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * -------------------------------------------------------------------------
 */

// Flag de endpoint AJAX do GLPI
$AJAX_INCLUDE = 1;

// CSRF token deve ser movido para o header ANTES do includes.php
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';

// Bootstrap do framework GLPI
include('../../../inc/includes.php');

// Define Content-Type da resposta
header('Content-Type: application/json; charset=UTF-8');

// Impede cache no navegador
Html::header_nocache();

// Garante que o arquivo não foi acessado diretamente fora do GLPI
if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

// Garante que o plugin está ativo
if (!Plugin::isPluginActive('nomedoplugin')) {
    http_response_code(503);
    die('Plugin not installed or activated');
}

// Verificação de sessão — sempre antes de qualquer lógica de negócio
Session::checkCentralAccess();

// --- Lógica do handler ---

$id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);

if ($id <= 0) {
    http_response_code(400);
    die();
}

$obj    = new MinhaClasse();
$result = $obj->processRequest($id, $_POST);

echo json_encode([
    'success' => $result !== false,
    'id'      => $result ?: 0,
]);
exit;
```

---

## Padrão 1: Clone / Operação Complexa com Redirect

Baseado em `ibgeconsultoria/ajax/cloneticket.php`.

```php
<?php

$AJAX_INCLUDE = 1;
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';
include('../../../inc/includes.php');

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

if (!Plugin::isPluginActive('ibgeconsultoria')) {
    http_response_code(503);
    die('Plugin not installed or activated');
}

Session::checkCentralAccess();

global $CFG_GLPI;

$tickets_id = (int) filter_input(INPUT_POST, 'tickets_id', FILTER_SANITIZE_NUMBER_INT);

if ($tickets_id <= 0) {
    http_response_code(400);
    die();
}

$input = filter_input(INPUT_POST, null, FILTER_DEFAULT, FILTER_REQUIRE_ARRAY) ?? [];

// Verifica permissão antes de processar
if (!Session::haveRight('ticket', UPDATE)) {
    http_response_code(403);
    die();
}

$tf      = new TicketForm();
$new_id  = $tf->processCloneRequest($input);
$success = $new_id !== false;

// Define para onde redirecionar
$redirect_scope = !empty($input['_redirect_new_ticket']);
$redirect_id    = ($redirect_scope && $success) ? $new_id : $tickets_id;

if ($success) {
    $message = __('O chamado foi clonado com sucesso.', 'ibgeconsultoria');
    Session::addMessageAfterRedirect($message, true);
}

echo json_encode([
    'success'     => $success,
    'redirecturl' => ($redirect_id > 0)
        ? $CFG_GLPI['root_doc'] . "/front/ticket.form.php?id={$redirect_id}"
        : '',
]);
exit;
```

---

## Padrão 2: Dropdown Condicional (retorna HTML)

Baseado em `ibgeconsultoria/ajax/dropdown_show.php`.

```php
<?php

$AJAX_INCLUDE = 1;
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';
include('../../../inc/includes.php');

// Este handler retorna HTML para injetar diretamente em um div
header('Content-Type: text/html; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

Session::checkCentralAccess();

$entities_id = (int) filter_input(INPUT_POST, 'entities_id', FILTER_SANITIZE_NUMBER_INT);
$rand        = (int) filter_input(INPUT_POST, 'rand', FILTER_SANITIZE_NUMBER_INT);
$type        = (string) filter_input(INPUT_POST, 'type');

if (empty($type)) {
    http_response_code(400);
    die();
}

switch ($type) {
    case 'itilcategory':
        // Impede enumeração de categorias em entidades sem permissão
        if (!TicketForm::userHasCreateTicketRightInEntity($entities_id)) {
            http_response_code(403);
            die();
        }

        ITILCategory::dropdown([
            'name'      => 'itilcategories_id',
            'entity'    => $entities_id,
            'value'     => 0,
            'width'     => '100%',
            'rand'      => $rand,
            'addicon'   => false,
            'condition' => ['OR' => ['is_incident' => true, 'is_request' => true]],
        ]);
        break;

    case 'location':
        Location::dropdown([
            'name'   => 'locations_id',
            'entity' => $entities_id,
            'value'  => 0,
            'rand'   => $rand,
        ]);
        break;

    default:
        http_response_code(400);
        die();
}

exit;
```

---

## Padrão 3: CRUD via POST (add/update/delete)

Baseado em `ibgeticket/ajax/categorygrouping_config.php`.

```php
<?php

$AJAX_INCLUDE = 1;
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';
include('../../../inc/includes.php');

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

if (!Plugin::isPluginActive('nomedoplugin')) {
    http_response_code(503);
    die('Plugin not installed or activated');
}

$obj = new MinhaClasse();

if (isset($_POST['add'])) {
    Session::checkRight(MinhaClasse::$rightname, CREATE);

    $newID = $obj->add($_POST);

    if ($newID === false) {
        // 422 = dados válidos sintaticamente, mas falha em regra de negócio
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'code'    => 'VALIDATION_ERROR',
            'message' => __('Não foi possível criar o item', 'nomedoplugin'),
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => __('Item adicionado com sucesso', 'nomedoplugin'),
        'id'      => $newID,
    ]);
    exit;
}

if (isset($_POST['update'])) {
    Session::checkRight(MinhaClasse::$rightname, UPDATE);

    $result = $obj->update($_POST);

    if ($result === false) {
        // 422 = falha de integridade ou validação de negócio no update
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'code'    => 'VALIDATION_ERROR',
            'message' => __('Não foi possível atualizar o item', 'nomedoplugin'),
        ]);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

if (isset($_POST['delete'])) {
    Session::checkRight(MinhaClasse::$rightname, DELETE);

    $id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);

    if ($id <= 0) {
        http_response_code(400);
        die();
    }

    $result = $obj->delete(['id' => $id]);

    echo json_encode(['success' => $result !== false]);
    exit;
}

// Nenhuma operação conhecida
http_response_code(400);
die();
```

---

## Padrão 4: Wizard Multi-operação (GET + POST mistos)

Baseado em `ibgeticket/ajax/wizard.php`.

```php
<?php

$AJAX_INCLUDE = 1;
// Wizard opera via GET — sem $_POST['_glpi_csrf_token'], logo sem CSRF header aqui
include('../../../inc/includes.php');

Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

if (!Plugin::isPluginActive('ibgeticket')) {
    http_response_code(503);
    die('Plugin not installed or activated');
}

Session::checkLoginUser();

$op   = (string) filter_input(INPUT_GET, 'op');
$rand = (int) filter_input(INPUT_GET, 'rand', FILTER_SANITIZE_NUMBER_INT);

if ($op === 'search_user') {
    header('Content-Type: application/json; charset=UTF-8');

    $term  = (string) filter_input(INPUT_GET, 'term');
    $users = User::getSqlSearchResult(false, 'all', -1, 0, [], $term);

    echo json_encode($users);
    exit;
}

if ($op === 'catalog') {
    header('Content-Type: text/html; charset=UTF-8');

    $itilcategories_id = (int) filter_input(INPUT_GET, 'itilcategory', FILTER_SANITIZE_NUMBER_INT);

    // Renderiza HTML parcial
    TemplateRenderer::getInstance()->display('@nomedoplugin/components/catalog.html.twig', [
        'rand'               => $rand,
        'itilcategories_id'  => $itilcategories_id,
    ]);
    exit;
}

http_response_code(400);
die();
```

---

## Padrão 5: Consulta ao Banco com Resposta JSON

Baseado em `ibgestructure/ajax/location_impact.php`.

```php
<?php

$AJAX_INCLUDE = 1;
include('../../../inc/includes.php');

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

Session::checkCentralAccess();

global $DB;

$locations_id = (int) filter_input(INPUT_GET, 'locations_id', FILTER_SANITIZE_NUMBER_INT);

if ($locations_id <= 0) {
    http_response_code(400);
    die();
}

// Conta usuários ativos na localidade
$users_iter = $DB->request([
    'COUNT' => 'cnt',
    'FROM'  => 'glpi_users',
    'WHERE' => [
        'locations_id' => $locations_id,
        'is_deleted'   => 0,
        'is_active'    => 1,
    ],
]);
$users_count = (int) ($users_iter->current()['cnt'] ?? 0);

// Conta itens de inventário na localidade
$assets_iter = $DB->request([
    'COUNT' => 'cnt',
    'FROM'  => 'glpi_computers',
    'WHERE' => [
        'locations_id' => $locations_id,
        'is_deleted'   => 0,
    ],
]);
$assets_count = (int) ($assets_iter->current()['cnt'] ?? 0);

echo json_encode([
    'users'  => $users_count,
    'assets' => $assets_count,
]);
exit;
```

---

## Padrão 6: Try-Catch para Operações com Risco de Exceção

Baseado em `ibgecomunicado/ajax/notificationgroup.php`.

```php
<?php

$AJAX_INCLUDE = 1;
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';
include('../../../inc/includes.php');

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

Session::checkCentralAccess();

try {
    $ret = NotificationGroup::processForm($_POST);
} catch (ErrorException $e) {
    // 500 = exceção inesperada; não usar 400 (mascara a origem do erro)
    http_response_code(500);
    echo json_encode(['success' => false, 'code' => 'INTERNAL_ERROR', 'message' => '']);
    exit;
}

echo json_encode(['success' => $ret !== false]);
exit;
```

---

## Padrão 7: Distinção 400 / 404 / 422

Usar o código correto comunica a origem do problema ao cliente JS e facilita debugging.

```php
// 400 — parâmetro malformado (formato errado antes de qualquer busca)
$id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);
if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'code' => 'BAD_REQUEST', 'message' => '']);
    exit;
}

// 404 — parâmetro válido, mas recurso não existe no banco
$item = new MinhaClasse();
if (!$item->getFromDB($id)) {
    http_response_code(404);
    echo json_encode(['success' => false, 'code' => 'NOT_FOUND', 'message' => '']);
    exit;
}

// 422 — recurso existe, mas operação falha por regra de negócio
if (!$item->canBeDeleted()) {
    http_response_code(422);
    echo json_encode([
        'success' => false,
        'code'    => 'UNPROCESSABLE',
        'message' => __('Item não pode ser removido pois possui dependências', 'nomedoplugin'),
    ]);
    exit;
}

$item->delete(['id' => $id]);
echo json_encode(['success' => true]);
exit;
```

---

## Validação de Parâmetros

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

## Operações Múltiplas via Parâmetro `op` (POST)

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

## Estruturas de Resposta JSON

```php
// Sucesso genérico (GET/PUT/PATCH) — HTTP 200
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

// Erro de permissão — HTTP 403
http_response_code(403);
echo json_encode([
    'success' => false,
    'code'    => 'FORBIDDEN',               // constante para decisão programática no JS
    'message' => __('Acesso não permitido', 'nomedoplugin'),
    'errors'  => [],                         // array de erros campo a campo (opcional)
]);
exit;

// Erros de validação granulares — HTTP 422
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

> Em AJAX puro (JS injeta HTML na mesma página), `200 + id` é suficiente. Usar `201 + Location` apenas quando o JS precisar conhecer a URL canônica do recurso criado.

---

## Integração com Dropdown GLPI

Ao retornar HTML de dropdown para injeção em `div` via JavaScript:

```php
// Dropdown de classe GLPI com condições
ITILCategory::dropdown([
    'name'      => $field_name,
    'entity'    => $entities_id,
    'value'     => $current_value,
    'rand'      => $rand,
    'width'     => '100%',
    'full_width' => true,
    'addicon'   => false,
    'condition' => ['OR' => ['is_incident' => true, 'is_request' => true]],
    'on_change' => "handleCategoryChange({$rand})",
]);

// Dropdown com itens bloqueados (usados)
MinhaDropdown::dropdown([
    'name'      => 'minha_dropdown_id',
    'value'     => $current_value,
    'rand'      => $rand,
    'used'      => $used_ids,   // IDs que não devem aparecer
    'condition' => ['parent_id' => $filter_id],
    'on_change' => "document.getElementById('btn-submit{$rand}').disabled = false;",
]);
```

---

## Integração JavaScript (lado cliente)

Padrão de chamada AJAX a partir de templates Twig:

```javascript
// POST com retorno JSON
$.ajax({
    url: '{{ baseurl }}/ajax/nomedoplugin/handler.php',
    type: 'POST',
    data: {
        '_glpi_csrf_token': '{{ csrf_token() }}',
        'rand': '{{ rand }}',
        'id': selectedId,
        'op': 'update_status',
    },
    dataType: 'json',
})
.fail(function(data) {
    console.error(data.statusText);
    alert('{{ __("Erro de comunicação. Tente novamente.", "nomedoplugin") }}');
})
.done(function(data) {
    if (data.success) {
        window.location.href = data.redirecturl || window.location.href;
    }
});

// GET com retorno HTML (injeção em div)
$.ajax({
    url: '{{ baseurl }}/ajax/nomedoplugin/dropdown.php',
    type: 'POST',
    data: {
        '_glpi_csrf_token': '{{ csrf_token() }}',
        'entities_id': entitiesId,
        'rand': '{{ rand }}',
        'type': 'itilcategory',
    },
    dataType: 'html',
})
.done(function(data) {
    $('#div-category-{{ rand }}').html(data);
});
```