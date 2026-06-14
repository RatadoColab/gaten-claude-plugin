---
name: api-rest
description: This skill should be used when designing or implementing REST APIs. Typical triggers include "design a REST API", "which HTTP status code should I return?", "how do I paginate this endpoint?", "structure this API error response", "version this API", "write the OpenAPI spec for this". Covers HTTP verbs, status codes, URL patterns, versioning, request/response contracts, error handling (RFC 9457), pagination strategies, caching, idempotency, security, OpenAPI 3.1, and REST best practices.
---

# API REST — Padrões e Boas Práticas

## Visão Geral

Diretrizes para design e implementação de APIs REST consistentes, previsíveis e fáceis de consumir. Aplicar estes padrões garante interoperabilidade, manutenibilidade e segurança ao longo do ciclo de vida da API.

---

## Princípios Fundamentais

- **Recursos como substantivos:** URLs representam recursos, não ações (`/users`, não `/getUsers`)
- **Verbos HTTP semânticos:** cada método HTTP carrega significado preciso — usá-los corretamente comunica intenção ao cliente
- **Stateless:** cada requisição contém todas as informações necessárias; o servidor não mantém estado de sessão entre chamadas
- **Respostas consistentes:** mesma estrutura de envelope em todas as respostas bem-sucedidas
- **Contract-first:** definir o contrato OpenAPI antes de escrever código; o contrato é artefato versionado que dirige desenvolvimento, documentação e testes

---

## Verbos HTTP e Semântica

| Método  | Uso                           | Idempotente | Seguro |
|---------|-------------------------------|-------------|--------|
| GET     | Leitura de recurso ou coleção | Sim         | Sim    |
| POST    | Criação de recurso            | Não         | Não    |
| PUT     | Substituição completa         | Sim         | Não    |
| PATCH   | Atualização parcial           | Não*        | Não    |
| DELETE  | Remoção de recurso            | Sim         | Não    |
| HEAD    | Metadados sem corpo           | Sim         | Sim    |
| OPTIONS | Capacidades do endpoint       | Sim         | Sim    |

> *Ver a seção **Idempotência** abaixo.

---

## Padrões de URL

> Ver exemplo completo em [`references/http-patterns.md`](references/http-patterns.md).

**Regras de nomenclatura:**
- Sempre plural para coleções: `/users`, `/orders`, `/products`
- Letras minúsculas com hífens: `/user-profiles`, não `/userProfiles` nem `/user_profiles`
- Sem trailing slash: `/users`, não `/users/`
- Evitar profundidade excessiva (geralmente >3 níveis), salvo quando necessário para clareza semântica: `/resources/{id}/sub-resources/{sub-id}`
- Ações não mapeáveis em CRUD devem usar substantivos de ação: `POST /orders/{id}/actions/cancel`

---

## Versionamento

Prefixar a URL com versão principal: `/api/v1/resources`

**Estratégias e trade-offs:**

| Estratégia          | Exemplo                              | Prós                              | Contras                       |
|---------------------|--------------------------------------|-----------------------------------|-------------------------------|
| URL path (preferida) | `/api/v2/users`                     | Visível, cacheável, testável      | URL muda entre versões        |
| Query string        | `/users?version=2`                   | Simples de implementar            | Pode ser ignorada por caches  |
| Header customizado  | `API-Version: 2`                     | URL estável                       | Menos visível, menos testável |
| Content negotiation | `Accept: application/vnd.api.v2+json` | Padrão HTTP                      | Complexo para clientes        |

**Regras de evolução:**
- Nunca faça breaking changes em uma versão publicada
- Adicionar campos é não-breaking; remover ou renomear é breaking
- Anuncie deprecação com header `Deprecation` e `Sunset` antes de remover versões
- Mantenha ao menos 2 versões ativas simultaneamente durante a migração

> Ver exemplo completo em [`references/http-patterns.md`](references/http-patterns.md).

---

## Status Codes

Use o código mais específico disponível — nunca retorne `200 OK` com um erro no corpo.

