# Python — Padrões Assíncronos com asyncio

Guia de concorrência assíncrona em Python 3.11+ com asyncio.

---

## Modelo de Concorrência

| Abordagem | Quando usar | Limitação |
|---|---|---|
| `asyncio` | I/O-bound: HTTP, banco, arquivos | Não paraleliza CPU |
| `threading` | I/O-bound com libs bloqueantes (sem suporte async) | GIL em CPU-bound |
| `multiprocessing` | CPU-bound: cálculo, imagem, ML | Overhead de IPC |
| `concurrent.futures` | Pool de threads ou processos com interface uniforme | API síncrona |

> Regra geral: usar `asyncio` para I/O-bound. Para CPU-bound, usar `ProcessPoolExecutor` integrado ao loop com `run_in_executor`.

---

## async/await — Fundamentos

```python
import asyncio
import httpx

# Coroutine: function defined with async def
async def fetch_user(client: httpx.AsyncClient, user_id: int) -> dict:
    # await suspends this coroutine until the response arrives
    # the event loop runs other tasks while waiting
    response = await client.get(f"/users/{user_id}")
    response.raise_for_status()
    return response.json()

# Entry point (3.7+): always use asyncio.run() — never call loop.run_until_complete()
async def main() -> None:
    async with httpx.AsyncClient(base_url="https://api.example.com") as client:
        user = await fetch_user(client, 42)
        print(user)

asyncio.run(main())
```

---

## Tasks — Execução Concorrente

### asyncio.create_task()

```python
import asyncio

async def task_a() -> str:
    await asyncio.sleep(1)   # simulates I/O
    return "result A"

async def task_b() -> str:
    await asyncio.sleep(2)
    return "result B"

async def run_concurrently() -> None:
    # create_task schedules coroutines to run concurrently
    ta = asyncio.create_task(task_a(), name="task-a")
    tb = asyncio.create_task(task_b(), name="task-b")

    # await both — total time ~2s, not 3s
    a, b = await asyncio.gather(ta, tb)
    print(a, b)
```

### asyncio.gather()

```python
async def fetch_many(ids: list[int]) -> list[dict]:
    async with httpx.AsyncClient() as client:
        # gather runs all coroutines concurrently and returns results in order
        results = await asyncio.gather(
            *[fetch_user(client, uid) for uid in ids],
            return_exceptions=True,   # errors become values, not exceptions
        )

    # filter out errors
    users = []
    for uid, result in zip(ids, results):
        if isinstance(result, Exception):
            logger.error("failed to fetch user %d: %s", uid, result)
        else:
            users.append(result)

    return users
```

### asyncio.wait() — Controle Fino

```python
import asyncio

async def run_with_first_result(coros) -> None:
    tasks = {asyncio.create_task(c) for c in coros}

    # FIRST_COMPLETED: proceed as soon as one task finishes
    done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)

    for task in done:
        print("first result:", task.result())

    # cancel remaining tasks
    for task in pending:
        task.cancel()

    await asyncio.gather(*pending, return_exceptions=True)
```

---

## Timeout

### asyncio.wait_for() — Timeout em Coroutine

```python
import asyncio

async def slow_operation() -> str:
    await asyncio.sleep(10)
    return "done"

async def with_timeout() -> str | None:
    try:
        result = await asyncio.wait_for(slow_operation(), timeout=5.0)
        return result
    except asyncio.TimeoutError:
        print("operation timed out")
        return None
```

### asyncio.timeout() — Context Manager (3.11)

```python
import asyncio

async def fetch_with_deadline(url: str) -> bytes:
    async with asyncio.timeout(30.0):   # raises TimeoutError if exceeded
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            return response.content

# Adjustable deadline
async def fetch_adaptable(url: str, deadline: float) -> bytes | None:
    try:
        async with asyncio.timeout(deadline):
            async with httpx.AsyncClient() as client:
                r = await client.get(url)
                return r.content
    except TimeoutError:
        return None
```

---

## Async Context Managers

```python
import asyncio
from contextlib import asynccontextmanager

# Implementing __aenter__ / __aexit__ manually
class AsyncDBConnection:
    async def __aenter__(self) -> "AsyncDBConnection":
        await self._connect()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        await self._disconnect()

    async def _connect(self) -> None:
        await asyncio.sleep(0.1)   # simulates connection

    async def _disconnect(self) -> None:
        await asyncio.sleep(0.01)

    async def query(self, sql: str) -> list[dict]:
        await asyncio.sleep(0.05)  # simulates query
        return []

# Using asynccontextmanager decorator (simpler)
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

# Usage
async def main() -> None:
    async with managed_connection("postgresql://localhost/mydb") as conn:
        rows = await conn.query("SELECT * FROM users")
```

