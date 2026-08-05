---
name: glpi-11-ajax-handlers
description: >
  This skill should be used when the user asks to "create an AJAX handler",
  "add an ajax endpoint", "create a file in ajax/", "handle an AJAX request",
  "return JSON from PHP in GLPI", "create a dropdown handler", "create a
  controller", "add a Route to a plugin", or mentions the ajax/ directory or
  src/Controller/ — in a GLPI 11 plugin context (explicit "GLPI 11" mention,
  `public/` directory present, or confirmed 11.x when asked). For GLPI
  10.0.x (`$AJAX_INCLUDE`, `include inc/includes.php`), use
  `domains/glpi-10/ajax-handlers/SKILL.md` instead. If the GLPI version
  cannot be determined from the project or the user's message, ask before
  generating code.
---

# GLPI 11 — Controllers e Handlers AJAX

> **Versão-alvo:** GLPI 11. Para GLPI 10.0.x, usar `domains/glpi-10/ajax-handlers/SKILL.md`.

## Visão Geral

Duas rotas para responder requisições assíncronas: **Controller** (`src/Controller/`, recomendado para toda feature nova) e **`ajax/` legado** (mantido apenas por compatibilidade, sem os includes/flags do GLPI 10). Ambos delegam autenticação inteiramente ao framework GLPI.

---

## 1. Rota Recomendada — Controller

```php
namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Symfony\Component\HttpFoundation\{JsonResponse, Request, Response};
use Symfony\Component\Routing\Attribute\Route;

final class MeuItemController extends AbstractController
{
    #[Route("/MeuItem/{id}", name: "meuplugin_meuitem_get", methods: "GET")]
    public function show(int $id): Response
    {
        // ...
        return new JsonResponse([/* ... */]);
    }
}
```

- Descoberta automática — sem registro em `setup.php`
- Prefixo `/plugins/meuplugin` aplicado automaticamente; **não** incluí-lo no atributo
- **Bug conhecido antes da 11.0.7:** rotas com método diferente de `GET` nunca casam. Workaround: declarar `methods: ['GET', 'POST']` e checar `$request->isMethod('POST')` manualmente, lançando `BadRequestHttpException` se não bater
- **Regra do prefixo `/ajax`:** aplica-se apenas quando a mesma página dispara **múltiplos POSTs consecutivos sem reload** (ex.: salvar um formulário várias vezes, autosave) — nesse caso específico, o path da rota deve começar por `/ajax` (limitação de checagem CSRF multi-request até o GLPI 12; ver seção 6.3 nesta skill). GETs, POSTs isolados seguidos de reload/redirect, e a maioria dos exemplos desta skill **não** precisam do prefixo.
- Acesso restrito por padrão a usuários autenticados; para liberar, usar `#[Glpi\Security\Attribute\SecurityStrategy(...)]`

Template completo anotado em **`references/patterns.md`**.

---

## 2. Rota Legada — `ajax/`

Manter apenas para handlers já existentes. **Sem** `$AJAX_INCLUDE`, **sem** `include('../../../inc/includes.php')` — o bootstrap roda automaticamente no ponto de entrada único (`public/index.php`).

```php
<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=UTF-8');
Html::header_nocache();

Session::checkCentralAccess();

// --- lógica do handler ---
```

Se o handler precisar de acesso não autenticado, declarar a estratégia em `plugin_init_<nome>()`:

```php
use Glpi\Http\Firewall;

Firewall::addPluginStrategyForLegacyScripts('meuplugin', '#^/ajax/publico\.php$#', Firewall::STRATEGY_NO_CHECK);
```

---

## 3. Verificação de Sessão

Inalterado em relação ao GLPI 10:

| Método | Quando usar |
|--------|-------------|
| `Session::checkCentralAccess()` | Padrão para a maioria dos handlers — exige login de usuário central |
| `Session::checkLoginUser()` | Quando qualquer usuário logado pode acessar (incluindo self-service) |
| `Session::checkRight($rightname, READ)` | Quando a operação exige um direito específico do plugin |
| `Session::haveRight($rightname, UPDATE)` | Quando a permissão é verificada condicionalmente (retorna bool) |

```php
Session::checkRight(MinhaClasse::$rightname, CREATE);

if (!Session::haveRight('ticket', UPDATE)) {
    throw new \Glpi\Exception\Http\AccessDeniedHttpException();
}
```

> **Sessão expirada em AJAX:** `Session::checkCentralAccess()`/`checkLoginUser()` continuam fazendo redirect HTML para a tela de login quando o usuário não está autenticado — comportamento que quebra parsing JSON em chamadas AJAX. O cliente JS deve detectar HTML na resposta e recarregar a página.

---

## 4. Validação de Parâmetros

