---
name: glpi-10-ajax-handlers
description: >
  This skill should be used when the user asks to "create an AJAX handler",
  "add an ajax endpoint", "create a file in ajax/", "handle an AJAX request",
  "return JSON from PHP in GLPI", "create a dropdown handler", or mentions
  the ajax/ directory — in a GLPI 10.0.x plugin context (explicit "GLPI 10"
  mention, `include('../../../inc/includes.php')` present, or confirmed 10.x
  when asked). For GLPI 11 (controllers, `$DB->doQuery`, `public/`), use
  `domains/glpi-11/ajax-handlers/SKILL.md` instead. If the GLPI version
  cannot be determined from the project or the user's message, ask before
  generating code.
---

# GLPI 10.x — Handlers AJAX

> **Versão-alvo:** GLPI 10.0.x. Para GLPI 11, usar `domains/glpi-11/ajax-handlers/SKILL.md`.

## Visão Geral

Handlers AJAX são arquivos PHP em `ajax/` que respondem a requisições JavaScript, retornando JSON ou HTML parcial. Seguem uma estrutura de inicialização obrigatória e delegam autenticação inteiramente ao framework GLPI.

---

## 1. Ordem de Inicialização (Obrigatória)

Todo handler deve seguir exatamente esta sequência:

1. `$AJAX_INCLUDE = 1;` — flag que indica ao GLPI que este é um endpoint AJAX
2. CSRF token movido para o header **antes** do includes.php: `$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';` (apenas se o handler receber `$_POST['_glpi_csrf_token']`)
3. Bootstrap do framework: `include('../../../inc/includes.php');`
4. Content-Type apropriado: `application/json` ou `text/html` (charset UTF-8)
5. `Html::header_nocache();` — impede cache
6. Verificação de ambiente: `if (!defined('GLPI_ROOT'))` → `403` + `die()`
7. Verificação de plugin ativo: `Plugin::isPluginActive('nomedoplugin')` → `503` se inativo (opcional quando o handler é genérico ao GLPI)
8. Verificação de sessão/permissões — **sempre antes de processar qualquer lógica**: `Session::checkCentralAccess();`

Template completo anotado em **`references/patterns.md`**.

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
Session::checkRight(MinhaClasse::$rightname, CREATE);

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
$id = (int) filter_input(INPUT_POST, 'id', FILTER_SANITIZE_NUMBER_INT);
if ($id <= 0) {
    http_response_code(400);
    die();
}
```

Padrões para strings, fallbacks e parâmetros JSON em GET na seção **Validação de Parâmetros** de `references/patterns.md`.

---

## 4. Padrões de Operação

Duas formas de despachar operações no mesmo handler:

- **CRUD via POST** — testar `isset($_POST['add'])` / `update` / `delete`, verificar o direito correspondente (`CREATE`/`UPDATE`/`DELETE`) antes de cada operação e responder JSON. Template completo no **Padrão 3** de `references/patterns.md`.
- **Operações múltiplas via parâmetro `op`** — `switch` sobre `filter_input(..., 'op')`, com `default` retornando `400`; cada case define seu próprio Content-Type. Exemplos nas seções **Operações Múltiplas** e **Padrão 4** (wizard via GET) de `references/patterns.md`.

---

## 5. Respostas

### 5.1 JSON vs HTML

| Retornar JSON | Retornar HTML |
|---------------|---------------|
| Operações CRUD (add, update, delete) | Dropdown para injetar em `div` via `$.html()` |
| Respostas com metadados (id, redirecturl) | Fragmentos de formulário carregados dinamicamente |
| Status de sucesso/erro | Conteúdo de wizard steps |

### 5.2 Envelope JSON

Sucesso: `{success: true, id, message, redirecturl?}` com HTTP `200`. Em criação, usar `201` + header `Location` apenas quando o JS precisar conhecer a URL canônica do recurso criado — em AJAX puro, `200 + id` é suficiente. Erro:

```php
http_response_code(422);
echo json_encode([
    'success' => false,
    'code'    => 'VALIDATION_ERROR',  // constante para decisão programática no JS
    'message' => __('Dados inválidos', 'nomedoplugin'),
    'errors'  => [],                  // erros campo a campo (opcional)
]);
```

Exemplos completos (200/201/403/422, erros granulares por campo) na seção **Estruturas de Resposta JSON** de `references/patterns.md`.

> **Nota sobre RFC 9457:** A api-rest recomenda Problem Details (RFC 9457) com `type`, `title`, `status`, `detail`. Handlers AJAX do GLPI são **endpoints internos** consumidos apenas pelo próprio frontend JS do plugin — não são APIs públicas. O envelope `{success, code, message, errors}` é compatível com o padrão existente nos plugins IBGE e dispensa o overhead do RFC 9457.

### 5.3 Tabela de códigos HTTP

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

Preferir delegar lógica complexa para métodos da classe `CommonDBTM`: o handler apenas valida entrada, delega e serializa a resposta (**Padrão 1** de `references/patterns.md`). Lógica inline é aceitável apenas para handlers simples (consultas `$DB`, renderização de dropdown).

---

## 7. Tratamento de Erros

Envolver operações com risco de exceção em try-catch respondendo `500` — nunca `400`, que mascara a origem — e nunca expor `$e->getMessage()` em produção (**Padrão 6** de `references/patterns.md`). Para mensagens ao usuário após redirect (não AJAX puro), usar `Session::addMessageAfterRedirect()`.

---

## 8. Globais Disponíveis

Declarar antes de usar: `global $DB;` (acesso ao banco) e `global $CFG_GLPI;` (configurações, ex.: `root_doc`).

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

- **`references/patterns.md`** — Templates completos anotados, validação de parâmetros, estruturas de resposta JSON e exemplos reais de handlers por tipo de operação
