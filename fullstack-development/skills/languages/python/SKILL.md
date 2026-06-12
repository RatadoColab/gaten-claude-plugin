---
name: python
description: This skill should be used when writing, reviewing, or refactoring Python code. Covers Python 3.11+ features, PEP 8 conventions, modern type system (type hints, Protocol, TypedDict, Pydantic v2), async patterns, project structure, testing with pytest, and Python-specific best practices. Use when the user asks to "write Python code", "review Python", "create a Python class", "implement async", "add type hints", "write pytest tests", "use match/case", "configure pyproject.toml", or "upgrade to Python 3.11".
version: 0.2.1
---

# Python — Convenções e Boas Práticas (3.11+)

Diretrizes para escrita de código Python moderno, idiomático e de fácil manutenção, com base no Python 3.11+.

---

## Convenções PEP 8

| Elemento | Convenção | Exemplo |
|---|---|---|
| Variável | `snake_case` | `user_name`, `total_count` |
| Constante | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Classe | `PascalCase` | `UserService`, `HttpClient` |
| Função / Método | `snake_case` | `get_user()`, `send_email()` |
| Módulo | `snake_case` | `user_service.py`, `http_client.py` |
| Pacote | `lowercase` sem underscore | `mypackage`, `httputils` |
| Parâmetro privado | `_prefixo` (convencional) | `_cache`, `_session` |
| Dunder | `__dunder__` | `__init__`, `__str__` |

Limitar linhas a **88 caracteres** (padrão Black). Usar 4 espaços — nunca tabs.

---

## Sistema de Tipos

Anotar **todos os parâmetros e retornos de funções públicas**. Variáveis locais anotar quando o tipo não for óbvio.

```python
from __future__ import annotations  # lazy evaluation — evita forward references

def process(items: list[str]) -> dict[str, int]:   # built-in generics (3.9+)
    return {item: len(item) for item in items}

def find_user(user_id: int) -> User | None: ...    # | (3.10+) — preferir sobre Optional/Union
```

| Anotação | Quando usar |
|---|---|
| `list[str]`, `dict[str, int]` | Coleções homogêneas — sintaxe 3.9+ |
| `str \| None` | Valor opcional — preferir sobre `Optional[str]` |
| `str \| int` | União de tipos — preferir sobre `Union[str, int]` |
| `Any` | Interoperabilidade com código não tipado — evitar em código novo |
| `TypeVar` | Funções e classes genéricas |
| `Protocol` | Duck typing com verificação estática |
| `TypedDict` | Dicionários com estrutura conhecida |
| `Final` | Constantes que não podem ser reatribuídas |
| `Literal` | Conjunto fixo de valores aceitos |

Para referência completa — TypeVar, Protocol, TypedDict, dataclasses, Pydantic v2 — consultar **`references/type-hints.md`**.

---

## Python 3.10–3.11 — Principais Recursos

| Recurso | Versão | Exemplo compacto |
|---|---|---|
| `match`/`case` | 3.10 | `match cmd: case "quit": sys.exit()` |
| Union com `\|` | 3.10 | `def f(x: int \| str) -> None` |
| `except*` | 3.11 | `except* ValueError as eg: ...` |
| `ExceptionGroup` | 3.11 | `raise ExceptionGroup("erros", [e1, e2])` |
| `tomllib` | 3.11 | `tomllib.load(f)` |
| `Self` type | 3.11 | `def clone(self) -> Self: ...` |
| `TypeVarTuple` | 3.11 | `Ts = TypeVarTuple("Ts")` |
| Fine-grained errors | 3.11 | Traceback aponta subexpressão exata |
| 60% mais rápido | 3.11 | CPython com adaptive interpreter |
| `asyncio.timeout()` | 3.11 | `async with asyncio.timeout(5): ...` |

Exemplos completos de cada recurso em **`references/modern-features.md`**.

---

## Estrutura de Projeto

Layout `src/`: pacote em `src/meu_pacote/` (`models.py`, `services.py`, `repositories.py`, `exceptions.py`), testes em `tests/` (`conftest.py` com fixtures compartilhadas, subdivisão `unit/` e `integration/`), metadados/deps/config de ferramentas centralizados em `pyproject.toml` (`[project]`, `[tool.pytest.ini_options]`, `[tool.mypy]` com `strict = true`, `[tool.ruff]` com `line-length = 88`) e `requirements.txt` com deps pinadas para reprodutibilidade.

```toml
[project]
name = "meu-projeto"
requires-python = ">=3.11"
dependencies = ["pydantic>=2.0", "httpx>=0.25"]
```

---

## Boas Práticas Essenciais

| Padrão | Regra | Exemplo compacto |
|---|---|---|
| Context managers | `with` para todo recurso; múltiplos em um só `with (...)` (3.10+) | `with open(p, encoding="utf-8") as f:` |
| Comprehensions | Preferir a `map`/`filter` em transformações simples; vale para dict e set | `{w: len(w) for w in words}` |
| Generator expressions | Evitam criar lista completa em memória | `sum(len(line) for line in file)` |
| f-strings | Sempre para interpolação; `{var=}` para debugging (3.8+) | `f"Pi ≈ {value:.2f}"` |
| Walrus `:=` | Só quando remove duplicação real (while, comprehension) | `while chunk := f.read(8192):` |
| Generators vs listas | Generator para iteração única/grandes volumes; lista para acesso aleatório e `len()` | `yield line.strip()` |

Exemplos completos (incluindo walrus em comprehensions) em **`references/modern-features.md`**.

---

## Tratamento de Erros

Capturar do mais específico para o mais geral, sempre encadeando a causa com `from`; definir hierarquia própria de exceções de domínio:

```python
class AppError(Exception): ...
class NotFoundError(AppError): ...

try:
    result = int(user_input)
except ValueError as exc:
    raise InvalidInputError(f"Valor inválido: {user_input!r}") from exc
```

Para erros de tarefas paralelas, usar `except*` com `ExceptionGroup` (3.11) — ver `references/modern-features.md`. Nunca engolir exceções silenciosamente (ver Anti-Patterns).

---

## Anti-Patterns

| Anti-Pattern | Padrão Python Correto |
|---|---|
| `except Exception: pass` | Logar e relançar ou tratar explicitamente |
| `from module import *` | Importações explícitas: `from module import Foo, Bar` |
| Mutável como default arg `def f(x=[])` | `def f(x: list \| None = None): x = x or []` |
| `type(x) == int` | `isinstance(x, int)` |
| Concatenar strings em loop `s += item` | `"".join(items)` |
| `open()` sem `with` | Sempre usar `with open(...) as f` |
| Checar `if len(lista) == 0` | `if not lista:` |
| `print()` para logging | `import logging; logger.info(...)` |
| Variáveis globais mutáveis | Injeção de dependência / encapsulamento |
| Ignorar type hints em código novo | Anotar parâmetros e retornos de funções públicas |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/type-hints.md`** | TypeVar, Protocol, TypedDict, dataclasses, Pydantic v2 |
| **`references/modern-features.md`** | match/case, ExceptionGroup, tomllib, Self, walrus, performance 3.11 |
| **`references/async-patterns.md`** | asyncio, async/await, Task, Queue, timeout, exemplo completo |
| **`references/testing.md`** | pytest, fixtures, parametrize, mocking, cobertura |

---

## Também consultar

- `domains/api-rest/SKILL.md` — APIs REST com FastAPI/Flask/Django REST
- `domains/database/SKILL.md` — acesso a banco com SQLAlchemy / asyncpg
- `domains/security/SKILL.md` — validação de input, autenticação, proteção contra injeções
