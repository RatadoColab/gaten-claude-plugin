---
name: api-rest
description: This skill should be used when designing or implementing REST APIs. Covers HTTP verbs, status codes, URL patterns, versioning, request/response contracts, error handling (RFC 9457), pagination strategies, caching, idempotency, security, OpenAPI 3.1, and REST best practices.
version: 0.2.0
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

> *PATCH não é idempotente por definição; o uso de Idempotency-Key garante segurança contra reenvio, mas não altera sua semântica HTTP.

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
| Header customizado  | `API-Version: 2`                     | URL estável                       | Menos visível, harder to test |
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

### 2xx — Sucesso

| Código | Uso                                                   |
|--------|-------------------------------------------------------|
| `200`  | Sucesso geral (GET, PUT, PATCH com corpo)             |
| `201`  | Recurso criado (POST); incluir `Location` no header  |
| `202`  | Requisição aceita para processamento assíncrono       |
| `204`  | Sucesso sem corpo (DELETE, PUT/PATCH sem retorno)     |
| `206`  | Conteúdo parcial (range requests)                     |

### 3xx — Redirecionamento

| Código | Uso                                              |
|--------|--------------------------------------------------|
| `301`  | Recurso movido permanentemente                   |
| `304`  | Not Modified — cliente pode usar cache           |

### 4xx — Erro do cliente

| Código | Uso                                                          |
|--------|--------------------------------------------------------------|
| `400`  | Requisição malformada, parâmetros inválidos                  |
| `401`  | Não autenticado — credenciais ausentes ou inválidas          |
| `403`  | Autenticado, mas sem permissão para o recurso                |
| `404`  | Recurso não encontrado (URL válida, recurso inexistente)     |
| `405`  | Método HTTP não permitido para este endpoint                 |
| `406`  | Not Acceptable — `Accept` header incompatível com os formatos disponíveis        |
| `409`  | Conflito de estado (ex.: e-mail duplicado)                   |
| `410`  | Recurso removido permanentemente (substitui 404 quando útil) |
| `415`  | Content-Type não suportado                                   |
| `422`  | Dados válidos sintaticamente, mas falha em regra de negócio  |
| `429`  | Rate limit excedido                                          |

### 5xx — Erro do servidor

| Código | Uso                                         |
|--------|---------------------------------------------|
| `500`  | Erro interno não tratado                    |
| `502`  | Bad gateway (proxy/upstream com falha)      |
| `503`  | Serviço indisponível (manutenção, overload) |
| `504`  | Gateway timeout                             |

---

## Tratamento de Erros — RFC 9457

Use o padrão **RFC 9457 (Problem Details for HTTP APIs)** com `Content-Type: application/problem+json`.

**Campos obrigatórios:**

| Campo    | Tipo   | Descrição                                               |
|----------|--------|---------------------------------------------------------|
| `type`   | string | URI que identifica o tipo do problema (pode ser relativa) |
| `title`  | string | Resumo legível, invariante para o tipo do problema      |
| `status` | number | Código HTTP refletido no corpo (ajuda proxies/logs)     |
| `detail` | string | Explicação específica desta ocorrência                  |

> Nota: O RFC 9457 define apenas `type` como obrigatório (com default `about:blank`). Os campos `title`, `status` e `detail` são exigidos por convenção interna deste projeto.

**Campos opcionais:**

| Campo      | Tipo   | Descrição                                       |
|------------|--------|-------------------------------------------------|
| `instance` | string | URI da requisição que causou o problema         |
| `errors`   | array  | Lista de erros de validação campo a campo       |

**Exemplo — erro de validação (`400`):**

```json
{
  "type": "https://api.exemplo.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "One or more fields failed validation.",
  "instance": "/api/v1/users",
  "errors": [
    {
      "field": "email",
      "code": "INVALID_FORMAT",
      "message": "Must be a valid email address."
    },
    {
      "field": "age",
      "code": "OUT_OF_RANGE",
      "message": "Must be between 18 and 120."
    }
  ]
}
```

**Exemplo — recurso não encontrado (`404`):**

```json
{
  "type": "https://api.exemplo.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with id '42' does not exist.",
  "instance": "/api/v1/users/42"
}
```

---

## Paginação

Nunca retorne coleções sem paginação. Escolha a estratégia adequada ao caso de uso:

### Offset/Page (datasets pequenos e estáticos)

```
GET /users?page=2&per_page=25
GET /users?offset=50&limit=25
```

**Resposta:**
```json
{
  "data": [...],
  "pagination": {
    "total": 1250,
    "page": 2,
    "per_page": 25,
    "total_pages": 50
  }
}
```

**Limitação:** degradação de performance com grandes offsets; dados podem ser duplicados/omitidos se a coleção mudar entre páginas.

### Cursor/Keyset (datasets grandes ou que mudam frequentemente)

```
GET /events?limit=25&after=cursor_abc123
GET /events?limit=25&before=cursor_xyz789
```

