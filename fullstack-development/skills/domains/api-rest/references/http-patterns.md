# HTTP Patterns — API REST

> Referência de exemplos HTTP para `domains/api-rest/SKILL.md`.

---

## Padrões de URL

**Quando usar:** nomenclatura e estrutura de endpoints REST.

```http
GET    /resources              → listar coleção (com paginação)
POST   /resources              → criar novo recurso
GET    /resources/{id}         → buscar recurso específico
PUT    /resources/{id}         → substituir recurso completo
PATCH  /resources/{id}         → atualizar campos parcialmente
DELETE /resources/{id}         → remover recurso
GET    /resources/{id}/sub     → sub-coleção relacionada
POST   /resources/{id}/actions/approve  → ação não-CRUD (verbo como sub-recurso)
```

---

## Versionamento — Deprecação

**Quando usar:** notificar clientes que um endpoint ou versão será removido.

```http
Deprecation: true
Sunset: Sat, 31 Dec 2025 23:59:59 GMT
Link: <https://api.exemplo.com/v2/users>; rel="successor-version"
```

---

## Rate Limiting — 429 com Headers

**Quando usar:** resposta completa ao exceder o limite de requisições.

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
RateLimit-Limit: 1000
RateLimit-Remaining: 0
RateLimit-Reset: 1716912000
```

```json
{
  "type": "https://api.exemplo.com/errors/rate-limit-exceeded",
  "title": "Rate Limit Exceeded",
  "status": 429,
  "detail": "You have exceeded 1000 requests per hour. Try again after 60 seconds.",
  "instance": "/api/v1/users"
}
```

---

## Segurança — HSTS Header

**Quando usar:** forçar HTTPS em todos os clientes.

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

---

## Headers Importantes — Catálogo

### Requisição

| Header              | Uso                                              |
|---------------------|--------------------------------------------------|
| `Authorization`     | Token de autenticação (`Bearer <token>`)         |
| `Content-Type`      | Formato do corpo enviado (`application/json`)    |
| `Accept`            | Formato esperado na resposta                     |
| `Idempotency-Key`   | Chave para operações idempotentes                |
| `If-None-Match`     | ETag para requisições condicionais (GET)         |
| `If-Match`          | ETag para atualizações condicionais (PUT/PATCH)  |
| `X-Request-ID`      | ID para rastreamento distribuído                 |

### Resposta

| Header              | Uso                                              |
|---------------------|--------------------------------------------------|
| `Content-Type`      | `application/json` ou `application/problem+json` |
| `Location`          | URI do recurso criado (POST 201)                 |
| `ETag`              | Versão do recurso para cache                     |
| `Cache-Control`     | Diretivas de cache                               |
| `X-Request-ID`      | Espelhamento do ID de rastreamento               |
| `Retry-After`       | Segundos antes de nova tentativa (429, 503)      |
| `RateLimit-Limit`   | Limite de requisições por janela                 |
| `RateLimit-Remaining` | Requisições restantes na janela atual          |
| `RateLimit-Reset`   | Timestamp Unix quando a janela reseta            |
| `Deprecation`       | Indica que o endpoint está deprecado             |
| `Sunset`            | Data prevista de remoção do endpoint             |
