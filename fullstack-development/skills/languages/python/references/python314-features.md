# Python — Novidades 3.11 → 3.14

Recursos introduzidos entre a linha antiga (3.11) e o baseline atual (3.14), com exemplos de uso.
Organizado pela versão de introdução — todos disponíveis no 3.14.

Para o que **quebra** ao subir de 3.11, ver a seção final **"O que muda ao subir de 3.11"**.

---

## PEP 695 — Sintaxe de Parâmetros de Tipo (3.12)

Declaração inline de genéricos — `def f[T](...)`, `class C[T]`, `type Alias[T] = ...` — sem `TypeVar`/
`ParamSpec`/`TypeVarTuple` explícitos nem `Generic[T]`. Suporta bounds (`[T: Number]`), constraints
(`[T: (int, float)]`) e variância inferida. O escopo do parâmetro é a própria assinatura/corpo.

Preferir esta forma em todo código novo; a sintaxe legada (`T = TypeVar("T")` + `Generic[T]`) só
permanece para ler código anterior a 3.12.

> Exemplos completos (bounds, constraints, `**P`, sintaxe legada) em **`type-hints.md`**.

---

## `@override` (3.12) — PEP 698

`from typing import override` — marca um método como sobrescrita deliberada. O type checker acusa erro
se o método da superclasse for renomeado ou sumir. Exemplo em **`type-hints.md`**.

---

## PEP 701 — f-strings sem Restrições (3.12)

f-strings passam a aceitar reúso de aspas, aninhamento arbitrário, quebras de linha e barra invertida.

```python
names = {"ana": 3, "bob": 5}
msg = f"total: {sum(names[k] for k in names if k != "bob")}"   # aspas iguais aninhadas — ok
report = f"{
    valor:.2f
} reais"                                                        # multilinha dentro do campo
```

> Continua valendo a regra de sempre usar f-string para interpolação de saída — **exceto** ao montar
> SQL ou HTML com dado externo, onde a t-string (abaixo) é obrigatória.

---

## Tipos — 3.13 (PEP 742, 696, 705)

| Recurso | Efeito | Exemplo em |
|---|---|---|
| `TypeIs[T]` (PEP 742) | Predicado que estreita o tipo **nos dois ramos** do `if` — ao contrário de `TypeGuard` | `type-hints.md` |
| Defaults de TypeVar (PEP 696) | `class Response[T = dict[str, object]]` — parâmetro de tipo com valor padrão | `type-hints.md` |
| `ReadOnly` em TypedDict (PEP 705) | `id: ReadOnly[int]` — chave imutável para o type checker | `type-hints.md` |

---

## `warnings.deprecated` (3.13) — PEP 702

Decorador que marca função, método ou classe como obsoleto — visível para o type checker **e** em
runtime (`DeprecationWarning`). Equivalente Python do `#[\Deprecated]` do PHP.

```python
from warnings import deprecated

@deprecated("Usar `charge(Money)` em vez disso.")
def charge_cents(amount: int) -> None: ...
```

---

## PEP 649 / 749 — Avaliação Tardia de Anotações (3.14)

Anotações de função, classe e módulo deixam de ser avaliadas na definição: ficam guardadas e só são
resolvidas quando algo as lê. **Não** viram strings (isso era o PEP 563 / `from __future__ import
annotations`) — continuam sendo objetos reais.

Consequências práticas:

- Forward references funcionam sem aspas e sem `from __future__ import annotations`.
- Custo de importação cai (anotações caras não são construídas até serem necessárias).
- `from __future__ import annotations` deixa de ser recomendado — só usar se o alvo mínimo ainda for
  < 3.14, ciente de que ele **força** o modo string antigo.

Para ler anotações em runtime, usar o módulo novo `annotationlib` (ou `typing.get_type_hints`), nunca
`__annotations__` cru:

```python
from annotationlib import get_annotations, Format

get_annotations(func)                       # Format.VALUE (padrão) — resolve os tipos
get_annotations(func, format=Format.FORWARDREF)  # nomes indefinidos viram marcadores, não erro
get_annotations(func, format=Format.STRING)      # devolve as anotações como texto
```

Bibliotecas que introspeccionam anotações precisam de versões recentes: **Pydantic ≥ 2.12**,
`typing_extensions` atual. Ver a seção "O que muda ao subir de 3.11".

---

## PEP 750 — Template Strings / t-strings (3.14)

Prefixo `t"..."`. Sintaxe idêntica à da f-string, mas o resultado é um objeto `Template` que **separa
a parte estática da parte interpolada** — a interpolação nunca é concatenada automaticamente. É a base
para montar SQL, HTML e shell com dado externo de forma segura por construção.

```python
from string.templatelib import Template, Interpolation

name = "Camembert"
tmpl = t"Ah! We do have {name}."
tmpl.strings          # ('Ah! We do have ', '.')   — sempre 1 item a mais que os valores
tmpl.values           # ('Camembert',)
list(tmpl)            # ['Ah! We do have ', Interpolation('Camembert', 'name', None, ''), '.']
```

