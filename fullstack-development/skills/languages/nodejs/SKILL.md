---
name: nodejs
description: This skill should be used when writing, reviewing, or configuring Node.js runtime code — as opposed to JavaScript language syntax. Covers Node.js 26.x (Current) and 24.x LTS APIs, ESM module resolution, native TypeScript execution via type stripping, package.json/npm/pnpm workflows, the built-in test runner (node:test), streams, worker_threads, the permission model, and npm supply-chain security. Use when the user asks to "write a Node.js script", "configure package.json", "use the Node test runner", "run TypeScript natively in Node", "configure the Node permission model", or "harden npm supply chain".
---

# Node.js — Convenções e Boas Práticas (26.x / 24.x LTS)

Diretrizes para o **runtime** Node.js — resolução de módulos, APIs `node:`, toolchain e deploy. Para sintaxe da linguagem (arrow functions, destructuring, classes, async/await), ver `languages/javascript/SKILL.md`; esta skill assume esse conteúdo e cobre apenas o que é específico da plataforma Node.

---

## Runtime e Versões

| Linha | Status (ago/2026) | Notas |
|---|---|---|
| 26.x | Current — vira LTS em out/2026 | Temporal API estável, V8 14.6, Undici 8, type stripping estável |
| 24.x "Krypton" | Active LTS | Baseline recomendado para produção hoje |
| 22.x "Jod" | Maintenance LTS | Suporte só a correções críticas |

Fixar a versão em `engines.node` no `package.json` e em `.nvmrc`/`.node-version`; usar `corepack enable` para fixar o gerenciador de pacotes (`packageManager` no `package.json`) em vez de instalar npm/pnpm/yarn global.

---

## Módulos e Resolução

ESM é o padrão para projeto novo: `"type": "module"` no `package.json`. Specifiers relativos exigem extensão explícita (`./db.js`, nunca `./db`) e módulos nativos exigem o prefixo `node:` (`node:fs`, não `fs`).

```js
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const here = import.meta.dirname;          // substitui __dirname em ESM
const pkg = JSON.parse(await readFile(new URL('./package.json', import.meta.url)));
```

`require(esm)` já é suportado de volta em CJS para consumo pontual, mas não inverter a dependência: bibliotecas novas publicam ESM-only. Para `exports`/`imports` maps, subpaths internos (`#internal/*`) e o dual package hazard, ver **`references/modules-esm.md`**.

---

## TypeScript Nativo (Type Stripping)

Node executa TypeScript apagando anotações de tipo — sem `tsc` gerando saída, sem source maps a distribuir. Estável desde a 24, sem flag.

| Funciona (apagável) | Não funciona (gera código) |
|---|---|
| Anotações de tipo, interfaces, generics | `enum` |
| `as`, `satisfies`, non-null `!` | `namespace` com corpo em runtime |
| Type-only imports | Parameter properties (`constructor(private x)`) |

- Import relativo **sempre** com extensão `.ts`.
- `tsc --noEmit` continua obrigatório em CI — type stripping **não checa tipos**, só remove.
- `tsconfig.json` com `"erasableSyntaxOnly": true` para o editor sinalizar sintaxe incompatível.

Matriz completa por versão, `tsconfig.json` recomendado e quando ainda vale um bundler em **`references/typescript-runtime.md`**.

---

## package.json e Gerenciadores

```json
{
  "type": "module",
  "engines": { "node": ">=24" },
  "packageManager": "pnpm@10.x",
  "scripts": { "test": "node --test", "start": "node --env-file=.env src/index.js" }
}
```

Em CI, sempre `npm ci` (nunca `npm install`) — respeita o lockfile e falha se `package.json`/lockfile divergirem. Build de produção: `npm ci --omit=dev`. Monorepo: workspaces nativos do npm/pnpm em vez de symlink manual. Detalhes de pnpm workspaces, SEA (single executable) e empacotamento em **`references/packaging-deploy.md`**.

---

## APIs Nativas — Antes de Adicionar uma Dependência

| Necessidade | Dependência comum | API nativa equivalente |
|---|---|---|
| Test runner | Jest, Mocha | `node:test` + `node:assert/strict` |
| HTTP client | axios | `fetch` global (Undici) |
| Parse de CLI args | yargs, commander | `util.parseArgs()` |
| Variáveis de ambiente de arquivo | dotenv | `node --env-file=.env` |
| Reload em desenvolvimento | nodemon | `node --watch` |
| UUID | uuid | `crypto.randomUUID()` |
| Data/hora com fuso e calendário | date-fns, moment | `Temporal` (estável na 26) |
| SQLite embarcado | better-sqlite3 | `node:sqlite` |

Cada linha economiza uma dependência de supply chain sem perder funcionalidade — preferir a coluna nativa sempre que cobrir o caso de uso.

---

## Async e Concorrência

`AsyncLocalStorage` propaga contexto (request ID, trace) através de chamadas assíncronas sem passar parâmetro explícito por toda a call stack — essencial para logging correlacionado em servidores HTTP. `worker_threads` para CPU-bound (paralelismo real, sem bloquear o event loop); `child_process` para isolar processos externos; `cluster` para escalar HTTP em múltiplos cores. Sempre tratar backpressure em streams com `stream/promises.pipeline` em vez de encadear `.pipe()` sem checar o retorno.

Padrões completos de `worker_threads` (pool, `MessageChannel`) e streams em **`references/streams-workers.md`**.

