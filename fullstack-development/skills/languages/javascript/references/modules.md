# Modules — Referência Detalhada

Sistema de módulos ES6 (ESM): exportações, importações, re-exports, dynamic import e convenções de projeto.

---

## Named Exports

Múltiplos exports por arquivo; importação seletiva pelo nome exato.

```js
// --- math.js ---
export const PI = 3.14159;
export const E = 2.71828;

export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }

// Export after declaration
function multiply(a, b) { return a * b; }
const GOLDEN_RATIO = 1.618;
export { multiply, GOLDEN_RATIO };

// --- consumer.js ---
import { add, PI } from './math.js';                // selective import
import { add as sum, PI as piValue } from './math.js'; // aliased import
import * as Math from './math.js';                  // namespace import

Math.add(1, 2);    // all exports accessible as properties
```

---

## Default Export

Um default export por arquivo; importação sem chaves, nome livre no caller.

```js
// --- Formatter.js ---
// Default export — typically a class or main function of the module
export default class Formatter {
    constructor(locale = 'pt-BR') {
        this.locale = locale;
    }

    currency(value) {
        return value.toLocaleString(this.locale, { style: 'currency', currency: 'BRL' });
    }
}

// --- consumer.js ---
import Formatter from './Formatter.js';             // name is up to the importer
import MyFormatter from './Formatter.js';           // also valid

// Mixing default and named imports
import Formatter, { PI, add } from './math-formatter.js';
```

**Convenção:** usar default export para o "objeto principal" do arquivo (componente, classe, função de fábrica); named exports para utilitários e constantes secundárias.

---

## Re-exports e Barrel Files

Barrel files (`index.js`) consolidam exports de um diretório, simplificando imports nos consumers.

```js
// --- utils/string.js ---
export function capitalize(s) { return s[0].toUpperCase() + s.slice(1); }
export function slugify(s) { return s.toLowerCase().replace(/\s+/g, '-'); }

// --- utils/array.js ---
export function unique(arr) { return [...new Set(arr)]; }
export function chunk(arr, size) {
    return Array.from({ length: Math.ceil(arr.length / size) }, (_, i) =>
        arr.slice(i * size, i * size + size)
    );
}

// --- utils/index.js (barrel file) ---
export { capitalize, slugify } from './string.js';  // re-export named
export { unique, chunk } from './array.js';
export * from './number.js';                        // re-export all named exports
export { default as Formatter } from './Formatter.js'; // re-export default as named

// --- consumer.js ---
// Single import path regardless of which file each utility lives in
import { capitalize, unique, chunk, Formatter } from './utils/index.js';
```

### Re-export com Alias

```js
// Rename on re-export — useful when names would collide
export { format as formatDate } from './date.js';
export { format as formatCurrency } from './currency.js';
```

---

## Dynamic import()

Retorna uma Promise com o módulo — permite carregamento sob demanda (lazy loading).

```js
// Basic dynamic import
async function loadChart() {
    const { Chart } = await import('./Chart.js');   // loaded only when called
    return new Chart(canvas, config);
}

// Conditional import based on feature flag
async function initEditor() {
    const editorModule = await import(
        process.env.USE_RICH_EDITOR
            ? './RichEditor.js'
            : './PlainEditor.js'
    );
    return editorModule.default;
}

// Code splitting — load heavy libraries only when needed
document.getElementById('export-btn').addEventListener('click', async () => {
    const { exportToPDF } = await import('./pdf-exporter.js');
    await exportToPDF(document.getElementById('report'));
});

// Import with error handling
async function safeImport(path) {
    try {
        return await import(path);
    } catch {
        console.warn(`Module not available: ${path}`);
        return null;
    }
}
```

---

## Tree-shaking

O bundler (Vite, Webpack, Rollup) elimina código não importado. Para que funcione corretamente:

**O que permite tree-shaking:**

```js
// Named exports — each can be tracked independently
export function usedFunction() { /* ... */ }
export function unusedFunction() { /* ... */ }   // removed if not imported

// Pure functions — no side effects
export const double = n => n * 2;

// Re-exports from barrel files — tree-shakeable when using named exports
```

**O que impede tree-shaking:**

```js
// Side effects at module scope — bundler must keep the entire module
import './polyfills.js';   // side effect import
document.title = 'App';   // top-level side effect

// Dynamic access to exports — bundler can't determine at build time
const fn = module[dynamicKey]();

// CommonJS (require) — not statically analyzable
const { fn } = require('./utils');
```

**Marcar módulos como side-effect-free em package.json:**

```json
{
    "sideEffects": false
}
```

Ou declarar apenas os arquivos com side effects:

```json
{
    "sideEffects": ["./src/polyfills.js", "*.css"]
}
```

---

## Circular Dependencies

Podem causar `undefined` em runtime sem erro de importação — difíceis de diagnosticar.

### Detectar

```bash
# Using madge (npm install -g madge)
madge --circular src/
```

### Exemplo do Problema

```js
// --- a.js ---
import { b } from './b.js';   // b.js imports a.js → circular

export const a = 'a';
export function useB() { return b(); }   // b may be undefined at init time

// --- b.js ---
import { a } from './a.js';

export const b = () => a.toUpperCase();  // a might be undefined here
```

### Resolver com Interface Segregation

```js
// Extract shared types/constants to a third file with no imports from a or b
// --- shared.js --- (no imports from a or b)
export const DEFAULT_VALUE = 'default';
export class BaseConfig { /* ... */ }

// --- a.js ---
import { DEFAULT_VALUE } from './shared.js';   // no circular reference

// --- b.js ---
import { DEFAULT_VALUE } from './shared.js';   // same
```

### Resolver com Lazy Import

```js
// --- a.js ---
export const a = 'a';

export async function useB() {
    const { b } = await import('./b.js');   // deferred — breaks the static cycle
    return b();
}
```

---

## Convenções de Projeto

### Estrutura com Barrel Files

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.js
│   │   ├── Button.css
│   │   └── index.js        ← re-exports Button.js default
│   ├── Modal/
│   │   ├── Modal.js
│   │   └── index.js
│   └── index.js            ← re-exports all components
├── utils/
│   ├── string.js
│   ├── array.js
│   └── index.js            ← barrel for utils
└── main.js
```

```js
// Consumer imports from the barrel — implementation location is irrelevant
import { Button, Modal } from './components/index.js';
import { capitalize, unique } from './utils/index.js';
```

### Default vs Named — Quando Usar

| Situação | Exportação recomendada |
|---|---|
| Classe ou componente principal do arquivo | `export default` |
| Múltiplas funções utilitárias em um arquivo | `export` (named) |
| Constantes de configuração | `export` (named) |
| Tipos/interfaces TypeScript | `export` (named) |
| Biblioteca pública (facilita tree-shaking) | `export` (named), evitar default |
| Single-function module (ex: middleware) | `export default` |

> Evitar trocar `export default` por named sem motivo — breaking change para quem já importa o módulo.