Cada `Interpolation` expõe `.value` (o valor avaliado), `.expression` (o texto entre chaves),
`.conversion` (`'r'`/`'s'`/`'a'` ou `None`) e `.format_spec` — nenhum deles é aplicado
automaticamente; quem processa o template decide.

### Parametrização de SQL

```python
def as_query(tmpl: Template) -> tuple[str, list[object]]:
    sql, params = "", []
    for part in tmpl:
        if isinstance(part, Interpolation):
            sql += "?"                 # cada valor vira placeholder
            params.append(part.value)
        else:
            sql += part                # trecho estático entra literal
    return sql, params

user_input = "abc' OR 1=1 --"
sql, params = as_query(t"SELECT * FROM users WHERE name = {user_input}")
# sql = "SELECT * FROM users WHERE name = ?"   params = ["abc' OR 1=1 --"]
cursor.execute(sql, params)
```

O valor do usuário só existe como `Interpolation.value` — a API nunca o deixa virar fragmento de SQL.

### Escape de HTML

```python
from html import escape

def render(tmpl: Template) -> str:
    out = ""
    for part in tmpl:
        out += escape(str(part.value)) if isinstance(part, Interpolation) else part
    return out

render(t"<p>{comment}</p>")   # o conteúdo de `comment` sai sempre escapado
```

> Ver **`domains/security/SKILL.md`** — a t-string é a defesa recomendada contra A05 (Injection) em
> código Python 3.14+.

---

## PEP 758 — `except` sem Parênteses (3.14)

Múltiplos tipos de exceção dispensam parênteses quando não há cláusula `as`.

```python
try:
    connect()
except TimeoutError, ConnectionRefusedError:      # antes: except (TimeoutError, ConnectionRefusedError)
    retry()

except* ValueError, KeyError:                     # também vale para except*
    ...
```

Com `as`, os parênteses continuam obrigatórios: `except (A, B) as exc:`.

---

## PEP 765 — Aviso de Fluxo em `finally` (3.14)

`return`, `break` ou `continue` que saem de um bloco `finally` emitem `SyntaxWarning` — esse padrão
engole silenciosamente exceções em andamento.

```python
def f():
    try:
        raise ValueError
    finally:
        return 1        # SyntaxWarning — a exceção é descartada sem rastro
```

---

## PEP 734 — Múltiplos Interpretadores na Stdlib (3.14)

Módulo `concurrent.interpreters`: vários interpretadores Python isolados no mesmo processo, cada um com
seu próprio GIL — paralelismo real de CPU sem o custo de IPC do `multiprocessing`. Detalhes e o
`InterpreterPoolExecutor` em **`concurrency.md`**.

---

## PEP 779 — Free-threading Oficialmente Suportado (3.14)

O build sem GIL (`python3.14t`) deixou de ser experimental. Penalidade em código single-thread caiu
para ~5–10%. Continua sendo um build separado, opt-in. Quando usar, como detectar em runtime e o
estado do ecossistema: **`concurrency.md`**.

---

## PEP 784 — Compressão Zstandard (3.14)

Novo pacote `compression` com `compression.zstd` (formato Zstandard) e reexports de `lzma`/`bz2`/
`gzip`/`zlib`. `tarfile`, `zipfile` e `shutil` passam a aceitar zstd.

```python
from compression import zstd

blob = zstd.compress(data)        # nível padrão 3; `level` maior comprime mais e mais devagar
original = zstd.decompress(blob)
```

---

## PEP 768 — Debug Remoto Seguro (3.14)

Interface de baixo overhead para anexar um debugger a um processo em execução por PID, sem reiniciá-lo.

```bash
python -m pdb -p 1234        # anexa ao processo 1234
```

Desligável por `PYTHON_DISABLE_REMOTE_DEBUG` ou `-X disable-remote-debug`.

---

## Introspecção de asyncio (3.14)

```bash
python -m asyncio ps 1234       # tabela de todas as tasks e suas pilhas de corrotina
python -m asyncio pstree 1234   # árvore hierárquica de await; detecta ciclos
```

Não requer instrumentação no código-alvo. Ver **`concurrency.md`**.

---

## `pathlib` — Cópia e Movimentação Recursivas (3.14)

```python
from pathlib import Path

Path("src").copy("dst")            # copia arquivo ou árvore inteira
Path("a.txt").copy_into("backup/") # copia para dentro do diretório
Path("old").move("new")
Path("f.txt").move_into("done/")
```

`Path.info` expõe um `PathInfo` com resultado de `stat` em cache — `iterdir()` já preenche o tipo de
cada entrada, reduzindo syscalls em varreduras.

---

## Miscelânea de stdlib e builtins (3.14)

