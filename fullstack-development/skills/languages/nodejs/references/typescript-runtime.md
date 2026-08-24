# Node.js — TypeScript Nativo (Type Stripping)

Execução de TypeScript sem build step, via remoção de sintaxe apagável.

---

## Linha do Tempo

| Versão | Comportamento |
|---|---|
| 22.6 | `--experimental-strip-types` atrás de flag |
| 22.18 | Type stripping roda sem flag para sintaxe totalmente erasable |
| 23.6 | Execução ligada por padrão |
| 24.x | Estável, sem flag, LTS |
| 26.x | Type stripping é parte do sistema de módulos estável |

## O Que É "Apagável"

Type stripping remove **apenas** sintaxe que não gera código — anotações de tipo, interfaces, generics, `as`/`satisfies`, imports type-only. Não faz type checking: um programa com erro de tipo roda normalmente até falhar em runtime na operação inválida.

```ts
// erasable — roda direto
interface User { id: number; name: string }
function greet(user: User): string {
  return `Olá, ${user.name}`;
}

const config = raw as Config;               // 'as' é apagável
type Handler = (req: Request) => Response;   // type alias é apagável
```

## Sintaxe Não Suportada (Gera Código)

| Sintaxe | Por quê falha | Alternativa |
|---|---|---|
| `enum Status { Active, Inactive }` | Gera objeto em runtime | `const Status = { Active: 'active', Inactive: 'inactive' } as const` |
| `namespace Foo { ... }` com corpo | Gera IIFE em runtime | Módulo ESM comum |
| `constructor(private x: number)` | Parameter property gera atribuição de campo | Atribuir explicitamente no corpo do construtor |
| `import Foo = require('foo')` | Sintaxe de import legada do CJS | `import Foo from 'foo'` |

Rodar com essas construções produz erro imediato do parser (`ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX`), não um erro silencioso.

## `tsconfig.json` Recomendado

```json
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "target": "esnext",
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true,
    "strict": true,
    "noEmit": true
  }
}
```

- `erasableSyntaxOnly` faz o editor/`tsc` sinalizar `enum`/`namespace`/parameter properties como erro **antes** de tentar rodar — evita descobrir em runtime.
- `verbatimModuleSyntax` obriga import/export explícitos de tipo (`import type`) — necessário para o stripping funcionar sem análise adicional.
- `noEmit: true` porque não se gera artefato — `tsc` roda só para checagem, o runtime real é `node arquivo.ts`.

## Import com Extensão `.ts`

```ts
import { db } from './db.ts';     // correto — extensão real do arquivo
import { db } from './db';        // ERRO — Node não infere extensão TS
import { db } from './db.js';     // ERRO — arquivo não existe com essa extensão
```

Diferente de bundlers (que toleram import sem extensão ou com `.js` apontando para fonte `.ts`), o runtime nativo do Node exige que o specifier corresponda exatamente ao arquivo no disco.

## CI: `tsc --noEmit` Continua Obrigatório

```yaml
# exemplo de step de CI
- run: node --run typecheck   # "typecheck": "tsc --noEmit" no package.json
- run: node --test
```

Type stripping é uma feature de **execução**, não de **verificação**. Sem `tsc --noEmit` no pipeline, erros de tipo só aparecem como exceção em runtime — a mesma classe de risco que JavaScript puro.

## Quando Ainda Vale um Bundler/`tsx`

- Projeto usa `enum`, `namespace` com runtime, ou parameter properties extensivamente (código legado, migração cara).
- Alvo de execução é o browser, não o Node — bundler é obrigatório de qualquer forma.
- Necessidade de down-level para engine mais antiga que não tem os recursos JS usados.

Fora desses casos, type stripping nativo elimina uma camada de build inteira sem custo de correção — preferir por padrão em projeto novo.