| Classe | Mais usados |
|--------|-------------|
| 2xx | `200` OK · `201` criado (+`Location`) · `202` aceito (assíncrono) · `204` sem corpo |
| 3xx | `301` movido · `304` not modified (cache) |
| 4xx | `400` malformado · `401` não autenticado · `403` sem permissão · `404` inexistente · `409` conflito · `422` falha de regra · `429` rate limit |
| 5xx | `500` erro interno · `502` bad gateway · `503` indisponível · `504` timeout |

> Catálogo completo por classe em [`references/status-codes.md`](references/status-codes.md).

---

## Tratamento de Erros — RFC 9457

Use o padrão **RFC 9457 (Problem Details for HTTP APIs)** com `Content-Type: application/problem+json`.

Campos: `type` (URI do tipo, único obrigatório pelo RFC), `title`, `status`, `detail` (obrigatórios por convenção do projeto); `instance` e `errors[]` (opcionais, validação campo a campo).

> Tabelas de campos e exemplos completos (validação 400, not found 404) em [`references/error-handling.md`](references/error-handling.md).

---

## Paginação

Nunca retorne coleções sem paginação. Escolha a estratégia adequada:

- **Offset/Page** (`?page=2&per_page=25`): datasets pequenos e estáticos; envelope com `total`/`total_pages`. Degrada com grandes offsets e pode duplicar/omitir em dados mutáveis.
- **Cursor/Keyset** (`?limit=25&after=cursor_abc`): datasets grandes ou mutáveis (feeds, timelines, >10k); envelope com `next_cursor`/`has_next`. Performance estável, sem gaps.
- Regras: `limit` padrão + máximo documentado; ordenar por campo estável e indexado (`id`+`created_at`); sempre incluir metadados de paginação.

> Envelopes JSON completos (offset e cursor) em [`references/pagination.md`](references/pagination.md).

---

## Filtragem e Ordenação

```
GET /products?category=electronics&min_price=100&max_price=500
GET /users?status=active&created_after=2024-01-01
GET /orders?sort=created_at:desc,total:asc
GET /users?fields=id,name,email          # sparse fieldsets
```

**Convenções:**
- Parâmetros de filtro como query strings simples: `?status=active`
- Ordenação com `sort=campo:direção` (asc/desc)
- Seleção de campos com `fields=` para reduzir payload (sparse fieldsets)
- Busca textual com `q=` ou `search=`

> Todos os parâmetros de filtro devem ser validados e sanitizados no servidor. Ver seção de Segurança para orientações sobre validação de input.

---

## Caching

Use headers HTTP padrão para controle de cache e validação condicional (evita transferência desnecessária):

```http
Cache-Control: public, max-age=300
ETag: "abc123def456"

# Cliente reenvia a ETag em If-None-Match; servidor responde 304 se não mudou
If-None-Match: "abc123def456"   →   HTTP/1.1 304 Not Modified
```

**Regras:**
- GET de recursos individuais: use `ETag` + `Cache-Control`
- PUT/PATCH: use `If-Match` para evitar conflitos de atualização concorrente
- Recursos privados: `Cache-Control: private, no-store`
- Evite cachear erros por padrão, exceto quando explicitamente controlado (ex.: 404, 410, 429) com headers apropriados.

---

## Idempotência

Garanta que operações possam ser repetidas com segurança em caso de falha de rede:

- GET, PUT, DELETE são idempotentes por definição
- POST e PATCH **não** são idempotentes nativamente — use `Idempotency-Key` (UUID no header); janela de retenção mínima de 24h, retornando o resultado armazenado em reenvios. A chave garante segurança contra reenvio, mas não altera a semântica HTTP do método

> Comportamento completo e exemplo em [`references/advanced-endpoints.md`](references/advanced-endpoints.md).

---

## Headers Importantes

Mais usados:
- **Requisição:** `Authorization` (Bearer), `Content-Type`, `Accept`, `Idempotency-Key`, `If-None-Match`/`If-Match` (condicionais), `X-Request-ID`
- **Resposta:** `Location` (201), `ETag`, `Cache-Control`, `Retry-After` (429/503), `RateLimit-*`, `Deprecation`/`Sunset`

> Catálogo completo de headers (requisição e resposta) em [`references/http-patterns.md`](references/http-patterns.md).

---

## Rate Limiting