| Adição | Uso |
|---|---|
| `map(func, *iters, strict=True)` | Erra se os iteráveis tiverem tamanhos diferentes (como `zip`) |
| `operator.is_none` / `is_not_none` | Predicados prontos para `filter`, `takewhile` etc. |
| `heapq.heapify_max` / `heappush_max` / `heappop_max` | Max-heap sem o truque de negar valores |
| `functools.Placeholder` | Reserva posições posicionais em `partial()` |
| `datetime.date.strptime()` / `datetime.time.strptime()` | Parsing direto, sem passar por `datetime.datetime` |
| `float.from_number()` / `complex.from_number()` | Construção a partir de qualquer numérico |
| REPL com syntax highlighting | Ligado por padrão; desligar com `PYTHON_BASIC_REPL` |

---

## Performance (3.12 → 3.14)

- **3.12–3.13:** `sys.monitoring` (tracing de baixo custo), comprehensions inline, per-interpreter GIL.
- **3.13:** JIT experimental (PEP 744) — **não** compilado por padrão; não contar com ele.
- **3.14:** interpretador *tail-call* (Clang 19+) com ~3–5% de ganho no `pyperformance`; especialização
  adaptativa também no build free-threaded.

Nenhuma mudança de código é necessária para colher esses ganhos.

---

## O que muda ao subir de 3.11

Checklist agrupado por severidade. Fonte: `whatsnew/3.14`, seções *Porting* e *Removed*.

### Comportamento em runtime

- **Anotações lazy (PEP 649):** qualquer código que leia `__annotations__` cru, ou que dependa da
  anotação ser avaliada no momento da definição, muda de comportamento. Migrar para
  `annotationlib.get_annotations()` / `typing.get_type_hints()`. Testar Pydantic, dataclasses e
  `attrs` — usar **Pydantic ≥ 2.12**.
- **`multiprocessing` / `ProcessPoolExecutor`:** método de start padrão no Unix passou de `fork` para
  `forkserver` (exceto macOS, que já era `spawn`). Código que dependia de herança implícita de estado
  do processo pai via `fork` precisa passar o estado explicitamente ou fixar
  `multiprocessing.set_start_method("fork")` cientes do risco.
- **`int()` não delega mais a `__trunc__()`:** classes conversíveis para `int` devem implementar
  `__int__()` ou `__index__()`.
- **`NotImplemented` em contexto booleano** agora levanta `TypeError` (era `DeprecationWarning`).
- `asyncio.get_event_loop()` sem loop em execução emite `DeprecationWarning` ao criar um novo —
  migrar para `asyncio.run()` / `asyncio.get_running_loop()`.

### Depreciações a resolver

- `collections.abc.ByteString` — **removido**. Usar `collections.abc.Buffer` ou `bytes | bytearray`.
- `typing.ByteString` — removido.
- `from __future__ import annotations`: não é erro, mas revisar se ainda é necessário; se o alvo
  mínimo for 3.14, remover.
- Vários utilitários já obsoletos saíram de `argparse`, `ast`, `asyncio`, `email`, `importlib.abc`,
  `itertools`, `pathlib`, `pkgutil`, `pty`, `sqlite3`, `urllib` — rodar a suíte com
  `-W error::DeprecationWarning` antes de migrar.

### Extensões C

- Build free-threaded (`python3.14t`) exige que extensões C sejam recompiladas e declarem
  `Py_GIL_DISABLED`. Muitas wheels nativas ainda não publicam variante free-threaded — ver
  **`concurrency.md`**.

---

## Resumo Rápido

| Recurso | Desde | Benefício principal |
|---|---|---|
| Sintaxe `def f[T]` / `class C[T]` / `type X =` (PEP 695) | 3.12 | Genéricos sem `TypeVar` explícito |
| `@override` | 3.12 | Erro estático se o método pai sumir |
| f-strings sem restrição (PEP 701) | 3.12 | Aspas reusadas, aninhamento, multilinha |
| `TypeIs` | 3.13 | Estreitamento de tipo nos dois ramos |
| Defaults de TypeVar (PEP 696) | 3.13 | Parâmetro de tipo com valor padrão |
| `ReadOnly` em TypedDict | 3.13 | Chave imutável para o type checker |
| `warnings.deprecated` | 3.13 | Obsolescência com efeito em runtime |
| Anotações lazy (PEP 649/749) | 3.14 | Forward refs sem aspas; import mais barato |
| t-strings (PEP 750) | 3.14 | SQL/HTML seguro por construção |
| `except A, B:` (PEP 758) | 3.14 | Sem parênteses quando não há `as` |
| `concurrent.interpreters` (PEP 734) | 3.14 | Paralelismo de CPU sem IPC |
| Free-threading suportado (PEP 779) | 3.14 | Build sem GIL deixa de ser experimental |
| `compression.zstd` (PEP 784) | 3.14 | Zstandard na stdlib |
| `python -m pdb -p PID` (PEP 768) | 3.14 | Anexar debugger a processo vivo |
| `python -m asyncio ps\|pstree` | 3.14 | Introspecção de tasks sem instrumentar código |
| `Path.copy/move/copy_into/move_into` | 3.14 | Cópia recursiva sem `shutil` |
