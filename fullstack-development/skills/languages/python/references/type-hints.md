# Python — Sistema de Tipos e Type Hints

Guia de anotações de tipo no baseline **Python 3.14**, com exemplos práticos. Para a linha do tempo
das mudanças (PEP 695, PEP 649, `TypeIs`), ver **`python314-features.md`**.

---

## Anotações em 3.14 (PEP 649 / 749)

Desde o 3.14 as anotações são avaliadas **tardiamente** por padrão: só são resolvidas quando algo as
lê. Continuam sendo objetos reais — não viram strings.

```python
# Forward reference funciona sem aspas e sem import de __future__
class Node:
    def __init__(self, value: int, next: Node | None = None) -> None:
        self.value = value
        self.next = next
```

**`from __future__ import annotations`** (PEP 563) deixou de ser recomendado:

- Só usar se o alvo mínimo do projeto ainda for **< 3.14**.
- Ele **força** o modo antigo — todas as anotações viram string — o que quebra bibliotecas que
  introspeccionam tipos em runtime (Pydantic, dataclasses, FastAPI antigos).
- Em projeto 3.14-only, remover o import.

Para ler anotações em runtime, nunca acessar `__annotations__` cru:

```python
from annotationlib import get_annotations, Format
from typing import get_type_hints

get_type_hints(Item)                              # resolve os tipos (uso mais comum)
get_annotations(func, format=Format.FORWARDREF)   # nomes indefinidos viram marcador, não NameError
```

---

## Built-in Types como Genéricos

Usar os tipos built-in diretamente. Não importar `List`, `Dict`, `Tuple`, `Set` de `typing`.

```python
def process(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}

def coordinates() -> tuple[float, float]:
    return (1.0, 2.0)

def parse_scores(raw: str) -> tuple[int, ...]:     # tupla homogênea de tamanho variável
    return tuple(int(x) for x in raw.split(","))

def group(items: list[dict[str, str]]) -> dict[str, list[str]]:   # genéricos aninhados
    result: dict[str, list[str]] = {}
    for item in items:
        result.setdefault(item["key"], []).append(item["value"])
    return result
```

| Tipo | Forma atual | Forma legada (`typing`) |
|---|---|---|
| Lista | `list[str]` | `List[str]` |
| Dicionário | `dict[str, int]` | `Dict[str, int]` |
| Tupla | `tuple[int, str]` | `Tuple[int, str]` |
| Conjunto | `set[float]` | `Set[float]` |
| Frozenset | `frozenset[str]` | `FrozenSet[str]` |

---

## Union e Optional

```python
def find_user(user_id: int) -> User | None: ...    # preferir sobre Optional[User]
def parse(value: str | int | bytes) -> str: ...    # preferir sobre Union[str, int, bytes]
```

`Optional[X]` é exatamente `X | None`; `Union[A, B]` é `A | B`. Usar sempre a forma com `|` em código
novo. `Optional`/`Union` só permanecem para ler código antigo.

---

## Genéricos — Sintaxe PEP 695 (3.12+)

Declarar o parâmetro de tipo entre colchetes na própria função, classe ou alias. Sem `TypeVar` solto,
sem herdar `Generic[T]`.

```python
def first[T](items: list[T]) -> T | None:
    return items[0] if items else None

class Stack[T]:
    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> None:
        self._items.append(item)

    def pop(self) -> T:
        return self._items.pop()

    def peek(self) -> T | None:
        return self._items[-1] if self._items else None

stack: Stack[int] = Stack()
stack.push(42)
value: int = stack.pop()

type Pair[T] = tuple[T, T]                          # alias genérico
type Json = None | bool | int | float | str | list["Json"] | dict[str, "Json"]  # recursivo
```

### Bounds e constraints

```python
def clamp[T: Number](value: T, lo: T, hi: T) -> T:      # bound: T é subtipo de Number
    return max(lo, min(value, hi))

def coerce[T: (int, float, str)](raw: str, kind: type[T]) -> T:   # constraints: um dos três
    return kind(raw)
```

### Defaults de parâmetro de tipo (PEP 696, 3.13+)

```python
class Response[T = dict[str, object]]:              # Response sem argumento == Response[dict[str, object]]
    def __init__(self, body: T) -> None:
        self.body = body
```

### Variância e `ParamSpec`

Variância é **inferida** automaticamente na sintaxe PEP 695 — não declarar `covariant`/`contravariant`
à mão. Para assinatura de callables preservada, usar `**P`:

```python
def with_logging[**P, R](fn: Callable[P, R]) -> Callable[P, R]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        logger.info("calling %s", fn.__name__)
        return fn(*args, **kwargs)
    return wrapper
```

### Sintaxe legada (só para ler código anterior a 3.12)

```python
from typing import TypeVar, Generic

T = TypeVar("T")
class Box(Generic[T]): ...          # equivalente a `class Box[T]`
```

### Variadic generics — `TypeVarTuple`

Para preservar os tipos de uma coleção de tamanho variável (frameworks de pipeline, `zip` tipado).
Avançado — usar só em código de biblioteca de baixo nível; em código de aplicação, preferir `Protocol`
ou um genérico simples.

```python
def pipeline[*Ts](*steps: *Ts) -> tuple[*Ts]:      # sintaxe PEP 695 para *Ts
    return steps
```

---

## `@override` (3.12+)

```python
from typing import override

class SqlRepository(Repository):
    @override
    def save(self, entity: object) -> None:        # erro estático se `save` sumir do pai
        ...
```

---

## `TypeIs` × `TypeGuard`

