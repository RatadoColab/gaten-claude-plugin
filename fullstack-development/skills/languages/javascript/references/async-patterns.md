# Async Patterns — Referência Detalhada

Padrões de programação assíncrona em JavaScript: event loop, Promises, async/await e cancelamento.

---

## Event Loop

O JavaScript é single-threaded. O event loop gerencia a execução assíncrona através de filas com prioridades distintas.

```
┌─────────────────────────────────────┐
│           Call Stack                │  ← execução síncrona (LIFO)
│  [ main() → fetchUser() → ... ]     │
└──────────────────┬──────────────────┘
                   │ tarefas I/O, timers, eventos
                   ▼
┌─────────────────────────────────────┐
│            Web APIs / Node APIs      │  ← setTimeout, fetch, fs, events
│  (execução fora da call stack)       │
└──────────────────┬──────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌───────────────┐   ┌──────────────────┐
│ Microtask Queue│   │  Callback Queue  │
│ (Promises,     │   │  (setTimeout,    │
│  queueMicrotask│   │   setInterval,   │
│  MutationObs.) │   │   I/O callbacks) │
└───────┬───────┘   └────────┬─────────┘
        │  PRIORIDADE ALTA   │  prioridade normal
        └──────────┬─────────┘
                   ▼
          Microtasks são drenadas completamente
          antes de qualquer callback da fila normal
```

### Por que Promises têm prioridade sobre setTimeout

```js
console.log('1 - sync start');

setTimeout(() => console.log('4 - timeout callback'), 0);

Promise.resolve()
    .then(() => console.log('2 - microtask 1'))
    .then(() => console.log('3 - microtask 2'));

console.log('1b - sync end');

// Output order: 1 → 1b → 2 → 3 → 4
// Microtask queue is fully drained before callback queue is processed
```

---

## Promise Chains

```js
// Basic chain — each .then receives the return of the previous
fetch('/api/user/1')
    .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();                  // next .then receives parsed JSON
    })
    .then(user => {
        return fetch(`/api/posts?author=${user.id}`);
    })
    .then(res => res.json())
    .then(posts => console.log(posts))
    .catch(err => console.error('Error:', err))   // catches any error above
    .finally(() => hideSpinner());                // always runs

// Anti-pattern: pyramid of doom (nested .then instead of chained)
fetch('/api/user/1')
    .then(res => res.json()
        .then(user => fetch(`/api/posts?author=${user.id}`)   // nested — avoid
            .then(res => res.json()
                .then(posts => console.log(posts))
            )
        )
    );
```

---

## async/await

### Conversão de Promise Chain para async/await

```js
// Promise chain version
function loadUserPosts(userId) {
    return fetch(`/api/users/${userId}`)
        .then(res => { if (!res.ok) throw new Error(res.status); return res.json(); })
        .then(user => fetch(`/api/posts?author=${user.id}`))
        .then(res => res.json());
}

// async/await version — same semantics, better readability
async function loadUserPosts(userId) {
    const userRes = await fetch(`/api/users/${userId}`);
    if (!userRes.ok) throw new Error(userRes.status);

    const user = await userRes.json();

    const postsRes = await fetch(`/api/posts?author=${user.id}`);
    return postsRes.json();
}
```

### Top-level await (ES2022 — apenas em módulos ES)

```js
// Available at module top level — no async wrapper needed
// file: config.js (must be an ES module)
const config = await fetch('/api/config').then(r => r.json());
export default config;
```

> Top-level `await` bloqueia a inicialização do módulo — usar com moderação, apenas para dados essenciais ao bootstrap.

---

## Error Handling

### try/catch em async

```js
async function fetchData(url) {
    try {
        const res = await fetch(url);

        if (!res.ok) {
            throw new HttpError(res.status, res.statusText);
        }

        return await res.json();
    } catch (err) {
        if (err instanceof HttpError && err.status === 404) {
            return null;   // known case — return empty
        }
        throw err;         // unknown error — re-throw for caller
    }
}
```

### Custom Error Classes

```js
// Base application error
class AppError extends Error {
    constructor(message, code) {
        super(message);
        this.name = this.constructor.name;   // 'AppError' instead of 'Error'
        this.code = code;
        Error.captureStackTrace?.(this, this.constructor);
    }
}

// Specific domain errors
class HttpError extends AppError {
    constructor(status, statusText) {
        super(`HTTP ${status}: ${statusText}`, 'HTTP_ERROR');
        this.status = status;
    }
}

class ValidationError extends AppError {
    constructor(field, message) {
        super(message, 'VALIDATION_ERROR');
        this.field = field;
    }
}

// Error type discrimination
async function saveUser(data) {
    try {
        await api.post('/users', data);
    } catch (err) {
        if (err instanceof ValidationError) {
            showFieldError(err.field, err.message);
        } else if (err instanceof HttpError && err.status === 409) {
            showError('Email already in use');
        } else {
            logToMonitoring(err);
            showGenericError();
        }
    }
}
```

