# ES6+ Features — Referência Detalhada

Funcionalidades avançadas do JavaScript moderno além do básico coberto em `SKILL.md`.

---

## Destructuring Avançado

### Aninhado

```js
const { address: { city, coords: { lat, lng } } } = user;
// city, lat, lng extraídos de user.address.coords

const [[a, b], [c, d]] = [[1, 2], [3, 4]];
```

### Com Defaults e Renomeação Combinados

```js
const {
    name: userName = 'Anonymous',   // rename + default
    role: userRole = 'guest',
    age,
} = user;
```

### Rest em Destructuring

```js
const { id, createdAt, ...payload } = record;   // payload has everything except id and createdAt
const [head, ...tail] = items;                   // head = first, tail = rest as array
```

### Destructuring em Parâmetros de Função

```js
// Destructure directly in the parameter list
function renderCard({ title, body, tags = [], author: { name } }) {
    return `${title} by ${name}: ${body} [${tags.join(', ')}]`;
}

// Useful for array callbacks
const totals = orders.map(({ qty, price }) => qty * price);
```

### Troca de Variáveis

```js
let a = 1, b = 2;
[a, b] = [b, a];   // swap without temp variable
```

---

## Generators

Funções que podem pausar e retomar a execução, produzindo valores sob demanda.

```js
// Generator function — declared with function*
function* counter(start = 0) {
    let i = start;
    while (true) {
        yield i++;   // pauses here and returns i, resumes on next()
    }
}

const gen = counter(5);
gen.next();   // { value: 5, done: false }
gen.next();   // { value: 6, done: false }

// Finite generator
function* range(start, end, step = 1) {
    for (let i = start; i < end; i += step) {
        yield i;
    }
}

// Iterating with for...of
for (const n of range(0, 10, 2)) {
    console.log(n);   // 0, 2, 4, 6, 8
}

// Spread — consumes the generator
const nums = [...range(1, 6)];   // [1, 2, 3, 4, 5]
```

### Caso de Uso Real: Paginação Lazy

```js
// Fetches pages only as needed — never loads all data at once
async function* paginate(endpoint, pageSize = 20) {
    let page = 1;
    let hasMore = true;

    while (hasMore) {
        const res = await fetch(`${endpoint}?page=${page}&size=${pageSize}`);
        const { data, total } = await res.json();
        yield data;   // caller receives one page at a time
        hasMore = page * pageSize < total;
        page++;
    }
}

// Usage — processes each page as it arrives
for await (const page of paginate('/api/users')) {
    processPage(page);
}
```

---

## Iterators e Iterables

Um objeto é **iterable** se implementa o protocolo `[Symbol.iterator]`.

```js
// Custom iterable collection
class Range {
    constructor(start, end) {
        this.start = start;
        this.end = end;
    }

    // Makes the object iterable via for...of, spread, destructuring
    [Symbol.iterator]() {
        let current = this.start;
        const end = this.end;

        return {
            next() {
                if (current <= end) {
                    return { value: current++, done: false };
                }
                return { value: undefined, done: true };
            },
        };
    }
}

const range = new Range(1, 5);
console.log([...range]);   // [1, 2, 3, 4, 5]
for (const n of range) { /* works */ }
const [first, second] = range;   // destructuring works too
```

---

## Proxy e Reflect

`Proxy` intercepta operações em objetos; `Reflect` fornece os comportamentos padrão.

```js
// Validation proxy — enforces data constraints automatically
function createValidated(target, validators) {
    return new Proxy(target, {
        set(obj, prop, value) {
            if (validators[prop] && !validators[prop](value)) {
                throw new TypeError(`Invalid value for "${prop}": ${value}`);
            }
            return Reflect.set(obj, prop, value);   // default behavior
        },
        get(obj, prop) {
            return Reflect.get(obj, prop);
        },
    });
}

const user = createValidated({}, {
    age: v => Number.isInteger(v) && v >= 0 && v <= 150,
    email: v => typeof v === 'string' && v.includes('@'),
});

user.age = 25;       // ok
user.email = 'test'; // TypeError — no '@'
```

---

## WeakMap e WeakSet

Diferem de `Map`/`Set` porque as referências são **fracas** — não impedem o garbage collector.

| | `Map` | `WeakMap` |
|---|---|---|
| Chaves | Qualquer tipo | Apenas objetos |
| GC de chaves | Não — mantém referência | Sim — removido quando objeto é coletado |
| Iterável | Sim (`for...of`, `.keys()`) | Não |
| Caso de uso | Dados persistentes | Metadata privada, cache com GC automático |

