# Paginação — Envelopes e Estratégias (detalhado)

Nunca retorne coleções sem paginação. Resumo das regras no `SKILL.md`; envelopes completos aqui.

## Offset/Page (datasets pequenos e estáticos)

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

## Cursor/Keyset (datasets grandes ou que mudam frequentemente)

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

## Regras gerais

- Defina um `limit` padrão sensato e documente o máximo permitido (ex.: `limit=100` máximo)
- Ordene sempre por campo estável e indexado (geralmente `id` + `created_at`)
- Inclua metadados de paginação sempre na resposta
- Use cursor-based para feeds, timelines e coleções grandes (>10k registros)
