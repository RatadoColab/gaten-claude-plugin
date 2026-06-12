# Status Codes HTTP — Catálogo Detalhado

Catálogo completo de status codes por classe. Resumo dos mais usados fica no `SKILL.md`.
Use sempre o código mais específico disponível — nunca retorne `200 OK` com um erro no corpo.

## 2xx — Sucesso

| Código | Uso                                                   |
|--------|-------------------------------------------------------|
| `200`  | Sucesso geral (GET, PUT, PATCH com corpo)             |
| `201`  | Recurso criado (POST); incluir `Location` no header  |
| `202`  | Requisição aceita para processamento assíncrono       |
| `204`  | Sucesso sem corpo (DELETE, PUT/PATCH sem retorno)     |
| `206`  | Conteúdo parcial (range requests)                     |

## 3xx — Redirecionamento

| Código | Uso                                              |
|--------|--------------------------------------------------|
| `301`  | Recurso movido permanentemente                   |
| `304`  | Not Modified — cliente pode usar cache           |

## 4xx — Erro do cliente

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

## 5xx — Erro do servidor

| Código | Uso                                         |
|--------|---------------------------------------------|
| `500`  | Erro interno não tratado                    |
| `502`  | Bad gateway (proxy/upstream com falha)      |
| `503`  | Serviço indisponível (manutenção, overload) |
| `504`  | Gateway timeout                             |
