---
name: javascript
description: This skill should be used when writing, reviewing, or refactoring JavaScript code for both frontend and backend (Node.js). Covers ES6+ features (arrow functions, destructuring, classes, modules, optional chaining, nullish coalescing), async patterns (Promises, async/await, combinators), module systems (named/default exports, dynamic import, tree-shaking), DOM manipulation, and JavaScript best practices. Use when the user asks to "write JavaScript", "review JS code", "implement async logic", "use ES6 classes", "configure modules", "handle DOM events", or "refactor to modern JS".
version: 0.2.0
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

```js
const user = { name: 'Ana' };
user.name = 'João'; // allowed — object content is mutable
// user = {};       // TypeError — reassignment is forbidden

let count = 0;
count++;            // allowed — reassignment with let

// var hoisting trap — avoid
console.log(x);    // undefined (not ReferenceError)
var x = 10;
```

---

## Arrow Functions

```js
// Traditional function
function add(a, b) {
    return a + b;
}

// Arrow — implicit return when body is a single expression
const add = (a, b) => a + b;

// Arrow with block body
const greet = (name) => {
    const greeting = `Hello, ${name}`;
    return greeting;
};

// Single parameter — parentheses optional
const double = n => n * 2;

// No parameters — empty parentheses required
const now = () => Date.now();
```

**Diferença crítica: `this`**

| Contexto | `function` regular | Arrow function |
|---|---|---|
| `this` em método de objeto | Referencia o objeto chamador | Herda `this` do escopo léxico externo |
| `this` em callback de evento | Referencia o elemento DOM | Herda `this` do escopo onde foi definida |
| Uso como construtor (`new`) | Permitido | **Não permitido** — lança TypeError |
| `arguments` object | Disponível | **Não disponível** |

```js
class Timer {
    constructor() {
        this.seconds = 0;
    }

    // Arrow captures `this` from class scope — correct for callbacks
    start() {
        setInterval(() => {
            this.seconds++; // `this` is the Timer instance
        }, 1000);
    }
}

const obj = {
    name: 'obj',
    // Arrow here would break `this` — use regular function for methods
    greet() {
        return `I am ${this.name}`;
    },
};
```

**Regra:** usar arrow para callbacks e funções anônimas; usar `function` regular para métodos de objeto e funções que precisam de `this` dinâmico ou `arguments`.

---

## Destructuring e Spread/Rest

### Destructuring de Arrays

```js
const [first, second, ...rest] = [1, 2, 3, 4, 5];
// first = 1, second = 2, rest = [3, 4, 5]

// Skip elements with empty comma
const [,, third] = [10, 20, 30];
// third = 30

// Default values
const [a = 0, b = 0] = [5];
// a = 5, b = 0
```

### Destructuring de Objetos

```js
const { name, age, role = 'user' } = person;

// Renaming
const { name: userName, age: userAge } = person;

// Nested destructuring
const { address: { city, zip } } = person;

// In function parameters
function display({ name, age = 0 }) {
    return `${name} (${age})`;
}
```

### Spread e Rest

```js
// Spread — expand iterable into individual elements
const merged = { ...defaults, ...overrides };           // object merge
const combined = [...arr1, ...arr2];                    // array concat
const copy = [...original];                             // shallow copy

// Rest — collect remaining into array/object
function sum(...numbers) {                              // rest in params
    return numbers.reduce((acc, n) => acc + n, 0);
}

const { id, ...rest } = user;                          // rest in destructuring
```

Para destructuring avançado (aninhado, generators, Proxy), ver **`references/es6-features.md`**.

---

## Template Literals

```js
const name = 'André';
const age = 30;

// Basic interpolation
const msg = `Name: ${name}, Age: ${age}`;

// Multiline — newlines are preserved
const html = `
  <div>
    <p>${name}</p>
  </div>
`;

// Expressions inside ${}
const total = `Total: ${(price * qty).toFixed(2)}`;

// Tagged templates — function processes the literal
const safe = html`<p>${userInput}</p>`;   // see references/es6-features.md
```

> **Tagged templates** permitem pré-processar os segmentos e valores interpolados — usados para sanitização de HTML/SQL, i18n, e styled-components.

---

## Classes ES6

```js
class Animal {
    // Private field (ES2022) — not accessible outside the class
    #sound;

    constructor(name, sound) {
        this.name = name;   // public field
        this.#sound = sound;
    }

    speak() {
        return `${this.name} says ${this.#sound}`;
    }

    // Static method — called on class, not instance
    static create(name, sound) {
        return new Animal(name, sound);
    }
}

