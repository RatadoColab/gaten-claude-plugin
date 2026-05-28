# Python — Sistema de Tipos e Type Hints

Guia completo de anotações de tipo em Python 3.11+ com exemplos práticos.

---

## `from __future__ import annotations`

Ativar em todo arquivo que usa anotações de tipo. Transforma todas as anotações em strings avaliadas tardiamente (*lazy evaluation*), eliminando forward references e reduzindo overhead de importação.

```python
from __future__ import annotations

# Without the import, forward references require quotes:
# def clone(self) -> "MyClass": ...

# With the import, no quotes needed even before the class is defined
class Node:
    def __init__(self, value: int, next: Node | None = None) -> None:
        self.value = value
        self.next = next
```

> Sem esse import, anotar o tipo da própria classe dentro dela mesma causaria `NameError` em tempo de definição.

---

## Built-in Types — Sintaxe 3.9+

A partir do Python 3.9, usar os tipos built-in diretamente como genéricos. Não importar `List`, `Dict`, `Tuple`, `Set` do módulo `typing`.

```python
from __future__ import annotations

# Correct (3.9+): built-in generics
def process(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

def coordinates() -> tuple[float, float]:
    return (1.0, 2.0)

def unique_tags(posts: list[dict[str, str]]) -> set[str]:
    return {tag for post in posts for tag in post.get("tags", "").split()}

# Homogeneous tuple of arbitrary length
def parse_scores(raw: str) -> tuple[int, ...]:
    return tuple(int(x) for x in raw.split(","))

# Nested generics
def group_by_key(items: list[dict[str, str]]) -> dict[str, list[str]]:
    result: dict[str, list[str]] = {}
    for item in items:
        key = item["key"]
        result.setdefault(key, []).append(item["value"])
    return result
```

| Tipo | Sintaxe 3.9+ | Antiga (typing) |
|---|---|---|
| Lista | `list[str]` | `List[str]` |
| Dicionário | `dict[str, int]` | `Dict[str, int]` |
| Tupla | `tuple[int, str]` | `Tuple[int, str]` |
| Conjunto | `set[float]` | `Set[float]` |
| Frozenset | `frozenset[str]` | `FrozenSet[str]` |

---

## Union e Optional

```python
from __future__ import annotations
from typing import Optional  # only for pre-3.10 compatibility

# New syntax (3.10+): prefer | over Union and Optional
def find_user(user_id: int) -> User | None: ...

def parse(value: str | int | bytes) -> str: ...

# Optional[X] is exactly equivalent to X | None — avoid in new code
# def find_user(user_id: int) -> Optional[User]: ...  # old style
```

> Regra: usar `X | None` em vez de `Optional[X]` e `A | B` em vez de `Union[A, B]` em todo código Python 3.10+.

---

## TypeVar e Generics

```python
from __future__ import annotations
from typing import TypeVar, Generic

T = TypeVar("T")
K = TypeVar("K")
V = TypeVar("V")

# Generic function: works for any type T
def first(items: list[T]) -> T | None:
    return items[0] if items else None

# Bounded TypeVar: T must be a subclass of Comparable
Comparable = TypeVar("Comparable", int, float, str)

def maximum(a: Comparable, b: Comparable) -> Comparable:
    return a if a > b else b

# Generic class
class Stack(Generic[T]):
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        if not self._items:
            raise IndexError("stack is empty")
        return self._items.pop()

    def peek(self) -> T | None:
        return self._items[-1] if self._items else None

# Usage — mypy infers the type parameter
stack: Stack[int] = Stack()
stack.push(42)
value: int = stack.pop()
```

---

## Protocol — Duck Typing Estático

`Protocol` permite verificação estática baseada em estrutura, sem herança explícita.

```python
from __future__ import annotations
from typing import Protocol, runtime_checkable

# Define the expected interface
@runtime_checkable
class Drawable(Protocol):
    def draw(self, x: int, y: int) -> None: ...
    def get_bounds(self) -> tuple[int, int, int, int]: ...

# These classes don't inherit from Drawable — they just implement the methods
class Circle:
    def __init__(self, radius: int) -> None:
        self.radius = radius

    def draw(self, x: int, y: int) -> None:
        print(f"circle at ({x}, {y}) r={self.radius}")

    def get_bounds(self) -> tuple[int, int, int, int]:
        return (0, 0, self.radius * 2, self.radius * 2)

class Rectangle:
    def __init__(self, width: int, height: int) -> None:
        self.width = width
        self.height = height

    def draw(self, x: int, y: int) -> None:
        print(f"rect at ({x}, {y}) {self.width}x{self.height}")

    def get_bounds(self) -> tuple[int, int, int, int]:
        return (0, 0, self.width, self.height)

# Function accepts any object that satisfies the Drawable protocol
def render_all(shapes: list[Drawable], canvas_x: int, canvas_y: int) -> None:
    for shape in shapes:
        shape.draw(canvas_x, canvas_y)

# isinstance check works with @runtime_checkable
assert isinstance(Circle(5), Drawable)

shapes: list[Drawable] = [Circle(10), Rectangle(20, 30)]
render_all(shapes, 0, 0)
```

> Diferença de ABC: com `Protocol`, as classes **não precisam importar nem herdar** da interface — basta implementar os métodos com as assinaturas corretas.

---

## TypedDict — Dicionários com Estrutura