`TypeIs` refina o tipo **nos dois ramos**; `TypeGuard` só no ramo verdadeiro. Usar `TypeIs` por padrão.

```python
from typing import TypeIs

def is_str_list(val: list[object]) -> TypeIs[list[str]]:
    return all(isinstance(x, str) for x in val)

if is_str_list(items):
    " ".join(items)          # items: list[str]
else:
    items.append(42)         # items: list[object]
```

---

## Protocol — Duck Typing Estático

Verificação estrutural, sem herança nem import da interface pela classe concreta.

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Drawable(Protocol):
    def draw(self, x: int, y: int) -> None: ...
    def bounds(self) -> tuple[int, int, int, int]: ...

class Circle:                                        # não herda de Drawable
    def __init__(self, radius: int) -> None:
        self.radius = radius
    def draw(self, x: int, y: int) -> None: ...
    def bounds(self) -> tuple[int, int, int, int]:
        return (0, 0, self.radius * 2, self.radius * 2)

def render_all(shapes: list[Drawable]) -> None:
    for shape in shapes:
        shape.draw(0, 0)

assert isinstance(Circle(5), Drawable)              # só funciona com @runtime_checkable
```

Protocol genérico usa a mesma sintaxe PEP 695: `class Container[T](Protocol): ...`.

---

## TypedDict

```python
from typing import TypedDict, Required, NotRequired, ReadOnly

class UserDict(TypedDict):                          # todas as chaves obrigatórias
    id: int
    name: str
    email: str

class UpdatePayload(TypedDict, total=False):        # todas opcionais
    name: str
    email: str

class EventDict(TypedDict):                         # misto
    id: ReadOnly[int]                               # imutável para o type checker (3.13+)
    title: Required[str]
    description: NotRequired[str]
    tags: NotRequired[list[str]]
```

---

## Dataclasses

```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class Product:
    name: str
    price: float
    tags: list[str] = field(default_factory=list)   # default mutável
    created_at: datetime = field(default_factory=datetime.now)

    def __post_init__(self) -> None:
        if self.price < 0:
            raise ValueError(f"price must be non-negative, got {self.price}")

@dataclass(frozen=True, slots=True)                  # imutável, hashable, sem __dict__
class Point:
    x: float
    y: float

    def distance_to(self, other: Point) -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5
```

| Característica | `@dataclass` | `NamedTuple` |
|---|---|---|
| Mutável | Sim (padrão) | Não |
| `__post_init__` | Sim | Não |
| `field(default_factory=)` | Sim | Não |
| Compatível com tuple | Não | Sim |
| `frozen=True` / `slots=True` | Sim | N/A (sempre imutável) |

---

## Pydantic v2

Usar **Pydantic ≥ 2.12** no Python 3.14 (versões anteriores não lidam com anotações lazy da PEP 649).

```python
from pydantic import BaseModel, field_validator, model_validator, Field
from datetime import datetime

class Address(BaseModel):
    street: str
    city: str
    zip_code: str = Field(pattern=r"^\d{5}-\d{3}$")

class User(BaseModel):
    id: int
    name: str = Field(min_length=2, max_length=100)
    email: str
    age: int = Field(ge=0, le=150)
    address: Address | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        if "@" not in value:
            raise ValueError("invalid email format")
        return value.lower()

    @model_validator(mode="after")
    def check_minor(self) -> User:
        if self.age < 18 and self.address is None:
            raise ValueError("minors must have an address")
        return self

user = User(id=1, name="Carlos", email="CARLOS@Example.com", age=25)
user.email                       # "carlos@example.com"
user.model_dump()                # dict
user.model_dump_json()           # str
User.model_validate(raw_dict)    # parse (substitui .parse_obj() da v1)
```

---

## Typing Extras

```python
from typing import Literal, Final, ClassVar, Annotated

Mode = Literal["read", "write", "append"]
def open_file(path: str, mode: Mode = "read") -> None: ...

MAX_SIZE: Final = 1000                              # não pode ser reatribuída

class Config:
    DEBUG: ClassVar[bool] = False                   # atributo de classe, não de instância
    instance_value: int                             # atributo de instância

# Annotated: metadados no tipo (Pydantic, FastAPI)
PositiveInt = Annotated[int, Field(gt=0)]
NonEmptyStr = Annotated[str, Field(min_length=1)]
```

---

## Tabela de Referência Rápida

| Necessidade | Anotação | Quando usar |
|---|---|---|
| Coleção homogênea | `list[str]`, `set[int]` | Tipo único de elemento |
| Mapeamento | `dict[str, Any]` | Chave-valor |
| Valor opcional | `X \| None` | Campo ou retorno pode ser `None` |
| Múltiplos tipos | `str \| int \| bytes` | União de tipos distintos |
| Função/classe genérica | `def f[T]`, `class C[T]` | Reutilização preservando o tipo |
| Alias de tipo | `type Nome = ...` | Nomear união ou estrutura recorrente |
| Estreitar tipo | `-> TypeIs[T]` | Predicado que refina nos dois ramos |
| Sobrescrita explícita | `@override` | Método que sobrescreve o da superclasse |
| Interface estrutural | `Protocol` | Duck typing com checagem estática |
| Dict com schema fixo | `TypedDict` | Resposta de API, configuração |
| Data model simples | `@dataclass` | Agrupamento de campos relacionados |
| Data model imutável | `@dataclass(frozen=True, slots=True)` | Value objects |
| Data model + validação | `pydantic.BaseModel` | Input externo, APIs |
| Conjunto fixo de valores | `Literal["a", "b"]` | Parâmetros com opções fixas |
| Constante ireatribuível | `Final` | Configurações, limites |
