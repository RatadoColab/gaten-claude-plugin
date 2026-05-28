# Python — Recursos Modernos (3.10–3.11)

Guia detalhado dos principais recursos introduzidos nas versões 3.10 e 3.11.

---

## match/case (3.10) — Structural Pattern Matching

O `match`/`case` é mais poderoso que um `switch`: compara **estrutura**, não apenas valor.

### Literal Patterns

```python
# Literal: match against exact values
def http_status(code: int) -> str:
    match code:
        case 200:
            return "OK"
        case 404:
            return "Not Found"
        case 500:
            return "Internal Server Error"
        case _:            # wildcard — default case
            return "Unknown"
```

### Capture Patterns

```python
# Capture: bind matched value to a variable
def describe(point: tuple[int, int]) -> str:
    match point:
        case (0, 0):
            return "origin"
        case (x, 0):
            return f"on x-axis at {x}"
        case (0, y):
            return f"on y-axis at {y}"
        case (x, y):
            return f"at ({x}, {y})"
```

### Guard Clauses

```python
# Guard: add conditional with `if` after the pattern
def classify(value: int) -> str:
    match value:
        case n if n < 0:
            return "negative"
        case 0:
            return "zero"
        case n if n % 2 == 0:
            return "positive even"
        case _:
            return "positive odd"
```

### Mapping Patterns — Dicionários

```python
# Mapping: match dict structure — extra keys are ignored
def handle_event(event: dict) -> str:
    match event:
        case {"type": "click", "x": x, "y": y}:
            return f"click at ({x}, {y})"
        case {"type": "keypress", "key": key}:
            return f"key pressed: {key}"
        case {"type": type_name}:
            return f"unknown event: {type_name}"
        case _:
            return "malformed event"
```

### Class Patterns — Dataclasses e Classes

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float

@dataclass
class Circle:
    center: Point
    radius: float

def describe_shape(shape: object) -> str:
    match shape:
        case Circle(center=Point(x=0, y=0), radius=r):
            return f"circle centered at origin, radius={r}"
        case Circle(center=Point(x=x, y=y), radius=r):
            return f"circle at ({x}, {y}), radius={r}"
        case Point(x=0, y=0):
            return "origin"
        case Point(x=x, y=y):
            return f"point at ({x}, {y})"
        case _:
            return "unknown shape"
```

### OR Patterns

```python
def is_whitespace_char(c: str) -> bool:
    match c:
        case " " | "\t" | "\n" | "\r":
            return True
        case _:
            return False
```

---

## ExceptionGroup e except* (3.11)

`ExceptionGroup` agrupa múltiplas exceções em uma só. `except*` captura subconjuntos por tipo, sem impedir o processamento das demais.

```python
import asyncio

# Creating an ExceptionGroup manually
def validate_form(data: dict) -> None:
    errors: list[Exception] = []

    if not data.get("name"):
        errors.append(ValueError("name is required"))
    if not data.get("email"):
        errors.append(ValueError("email is required"))
    if data.get("age", 0) < 0:
        errors.append(ValueError("age must be non-negative"))

    if errors:
        raise ExceptionGroup("validation errors", errors)

# Catching with except* — runs for each matching type
try:
    validate_form({"name": "", "email": "", "age": -1})
except* ValueError as eg:
    # eg.exceptions: tuple of all ValueError instances captured
    for exc in eg.exceptions:
        print(f"  - {exc}")
except* TypeError as eg:
    print("type errors:", eg.exceptions)

# asyncio.TaskGroup raises ExceptionGroup automatically
async def fetch_all(urls: list[str]) -> None:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]

# If multiple tasks raise, all exceptions are grouped
try:
    asyncio.run(fetch_all(["http://a.com", "http://b.com"]))
except* TimeoutError as eg:
    print(f"{len(eg.exceptions)} requests timed out")
except* ConnectionError as eg:
    print(f"{len(eg.exceptions)} connection errors")
```

> `except*` é diferente de `except`: pode haver múltiplos `except*` no mesmo `try`, e todos os tipos correspondentes são processados, não apenas o primeiro.

---

## tomllib (3.11) — Leitura de TOML

```python
import tomllib
from pathlib import Path

# Reading pyproject.toml
def load_project_config(project_root: Path) -> dict:
    config_path = project_root / "pyproject.toml"

    # tomllib requires binary mode ("rb")
    with open(config_path, "rb") as f:
        return tomllib.load(f)

# Reading from string
raw_toml = b"""
[database]
host = "localhost"
port = 5432
name = "mydb"

[app]
debug = false
max_connections = 10
"""

config = tomllib.loads(raw_toml.decode())
db_host = config["database"]["host"]    # "localhost"
max_conn = config["app"]["max_connections"]  # 10

# Practical example: loading app settings
def get_settings(env: str = "production") -> dict:
    path = Path(f"config/{env}.toml")
    with open(path, "rb") as f:
        return tomllib.load(f)
