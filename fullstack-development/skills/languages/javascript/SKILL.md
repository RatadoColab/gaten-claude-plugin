---
name: javascript
description: This skill should be used when writing, reviewing, or refactoring JavaScript language syntax, used in both frontend and backend (Node.js) code — for Node.js runtime concerns (ESM, `node:` APIs, deployment), see the companion `nodejs` skill instead. Covers ES6+ features (arrow functions, destructuring, classes, optional chaining, nullish coalescing), async patterns (Promises, async/await, combinators), DOM manipulation, and JavaScript best practices. Use when the user asks to "write JavaScript", "review JS code", "implement async logic", "use ES6 classes", "handle DOM events", or "refactor to modern JS".
---

# JavaScript — Convenções e Boas Práticas (ES6+)

Diretrizes para escrita de JavaScript moderno com base no ES2015+ e boas práticas de frontend e backend (Node.js).

---

## Declaração de Variáveis

| Palavra-chave | Escopo | Hoisting | Mutável | Quando usar |
|---|---|---|---|---|
| `const` | Bloco | Sim (não inicializada) | Não (binding) | Padrão — sempre que não houver reatribuição |
| `let` | Bloco | Sim (não inicializada) | Sim | Quando reatribuição for necessária (loops, acumuladores) |
| `var` | Função / Global | Sim (inicializada com `undefined`) | Sim | **Nunca usar** em código novo |

> `const` não torna o valor imutável — impede apenas a **reatribuição do binding**. Objetos e arrays declarados com `const` ainda podem ter seu conteúdo modificado.

---

## Arrow Functions

```js
const add = (a, b) => a + b;          // implicit return (single expression)
const double = n => n * 2;            // single param — parentheses optional
const now = () => Date.now();         // no params — parentheses required
```

**Diferença crítica: `this`**

| Contexto | `function` regular | Arrow function |
|---|---|---|
| `this` em método de objeto | Referencia o objeto chamador | Herda `this` do escopo léxico externo |
| `this` em callback de evento | Referencia o elemento DOM | Herda `this` do escopo onde foi definida |
| Uso como construtor (`new`) | Permitido | **Não permitido** — lança TypeError |
| `arguments` object | Disponível | **Não disponível** |

**Regra:** usar arrow para callbacks e funções anônimas; usar `function` regular para métodos de objeto e funções que precisam de `this` dinâmico ou `arguments`.

---

## Destructuring e Spread/Rest

```js
const { name, age, role = 'user' } = person;     // object destructuring + default
const [first, ...restItems] = [1, 2, 3];         // array destructuring + rest
const merged = { ...defaults, ...overrides };    // spread — shallow merge
function sum(...numbers) { /* rest in params */ }
```

Para destructuring avançado (aninhado, renomeação, troca de variáveis) e generators/Proxy, ver **`references/es6-features.md`**.

---

## Template Literals

Interpolação com `` `${expr}` ``, multiline nativo (newlines preservados) e expressões arbitrárias dentro de `${}` — preferir sempre a concatenação com `+`.

> **Tagged templates** permitem pré-processar os segmentos e valores interpolados — usados para sanitização de HTML/SQL, i18n e styled-components. Exemplos em `references/es6-features.md`.

---

## Classes ES6

| Recurso | Sintaxe | Notas |
|---|---|---|
| Campo público | `this.prop = val` | Acessível externamente |
| Campo privado | `#prop` | Apenas dentro da classe (ES2022) |
| Método estático | `static method()` | Chamado em `Class.method()`, não em instância |
| Getter/Setter | `get prop()` / `set prop(v)` | Acesso como propriedade |
| Herança | `extends` + `super()` | `super()` obrigatório antes de `this` no construtor |

Exemplo completo (campos privados, herança, override) em **`references/es6-features.md`** (§Classes ES6).

---

## Async/Await

| Abordagem | Código | Erro handling | Legibilidade |
|---|---|---|---|
| Callback | `fs.readFile(path, (err, data) => {...})` | Parâmetro `err` | Ruim (callback hell) |
| Promise | `.then(data => ...).catch(err => ...)` | `.catch()` | Média |
| `async/await` | `const data = await readFile(path)` | `try/catch` | Boa |

```js
const res = await fetch(`/api/users/${id}`);
if (!res.ok) throw new Error(`HTTP ${res.status}`);

// Parallel execution — don't await sequentially if independent
const [users, products] = await Promise.all([fetchUsers(), fetchProducts()]);
```

Para event loop, Promise combinators, AbortController e exemplos completos com try/catch, ver **`references/async-patterns.md`**.

---

## Optional Chaining e Nullish Coalescing

```js
const city = user?.address?.city ?? 'Unknown';   // safe access with fallback
const port = config.port ?? 3000;                // 0 would NOT trigger ?? (unlike ||)
user.role ??= 'guest';                           // assign only if null/undefined
```

| Operador | Trigger | Exemplo |
|---|---|---|
| `?.` | `null` ou `undefined` | `obj?.prop` retorna `undefined` em vez de lançar |
| `??` | `null` ou `undefined` | `null ?? 'x'` → `'x'`; `0 ?? 'x'` → `0` |
| `\|\|` | Qualquer falsy | `0 \|\| 'x'` → `'x'`; `'' \|\| 'x'` → `'x'` |

---

## Anti-Patterns

| Anti-Pattern | Problema | Padrão ES6 correto |
|---|---|---|
| `var x = 1` | Escopo de função, hoisting perigoso | `const x = 1` ou `let x = 1` |
| `function() { return this.x }` em callback | `this` incorreto | Arrow function `() => this.x` |
| `obj.hasOwnProperty(key)` | Pode falhar se `hasOwnProperty` for sobrescrito | `Object.hasOwn(obj, key)` |
| `typeof x === 'undefined'` | Verboso | `x === undefined` (em contextos seguros) |
| `[].concat(arr1, arr2)` | Verboso | `[...arr1, ...arr2]` |
| `Object.assign({}, obj)` | Verboso | `{ ...obj }` |
| `then().then().then()` aninhados | Dificulta leitura e error handling | `async/await` com `try/catch` |
| `new Promise(resolve => resolve(x))` | Desnecessário | `Promise.resolve(x)` |
| `== null` para checar null/undefined | Coerção implícita (funciona, mas não óbvio) | `=== null \|\| === undefined` ou `?? ` |
| `arguments[0]` | Não disponível em arrows, sem nome | Rest params `(...args)` |
| String concatenação com `+` | Ilegível com múltiplas variáveis | Template literals `` `${a} ${b}` `` |
| `for...in` em arrays | Itera propriedades do prototype | `for...of` ou `.forEach()` |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/es6-features.md`** | Destructuring avançado, classes ES6, generators, iterators, Proxy, WeakMap, Symbols, tagged templates |
| **`references/async-patterns.md`** | Event loop, Promise chains, combinators, AbortController, timeout e cancelamento |
| **`references/dom-patterns.md`** | Event delegation, MutationObserver, IntersectionObserver, CustomEvent, debounce/throttle |
| **`references/modules.md`** | Módulos ES6 (ESM): named/default exports, re-exports, dynamic import, convenções de projeto |

---

## Também consultar

- `languages/nodejs/SKILL.md` — runtime Node.js (ESM, APIs `node:`, deploy) para código que roda fora do browser
- `languages/vue/SKILL.md` — uso de JavaScript no contexto Vue.js (reatividade, composables, lifecycle)
- `domains/security/SKILL.md` — XSS, sanitização de input, CSP e segurança em JavaScript