---

## Async Generators

```python
import asyncio
from typing import AsyncGenerator

# Async generator: yields items as they arrive (streaming)
async def stream_records(batch_size: int = 100) -> AsyncGenerator[dict, None]:
    offset = 0
    while True:
        # fetch one batch at a time — no need to load all into memory
        batch = await fetch_batch(offset=offset, limit=batch_size)
        if not batch:
            return
        for record in batch:
            yield record
        offset += batch_size

# Consuming with async for
async def process_all() -> None:
    async for record in stream_records(batch_size=50):
        await process_record(record)

# Collecting into a list when needed
async def collect() -> list[dict]:
    return [r async for r in stream_records()]
```

---

## asyncio.Queue — Produtor/Consumidor

```python
import asyncio
from asyncio import Queue

SENTINEL = object()   # sentinel value to signal shutdown

async def producer(queue: Queue, items: list[str]) -> None:
    for item in items:
        await queue.put(item)
        await asyncio.sleep(0.1)   # simulate work between items
    await queue.put(SENTINEL)      # signal completion

async def consumer(queue: Queue, worker_id: int) -> list[str]:
    results: list[str] = []
    while True:
        item = await queue.get()
        if item is SENTINEL:
            await queue.put(SENTINEL)  # pass sentinel to next consumer
            break
        results.append(f"worker-{worker_id}: processed {item}")
        queue.task_done()
    return results

async def producer_consumer_example() -> None:
    queue: Queue[str | object] = Queue(maxsize=10)
    data = ["item-1", "item-2", "item-3", "item-4", "item-5"]

    # Start producer and multiple consumers concurrently
    await asyncio.gather(
        producer(queue, data),
        consumer(queue, worker_id=1),
        consumer(queue, worker_id=2),
    )
```

---

## Exemplo Completo — Scraper Assíncrono

Web scraper com rate limiting, timeout por requisição e cancelamento gracioso.

```python
from __future__ import annotations

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
    rate_limit_rps: float = 5.0           # requests per second
    _semaphore: asyncio.Semaphore = field(init=False)
    _interval: float = field(init=False)

    def __post_init__(self) -> None:
        self._semaphore = asyncio.Semaphore(self.max_concurrency)
        self._interval = 1.0 / self.rate_limit_rps

    async def _fetch_one(
        self,
        client: httpx.AsyncClient,
        url: str,
    ) -> ScrapeResult:
        # rate limiting via semaphore + sleep
        async with self._semaphore:
            start = datetime.now()
            try:
                async with asyncio.timeout(self.timeout_per_request):
                    response = await client.get(url)
                elapsed = (datetime.now() - start).total_seconds() * 1000
                return ScrapeResult(
                    url=url,
                    status=response.status_code,
                    body_size=len(response.content),
                    elapsed_ms=elapsed,
                )
            except TimeoutError:
                return ScrapeResult(
                    url=url, status=0, body_size=0,
                    elapsed_ms=self.timeout_per_request * 1000,
                    error="timeout",
                )
            except httpx.RequestError as exc:
                return ScrapeResult(
                    url=url, status=0, body_size=0, elapsed_ms=0,
                    error=str(exc),
                )
            finally:
                # throttle: ensure minimum interval between requests
                await asyncio.sleep(self._interval)

    async def run(self) -> list[ScrapeResult]:
        async with httpx.AsyncClient(
            follow_redirects=True,
            headers={"User-Agent": "scraper/1.0"},
        ) as client:
            tasks = [
                asyncio.create_task(self._fetch_one(client, url), name=url)
                for url in self.urls
            ]

            # gather with return_exceptions=True prevents one failure
            # from cancelling all other tasks
            raw = await asyncio.gather(*tasks, return_exceptions=True)

        results: list[ScrapeResult] = []
        for url, result in zip(self.urls, raw):
            if isinstance(result, Exception):
                logger.error("unexpected error scraping %s: %s", url, result)
                results.append(ScrapeResult(url=url, status=0, body_size=0,
                                            elapsed_ms=0, error=str(result)))
            else:
                results.append(result)

        return results


async def main() -> None:
    urls = [
        "https://httpbin.org/get",
        "https://httpbin.org/status/404",
        "https://httpbin.org/delay/2",
    ]

    scraper = Scraper(urls=urls, max_concurrency=5, rate_limit_rps=3.0)
    results = await scraper.run()

    for r in results:
        if r.error:
            logger.warning("%s — error: %s", r.url, r.error)
        else:
            logger.info("%s — %d (%d bytes, %.0fms)", r.url, r.status,
                        r.body_size, r.elapsed_ms)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
```
