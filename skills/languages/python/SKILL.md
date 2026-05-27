---
name: python
description: This skill should be used when writing, reviewing, or refactoring Python code. Covers PEP 8 conventions, project structure, common patterns, type hints, and Python-specific best practices.
version: 0.1.0
---

# Python — Convenções e Boas Práticas

## Visão Geral

Diretrizes para escrita de código Python limpo, idiomático e de fácil manutenção.

## Convenções (PEP 8)

- Indentação com 4 espaços
- Nomes de variáveis e funções em `snake_case`
- Classes em `PascalCase`
- Constantes em `UPPER_SNAKE_CASE`
- Linhas com no máximo 88 caracteres (padrão Black)

## Estrutura de Projeto

```
projeto/
├── src/
│   └── modulo/
│       ├── __init__.py
│       ├── models.py
│       ├── services.py
│       └── repositories.py
├── tests/
├── requirements.txt
└── pyproject.toml
```

## Práticas Recomendadas

- **Type hints:** Anotar tipos em funções e variáveis para clareza e análise estática
- **Dataclasses ou Pydantic:** Para modelagem de dados estruturados
- **Context managers:** Usar `with` para recursos que precisam ser liberados
- **List comprehensions:** Preferir a loops explícitos para transformações simples
- **f-strings:** Para formatação de strings (Python 3.6+)

## Referências

- Ver `domains/security/SKILL.md` para práticas de segurança
- Ver `domains/api-rest/SKILL.md` para APIs com FastAPI/Flask/Django REST
