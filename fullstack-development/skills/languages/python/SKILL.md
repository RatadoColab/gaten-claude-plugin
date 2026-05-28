---
name: python
description: This skill should be used when writing, reviewing, or refactoring Python code. Covers Python 3.11+ features, PEP 8 conventions, modern type system (type hints, Protocol, TypedDict, Pydantic v2), async patterns, project structure, testing with pytest, and Python-specific best practices. Use when the user asks to "write Python code", "review Python", "create a Python class", "implement async", "add type hints", "write pytest tests", "use match/case", "configure pyproject.toml", or "upgrade to Python 3.11".
version: 0.2.0
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

```python
# Correct: PEP 8 applied consistently
MAX_CONNECTIONS: int = 10

class UserRepository:
    def find_by_email(self, email: str) -> "User | None":
        ...

def calculate_total(items: list[float], tax_rate: float = 0.0) -> float:
    return sum(items) * (1 + tax_rate)
```

---

## Sistema de Tipos

Anotar **todos os parâmetros e retornos de funções públicas**. Variáveis locais anotar quando o tipo não for óbvio.

```python
from __future__ import annotations  # lazy evaluation — evita forward references

# Built-in generics (3.9+): sem necessidade de importar List, Dict, etc.
def process(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

# Union: nova sintaxe com | (3.10+) — preferir sobre Optional e Union
def find_user(user_id: int) -> User | None: ...
def parse(value: str | int | None) -> str: ...

# Any: usar com moderação — equivale a desativar a checagem de tipo
from typing import Any
def legacy_adapter(data: Any) -> dict[str, Any]: ...
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

```python
# match/case with guard clause (3.10)
match point:
    case (x, y) if x == y:
        print(f"diagonal at {x}")
    case (x, y):
        print(f"point at {x}, {y}")

# ExceptionGroup and except* (3.11)
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(fetch_a())
        tg.create_task(fetch_b())
except* TimeoutError as eg:
    for err in eg.exceptions:
        logger.error("timeout: %s", err)
```

Exemplos completos de cada recurso em **`references/modern-features.md`**.

---

## Estrutura de Projeto

```
meu_projeto/
├── src/
│   └── meu_pacote/
│       ├── __init__.py
│       ├── models.py          # data models (dataclasses, Pydantic)
│       ├── services.py        # business logic
│       ├── repositories.py    # data access layer
│       └── exceptions.py      # custom exception hierarchy
├── tests/
│   ├── conftest.py            # shared fixtures
│   ├── unit/
│   │   └── test_services.py
│   └── integration/
│       └── test_repositories.py
├── pyproject.toml             # project metadata, deps, tool config
└── requirements.txt           # pinned deps for reproducibility
```

```toml
# pyproject.toml — configuração centralizada
[project]
name = "meu-projeto"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["pydantic>=2.0", "httpx>=0.25"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"

[tool.mypy]
python_version = "3.11"
strict = true

[tool.ruff]
line-length = 88
```

---

## Boas Práticas Essenciais

### Context Managers

```python
# Correct: usar with para garantir liberação de recursos
with open("data.csv", encoding="utf-8") as f:
    content = f.read()

# Multiple resources in one with (3.10+: parênteses opcionais)
with (
    open("input.txt") as src,
    open("output.txt", "w") as dst,
):
    dst.write(src.read())
```

### Comprehensions

```python
# List comprehension: preferir a map/filter para transformações simples
squares = [x**2 for x in range(10) if x % 2 == 0]

# Dict comprehension
word_lengths = {word: len(word) for word in words}

# Set comprehension
unique_domains = {email.split("@")[1] for email in emails}

# Generator expression: evita criar lista completa em memória
total = sum(len(line) for line in file)
```

### f-strings

```python
name = "Maria"
value = 3.14159

# Correct: f-string com formatação
print(f"Olá, {name}! Pi ≈ {value:.2f}")

# Debugging (3.8+): = preserva o nome da variável
print(f"{name=}, {value=}")  # name='Maria', value=3.14159

# Multiline (Python 3.12+: f-strings aninhadas)
report = (
    f"Usuário: {name}\n"
    f"Valor: R$ {value:,.2f}\n"
)
```

### Walrus Operator `:=`

```python
# Use in while loops to avoid duplicating the call
while chunk := file.read(8192):
    process(chunk)

# Use in comprehensions to avoid computing twice
results = [y for x in data if (y := transform(x)) is not None]

# Avoid: overusing walrus reduces readability
# Prefer := only when it genuinely removes duplication
```

### Generators vs Listas

```python
# Generator: use when iterating once or handling large datasets
def read_lines(path: str):
    with open(path) as f:
        for line in f:
            yield line.strip()

# List: use when needing random access, len(), or multiple iterations
lines = list(read_lines("data.txt"))
print(f"Total: {len(lines)}")
```

---

## Tratamento de Erros

```python
# Hierarchy: BaseException > Exception > specific errors
# Catch from most specific to most general
try:
    result = int(user_input)
except ValueError as exc:
    raise InvalidInputError(f"Valor inválido: {user_input!r}") from exc
except OverflowError as exc:
    raise InvalidInputError("Número muito grande.") from exc

# Custom exception hierarchy — domain-specific
class AppError(Exception):
    """Base for all application exceptions."""

class NotFoundError(AppError):
    """Resource not found."""

    @classmethod
    def for_user(cls, user_id: int) -> "NotFoundError":
        return cls(f"Usuário #{user_id} não encontrado.")

# except* for ExceptionGroup (3.11) — parallel task errors
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(task_a())
        tg.create_task(task_b())
except* ValueError as eg:
    for exc in eg.exceptions:
        logger.warning("validation error: %s", exc)
except* IOError as eg:
    raise RuntimeError("I/O failure in tasks") from eg.exceptions[0]

# Never silently swallow exceptions
# try:
#     ...
# except Exception:
#     pass  # DON'T DO THIS — log and re-raise
```

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
| **`references/modern-features.md`** | match/case, ExceptionGroup, tomllib, Self, performance 3.11 |
| **`references/async-patterns.md`** | asyncio, async/await, Task, Queue, timeout, exemplo completo |
| **`references/testing.md`** | pytest, fixtures, parametrize, mocking, cobertura |

---

## Também consultar

- `domains/api-rest/SKILL.md` — APIs REST com FastAPI/Flask/Django REST
- `domains/database/SKILL.md` — acesso a banco com SQLAlchemy / asyncpg
- `domains/security/SKILL.md` — validação de input, autenticação, proteção contra injeções
