---
name: python
description: This skill should be used when writing, reviewing, refactoring, or migrating Python code. Covers Python 3.14 as the baseline (3.12+ features usable), PEP 8 conventions, the modern type system (PEP 695 generics, PEP 649 lazy annotations, Protocol, TypedDict, TypeIs, Pydantic v2), async and parallelism (asyncio, free-threading, subinterpreters), t-strings, project structure with uv, and testing with pytest. Use when the user asks to "write Python code", "review Python", "create a Python class", "implement async", "add type hints", "write pytest tests", "use match/case", "configure pyproject.toml", "upgrade to Python 3.14", "migrate to Python 3.14", "use t-strings", "use free-threaded Python", or "use PEP 695 generics".
---

# Python — Convenções e Boas Práticas (3.14.x)

Diretrizes para código Python moderno, idiomático e de fácil manutenção, com **Python 3.14** como
baseline. Recursos de 3.12–3.13 podem ser usados livremente; o que é específico de cada versão está
catalogado em `references/python314-features.md`.

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

Limitar linhas a **88 caracteres** (padrão do `ruff format`). Usar 4 espaços — nunca tabs.

---

## Runtime e Versões

| Linha | Lançada | Status (set/2026) | Notas |
|---|---|---|---|
| **3.14** | out/2025 | atual — bugfix | free-threading (PEP 779) e subinterpretadores (PEP 734) suportados; t-strings; anotações lazy |
| 3.13 | out/2024 | bugfix (fim ~out/2026) | `TypeIs`, defaults de TypeVar, `ReadOnly`; JIT experimental |
| 3.12 | out/2023 | security-only | piso realista para bibliotecas; PEP 695, `@override`, f-strings sem restrição |
| 3.11 | out/2022 | security-only (EOL out/2027) | versão-alvo anterior desta skill |

Fixar a versão em `.python-version` (lido por `uv` e por CI) **e** em `requires-python` no
`pyproject.toml`. Instalar interpretadores com `uv python install 3.14` (`3.14t` para o build
free-threaded). Não gerar código preso a 3.11 sem indício explícito no projeto de que esse é o alvo.

---

## Sistema de Tipos

Anotar **todos os parâmetros e retornos de funções públicas**. Variáveis locais, só quando o tipo não
for óbvio.

```python
def process(items: list[str]) -> dict[str, int]:   # generics built-in — não importar List/Dict
    return {item: len(item) for item in items}

def first[T](items: list[T]) -> T | None:          # genérico — sintaxe PEP 695 (3.12+)
    return items[0] if items else None

def find_user(user_id: int) -> User | None: ...    # `X | None` — nunca Optional/Union
```

Desde o 3.14 as anotações são **lazy por padrão** (PEP 649): forward references funcionam sem aspas e
`from __future__ import annotations` deixou de ser recomendado — só usar se o alvo mínimo for < 3.14.

| Anotação | Quando usar |
|---|---|
| `list[str]`, `dict[str, int]` | Coleções homogêneas |
| `str \| None` | Valor opcional — preferir sobre `Optional[str]` |
| `str \| int` | União de tipos — preferir sobre `Union[str, int]` |
| `def f[T](...)`, `class C[T]` | Função/classe genérica — sintaxe PEP 695 |
| `type X = ...` | Alias de tipo: união ou estrutura recorrente |
| `Protocol` | Duck typing com verificação estática |
| `TypedDict` | Dicionários com estrutura conhecida |
| `TypeIs[T]` | Predicado que estreita o tipo nos dois ramos do `if` |
| `@override` | Método que sobrescreve o da superclasse |
| `Final` | Constantes que não podem ser reatribuídas |
| `Literal` | Conjunto fixo de valores aceitos |
| `Any` | Interop com código não tipado — evitar em código novo |

Referência completa — PEP 695, PEP 649, `TypeIs`, Protocol, TypedDict, dataclasses, Pydantic v2 — em
**`references/type-hints.md`**.

---

## Novidades 3.11 → 3.14

