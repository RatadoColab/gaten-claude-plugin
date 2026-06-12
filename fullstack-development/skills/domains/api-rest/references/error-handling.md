# Tratamento de Erros — RFC 9457 (detalhado)

Padrão **RFC 9457 (Problem Details for HTTP APIs)** com `Content-Type: application/problem+json`.
Resumo no `SKILL.md`.

## Campos obrigatórios

| Campo    | Tipo   | Descrição                                               |
|----------|--------|---------------------------------------------------------|
| `type`   | string | URI que identifica o tipo do problema (pode ser relativa) |
| `title`  | string | Resumo legível, invariante para o tipo do problema      |
| `status` | number | Código HTTP refletido no corpo (ajuda proxies/logs)     |
| `detail` | string | Explicação específica desta ocorrência                  |

> Nota: O RFC 9457 define apenas `type` como obrigatório (com default `about:blank`). Os campos `title`, `status` e `detail` são exigidos por convenção interna deste projeto.

## Campos opcionais

| Campo      | Tipo   | Descrição                                       |
|------------|--------|-------------------------------------------------|
| `instance` | string | URI da requisição que causou o problema         |
| `errors`   | array  | Lista de erros de validação campo a campo       |

## Exemplo — erro de validação (`400`)

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

## Exemplo — recurso não encontrado (`404`)

```json
{
  "type": "https://api.exemplo.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "User with id '42' does not exist.",
  "instance": "/api/v1/users/42"
}
```
