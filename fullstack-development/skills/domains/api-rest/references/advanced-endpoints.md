# Endpoints Avançados — Idempotência, Assíncrono, Webhooks, Health, Lote, Soft Delete

Padrões para endpoints avançados. Resumo no `SKILL.md`. Exemplos completos de
processamento assíncrono, webhooks, health check e lote em
[`async-patterns.md`](async-patterns.md).

## Idempotência

Garanta que operações possam ser repetidas com segurança em caso de falha de rede:

- GET, PUT, DELETE são idempotentes por definição
- POST e PATCH **não** são idempotentes nativamente — use `Idempotency-Key`

```http
POST /payments HTTP/1.1
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
Content-Type: application/json

{
  "amount": 150.00,
  "currency": "BRL"
}
```

**Comportamento esperado:**
- Primeira chamada: processa e armazena resultado associado à chave
- Chamadas subsequentes com mesma chave: retorna resultado armazenado (sem reprocessar)
- Janela de retenção: mínimo 24 horas
- Chave expirada ou inválida: retornar `422` com detalhe

## Processamento Assíncrono

Para operações longas, retorne `202 Accepted` com `Location` apontando para o job e link de polling no corpo.

> Ver exemplo completo em [`async-patterns.md`](async-patterns.md).

O cliente faz polling em `/jobs/{id}` até o status ser `completed` ou `failed`.

## Webhooks

Para notificação push de eventos, prefira webhooks ao polling contínuo:

- Entregar eventos via `POST` para URL cadastrada pelo consumidor
- Assinar payload com HMAC-SHA256 no header `X-Webhook-Signature: sha256=<hash>`
- Aguardar resposta `2xx` em até 5 segundos; marcar como falha caso contrário
- Implementar retry com exponential backoff (máx. 3 tentativas em 24h)
- O consumidor deve responder `200` imediatamente e processar de forma assíncrona

> Ver exemplo completo em [`async-patterns.md`](async-patterns.md).

## Health Check

Expor endpoints de saúde sem autenticação:

```
GET /health        → liveness (processo está vivo)
GET /health/ready  → readiness (pronto para receber tráfego)
```

> Ver exemplo completo em [`async-patterns.md`](async-patterns.md).

- `200` quando `healthy` ou `degraded`
- `503` quando `unhealthy`
- Nunca expor detalhes internos (versão, stack trace) nesses endpoints

## Operações em Lote

Para criar ou atualizar múltiplos recursos em uma requisição, use `POST /resources/batch` com array `operations`.

> Ver exemplo completo em [`async-patterns.md`](async-patterns.md).

- Usar `207 Multi-Status` quando a operação tem resultados parcialmente bem-sucedidos
- Garantir idempotência com `Idempotency-Key` no header da requisição em lote

## Soft Delete

Quando recursos removidos precisam ser auditados ou restaurados:

- `DELETE /resources/{id}` retorna `204` e marca o registro como excluído (`deleted_at`)
- Coleções filtram registros excluídos por padrão
- Para incluir excluídos: `GET /resources?include_deleted=true`
- Para restaurar: `POST /resources/{id}/actions/restore`
- Expor `deleted_at` no schema quando o estado importa para o consumidor
- Em tabelas de alto volume, avaliar impacto de performance antes de adotar soft delete