---

## Promise Combinators

### Promise.all — Paralelo, Falha Rápida

```js
// All must succeed — rejects immediately if any fails
try {
    const [user, settings, notifications] = await Promise.all([
        fetchUser(id),
        fetchSettings(id),
        fetchNotifications(id),
    ]);
} catch (err) {
    // Any single failure rejects the entire group
}
```

### Promise.allSettled — Paralelo, Coleta Todos os Resultados

```js
// Never rejects — returns array of { status, value/reason }
const results = await Promise.allSettled([
    fetchUser(id),
    fetchSettings(id),
    fetchNotifications(id),
]);

results.forEach(result => {
    if (result.status === 'fulfilled') {
        process(result.value);
    } else {
        logError(result.reason);   // continues despite individual failures
    }
});
```

### Promise.race — Primeiro a Resolver (Sucesso ou Erro)

```js
// Resolves/rejects with the first settled promise
function withTimeout(promise, ms) {
    const timeout = new Promise((_, reject) =>
        setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
    );
    return Promise.race([promise, timeout]);
}

const data = await withTimeout(fetchData(url), 5000);
```

### Promise.any — Primeiro com Sucesso

```js
// Resolves with first fulfilled; rejects only if ALL fail (AggregateError)
const fastestMirror = await Promise.any([
    fetch('https://mirror1.example.com/data'),
    fetch('https://mirror2.example.com/data'),
    fetch('https://mirror3.example.com/data'),
]);
```

| Combinator | Resolve quando | Rejeita quando |
|---|---|---|
| `Promise.all` | Todas cumprem | Qualquer uma falha |
| `Promise.allSettled` | Todas terminam (sucesso ou falha) | Nunca |
| `Promise.race` | Primeira termina | Primeira termina com erro |
| `Promise.any` | Primeira cumpre | Todas falham (`AggregateError`) |

---

## AbortController

Permite cancelar `fetch` e outras operações assíncronas.

```js
// Basic fetch cancellation
function fetchWithCancel(url) {
    const controller = new AbortController();

    const promise = fetch(url, { signal: controller.signal })
        .then(res => res.json());

    // Return both the promise and the cancel function
    return {
        promise,
        cancel: () => controller.abort(),
    };
}

const { promise, cancel } = fetchWithCancel('/api/search?q=test');
cancelButton.addEventListener('click', cancel);

try {
    const data = await promise;
} catch (err) {
    if (err.name === 'AbortError') {
        console.log('Request was cancelled');   // not an error
    } else {
        throw err;
    }
}
```

---

## Exemplo Completo: Busca Paralela com Timeout e Cancelamento

```js
class DataLoader {
    #controller = null;

    // Loads multiple resources in parallel with a shared timeout
    async load(endpoints, timeoutMs = 10_000) {
        // Cancel any previous in-flight request
        this.cancel();
        this.#controller = new AbortController();
        const { signal } = this.#controller;

        // Timeout that cancels via the shared AbortController
        const timeoutId = setTimeout(() => this.#controller.abort(), timeoutMs);

        try {
            const requests = endpoints.map(url =>
                fetch(url, { signal }).then(res => {
                    if (!res.ok) throw new HttpError(res.status, res.statusText);
                    return res.json();
                })
            );

            // allSettled so one failure doesn't cancel the rest
            const results = await Promise.allSettled(requests);

            return results.map((r, i) => ({
                endpoint: endpoints[i],
                data: r.status === 'fulfilled' ? r.value : null,
                error: r.status === 'rejected' ? r.reason : null,
            }));
        } catch (err) {
            if (err.name === 'AbortError') throw new Error('Request timed out or cancelled');
            throw err;
        } finally {
            clearTimeout(timeoutId);
        }
    }

    cancel() {
        this.#controller?.abort();
    }
}

// Usage
const loader = new DataLoader();
const results = await loader.load(['/api/users', '/api/products'], 5000);
results.forEach(({ endpoint, data, error }) => {
    if (error) console.error(`Failed ${endpoint}:`, error);
    else processData(data);
});
```
