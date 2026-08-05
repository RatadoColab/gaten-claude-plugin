# GLPI 11 — Controllers e Handlers AJAX — Padrões e Exemplos

## Template Completo Anotado — Controller (Recomendado)

```php
<?php

/**
 * Controller para [descrição da operação].
 *
 * -------------------------------------------------------------------------
 * LICENSE
 * [License header]
 * -------------------------------------------------------------------------
 */

declare(strict_types=1);

namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Glpi\Exception\Http\BadRequestHttpException;
use Glpi\Exception\Http\NotFoundHttpException;
use GlpiPlugin\Meuplugin\MinhaClasse;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class MinhaClasseController extends AbstractController
{
    #[Route("/MinhaClasse/{id}", name: "meuplugin_minhaclasse_process", methods: ["GET", "POST"])]
    public function process(int $id, Request $request): Response
    {
        if (!$request->isMethod('POST')) {
            throw new BadRequestHttpException();
        }

        \Session::checkRight(MinhaClasse::$rightname, UPDATE);

        if ($id <= 0) {
            throw new BadRequestHttpException();
        }

        $obj    = new MinhaClasse();
        $result = $obj->processRequest($id, $request->request->all());

        if ($result === false) {
            throw new NotFoundHttpException();
        }

        return new JsonResponse(['success' => true, 'id' => $result]);
    }
}
```

---

## Template Completo Anotado — Handler Legado (`ajax/`)

```php
<?php

/**
 * Handler AJAX legado para [descrição da operação].
 *
 * -------------------------------------------------------------------------
 * LICENSE
 * [License header]
 * -------------------------------------------------------------------------
 */

declare(strict_types=1);

// Bootstrap roda automaticamente no ponto de entrada único — sem include()

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

// Verificação de sessão — sempre antes de qualquer lógica de negócio
Session::checkCentralAccess();

// --- Lógica do handler ---

$id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);

if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'code' => 'BAD_REQUEST', 'message' => '']);
    exit;
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

## Padrão 1: CRUD via POST (add/update/delete) — Handler Legado

```php
<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

$obj = new \GlpiPlugin\Meuplugin\MinhaClasse();

if (isset($_POST['add'])) {
    Session::checkRight(\GlpiPlugin\Meuplugin\MinhaClasse::$rightname, CREATE);

    $newID = $obj->add($_POST);

    if ($newID === false) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'code'    => 'VALIDATION_ERROR',
            'message' => __('Não foi possível criar o item', 'meuplugin'),
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => __('Item adicionado com sucesso', 'meuplugin'),
        'id'      => $newID,
    ]);
    exit;
}

if (isset($_POST['update'])) {
    Session::checkRight(\GlpiPlugin\Meuplugin\MinhaClasse::$rightname, UPDATE);

    $result = $obj->update($_POST);

    if ($result === false) {
        http_response_code(422);
        echo json_encode([
            'success' => false,
            'code'    => 'VALIDATION_ERROR',
            'message' => __('Não foi possível atualizar o item', 'meuplugin'),
        ]);
        exit;
    }

    echo json_encode(['success' => true]);
    exit;
}

if (isset($_POST['delete'])) {
    Session::checkRight(\GlpiPlugin\Meuplugin\MinhaClasse::$rightname, DELETE);

    $id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);

    if ($id <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'code' => 'BAD_REQUEST', 'message' => '']);
        exit;
    }

    $result = $obj->delete(['id' => $id]);

    echo json_encode(['success' => $result !== false]);
    exit;
}

http_response_code(400);
echo json_encode(['success' => false, 'code' => 'BAD_REQUEST', 'message' => '']);
exit;
```

---

## Padrão 2: Consulta ao Banco com Resposta JSON — Controller

```php
<?php

declare(strict_types=1);

namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Glpi\Exception\Http\BadRequestHttpException;
use Symfony\Component\HttpFoundation\{JsonResponse, Request, Response};
use Symfony\Component\Routing\Attribute\Route;

final class LocationImpactController extends AbstractController
{
    #[Route("/LocationImpact", name: "meuplugin_location_impact", methods: "GET")]
    public function __invoke(Request $request): Response
    {
        global $DB;

        $locations_id = (int) $request->query->get('locations_id', 0);

        if ($locations_id <= 0) {
            throw new BadRequestHttpException();
        }

        $users_iter = $DB->request([
            'COUNT' => 'cnt',
            'FROM'  => 'glpi_users',
            'WHERE' => ['locations_id' => $locations_id, 'is_deleted' => 0, 'is_active' => 1],
        ]);
        $users_count = (int) ($users_iter->current()['cnt'] ?? 0);

        $assets_iter = $DB->request([
            'COUNT' => 'cnt',
            'FROM'  => 'glpi_computers',
            'WHERE' => ['locations_id' => $locations_id, 'is_deleted' => 0],
        ]);
        $assets_count = (int) ($assets_iter->current()['cnt'] ?? 0);

        return new JsonResponse(['users' => $users_count, 'assets' => $assets_count]);
    }
}
```

---

## Padrão 3: Try-Catch para Operações com Risco de Exceção

```php
try {
    $ret = MinhaClasse::processForm($_POST);
} catch (\Throwable $e) {
    // 500 = exceção inesperada; não usar 400 (mascara a origem)
    http_response_code(500);
    echo json_encode(['success' => false, 'code' => 'INTERNAL_ERROR', 'message' => '']);
    exit;
}

