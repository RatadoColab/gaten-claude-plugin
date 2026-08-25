# Node.js — Módulos ESM

Detalhamento de resolução de módulos, `exports`/`imports` maps e migração CJS→ESM.

---

## ESM × CJS

| Aspecto | CommonJS (CJS) | ES Modules (ESM) |
|---|---|---|
| Ativação | Padrão sem `"type"` no `package.json`, ou `.cjs` | `"type": "module"` no `package.json`, ou `.mjs` |
| Sintaxe | `require()` / `module.exports` | `import` / `export` |
| Resolução | Extensão opcional, resolve `index.js` de diretório | Extensão **obrigatória** no specifier relativo |
| Top-level await | Não suportado | Suportado nativamente |
| `__dirname`/`__filename` | Disponíveis | Não existem — usar `import.meta.dirname`/`import.meta.filename` |
| Carregamento | Síncrono | Assíncrono internamente (mesmo com specifiers estáticos) |

```js
// CJS
const { readFile } = require('node:fs/promises');
module.exports = { handler };

// ESM equivalente
import { readFile } from 'node:fs/promises';
export { handler };
```

## `require(esm)`

Node permite `require()` carregar um módulo ESM síncrono (sem top-level await) a partir de código CJS — útil para consumir uma dependência ESM-only sem migrar o projeto inteiro de uma vez. Não depender disso como estratégia permanente: bibliotecas novas cada vez mais são ESM-only, e o caminho reverso (ESM importando CJS) sempre funcionou via `import`.

## `exports` e `imports` Maps

`exports` no `package.json` controla precisamente o que é importável de fora do pacote — substitui a exposição implícita de toda a árvore de arquivos:

```json
{
  "exports": {
    ".": "./dist/index.js",
    "./client": "./dist/client.js",
    "./package.json": "./package.json"
  },
  "imports": {
    "#internal/*": "./src/internal/*.js"
  }
}
```

`imports` define subpaths internos ao próprio pacote (prefixo `#`, nunca resolve para fora) — útil para abstrair caminho absoluto/relativo longo em código interno, com resolução condicional por ambiente:

```json
{
  "imports": {
    "#db": { "test": "./src/db.mock.js", "default": "./src/db.js" }
  }
}
```

## Dual Package Hazard

Publicar o mesmo pacote em CJS e ESM simultaneamente pode fazer duas cópias distintas do módulo coexistirem no processo (uma via `require`, outra via `import`) — quebra comparação de identidade (`instanceof`, cache de singleton) porque cada entrypoint carrega uma instância separada. Mitigar com `exports` mapeando `require`/`import` para o **mesmo** arquivo sempre que a lógica permitir, ou publicando ESM-only quando não há razão para suportar CJS.

## Dynamic Import

```js
const feature = await import('./feature.js');           // condicional, code-splitting
const modulePath = process.env.DRIVER === 'pg' ? './pg.js' : './sqlite.js';
const { Driver } = await import(modulePath);
```

Import dinâmico funciona em CJS e ESM, permite path computado em runtime (ao contrário do `import` estático, que exige specifier literal) e é a forma correta de carregar plugin/driver selecionado por configuração.

## `module.register()` — Loader Hooks

API estável para interceptar resolução/carregamento de módulo (transformação em runtime, mock global, suporte a formato customizado):

```js
// loader.js
export async function resolve(specifier, context, nextResolve) {
  return nextResolve(specifier, context);
}
```

```bash
node --import ./register-loader.mjs app.js
```

Usar com moderação — loaders adicionam uma camada de indireção que dificulta debugging; preferir `exports` condicional quando resolver o mesmo problema.

## Migração CJS → ESM

1. `"type": "module"` no `package.json`.
2. Adicionar extensão `.js` em todo `require`/`import` relativo.
3. Substituir `__dirname`/`__filename` por `import.meta.dirname`/`import.meta.filename`.
4. Substituir `module.exports`/`exports.x` por `export`/`export default`.
5. JSON importado via `import data from './data.json' with { type: 'json' }` (import attributes, estável).
6. Rodar `node --test` e `tsc --noEmit` (se TypeScript) para pegar specifier sem extensão.
