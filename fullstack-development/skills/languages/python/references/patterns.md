# Python — Padrões e Idiomas

Catálogo de construções idiomáticas no baseline **Python 3.14**. Para os recursos por versão e a
linha do tempo das mudanças, ver **`python314-features.md`**.

---

## match/case — Structural Pattern Matching

Compara **estrutura**, não apenas valor. Mais poderoso que um `switch`.

### Literal e wildcard

```python
def http_status(code: int) -> str:
    match code:
        case 200:
            return "OK"
        case 404:
            return "Not Found"
        case 500:
            return "Internal Server Error"
        case _:                       # wildcard — caso padrão
            return "Unknown"
```

### Capture patterns

```python
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

### Guard clauses

```python
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

### Mapping patterns — dicionários

```python
def handle_event(event: dict[str, object]) -> str:
    match event:
        case {"type": "click", "x": x, "y": y}:      # chaves extras são ignoradas
            return f"click at ({x}, {y})"
        case {"type": "keypress", "key": key}:
            return f"key pressed: {key}"
        case {"type": type_name}:
            return f"unknown event: {type_name}"
        case _:
            return "malformed event"
```

### Class patterns — dataclasses e classes

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

### OR patterns

```python
def is_whitespace(c: str) -> bool:
    match c:
        case " " | "\t" | "\n" | "\r":
            return True
        case _:
            return False
```

---

## ExceptionGroup e except*

`ExceptionGroup` agrupa várias exceções numa só. `except*` captura subconjuntos por tipo sem impedir o
processamento dos demais — pode haver vários `except*` no mesmo `try`, e todos os tipos
correspondentes são processados.

```python
def validate_form(data: dict[str, object]) -> None:
    errors: list[Exception] = []
    if not data.get("name"):
        errors.append(ValueError("name is required"))
    if not data.get("email"):
        errors.append(ValueError("email is required"))
    if data.get("age", 0) < 0:
        errors.append(ValueError("age must be non-negative"))
    if errors:
        raise ExceptionGroup("validation errors", errors)

try:
    validate_form({"name": "", "email": "", "age": -1})
except* ValueError as eg:
    for exc in eg.exceptions:
        print(f"  - {exc}")
```

A fonte mais comum de `ExceptionGroup` é `asyncio.TaskGroup` — ver **`concurrency.md`**. No 3.14 o
`except*` também dispensa parênteses para múltiplos tipos: `except* ValueError, KeyError:`.

---

## tomllib — Leitura de TOML

```python
import tomllib
from pathlib import Path

def load_config(project_root: Path) -> dict[str, object]:
    with open(project_root / "pyproject.toml", "rb") as f:   # modo binário obrigatório
        return tomllib.load(f)

config = tomllib.loads('[app]\ndebug = false\nmax_connections = 10\n')
config["app"]["max_connections"]   # 10
```

> `tomllib` é somente leitura. Para escrever TOML, usar o pacote externo `tomli-w`.

---

## Self — Métodos que Retornam a Própria Classe

```python
from typing import Self
from dataclasses import dataclass, replace

@dataclass(frozen=True)
class QueryBuilder:
    table: str
    conditions: tuple[str, ...] = ()
    limit: int | None = None

    def where(self, condition: str) -> Self:        # Self garante o tipo correto em subclasses
        return replace(self, conditions=(*self.conditions, condition))

    def take(self, n: int) -> Self:
        return replace(self, limit=n)

    def build(self) -> str:
        sql = f"SELECT * FROM {self.table}"
        if self.conditions:
            sql += " WHERE " + " AND ".join(self.conditions)
        if self.limit is not None:
            sql += f" LIMIT {self.limit}"
        return sql

query = QueryBuilder("users").where("active = TRUE").where("age >= 18").take(20).build()
```

> Anotar o retorno como `"QueryBuilder"` quebraria a tipagem em subclasses. `Self` sempre resolve para
> a classe atual.

---

## Walrus Operator `:=`

Usar **apenas** quando elimina uma duplicação real de chamada. Evitar em expressões aninhadas que
reduzem a leitura.

```python
import re

with open("large_file.txt") as f:
    while chunk := f.read(8192):            # sem walrus, seria preciso ler antes e dentro do loop
        process(chunk)

if m := re.search(r"\d+", line):
    print(f"found number: {m.group()}")

values = [1, None, 3, None, 5]
cleaned = [y for x in values if (y := x or 0) > 0]      # [1, 3, 5]
```

---

## Comprehensions e Generators

```python
{w: len(w) for w in words}                              # dict comprehension
{tag for post in posts for tag in post.tags}           # set comprehension
sum(len(line) for line in file)                         # generator — não materializa a lista
```

| Escolha | Regra |
|---|---|
| Comprehension × `map`/`filter` | Preferir comprehension em transformações simples |
| Generator × lista | Generator para iteração única / grandes volumes; lista para acesso aleatório e `len()` |
| `any(...)` / `all(...)` com generator | Curto-circuita — não construir a lista antes |

---

## Context Managers

```python
with open(path, encoding="utf-8") as f:                 # sempre `with` para recursos
    data = f.read()

with (                                                   # múltiplos num só `with` (3.10+)
    open("in.txt", encoding="utf-8") as src,
    open("out.txt", "w", encoding="utf-8") as dst,
):
    dst.write(src.read())
```

```python
from contextlib import contextmanager

@contextmanager
def timed(label: str):
    start = perf_counter()
    try:
        yield
    finally:
        logger.info("%s levou %.3fs", label, perf_counter() - start)
```