Contrato HTTP: retorne `429 Too Many Requests` com headers `RateLimit-*`/`Retry-After` e body RFC 9457; documente os limites por endpoint ou tier no OpenAPI. Políticas de limite (critérios por usuário/IP/device, backoff): ver `domains/security/SKILL.md` (§Rate Limiting) — fonte autoritativa.

> Ver exemplo completo em [`references/http-patterns.md`](references/http-patterns.md).

---

## Segurança

Específico de API (autenticação/autorização completas em `domains/security/SKILL.md` — fonte autoritativa):

- **Autenticação:** OAuth 2.0 + OIDC; JWT Bearer (access token de 15 min + refresh token — parâmetros em `domains/security/SKILL.md`); API Keys só server-to-server; não pôr dados sensíveis no payload do JWT
- **Transporte:** TLS 1.2+ e HSTS em todos os endpoints
- **Input:** validar/sanitizar contra schema (JSON Schema / OpenAPI); nunca expor stack traces em produção
- **CORS:** allowlist explícita de origens — nunca `*` em APIs autenticadas

---

## Estrutura de Resposta

### Resposta de sucesso (coleção)

Envelope padrão com `data[]`, `pagination` e `meta`.

> Ver exemplo completo em [`references/response-examples.md`](references/response-examples.md).

### Resposta de sucesso (recurso único)

Envelope com `data` como objeto único.

> Ver exemplo completo em [`references/response-examples.md`](references/response-examples.md).

### Resposta de criação (201)

Retorna `Location` header com URI do novo recurso + `data` com o recurso criado.

> Ver exemplo completo em [`references/response-examples.md`](references/response-examples.md).

---

## HATEOAS (Hypermedia)

HATEOAS (Hypermedia as the Engine of Application State) permite que clientes descubram ações disponíveis dinamicamente, sem conhecimento prévio das URLs.

Aplicar quando a API for consumida por clientes que precisam navegar recursos sem acoplamento forte às URLs.

> Ver exemplo completo em [`references/response-examples.md`](references/response-examples.md).

Links disponíveis variam conforme o estado do recurso — um pedido já confirmado não expõe o link `confirm`.

---

## OpenAPI 3.1

Toda API deve ter especificação OpenAPI 3.1 mantida como fonte de verdade.

> Ver modelo completo em [`references/openapi-example.yaml`](references/openapi-example.yaml).

**Práticas com OpenAPI:**
- Manter schema em `components/schemas` e responses em `components/responses` para reuso
- Documentar todos os parâmetros, tipos, exemplos e códigos de erro
- Usar `deprecated: true` para marcar endpoints que serão removidos
- Lint com **Spectral** para enforçar style guide no CI
- Usar **Prism** ou **Schemathesis** para testes de contrato automatizados
- Versionar o arquivo `.yaml` junto ao código no repositório

---

## Datas e Formatos

- **Datas/horários:** sempre ISO 8601 com timezone UTC: `2025-05-27T10:00:00Z`
- **IDs:** strings UUID v4 ou ULID (evitar inteiros sequenciais expostos por segurança)
- **Moeda:** usar centavos como inteiro **ou** string decimal com precisão definida — documente a escolha
- **Booleanos:** `true`/`false` JSON nativo, nunca `"yes"`/`"no"` ou `1`/`0`
- **Enumerações:** strings em `SCREAMING_SNAKE_CASE` ou `snake_case` — seja consistente

---

## Endpoints Avançados

Padrões detalhados (com exemplos) em [`references/advanced-endpoints.md`](references/advanced-endpoints.md):

- **Processamento assíncrono:** `202 Accepted` + `Location` do job; cliente faz polling em `/jobs/{id}`
- **Webhooks:** `POST` à URL do consumidor, payload assinado com HMAC-SHA256, retry com backoff
- **Health check:** `GET /health` (liveness) e `/health/ready` (readiness), sem autenticação, sem detalhes internos
- **Operações em lote:** `POST /resources/batch`, `207 Multi-Status` para resultados parciais
- **Soft delete:** marcar `deleted_at`, filtrar por padrão, restaurar via `actions/restore`

---

## Referências

- Ver `domains/security/SKILL.md` para autenticação e autorização em APIs
- [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0)
- [Microsoft Azure REST API Guidelines](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design)
- [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)
