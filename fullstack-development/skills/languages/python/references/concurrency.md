# Python — Concorrência e Paralelismo

Guia de concorrência no baseline **Python 3.14**: asyncio para I/O, e as duas novidades de paralelismo
de CPU — free-threading (PEP 779) e subinterpretadores (PEP 734).

---

## Escolha do Modelo

| Abordagem | Quando usar | Limitação |
|---|---|---|
| `asyncio` | I/O-bound: HTTP, banco, arquivos, filas | Não paraleliza CPU dentro de um interpretador |
| `threading` | I/O-bound com libs bloqueantes sem API async | Com GIL, não paraleliza CPU |
| `multiprocessing` / `ProcessPoolExecutor` | CPU-bound, isolamento forte, libs não thread-safe | Overhead de IPC e serialização |
| `concurrent.interpreters` (3.14, PEP 734) | CPU-bound com menos overhead que processos | Modelo novo; troca de objetos limitada |
| Build free-threaded `python3.14t` (PEP 779) | CPU-bound com memória compartilhada real | Build separado; wheels nativas ainda parciais |

Regra geral: **`asyncio` para I/O-bound**. Para CPU-bound, hoje o caminho estável ainda é
`ProcessPoolExecutor`; free-threading e subinterpretadores são adoção antecipada (ver ressalvas
adiante).

---

## async/await — Fundamentos

```python
import asyncio
import httpx

async def fetch_user(client: httpx.AsyncClient, user_id: int) -> dict:
    response = await client.get(f"/users/{user_id}")   # suspende; o loop roda outras tasks
    response.raise_for_status()
    return response.json()

async def main() -> None:
    async with httpx.AsyncClient(base_url="https://api.example.com") as client:
        user = await fetch_user(client, 42)
        print(user)

asyncio.run(main())        # sempre asyncio.run() — nunca loop.run_until_complete()
```

---

## asyncio.TaskGroup — Concorrência Estruturada (preferir)

`TaskGroup` (3.11+) é a forma **preferida** de rodar tasks concorrentes: espera todas, cancela as
demais se uma falhar, e agrega as falhas num `ExceptionGroup`. Preferir a `gather` em código novo.

```python
async def fetch_all(client: httpx.AsyncClient, ids: list[int]) -> list[dict]:
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_user(client, uid)) for uid in ids]
    return [t.result() for t in tasks]        # só chega aqui se todas tiverem sucesso

try:
    users = asyncio.run(fetch_all(client, [1, 2, 3]))
except* httpx.HTTPStatusError as eg:
    for exc in eg.exceptions:
        logger.error("falha HTTP: %s", exc)
```

Usar `gather` apenas quando o objetivo for **coletar resultados e erros lado a lado** sem cancelar o
resto:

```python
results = await asyncio.gather(*coros, return_exceptions=True)
for r in results:
    if isinstance(r, Exception):
        logger.warning("item falhou: %s", r)
```

### asyncio.wait — controle fino

```python
done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
for task in pending:
    task.cancel()
await asyncio.gather(*pending, return_exceptions=True)
```

---

## Timeout

```python
async def with_deadline(url: str) -> bytes | None:
    try:
        async with asyncio.timeout(30.0):        # 3.11+ — preferir a wait_for
            async with httpx.AsyncClient() as client:
                return (await client.get(url)).content
    except TimeoutError:
        return None
```

`asyncio.wait_for(coro, timeout=5.0)` continua válido para envolver uma única corrotina.

---

## Async Context Managers e Generators

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def managed_connection(dsn: str):
    conn = await create_connection(dsn)
    try:
        yield conn
    except Exception:
        await conn.rollback()
        raise
    finally:
        await conn.close()

async def stream_records(batch_size: int = 100):
    offset = 0
    while batch := await fetch_batch(offset=offset, limit=batch_size):
        for record in batch:
            yield record
        offset += batch_size

async def consume() -> None:
    async for record in stream_records(batch_size=50):
        await process(record)
```

---

## asyncio.Queue — Produtor/Consumidor

Desde o **3.13**, `Queue.shutdown()` encerra a fila de forma limpa — dispensa o sentinela manual.

```python
from asyncio import Queue, QueueShutDown

async def producer(queue: Queue[str], items: list[str]) -> None:
    for item in items:
        await queue.put(item)
    queue.shutdown()                          # 3.13+ — sinaliza fim a todos os consumidores

async def consumer(queue: Queue[str], worker_id: int) -> None:
    while True:
        try:
            item = await queue.get()
        except QueueShutDown:
            return
        await handle(item)
        queue.task_done()

async def run() -> None:
    queue: Queue[str] = Queue(maxsize=10)
    async with asyncio.TaskGroup() as tg:
        tg.create_task(producer(queue, ["a", "b", "c"]))
        for wid in range(3):
            tg.create_task(consumer(queue, wid))
```

---

## Outras adições de asyncio

| Adição | Versão | Uso |
|---|---|---|
| `asyncio.eager_task_factory` | 3.12 | Tasks que começam a rodar já na criação, não no próximo `await` — reduz latência quando muitas terminam sem suspender |
| `Queue.shutdown()` / `QueueShutDown` | 3.13 | Encerramento de fila sem sentinela |
| `create_task(coro, **kw)` | 3.14 | `name`/`context` deixam de ser especiais; `**kw` é repassado ao task factory |
| `python -m asyncio ps PID` / `pstree PID` | 3.14 | Inspecionar tasks e a árvore de `await` de um processo vivo, sem instrumentar o código; `pstree` detecta ciclos |

```python
loop = asyncio.get_running_loop()
loop.set_task_factory(asyncio.eager_task_factory)
```

---

## CPU-bound com o event loop

Não bloquear o loop com trabalho pesado — delegar a um executor:

```python
async def crunch(data: bytes) -> Result:
    loop = asyncio.get_running_loop()
    return await loop.run_in_executor(process_pool, heavy_parse, data)  # ProcessPoolExecutor