| Recurso | Desde | Resumo |
|---|---|---|
| Sintaxe `def f[T]` / `class C[T]` / `type X =` (PEP 695) | 3.12 | Genéricos sem `TypeVar` explícito nem `Generic[T]` |
| `@override` | 3.12 | Erro estático se o método da superclasse mudar de nome ou sumir |
| f-strings sem restrição (PEP 701) | 3.12 | Reúso de aspas, aninhamento, multilinha, barra invertida |
| `TypeIs` | 3.13 | Estreitamento de tipo nos dois ramos, ao contrário de `TypeGuard` |
| `warnings.deprecated` | 3.13 | Obsolescência com efeito em runtime + type checker |
| Anotações lazy (PEP 649/749) | 3.14 | Forward refs sem aspas; `from __future__ import annotations` obsoleto |
| t-strings (PEP 750) | 3.14 | `Template` separa estático de interpolado — habilita processador que parametriza SQL / escapa HTML |
| `except A, B:` (PEP 758) | 3.14 | Múltiplos tipos de exceção sem parênteses (quando não há `as`) |
| Free-threading suportado (PEP 779) | 3.14 | Build `python3.14t` sem GIL deixa de ser experimental |
| Subinterpretadores (PEP 734) | 3.14 | `concurrent.interpreters` — paralelismo de CPU sem IPC |
| `compression.zstd` (PEP 784) | 3.14 | Zstandard na stdlib; `tarfile`/`zipfile`/`shutil` |
| Debug e introspecção remotos | 3.14 | `python -m pdb -p PID`, `python -m asyncio ps\|pstree PID` |

Exemplos de cada recurso e o **checklist de migração a partir do 3.11** em
**`references/python314-features.md`**.

---

## Estrutura de Projeto

Layout `src/`: pacote em `src/meu_pacote/` (`models.py`, `services.py`, `repositories.py`,
`exceptions.py`), testes em `tests/` (`conftest.py` com fixtures compartilhadas, subdivisão `unit/` e
`integration/`), metadados/deps/config de ferramentas centralizados em `pyproject.toml` (`[project]`,
`[dependency-groups]`, `[tool.ruff]`, `[tool.mypy]` com `strict = true`, `[tool.pytest.ini_options]`).
Dependências resolvidas em `uv.lock` versionado — dispensa `requirements.txt` pinado.

```toml
[project]
name = "meu-projeto"
requires-python = ">=3.14"
dependencies = ["pydantic>=2.12", "httpx>=0.27"]
```

Setup completo (uv, ruff, pre-commit, Docker) em **`references/tooling.md`**.

---

## Boas Práticas Essenciais

| Padrão | Regra | Exemplo compacto |
|---|---|---|
| Context managers | `with` para todo recurso; múltiplos num só `with (...)` | `with open(p, encoding="utf-8") as f:` |
| Comprehensions | Preferir a `map`/`filter` em transformações simples; vale para dict e set | `{w: len(w) for w in words}` |
| Generator expressions | Evitam materializar a lista inteira | `sum(len(line) for line in file)` |
| f-strings | Para interpolação de saída — **exceto** SQL/HTML com dado externo (usar t-string) | `f"Pi ≈ {value:.2f}"` |
| t-strings | Dado externo em SQL/HTML/shell — passar o `Template` a um processador que faz binding/escape | `as_query(t"WHERE id = {uid}")` |
| Walrus `:=` | Só quando remove duplicação real (while, comprehension) | `while chunk := f.read(8192):` |
| Generators vs listas | Generator para iteração única/grandes volumes; lista para acesso aleatório e `len()` | `yield line.strip()` |

Exemplos completos em **`references/patterns.md`**.

---

## Tratamento de Erros

Capturar do mais específico para o mais geral, sempre encadeando a causa com `from`; definir hierarquia
própria de exceções de domínio:

```python
class AppError(Exception): ...
class NotFoundError(AppError): ...

try:
    result = int(user_input)
except ValueError as exc:
    raise InvalidInputError(f"Valor inválido: {user_input!r}") from exc
```