echo json_encode(['success' => $ret !== false]);
exit;
```

Em Controller, deixar a exceção propagar quando for um dos tipos `Glpi\Exception\Http\*` — o framework converte automaticamente na resposta HTTP correta.

---

## Padrão 4: Distinção 400 / 404 / 422 — Controller

```php
use Glpi\Exception\Http\{BadRequestHttpException, NotFoundHttpException, UnprocessableEntityHttpException};

// 400 — parâmetro malformado
$id = (int) $request->request->get('id', 0);
if ($id <= 0) {
    throw new BadRequestHttpException();
}

// 404 — parâmetro válido, mas recurso não existe
$item = new MinhaClasse();
if (!$item->getFromDB($id)) {
    throw new NotFoundHttpException();
}

// 422 — recurso existe, mas operação falha por regra de negócio
if (!$item->canBeDeleted()) {
    throw new UnprocessableEntityHttpException(__('Item não pode ser removido pois possui dependências', 'meuplugin'));
}

$item->delete(['id' => $id]);

return new JsonResponse(['success' => true]);
```

---

## Validação de Parâmetros

Em Controller, usar os bags do `Request` (`$request->request`, `$request->query`) em vez de `$_POST`/`$_GET` diretamente — mais testável e explícito sobre a origem do dado:

```php
$id       = (int) $request->request->get('id', 0);
$entities = (int) $request->request->get('entities_id', 0);
$type     = (string) $request->request->get('type', '');
```

Em handler legado, `filter_input` continua sendo o padrão:

```php
$id   = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);
$type = (string) filter_input(INPUT_POST, 'type');

if ($id <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'code' => 'BAD_REQUEST', 'message' => '']);
    exit;
}
```

Sem auto-sanitização, os dados chegam brutos em ambos os casos — o cast/validação acima **é** a proteção.

---

## Estruturas de Resposta JSON

```php
global $CFG_GLPI;

// Sucesso genérico — HTTP 200
echo json_encode([
    'success'     => true,
    'id'          => $newID,
    'message'     => __('Item atualizado com sucesso', 'meuplugin'),
    'redirecturl' => $CFG_GLPI['root_doc'] . "/plugins/meuplugin/MeuItem/{$newID}",
]);
exit;

// Criação de recurso — HTTP 201
http_response_code(201);
echo json_encode(['success' => true, 'id' => $newID]);
exit;

// Erros de validação granulares — HTTP 422
http_response_code(422);
echo json_encode([
    'success' => false,
    'code'    => 'VALIDATION_ERROR',
    'message' => __('Dados inválidos', 'meuplugin'),
    'errors'  => [
        ['field' => 'name',        'message' => __('Nome é obrigatório', 'meuplugin')],
        ['field' => 'entities_id', 'message' => __('Entidade não existe', 'meuplugin')],
    ],
]);
exit;
```

Em Controller, o equivalente é retornar `new JsonResponse([...], 422)`.

---

## Integração JavaScript (lado cliente)

URLs de Controller não usam mais `/ajax/nomedoplugin/...` — apontam diretamente para a rota registrada:

```javascript
fetch('/plugins/meuplugin/MeuItem', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
        '_glpi_csrf_token': '{{ csrf_token() }}',
        'name': itemName,
    }),
})
.then((response) => {
    if (!response.ok) {
        throw new Error(response.statusText);
    }
    return response.json();
})
.then((data) => {
    if (data.success) {
        window.location.href = data.redirecturl || window.location.href;
    }
})
.catch(() => {
    alert('{{ __("Erro de comunicação. Tente novamente.", "meuplugin") }}');
});
```

Handlers legados em `ajax/` continuam acessíveis pela mesma URL de sempre (`/plugins/meuplugin/ajax/handler.php`) — `$.ajax`/`fetch` apontando para eles não precisa mudar.

**Sobre o prefixo `/ajax` da rota:** o exemplo acima (`/plugins/meuplugin/MeuItem`) representa um POST isolado por submissão de formulário — não precisa do prefixo. A regra do prefixo (ver `SKILL.md`) só se aplica quando a mesma página dispara múltiplos POSTs em sequência sem reload (ex.: autosave a cada poucos segundos, um botão "salvar" clicável repetidamente sem navegar). Nesse caso específico, a rota do Controller deveria ser declarada como `#[Route("/ajax/MeuItem", ...)]` em vez de `#[Route("/MeuItem", ...)]`.