class Dog extends Animal {
    #tricks = [];

    constructor(name) {
        super(name, 'woof');    // must call super before using `this`
    }

    learn(trick) {
        this.#tricks.push(trick);
    }

    // Override parent method
    speak() {
        return `${super.speak()}! Tricks: ${this.#tricks.join(', ')}`;
    }
}

const dog = new Dog('Rex');
dog.learn('sit');
console.log(dog.speak());
// console.log(dog.#tricks);   // SyntaxError — private field
```

| Recurso | Sintaxe | Notas |
|---|---|---|
| Campo público | `this.prop = val` | Acessível externamente |
| Campo privado | `#prop` | Apenas dentro da classe (ES2022) |
| Método estático | `static method()` | Chamado em `Class.method()`, não em instância |
| Getter/Setter | `get prop()` / `set prop(v)` | Acesso como propriedade |
| Herança | `extends` + `super()` | `super()` obrigatório antes de `this` no construtor |

---

## Módulos ES6

```js
// --- math.js ---
// Named exports — multiple per file
export const PI = 3.14159;
export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }

// --- formatter.js ---
// Default export — one per file
export default class Formatter {
    format(value) { return String(value); }
}

// --- main.js ---
import Formatter from './formatter.js';               // default import
import { add, subtract } from './math.js';            // named imports
import { add as sum } from './math.js';               // aliased import
import * as MathUtils from './math.js';               // namespace import

// Dynamic import — returns a Promise
async function loadModule() {
    const { add } = await import('./math.js');         // lazy loading
    return add(1, 2);
}
```

Para re-exports, barrel files, tree-shaking e circular dependencies, ver **`references/modules.md`**.

---

## Async/Await

| Abordagem | Código | Erro handling | Legibilidade |
|---|---|---|---|
| Callback | `fs.readFile(path, (err, data) => {...})` | Parâmetro `err` | Ruim (callback hell) |
| Promise | `.then(data => ...).catch(err => ...)` | `.catch()` | Média |
| `async/await` | `const data = await readFile(path)` | `try/catch` | Boa |

```js
// Promise chain
function fetchUser(id) {
    return fetch(`/api/users/${id}`)
        .then(res => {
            if (!res.ok) throw new Error(`HTTP ${res.status}`);
            return res.json();
        })
        .catch(err => console.error(err));
}

// Equivalent with async/await — preferred
async function fetchUser(id) {
    try {
        const res = await fetch(`/api/users/${id}`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return await res.json();
    } catch (err) {
        console.error('Failed to fetch user:', err);
        throw err;    // re-throw so callers can handle
    }
}

// Parallel execution — don't await sequentially if independent
const [users, products] = await Promise.all([
    fetchUsers(),
    fetchProducts(),
]);
```

Para event loop, Promise combinators, AbortController e exemplos completos, ver **`references/async-patterns.md`**.

---

## Optional Chaining e Nullish Coalescing

```js
// Optional chaining (?.) — short-circuits on null/undefined
const city = user?.address?.city;           // undefined if any step is null
const first = arr?.[0];                     // safe array access
const result = obj?.method?.();             // safe method call

// Nullish coalescing (??) — fallback only for null/undefined
const name = user.name ?? 'Anonymous';     // 'Anonymous' only if null/undefined
const port = config.port ?? 3000;          // 0 would NOT trigger ?? (unlike ||)

// Combined — safe access with fallback
const city = user?.address?.city ?? 'Unknown';

// Nullish assignment (??=) — assign only if null/undefined
user.role ??= 'guest';

// Optional chaining with ternary anti-pattern — avoid
// const city = user && user.address && user.address.city;  // verbose
// Use:
const city = user?.address?.city;   // clean and safe
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
| **`references/es6-features.md`** | Destructuring avançado, generators, iterators, Proxy, WeakMap, Symbols, tagged templates |
| **`references/async-patterns.md`** | Event loop, Promise chains, combinators, AbortController, timeout e cancelamento |
| **`references/modules.md`** | Barrel files, re-exports, dynamic import, tree-shaking, circular dependencies |
| **`references/dom-patterns.md`** | Event delegation, MutationObserver, IntersectionObserver, CustomEvent, debounce/throttle |

---

## Também consultar

- `languages/vue/SKILL.md` — uso de JavaScript no contexto Vue.js (reatividade, composables, lifecycle)
- `domains/security/SKILL.md` — XSS, sanitização de input, CSP e segurança em JavaScript