- **PEP 758 (3.14):** múltiplos tipos sem parênteses quando não há `as` — `except TimeoutError,
  ConnectionRefusedError:`.
- **PEP 765 (3.14):** `return`/`break`/`continue` dentro de `finally` emitem `SyntaxWarning` —
  engolem a exceção em andamento; nunca usar.
- Erros de tarefas paralelas: `except*` com `ExceptionGroup`, tipicamente vindo de `asyncio.TaskGroup`
  — ver `references/concurrency.md`.
- Nunca engolir exceções silenciosamente (ver Anti-Patterns).

---

## Anti-Patterns

| Anti-Pattern | Padrão Python Correto |
|---|---|
| `f"... {user_input} ..."` para montar SQL ou HTML | `t"..."` + binding do driver / `html.escape` — ver `domains/security` |
| `from __future__ import annotations` em projeto 3.14-only | Desnecessário; força o modo string antigo e quebra introspecção em runtime (Pydantic, dataclasses) |
| `TypeVar("T")` + `Generic[T]` em código novo | Sintaxe PEP 695: `def f[T](...)`, `class C[T]`, `type X = ...` |
| `Optional[X]` / `Union[A, B]` | `X \| None` / `A \| B` |
| `except Exception: pass` | Logar e relançar ou tratar explicitamente |
| `from module import *` | Importações explícitas: `from module import Foo, Bar` |
| Mutável como default arg `def f(x=[])` | `def f(x: list \| None = None): x = [] if x is None else x` |
| `type(x) == int` | `isinstance(x, int)` |
| Concatenar strings em loop `s += item` | `"".join(items)` |
| `open()` sem `with` | Sempre `with open(...) as f` |
| Checar `if len(lista) == 0` | `if not lista:` |
| `print()` para logging | `import logging; logger.info(...)` |
| Variáveis globais mutáveis | Injeção de dependência / encapsulamento |
| Ignorar type hints em código novo | Anotar parâmetros e retornos de funções públicas |

---

## Ferramentas

| Ferramenta | Uso |
|---|---|
| `uv` | Pacotes, venv e versão do Python — substitui pip/pyenv/pipx; `uv.lock` versionado, `uv sync --frozen` em CI |
| `ruff` | Lint + formatação num binário — substitui black/isort/flake8/pyupgrade |
| `mypy --strict` | Type checking em CI (alternativas: `pyright`; `ty` da Astral em preview) |
| `pytest` | Testes — ver `references/testing.md` |
| `python -m asyncio ps\|pstree PID` | Introspecção de tasks de um processo async vivo (3.14) |
| `python -m pdb -p PID` | Anexar debugger a processo em execução (3.14) |

Configuração de referência (`pyproject.toml`, pre-commit, Docker) em **`references/tooling.md`**.

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/type-hints.md`** | PEP 695, PEP 649, `@override`, `TypeIs`, Protocol, TypedDict, dataclasses, Pydantic v2 |
| **`references/python314-features.md`** | Novidades 3.11 → 3.14 em detalhe + o que muda ao subir de 3.11 |
| **`references/patterns.md`** | match/case, ExceptionGroup/except*, tomllib, Self, walrus, comprehensions, context managers |
| **`references/concurrency.md`** | asyncio (TaskGroup, timeout, Queue), free-threading (PEP 779), subinterpretadores (PEP 734) |
| **`references/testing.md`** | pytest, fixtures, parametrize, mocking, cobertura, execução free-threaded |
| **`references/tooling.md`** | uv, ruff, mypy/pyright, `pyproject.toml`, pre-commit, Docker |

---

## Também consultar

- `domains/api-rest/SKILL.md` — APIs REST com FastAPI/Flask/Django REST
- `domains/database/SKILL.md` — acesso a banco com SQLAlchemy / asyncpg
- `domains/security/SKILL.md` — validação de input, autenticação, proteção contra injeções (t-strings)