Sem auto-sanitização no GLPI 11 — o cast explícito e `filter_input` continuam obrigatórios, mas agora são a **única** proteção contra tipos inesperados (a proteção contra SQL injection vem do query builder, não da sanitização de `$_POST`):

```php
$id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);
if ($id <= 0) {
    throw new \Glpi\Exception\Http\BadRequestHttpException();
}
```

Padrões para strings, fallbacks e parâmetros JSON em GET na seção **Validação de Parâmetros** de `references/patterns.md`.

---

## 5. Padrões de Operação

Idênticos ao GLPI 10 na forma: **CRUD via POST** (`isset($_POST['add'])`/`update`/`delete`, verificando o direito correspondente antes de cada operação) ou **operações múltiplas via `op`** (`switch` sobre `filter_input(..., 'op')`). Delegar lógica complexa para métodos da classe `CommonDBTM` — o handler ou controller apenas valida entrada, delega e serializa a resposta. Templates completos em `references/patterns.md`.

---

## 6. Respostas

### 6.1 Envelope JSON e códigos HTTP

**Inalterado** em relação ao GLPI 10 — envelope `{success, code, message, errors}`, mesma tabela de códigos (`200`/`201`/`400`/`403`/`404`/`422`/`500`/`503`).

> **Nota sobre RFC 9457:** a `api-rest` recomenda Problem Details (RFC 9457). Controllers e handlers AJAX do GLPI são **endpoints internos** consumidos apenas pelo próprio frontend JS do plugin — não APIs públicas. O envelope `{success, code, message, errors}` é compatível com o padrão existente nos plugins IBGE e dispensa o overhead do RFC 9457.

### 6.2 Erros — exceção, nunca `exit()`

```php
if (!$item->getFromDB($id)) {
    throw new \Glpi\Exception\Http\NotFoundHttpException();
}
```

Em Controller, a exceção vira a resposta HTTP automaticamente. Em `ajax/` legado, capturar e converter para JSON antes de encerrar:

```php
try {
    $item = new MinhaClasse();
    if (!$item->getFromDB($id)) {
        throw new \Glpi\Exception\Http\NotFoundHttpException();
    }
} catch (\Glpi\Exception\Http\NotFoundHttpException) {
    http_response_code(404);
    echo json_encode(['success' => false, 'code' => 'NOT_FOUND', 'message' => '']);
    exit;
}
```

Nunca expor `$e->getMessage()` em produção.

### 6.3 Validação de CSRF no Servidor

O token continua sendo gerado no Twig via `csrf_token()` e enviado como campo `_glpi_csrf_token` no corpo do POST — isso não muda em relação ao GLPI 10. O que muda é a checagem: como o hook `csrf_compliant` foi depreciado (ver seção Hooks de `domains/glpi-11/SKILL.md`), o plugin **não** declara mais explicitamente que é compatível com CSRF nem move o token para o header `HTTP_X_GLPI_CSRF_TOKEN` antes do bootstrap — a validação do `_glpi_csrf_token` passa a ser responsabilidade do framework em torno do ponto de entrada único (`public/index.php`), antes da rota (Controller ou legada) ser alcançada. Na prática, para o autor do plugin: continuar sempre incluindo `_glpi_csrf_token` (via `csrf_token()`) em todo formulário e toda chamada `fetch`/`$.ajax` que faça POST — sem o campo, a requisição é rejeitada pelo framework antes de chegar ao handler. Não implementar verificação de CSRF manual no handler/Controller.

---

## 7. Globais Disponíveis

Declarar antes de usar: `global $DB;` e `global $CFG_GLPI;`. `$AJAX_INCLUDE` foi **removida** — não referenciá-la.

---

## 8. Segurança — Checklist

- [ ] Handler legado sem `include('../../../inc/includes.php')`; Controller com `#[Route]` e prefixo automático
- [ ] Estratégia de Firewall declarada se o acesso não for o padrão autenticado
- [ ] Parâmetros sanitizados com `filter_input` + cast explícito
- [ ] IDs validados (`> 0`) antes de usar
- [ ] Permissão verificada antes de qualquer lógica
- [ ] Verificação de entidade ao acessar recursos de outras entidades
- [ ] `_glpi_csrf_token` presente em todo formulário/chamada AJAX que faça POST (via `csrf_token()` no Twig)
- [ ] Em Controller: erros sinalizados via exceção `Glpi\Exception\Http\*`, nunca `exit()`/`die()`/`http_response_code()`. Em handler `ajax/` legado: `http_response_code()` + JSON + `exit` é aceitável
- [ ] Saída HTML/JS escapada com `htmlescape()`/`jsescape()`
- [ ] Nunca expor mensagens de exceção em produção

---

## Recursos Adicionais

- **`references/patterns.md`** — Templates completos anotados (Controller e legado), validação de parâmetros, estruturas de resposta JSON e exemplos reais por tipo de operação