```python
from __future__ import annotations
from typing import TypedDict, Required, NotRequired

# All fields required by default
class UserDict(TypedDict):
    id: int
    name: str
    email: str

# total=False: all fields optional
class UpdatePayload(TypedDict, total=False):
    name: str
    email: str
    active: bool

# Mixing required and optional (3.11+)
class EventDict(TypedDict):
    id: Required[int]
    title: Required[str]
    description: NotRequired[str]   # optional field
    tags: NotRequired[list[str]]

def create_user(data: UserDict) -> None:
    print(f"creating user {data['name']} <{data['email']}>")

# Valid — all fields provided
user: UserDict = {"id": 1, "name": "Ana", "email": "ana@example.com"}
create_user(user)
```

---

## Dataclasses

```python
from __future__ import annotations
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class Product:
    name: str
    price: float
    tags: list[str] = field(default_factory=list)   # mutable default
    created_at: datetime = field(default_factory=datetime.now)

    def __post_init__(self) -> None:
        # Validation after auto-generated __init__
        if self.price < 0:
            raise ValueError(f"price must be non-negative, got {self.price}")

# frozen=True: immutable — generates __hash__, enables use as dict key
@dataclass(frozen=True)
class Point:
    x: float
    y: float

    def distance_to(self, other: Point) -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

# Comparison with NamedTuple
from typing import NamedTuple

class Coordinate(NamedTuple):
    lat: float
    lon: float
    # NamedTuple: immutable, tuple-compatible, but no __post_init__ or field()
```

| Característica | `@dataclass` | `NamedTuple` |
|---|---|---|
| Mutável | Sim (padrão) | Não |
| `__post_init__` | Sim | Não |
| `field(default_factory=)` | Sim | Não |
| Compatível com tuple | Não | Sim |
| `frozen=True` | Sim | N/A (sempre) |
| Herança | Flexível | Limitada |

---

## Pydantic v2

```python
from __future__ import annotations
from pydantic import BaseModel, field_validator, model_validator, Field
from datetime import datetime

class Address(BaseModel):
    street: str
    city: str
    zip_code: str = Field(pattern=r"^\d{5}-\d{3}$")   # regex validation

class User(BaseModel):
    id: int
    name: str = Field(min_length=2, max_length=100)
    email: str
    age: int = Field(ge=0, le=150)                      # ge=greater_equal, le=less_equal
    address: Address | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    # Field-level validator
    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        if "@" not in value:
            raise ValueError("invalid email format")
        return value.lower()

    # Cross-field validator
    @model_validator(mode="after")
    def validate_model(self) -> User:
        if self.age < 18 and self.address is None:
            raise ValueError("minors must have an address")
        return self

# Automatic validation on instantiation
user = User(id=1, name="Carlos", email="CARLOS@Example.com", age=25)
print(user.email)        # carlos@example.com (normalized)

# Serialize to dict / JSON
data = user.model_dump()
json_str = user.model_dump_json()

# Generate JSON Schema
schema = User.model_json_schema()

# Parse from dict (replaces .parse_obj() from v1)
raw = {"id": 2, "name": "Ana", "email": "ana@example.com", "age": 30}
ana = User.model_validate(raw)
```

---

## Typing Extras

```python
from __future__ import annotations
from typing import Literal, Final, ClassVar, Annotated, get_type_hints

# Literal: restrict to specific values
Mode = Literal["read", "write", "append"]

def open_file(path: str, mode: Mode = "read") -> None: ...

# Final: constant — cannot be reassigned
MAX_SIZE: Final = 1000
# MAX_SIZE = 2000  # mypy error: cannot assign to final

# ClassVar: class-level attribute, not instance
class Config:
    DEBUG: ClassVar[bool] = False
    instance_value: int     # this is an instance attribute

# Annotated: attach metadata to types (used by Pydantic, FastAPI, etc.)
from pydantic import Field

PositiveInt = Annotated[int, Field(gt=0)]
NonEmptyStr = Annotated[str, Field(min_length=1)]

class Item(BaseModel):
    quantity: PositiveInt
    label: NonEmptyStr

# get_type_hints: resolve annotations at runtime
hints = get_type_hints(Item)
# {'quantity': int, 'label': str} — resolved types
```

---

## Tabela de Referência Rápida

| Necessidade | Anotação | Quando usar |
|---|---|---|
| Coleção homogênea | `list[str]`, `set[int]` | Tipo único de elemento |
| Mapeamento | `dict[str, Any]` | Chave-valor |
| Valor opcional | `X \| None` | Campo ou retorno pode ser None |
| Múltiplos tipos | `str \| int \| bytes` | Union de tipos distintos |
| Qualquer tipo | `Any` | Interop com código não tipado |
| Tipo genérico | `TypeVar` + `Generic` | Funções/classes reutilizáveis |
| Interface estrutural | `Protocol` | Duck typing com checagem estática |
| Dict com schema fixo | `TypedDict` | Resposta de API, configuração |
| Data model simples | `@dataclass` | Agrupamento de campos relacionados |
| Data model imutável | `@dataclass(frozen=True)` | Value objects |
| Data model + validação | `pydantic.BaseModel` | Input externo, APIs |
| Valor constante | `Literal["a", "b"]` | Parâmetros com opções fixas |
| Constante ireatribuível | `Final` | Configurações, limites |
