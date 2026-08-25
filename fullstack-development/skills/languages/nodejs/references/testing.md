# Node.js — Test Runner Nativo (node:test)

Guia completo do test runner embutido — dispensa Jest/Mocha na maioria dos projetos.

---

## Estrutura Básica

```js
import { describe, it, before, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

describe('UserService', () => {
  let service;

  before(() => { service = new UserService(fakeRepo); });
  beforeEach(() => { fakeRepo.reset(); });

  it('retorna usuário existente', async () => {
    const user = await service.findById('1');
    assert.equal(user.name, 'Ana');
  });

  it('lança em usuário inexistente', async () => {
    await assert.rejects(() => service.findById('999'), /não encontrado/);
  });
});
```

Executar: `node --test` (descobre `*.test.js` recursivamente) ou `node --test src/user.test.js` para um arquivo. Testes aninhados aguardam automaticamente conclusão dos filhos desde a 24 — evita o erro clássico "test did not finish before its parent".

## Hooks Disponíveis

| Hook | Escopo |
|---|---|
| `before` / `after` | Uma vez por `describe` (ou arquivo, no nível superior) |
| `beforeEach` / `afterEach` | Antes/depois de cada `it` |

## Mocking

```js
import { mock } from 'node:test';

const fetchMock = mock.method(httpClient, 'get', async () => ({ status: 200, data: [] }));
// ... exercitar código que chama httpClient.get
assert.equal(fetchMock.mock.callCount(), 1);
mock.reset();   // restaura todos os mocks registrados
```

`mock.fn()` cria uma função espiã isolada; `mock.method()` substitui um método de objeto existente preservando a referência original para restauração. Mock timers:

```js
const { mock } = require('node:test');
mock.timers.enable({ apis: ['setTimeout', 'Date'] });
mock.timers.tick(1000);   // avança tempo virtual sem esperar de verdade
```

## Snapshot Testing

```js
it('formata relatório', (t) => {
  t.assert.snapshot(buildReport(data));
});
```

Rodar com `node --test --test-update-snapshots` na primeira execução para gravar o snapshot; execuções seguintes comparam e falham em divergência.

## Coverage

```bash
node --test --experimental-test-coverage --test-coverage-exclude='**/*.test.js'
node --test --experimental-test-coverage --test-reporter=lcov --test-reporter-destination=coverage.lcov
```

Gera relatório de cobertura nativo baseado em V8 — sem Istanbul/NYC como dependência.

## Watch Mode

```bash
node --test --watch
```

Reexecuta apenas os arquivos afetados pela mudança. `--test-randomize`/`--test-random-seed` não são suportados junto com `--watch` — usar em execução única (CI) para detectar dependência de ordem entre testes.

## Reporters

```bash
node --test --test-reporter=spec                    # saída legível, padrão local
node --test --test-reporter=tap                      # formato TAP, integração com ferramentas externas
node --test --test-reporter=junit --test-reporter-destination=report.xml   # CI que consome JUnit XML
```

## Testes de Integração HTTP

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from '../src/server.js';

test('GET /users/:id retorna 200', async () => {
  const server = createServer();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();

  const res = await fetch(`http://localhost:${port}/users/1`);
  assert.equal(res.status, 200);

  server.close();
});
```

Subir o servidor real na porta `0` (o SO escolhe uma porta livre) e usar `fetch` global — dispensa `supertest` para testes de rota simples.