```

No Python 3.14, o `ProcessPoolExecutor` usa `forkserver` por padrão no Unix (exceto macOS) — ver
`python314-features.md`, seção de migração.

---

## Free-threading (PEP 779, 3.14)

O build sem GIL (`python3.14t`) passou a ser **oficialmente suportado** no 3.14. Nele, threads Python
executam bytecode em paralelo de verdade — `threading` vira uma opção real para CPU-bound, com memória
compartilhada e sem custo de serialização.

```bash
uv python install 3.14t          # instala o build free-threaded
uv run --python 3.14t app.py
```

```python
import sys
sys._is_gil_enabled()            # False no build free-threaded
```

**Ainda é adoção antecipada — em set/2026:**

- Build **separado**; o `python3.14` padrão continua com GIL.
- Penalidade em código single-thread: ~5–10%.
- Cobertura de wheels nativas parcial (~metade dos pacotes mais baixados que publicam wheel binária
  já publicam a variante free-threaded; o resto compila do source ou não suporta).
- Extensões C precisam ser recompiladas com `Py_GIL_DISABLED` e auditadas para thread-safety.
- Código Python puro que antes contava com a atomicidade implícita do GIL (ex.: `dict`/`list`
  compartilhados sem lock) passa a precisar de `threading.Lock` explícito.

Recomendação: **testar a suíte contra `3.14t` já**; **não** torná-lo o runtime de produção padrão
antes de o ecossistema do projeto estar coberto.

---

## Subinterpretadores (PEP 734, 3.14)

`concurrent.interpreters`: vários interpretadores isolados no mesmo processo, cada um com seu GIL.
Paralelismo de CPU com muito menos overhead que `multiprocessing` e mais isolamento que threads.

```python
from concurrent import interpreters

interp = interpreters.create()
interp.exec("import math; result = math.factorial(50_000)")
interp.close()
```

Integração com o modelo de pools:

```python
from concurrent.futures import InterpreterPoolExecutor

with InterpreterPoolExecutor(max_workers=4) as pool:
    results = list(pool.map(heavy_compute, chunks))
```

**Limitações atuais:** startup não otimizado; troca de objetos entre interpretadores restrita
(primitivos, `bytes`, memoryview via canais); extensões de terceiros em geral ainda incompatíveis.
Também é adoção antecipada — avaliar caso a caso contra `ProcessPoolExecutor`.

---

## Exemplo Completo — Scraper Assíncrono

Web scraper com rate limiting, timeout por requisição e agregação de falhas via `TaskGroup`.

```python
import asyncio
import logging
from dataclasses import dataclass, field
from datetime import datetime

import httpx

logger = logging.getLogger(__name__)


@dataclass
class ScrapeResult:
    url: str
    status: int
    body_size: int
    elapsed_ms: float
    error: str | None = None


@dataclass
class Scraper:
    urls: list[str]
    max_concurrency: int = 10
    timeout_per_request: float = 30.0
    rate_limit_rps: float = 5.0
    _semaphore: asyncio.Semaphore = field(init=False)
    _interval: float = field(init=False)

    def __post_init__(self) -> None:
        self._semaphore = asyncio.Semaphore(self.max_concurrency)
        self._interval = 1.0 / self.rate_limit_rps

    async def _fetch_one(self, client: httpx.AsyncClient, url: str) -> ScrapeResult:
        async with self._semaphore:
            start = datetime.now()
            try:
                async with asyncio.timeout(self.timeout_per_request):
                    response = await client.get(url)
                elapsed = (datetime.now() - start).total_seconds() * 1000
                return ScrapeResult(url, response.status_code, len(response.content), elapsed)
            except TimeoutError:
                return ScrapeResult(url, 0, 0, self.timeout_per_request * 1000, error="timeout")
            except httpx.RequestError as exc:
                return ScrapeResult(url, 0, 0, 0, error=str(exc))
            finally:
                await asyncio.sleep(self._interval)      # throttle

    async def run(self) -> list[ScrapeResult]:
        async with httpx.AsyncClient(follow_redirects=True) as client:
            async with asyncio.TaskGroup() as tg:
                tasks = [
                    tg.create_task(self._fetch_one(client, url), name=url)
                    for url in self.urls
                ]
        return [t.result() for t in tasks]


async def main() -> None:
    scraper = Scraper(
        urls=["https://httpbin.org/get", "https://httpbin.org/delay/2"],
        max_concurrency=5,
        rate_limit_rps=3.0,
    )
    for r in await scraper.run():
        if r.error:
            logger.warning("%s — erro: %s", r.url, r.error)
        else:
            logger.info("%s — %d (%d bytes, %.0fms)", r.url, r.status, r.body_size, r.elapsed_ms)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
```

> `_fetch_one` trata os próprios erros e sempre devolve um `ScrapeResult`, então o `TaskGroup` nunca
> cancela o lote. Para deixar uma falha abortar tudo, remover o `try/except` interno e capturar o
> `ExceptionGroup` em volta do `asyncio.run`.
