# Response Examples — API REST

> Referência de exemplos de resposta para `domains/api-rest/SKILL.md`.

---

## Resposta de Coleção com Paginação e Meta

**Quando usar:** qualquer endpoint que retorne lista de recursos (GET /resources).

```json
{
  "data": [
    { "id": "1", "name": "Alice", "email": "alice@example.com" },
    { "id": "2", "name": "Bob",   "email": "bob@example.com" }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "per_page": 20,
    "total_pages": 5
  },
  "meta": {
    "request_id": "req_abc123",
    "timestamp": "2025-05-27T10:00:00Z"
  }
}
```

---

## Recurso Único

**Quando usar:** GET /resources/{id} retornando um único recurso.

```json
{
  "data": {
    "id": "1",
    "name": "Alice",
    "email": "alice@example.com",
    "created_at": "2025-01-10T08:30:00Z"
  }
}
```

---

## Criação — 201 Created

**Quando usar:** resposta de POST bem-sucedido com Location header.

```http
HTTP/1.1 201 Created
Location: /api/v1/users/1
Content-Type: application/json
```

```json
{
  "data": {
    "id": "1",
    "name": "Alice",
    "email": "alice@example.com"
  }
}
```

---

## HATEOAS — Links Dinâmicos

**Quando usar:** API consumida por clientes que navegam recursos sem acoplamento a URLs hardcoded.

```json
{
  "data": {
    "id": "42",
    "status": "pending",
    "amount": 150.00
  },
  "links": {
    "self":    { "href": "/api/v1/orders/42", "method": "GET" },
    "confirm": { "href": "/api/v1/orders/42/actions/confirm", "method": "POST" },
    "cancel":  { "href": "/api/v1/orders/42/actions/cancel",  "method": "POST" }
  }
}
```

> Links disponíveis variam conforme o estado do recurso — um pedido já confirmado não expõe o link `confirm`.