---

## Erros e Encerramento

Distinguir erro **operacional** (entrada inválida, timeout de rede — esperado, tratável) de erro **de programação** (bug — deve derrubar o processo). Encadear causa com `Error.cause`; nunca deixar `unhandledRejection` sem handler — ele deve derrubar o processo, não ser ignorado silenciosamente.

```js
process.on('SIGTERM', async () => {
  await server.close();          // para de aceitar novas conexões
  await pool.end();              // drena recursos (DB, filas)
  process.exit(0);
});
```

Graceful shutdown é obrigatório em qualquer processo orquestrado por container/Kubernetes: sem tratar `SIGTERM`, o orquestrador força `SIGKILL` após o grace period e derruba requisições em voo.

---

## Frameworks HTTP

| Framework | Quando usar |
|---|---|
| **Fastify** | Alto throughput, validação por JSON Schema, plugin system tipado |
| **Hono** | Edge runtimes (Cloudflare Workers, Deno, Bun) e bundle mínimo (~5 KB); roda em Node também |
| **NestJS** | Times de 3+ devs, aplicação corporativa grande, DI e módulos como no Angular |
| **Express** | APIs simples, protótipos, times com expertise Express consolidada |

Sem framework nenhum, `node:http` cobre casos simples. Detalhamento de rotas, middleware, contrato de erro e versionamento em `domains/api-rest/SKILL.md`.

---

## Segurança e Supply Chain

`node --permission --allow-fs-read=./data --allow-net=api.example.com server.js` restringe o que o processo pode ler, escrever ou acessar na rede — camada extra contra dependência comprometida, não substitui revisão de dependências.

Práticas mínimas de supply chain: `npm ci` em CI (nunca `install`), lockfile sempre commitado, `--ignore-scripts` para instalar dependências não confiáveis sem rodar `postinstall` arbitrário, `npm audit signatures` para verificar assinatura dos pacotes instalados, e publicação via *trusted publishing* (OIDC do CI, sem token de longa duração) com provenance attestation.

Detalhamento de permission model, provenance e cooldown de versão em **`references/security-supply-chain.md`**; contexto amplo de segurança de aplicação em `domains/security/SKILL.md` e de pipeline em `domains/devsecops/SKILL.md`.

---

## Observabilidade

`diagnostics_channel` expõe eventos internos do runtime (HTTP, DNS, fs) para instrumentação sem patching de módulo; `perf_hooks` mede latência de trechos críticos. Logar sempre estruturado (JSON), nunca `console.log` de string livre em produção. Padrões de métricas, logs e traces em `domains/observability/SKILL.md`.

---

## Anti-Patterns

| Anti-Pattern | Problema | Correção |
|---|---|---|
| `require()` em projeto `"type": "module"` | Quebra resolução ESM | `import` com extensão explícita |
| `__dirname` em arquivo ESM | Não existe em ESM | `import.meta.dirname` |
| `import fs from 'fs'` | Ambíguo com pacote de terceiros de mesmo nome | `import fs from 'node:fs'` |
| Dependência `dotenv` com Node 24+ | Redundante | `node --env-file=.env` |
| `npm install` em pipeline de CI | Pode alterar o lockfile silenciosamente | `npm ci` |
| `unhandledRejection` sem handler | Processo pode ficar em estado inconsistente | Handler explícito que loga e derruba o processo |
| API síncrona (`fs.readFileSync`) no caminho de uma requisição | Bloqueia o event loop, derruba throughput | Versão `async`/`promises` |
| `.pipe()` sem checar backpressure | Estoura memória com produtor mais rápido que consumidor | `stream/promises.pipeline` |
| Container rodando como root | Superfície de ataque desnecessária | `USER node` na imagem |
| Imagem base `node:latest` | Build não reprodutível, atualiza sem aviso | Tag de versão fixa (`node:24-alpine`) |
| Sem tratamento de `SIGTERM` | Kubernetes mata o processo à força, requisições em voo se perdem | Graceful shutdown com `server.close()` |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/modules-esm.md`** | ESM × CJS, `exports`/`imports` maps, dual package hazard, migração, dynamic import |
| **`references/typescript-runtime.md`** | Type stripping detalhado, `tsconfig.json` recomendado, matriz de compatibilidade por versão |
| **`references/testing.md`** | `node:test` completo: hooks, mocks, mock timers, snapshots, coverage, `--watch` |
| **`references/streams-workers.md`** | Web Streams × Node Streams, backpressure, `worker_threads`, `AsyncLocalStorage` |
| **`references/packaging-deploy.md`** | `package.json`, pnpm workspaces, SEA, Dockerfile multi-stage, `--permission` em produção |
| **`references/security-supply-chain.md`** | Permission model, `ignore-scripts`, provenance, trusted publishing OIDC, SBOM |

---

## Também consultar

- `languages/javascript/SKILL.md` — sintaxe da linguagem (ES6+, async/await, classes) usada dentro do runtime Node
- `domains/api-rest/SKILL.md` — contrato de API REST, versionamento, tratamento de erro HTTP
- `domains/security/SKILL.md` — segurança de aplicação (XSS, CSRF, autenticação)
- `domains/devsecops/SKILL.md` — segurança de pipeline e infraestrutura
- `domains/containers/SKILL.md` — Containerfile/Dockerfile para empacotar o serviço Node