**Resposta:**
```json
{
  "data": [...],
  "pagination": {
    "has_next": true,
    "has_prev": false,
    "next_cursor": "cursor_def456",
    "prev_cursor": null
  }
}
```

**Vantagens:** performance estável em qualquer volume, sem duplicações ou gaps em dados mutáveis.

**Regras gerais:**
- Defina um `limit` padrão sensato e documente o máximo permitido (ex.: `limit=100` máximo)
- Ordene sempre por campo estável e indexado (geralmente `id` + `created_at`)
- Inclua metadados de paginação sempre na resposta
- Use cursor-based para feeds, timelines e coleções grandes (>10k registros)

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

Use headers HTTP padrão para controle de cache:

```http
Cache-Control: public, max-age=300
ETag: "abc123def456"
Last-Modified: Tue, 27 May 2025 10:00:00 GMT
```

**Validação condicional (evita transferência desnecessária):**

```http
# Cliente envia ETag recebida anteriormente
GET /products/42 HTTP/1.1
If-None-Match: "abc123def456"

# Servidor responde 304 se não mudou
HTTP/1.1 304 Not Modified
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

---

## Headers Importantes

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

---

## Rate Limiting

Retorne `429 Too Many Requests` com headers informativos e body RFC 9457.

> Ver exemplo completo em [`references/http-patterns.md`](references/http-patterns.md).

**Regras:**
- Aplicar rate limit por token/usuário, não apenas por IP
- Documentar limites por endpoint ou tier no OpenAPI
- Orientar clientes a implementar exponential backoff usando o valor de `Retry-After` como base para o intervalo mínimo

---

## Segurança

### Autenticação

- **OAuth 2.0 + OIDC:** padrão para delegação de acesso e autenticação federada
- **JWT (Bearer tokens):** expiração de 15–60 minutos; usar refresh tokens para sessões longas
- **API Keys:** apenas para comunicação server-to-server, nunca em clientes públicos
- Não armazenar dados sensíveis no payload do JWT (assinado, não criptografado)

```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Práticas obrigatórias

- TLS 1.2+ em todos os endpoints (sem exceções)
- Validar e sanitizar **todo** input do cliente contra schema (JSON Schema / OpenAPI)
- Não expor stack traces ou detalhes internos em respostas de erro de produção
- Usar HTTPS-only com `Strict-Transport-Security` (HSTS)
- Implementar CORS restritivo — listar origens explicitamente, não usar `*` em APIs autenticadas

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

> Ver `../security/SKILL.md` para checklist completo de autenticação e autorização.

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

## Processamento Assíncrono

Para operações longas, retorne `202 Accepted` com `Location` apontando para o job e link de polling no corpo.

> Ver exemplo completo em [`references/async-patterns.md`](references/async-patterns.md).

O cliente faz polling em `/jobs/{id}` até o status ser `completed` ou `failed`.

---

## Webhooks

Para notificação push de eventos, prefira webhooks ao polling contínuo:

- Entregar eventos via `POST` para URL cadastrada pelo consumidor
- Assinar payload com HMAC-SHA256 no header `X-Webhook-Signature: sha256=<hash>`
- Aguardar resposta `2xx` em até 5 segundos; marcar como falha caso contrário
- Implementar retry com exponential backoff (máx. 3 tentativas em 24h)
- O consumidor deve responder `200` imediatamente e processar de forma assíncrona

> Ver exemplo completo em [`references/async-patterns.md`](references/async-patterns.md).

---

## Health Check

Expor endpoints de saúde sem autenticação:

```
GET /health        → liveness (processo está vivo)
GET /health/ready  → readiness (pronto para receber tráfego)
```

> Ver exemplo completo em [`references/async-patterns.md`](references/async-patterns.md).

- `200` quando `healthy` ou `degraded`
- `503` quando `unhealthy`
- Nunca expor detalhes internos (versão, stack trace) nesses endpoints

---

## Operações em Lote

Para criar ou atualizar múltiplos recursos em uma requisição, use `POST /resources/batch` com array `operations`.

> Ver exemplo completo em [`references/async-patterns.md`](references/async-patterns.md).

- Usar `207 Multi-Status` quando a operação tem resultados parcialmente bem-sucedidos
- Garantir idempotência com `Idempotency-Key` no header da requisição em lote

---

## Soft Delete

Quando recursos removidos precisam ser auditados ou restaurados:

- `DELETE /resources/{id}` retorna `204` e marca o registro como excluído (`deleted_at`)
- Coleções filtram registros excluídos por padrão
- Para incluir excluídos: `GET /resources?include_deleted=true`
- Para restaurar: `POST /resources/{id}/actions/restore`
- Expor `deleted_at` no schema quando o estado importa para o consumidor
- Em tabelas de alto volume, avaliar impacto de performance antes de adotar soft delete

---

## Referências

- Ver `../security/SKILL.md` para autenticação e autorização em APIs
- [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0)
- [Microsoft Azure REST API Guidelines](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design)
- [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)
