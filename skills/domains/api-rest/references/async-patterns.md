# Async Patterns — API REST

> Referência de exemplos de padrões assíncronos para `domains/api-rest/SKILL.md`.

---

## Processamento Assíncrono — 202 Accepted com Polling

**Quando usar:** operações longas (relatórios, importações, processamentos) que não concluem no ciclo da requisição.

```http
HTTP/1.1 202 Accepted
Location: /api/v1/jobs/job_abc123
Content-Type: application/json
```

```json
{
  "data": {
    "job_id": "job_abc123",
    "status": "queued",
    "links": {
      "status": { "href": "/api/v1/jobs/job_abc123", "method": "GET" }
    }
  }
}
```

O cliente faz polling em `/jobs/{id}` até o status ser `completed` ou `failed`.

---

## Webhooks com HMAC-SHA256

**Quando usar:** notificação push de eventos para evitar polling contínuo pelo consumidor.

```http
POST https://cliente.com/webhook HTTP/1.1
X-Webhook-Signature: sha256=abc123...
Content-Type: application/json

{ "event": "order.completed", "data": { "id": "42", "status": "paid" } }
```

**Contrato do consumidor:**
- Responder `200` imediatamente e processar de forma assíncrona
- Aguardar resposta `2xx` em até 5 segundos; marcar como falha caso contrário
- Retry com exponential backoff (máx. 3 tentativas em 24h)

---

## Health Check — Resposta JSON

**Quando usar:** endpoints `GET /health` (liveness) e `GET /health/ready` (readiness).

```json
{
  "status": "healthy",
  "checks": {
    "database": "healthy",
    "cache": "degraded"
  },
  "timestamp": "2025-05-27T10:00:00Z"
}
```

- `200` quando `healthy` ou `degraded`
- `503` quando `unhealthy`
- Nunca expor detalhes internos (versão, stack trace) nesses endpoints

---

## Operações em Lote — 207 Multi-Status

**Quando usar:** criar ou atualizar múltiplos recursos em uma única requisição com resultados parcialmente bem-sucedidos.

```http
POST /users/batch HTTP/1.1
Content-Type: application/json

{
  "operations": [
    { "name": "Alice", "email": "alice@example.com" },
    { "name": "Bob",   "email": "email-invalido" }
  ]
}
```

```json
{
  "results": [
    { "index": 0, "status": 201, "data": { "id": "1" } },
    { "index": 1, "status": 422, "error": { "field": "email", "code": "INVALID_FORMAT" } }
  ]
}
```
