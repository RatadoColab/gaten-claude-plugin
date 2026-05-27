---
name: api-rest
description: This skill should be used when designing or implementing REST APIs. Covers HTTP verbs, status codes, URL patterns, versioning, request/response contracts, and REST best practices.
version: 0.1.0
---

# API REST — Padrões e Boas Práticas

## Visão Geral

Diretrizes para design e implementação de APIs REST consistentes, previsíveis e fáceis de consumir.

## Princípios Fundamentais

- **Recursos como substantivos:** URLs representam recursos, não ações (`/users`, não `/getUsers`)
- **Verbos HTTP corretos:** GET (leitura), POST (criação), PUT/PATCH (atualização), DELETE (remoção)
- **Stateless:** Cada requisição contém todas as informações necessárias
- **Respostas consistentes:** Mesma estrutura de envelope em todas as respostas

## Status Codes

- `200 OK` — sucesso geral
- `201 Created` — recurso criado
- `204 No Content` — sucesso sem corpo de resposta
- `400 Bad Request` — erro de validação do cliente
- `401 Unauthorized` — não autenticado
- `403 Forbidden` — autenticado, mas sem permissão
- `404 Not Found` — recurso não encontrado
- `422 Unprocessable Entity` — dados válidos mas regra de negócio falhou
- `500 Internal Server Error` — erro não tratado no servidor

## Padrões de URL

```
GET    /resources          → listar
POST   /resources          → criar
GET    /resources/{id}     → buscar um
PUT    /resources/{id}     → substituir
PATCH  /resources/{id}     → atualizar parcialmente
DELETE /resources/{id}     → remover
GET    /resources/{id}/sub → sub-recurso
```

## Versionamento

Prefixar a URL com a versão: `/api/v1/resources`

## Referências

- Ver `domains/security/SKILL.md` para autenticação e autorização em APIs
