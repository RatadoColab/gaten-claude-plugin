# Node.js — Streams, Workers e Contexto Assíncrono

Backpressure, paralelismo real e propagação de contexto através de chamadas assíncronas.

---

## Web Streams × Node Streams

Node expõe ambas as APIs — Web Streams (`ReadableStream`/`WritableStream`, padrão de browser/fetch) e Node Streams (`stream.Readable`/`Writable`, API histórica, mais rica em recursos). Interoperam via `Readable.toWeb()`/`Writable.fromWeb()`.

| API | Quando usar |
|---|---|
| Web Streams | Código que também roda no browser/edge; consumir `fetch` response body |
| Node Streams | Pipelines de arquivo/processo, precisa de `Transform` customizado, ecossistema `npm` (a maioria assume Node Streams) |

## Backpressure

Backpressure é o mecanismo que impede um produtor rápido de estourar a memória de um consumidor lento — o stream pausa a leitura até o buffer de escrita esvaziar. Encadear `.pipe()` manualmente **não propaga erro** de um estágio para o próximo; usar sempre `pipeline`:

```js
import { pipeline } from 'node:stream/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { createGzip } from 'node:zlib';

await pipeline(
  createReadStream('entrada.log'),
  createGzip(),
  createWriteStream('saida.log.gz'),
);
// erro em qualquer estágio rejeita a Promise e fecha todos os streams — sem vazamento de fd
```

## `Transform` Customizado

```js
import { Transform } from 'node:stream';

const upperCase = new Transform({
  transform(chunk, encoding, callback) {
    callback(null, chunk.toString().toUpperCase());
  },
});
```

Usar `Transform` para processar dado em trânsito (parsing incremental, compressão custom, mascaramento de PII) sem materializar o arquivo inteiro em memória.

## `worker_threads`

CPU-bound (parsing pesado, criptografia, processamento de imagem) bloqueia o event loop se rodado no thread principal — mover para `worker_threads` mantém o servidor respondendo a outras requisições.

```js
// worker.js
import { parentPort, workerData } from 'node:worker_threads';
parentPort.postMessage(heavyComputation(workerData));
```

```js
// main.js
import { Worker } from 'node:worker_threads';

function runWorker(data) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./worker.js', { workerData: data });
    worker.once('message', resolve);
    worker.once('error', reject);
  });
}
```

Para reaproveitar threads entre múltiplas tarefas (evitar custo de criação por chamada), manter um **pool** de workers reutilizáveis em vez de instanciar um novo por requisição. `MessageChannel`/`MessagePort` permitem canal de comunicação direto entre dois workers, sem passar pelo thread principal.

## `child_process` × `cluster`

- `child_process.spawn`/`execFile`: isola um processo externo (CLI, binário de terceiro) — não é para paralelizar código Node.
- `cluster`: bifurca múltiplas cópias do próprio processo Node para usar todos os cores em um servidor HTTP — cada worker tem heap independente (sem estado compartilhado automático, diferente de `worker_threads`).

## `AsyncLocalStorage`

Propaga um valor de contexto (request ID, usuário autenticado, span de trace) através de toda a cadeia de chamadas assíncronas de uma requisição, sem passar parâmetro explícito por cada função:

```js
import { AsyncLocalStorage } from 'node:async_hooks';

const requestContext = new AsyncLocalStorage();

function middleware(req, res, next) {
  requestContext.run({ requestId: crypto.randomUUID() }, next);
}

function logInfo(message) {
  const ctx = requestContext.getStore();
  logger.info(message, { requestId: ctx?.requestId });
}
```

Essencial para logging correlacionado em servidor HTTP concorrente — sem isso, correlacionar log de uma mesma requisição exige passar `requestId` manualmente por toda função da call stack.