```js
// Private metadata — invisible to users of the object
const _private = new WeakMap();

class SecureCounter {
    constructor() {
        _private.set(this, { count: 0 });   // data not accessible via instance
    }

    increment() {
        _private.get(this).count++;
    }

    get value() {
        return _private.get(this).count;
    }
}

// Cache with automatic cleanup — no memory leak risk
const cache = new WeakMap();

function getProcessed(element) {
    if (!cache.has(element)) {
        cache.set(element, expensiveProcess(element));
    }
    return cache.get(element);   // if element is GC'd, cache entry disappears too
}
```

---

## Symbols

Valores únicos e imutáveis, usados para chaves de propriedade sem colisão.

```js
// Each Symbol() call produces a unique value
const id = Symbol('id');
const id2 = Symbol('id');
id === id2;   // false — always unique

// As object keys — not enumerable in for...in or JSON.stringify
const user = {
    name: 'Ana',
    [id]: 123,   // symbol key — hidden from casual inspection
};

Object.keys(user);           // ['name'] — symbols excluded
Object.getOwnPropertySymbols(user);   // [Symbol(id)]
```

### Well-Known Symbols

```js
// Symbol.iterator — makes object iterable (see Iterators section)
// Symbol.toPrimitive — controls type coercion
class Money {
    constructor(amount, currency) {
        this.amount = amount;
        this.currency = currency;
    }

    [Symbol.toPrimitive](hint) {
        if (hint === 'number') return this.amount;
        if (hint === 'string') return `${this.amount} ${this.currency}`;
        return this.amount;   // 'default' hint
    }
}

const price = new Money(42, 'BRL');
+price;           // 42 (number hint)
`${price}`;       // '42 BRL' (string hint)
price + 10;       // 52 (default hint → number)
```

### Symbol.for — Registro Global

```js
// Shared symbols across modules/realms
const KEY = Symbol.for('app.userKey');

// Same key retrieved anywhere in the app
const sameKey = Symbol.for('app.userKey');
KEY === sameKey;   // true — global registry lookup
```

---

## Tagged Template Literals

Uma função antes do template literal recebe os segmentos e valores separados.

```js
// Tag function signature: (strings, ...values)
function highlight(strings, ...values) {
    return strings.reduce((result, str, i) => {
        const val = values[i - 1];
        return result + `<mark>${val}</mark>` + str;
    });
}

const name = 'André';
const role = 'admin';
highlight`User ${name} has role ${role}`;
// User <mark>André</mark> has role <mark>admin</mark>
```

### Sanitização de HTML

```js
// Prevents XSS by escaping interpolated values
function safeHtml(strings, ...values) {
    const escaped = values.map(v =>
        String(v)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
    );
    return strings.reduce((acc, str, i) => acc + (escaped[i - 1] ?? '') + str);
}

const userInput = '<script>alert("xss")</script>';
const html = safeHtml`<p>Hello, ${userInput}</p>`;
// <p>Hello, &lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;</p>
```

### Sanitização de SQL (Ilustrativa)

```js
// Parameterized query builder via tagged template
function sql(strings, ...values) {
    const query = strings.reduce((acc, str, i) => acc + (i > 0 ? `$${i}` : '') + str);
    return { query, params: values };   // params passed separately to driver
}

const { query, params } = sql`SELECT * FROM users WHERE id = ${userId} AND active = ${true}`;
// query: 'SELECT * FROM users WHERE id = $1 AND active = $2'
// params: [userId, true]
```

---

## Tabela de Referência Rápida

| Feature | Exemplo compacto | ES version |
|---|---|---|
| Destructuring | `const { a, b } = obj` | ES2015 |
| Rest params | `function f(...args)` | ES2015 |
| Spread | `[...arr1, ...arr2]` | ES2015 |
| Generator | `function* gen() { yield 1 }` | ES2015 |
| Symbol | `Symbol('desc')` | ES2015 |
| Symbol.iterator | `obj[Symbol.iterator] = function*(){}` | ES2015 |
| Proxy | `new Proxy(target, handler)` | ES2015 |
| Reflect | `Reflect.set(obj, key, val)` | ES2015 |
| WeakMap | `new WeakMap()` | ES2015 |
| WeakSet | `new WeakSet()` | ES2015 |
| Symbol.toPrimitive | `[Symbol.toPrimitive](hint){}` | ES2015 |
| Symbol.for | `Symbol.for('key')` | ES2015 |
| Tagged template | `` tag`str ${val}` `` | ES2015 |
| `for await...of` | `for await (const x of asyncGen)` | ES2018 |
| Private fields | `#field` | ES2022 |
| `Object.hasOwn` | `Object.hasOwn(obj, key)` | ES2022 |