```

> `tomllib` é somente leitura. Para escrever TOML, usar o pacote externo `tomli-w`.

---

## Self Type (3.11) — Métodos que Retornam a Própria Classe

```python
from __future__ import annotations
from typing import Self
from dataclasses import dataclass, replace

@dataclass(frozen=True)
class QueryBuilder:
    table: str
    conditions: tuple[str, ...] = ()
    limit: int | None = None
    offset: int = 0

    # Self ensures subclasses return the correct type
    def where(self, condition: str) -> Self:
        return replace(self, conditions=(*self.conditions, condition))

    def take(self, n: int) -> Self:
        return replace(self, limit=n)

    def skip(self, n: int) -> Self:
        return replace(self, offset=n)

    def build(self) -> str:
        sql = f"SELECT * FROM {self.table}"
        if self.conditions:
            sql += " WHERE " + " AND ".join(self.conditions)
        if self.limit is not None:
            sql += f" LIMIT {self.limit}"
        if self.offset:
            sql += f" OFFSET {self.offset}"
        return sql

# Fluent builder pattern
query = (
    QueryBuilder("users")
    .where("active = TRUE")
    .where("age >= 18")
    .take(20)
    .skip(40)
    .build()
)
# SELECT * FROM users WHERE active = TRUE AND age >= 18 LIMIT 20 OFFSET 40
```

> Sem `Self`, anotar o retorno como `"QueryBuilder"` quebraria a tipagem em subclasses. `Self` garante que o tipo seja sempre o da classe atual.

---

## Variadic Generics (3.11) — TypeVarTuple

```python
from __future__ import annotations
from typing import TypeVarTuple, Unpack

Ts = TypeVarTuple("Ts")

# Function that preserves the types of all its arguments
def pipeline(*steps: Unpack[Ts]) -> tuple[Unpack[Ts]]:
    return steps  # type: ignore[return-value]

# Practical use: typed zip
from typing import overload

# TypeVarTuple is most useful in low-level library code
# For application code, prefer Protocol or Generic[T] instead
```

> `TypeVarTuple` é avançado — usar principalmente em bibliotecas que precisam preservar tipos de coleções com tamanho variável (ex.: frameworks de pipeline de dados).

---

## Fine-grained Error Locations (3.11)

O Python 3.11 introduziu anotações precisas no traceback, apontando a subexpressão exata que causou o erro.

```python
# Example that raises AttributeError
user = None
name = user.profile.name   # before 3.11: just "line X, AttributeError"
                           # on 3.11+:
# AttributeError: 'NoneType' object has no attribute 'profile'
#     name = user.profile.name
#            ^^^^^^^^^^^^
#                        ^^^^

# Another example with chained calls
result = data["users"][0]["email"].split("@")[1]
# 3.11 traceback highlights exactly which subscript or attribute failed
```

> Nenhuma mudança de código necessária — o benefício é automático. Reduz o tempo de depuração especialmente em expressões encadeadas.

---

## Performance — Python 3.11

O Python 3.11 é aproximadamente **60% mais rápido** que o 3.10 no benchmark pyperformance.

| Técnica interna | Descrição |
|---|---|
| Adaptive interpreter | Especializa bytecode por tipo após N execuções ("specializing") |
| Zero-cost exceptions | `try` sem exceção não tem overhead no caminho feliz |
| Faster calls | Chamadas de função com frame mais leve |
| Inlined comprehensions | List comprehensions sem frame de função adicional |
| Better tracing | `sys.monitoring` substitui `sys.settrace` com menor overhead |

```python
# Zero-cost exceptions: prefer try/except over explicit checking in hot paths
def get_value(d: dict, key: str, default: int = 0) -> int:
    try:
        return d[key]    # fast path — no overhead when key exists
    except KeyError:
        return default

# vs. explicit check (slower in the common case):
# return d[key] if key in d else default  # two lookups
```

---

## Walrus Operator `:=` (3.8)

```python
import re

# Avoiding double function calls in while loops
with open("large_file.txt") as f:
    while chunk := f.read(8192):
        process(chunk)

# In comprehensions: compute once, filter and use result
values = [1, None, 3, None, 5]
cleaned = [y for x in values if (y := x or 0) > 0]
# [1, 3, 5]

# In if chains: assign and test in one expression
if m := re.search(r"\d+", line):
    print(f"found number: {m.group()}")

# Avoid: using := where a regular assignment is clearer
# Bad:
while data := fetch():            # ok
    if result := process(data):   # getting verbose
        store(result)

# Better when legibility suffers:
data = fetch()
while data:
    result = process(data)
    if result:
        store(result)
    data = fetch()
```

> Regra: usar `:=` somente quando **eliminar uma duplicação real** de chamada de função. Evitar em expressões aninhadas que reduzem a leitura.
