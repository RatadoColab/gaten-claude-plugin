# DOM Patterns — Referência Detalhada

Padrões modernos para manipulação do DOM: seleção, eventos, observadores e comunicação entre componentes.

---

## Seleção de Elementos

```js
const btn = document.querySelector('#submit-btn');                        // first match or null
const items = document.querySelectorAll('[data-item]');                   // static NodeList
const cards = [...document.querySelectorAll('.card')];                    // convert to array

const listItem = element.closest('li');                                   // nearest matching ancestor
if (element.matches('.active, .highlighted')) { /* selector test */ }
if (container.contains(element)) { /* containment check */ }
```

> Preferir `querySelector`/`querySelectorAll` a `getElementById`/`getElementsByClassName` — mais expressivos e consistentes.

---

## Event Delegation

Adicionar um único listener no ancestor em vez de listeners em cada filho — funciona com elementos dinâmicos e tem melhor performance.

```js
// Anti-pattern: listener on each item — breaks with dynamic content
document.querySelectorAll('.delete-btn').forEach(btn => {
    btn.addEventListener('click', handleDelete);   // elements added later won't have listener
});

// Correct: single listener on stable ancestor
document.addEventListener('click', (event) => {
    // closest() walks up from the click target
    const deleteBtn = event.target.closest('[data-action="delete"]');
    if (!deleteBtn) return;   // click was elsewhere

    const id = deleteBtn.dataset.targetId;
    handleDelete(id);
});

// Reusable delegation helper
function delegate(container, selector, eventType, handler) {
    container.addEventListener(eventType, (event) => {
        const target = event.target.closest(selector);
        if (target && container.contains(target)) {
            handler.call(target, event);
        }
    });
}

// Usage
delegate(document.getElementById('user-list'), '[data-action]', 'click', function(event) {
    const { action, userId } = this.dataset;
    dispatchAction(action, userId);
});
```

---

## Criação de Elementos

```js
// createElement — safe, no XSS risk
function createCard({ title, description, id }) {
    const article = document.createElement('article');
    article.className = 'card';
    article.dataset.id = id;

    const h2 = document.createElement('h2');
    h2.textContent = title;   // textContent is XSS-safe

    const p = document.createElement('p');
    p.textContent = description;

    article.append(h2, p);   // append multiple nodes at once
    return article;
}
```

### DocumentFragment — Batch Insert

```js
// Avoid reflow on each insertion — append everything in one operation
function renderList(items) {
    const list = document.getElementById('item-list');
    const fragment = document.createDocumentFragment();

    items.forEach(item => {
        const li = document.createElement('li');
        li.textContent = item.label;
        li.dataset.id = item.id;
        fragment.appendChild(li);   // no DOM reflow here
    });

    list.innerHTML = '';       // single clear
    list.appendChild(fragment); // single insertion — one reflow
}
```

### innerHTML — Apenas com Conteúdo Confiável

```js
// Safe — content comes from your own code
container.innerHTML = `<div class="wrapper"><span>${escapeHtml(userInput)}</span></div>`;

// Dangerous — never insert raw user input directly
// container.innerHTML = userInput;   // XSS vulnerability

// Helper to escape before inserting
function escapeHtml(str) {
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}
```

---

## MutationObserver

Observa mudanças no DOM — adição/remoção de nós, mudanças de atributos.

```js
// Watch for new elements being added — useful for lazy initialization
const observer = new MutationObserver((mutations) => {
    mutations.forEach(mutation => {
        mutation.addedNodes.forEach(node => {
            if (node.nodeType !== Node.ELEMENT_NODE) return;

            // Initialize components added dynamically (e.g., from AJAX)
            if (node.matches('[data-component="chart"]')) {
                initChart(node);
            }
            // Also check descendants of added nodes
            node.querySelectorAll('[data-component="tooltip"]')
                .forEach(initTooltip);
        });
    });
});

observer.observe(document.body, {
    childList: true,      // watch for add/remove of child nodes
    subtree: true,        // include all descendants
    // attributes: true,  // watch for attribute changes
    // characterData: true, // watch for text content changes
});

// Always disconnect when no longer needed
function cleanup() {
    observer.disconnect();
}
```

---

## IntersectionObserver

Detecta quando um elemento entra ou sai da viewport — sem listeners de scroll.

```js
// Lazy loading images
const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (!entry.isIntersecting) return;

        const img = entry.target;
        img.src = img.dataset.src;             // swap placeholder for real src
        img.removeAttribute('data-src');
        imageObserver.unobserve(img);          // stop watching once loaded
    });
}, {
    rootMargin: '200px',    // start loading 200px before entering viewport
    threshold: 0,           // trigger as soon as any part is visible
});

document.querySelectorAll('img[data-src]').forEach(img => imageObserver.observe(img));

// Infinite scroll — trigger load when sentinel element is visible
const sentinel = document.getElementById('scroll-sentinel');
const scrollObserver = new IntersectionObserver(([entry]) => {
    if (entry.isIntersecting) {
        loadNextPage();
    }
}, { threshold: 1.0 });   // trigger only when fully visible

scrollObserver.observe(sentinel);

// Animate on scroll
const animationObserver = new IntersectionObserver((entries) => {
    entries.forEach(({ target, isIntersecting }) => {
        target.classList.toggle('is-visible', isIntersecting);
    });
}, { threshold: 0.2 });

document.querySelectorAll('[data-animate]').forEach(el => animationObserver.observe(el));
```

---

## CustomEvent — Comunicação entre Componentes

```js
// Dispatch a custom event with payload
function notifySelection(productId, quantity) {
    const event = new CustomEvent('cart:add', {
        detail: { productId, quantity },
        bubbles: true,            // propagates up the DOM tree
        cancelable: true,         // allows event.preventDefault()
    });
    document.dispatchEvent(event);
}

// Listen anywhere in the app
document.addEventListener('cart:add', ({ detail }) => {
    updateCartUI(detail.productId, detail.quantity);
});

// Component can cancel the event (if cancelable: true)
document.addEventListener('cart:add', (event) => {
    if (!isAuthenticated()) {
        event.preventDefault();   // cancel the add
        showLoginModal();
    }
});

// Typed event bus — centralizes event management
const EventBus = {
    emit(name, detail) {
        document.dispatchEvent(new CustomEvent(name, { detail, bubbles: true }));
    },
    on(name, handler) {
        document.addEventListener(name, handler);
        return () => document.removeEventListener(name, handler);   // returns unsubscribe fn
    },
};

const unsubscribe = EventBus.on('user:logout', () => clearSession());
// Call unsubscribe() when component is destroyed
```

---

## Debounce e Throttle

### Debounce — Aguarda o Fim da Atividade

```js
// Executes fn only after `delay` ms of inactivity
// Use for: search input, window resize, form auto-save
function debounce(fn, delay) {
    let timer;
    return function(...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
}

const searchInput = document.getElementById('search');
searchInput.addEventListener('input', debounce((event) => {
    fetchResults(event.target.value);
}, 300));
```

### Throttle — Limita a Frequência de Execução

```js
// Executes fn at most once per `limit` ms
// Use for: scroll handler, mouse move, resize with heavy computation
function throttle(fn, limit) {
    let inThrottle = false;
    return function(...args) {
        if (inThrottle) return;
        fn.apply(this, args);
        inThrottle = true;
        setTimeout(() => { inThrottle = false; }, limit);
    };
}

window.addEventListener('scroll', throttle(() => {
    updateProgressBar(window.scrollY);
}, 100));   // runs at most 10 times per second
```

| | Debounce | Throttle |
|---|---|---|
| Quando executa | Após silêncio de X ms | A cada X ms no máximo |
| Casos de uso | Search input, auto-save | Scroll, resize, mousemove |
| Última chamada | Sempre executa | Pode ser descartada |

---

## Exemplo Completo: Tabela com Busca Debounced e Infinite Scroll

```js
class DataTable {
    #page = 0;
    #query = '';
    #loading = false;

    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.tbody = this.container.querySelector('tbody');
        this.sentinel = this.container.querySelector('[data-sentinel]');

        // Debounced search — reset and reload on input
        this.container.querySelector('[data-search]').addEventListener('input',
            debounce((e) => {
                this.#query = e.target.value.trim();
                this.#page = 0;
                this.tbody.innerHTML = '';
                this.#loadPage();
            }, 350)
        );

        // IntersectionObserver for infinite scroll
        const observer = new IntersectionObserver(([entry]) => {
            if (entry.isIntersecting && !this.#loading) this.#loadPage();
        }, { threshold: 1.0 });
        observer.observe(this.sentinel);
        this.destroy = () => observer.disconnect();

        this.#loadPage();
    }

    async #loadPage() {
        this.#loading = true;
        try {
            const params = new URLSearchParams({ q: this.#query, page: this.#page, size: 20 });
            const { data, hasMore } = await fetch(`/api/data?${params}`).then(r => r.json());

            // Batch insert via DocumentFragment — single reflow
            const fragment = document.createDocumentFragment();
            data.forEach(({ id, name, status }) => {
                const tr = document.createElement('tr');
                tr.dataset.id = id;
                tr.innerHTML = `
                    <td>${escapeHtml(name)}</td>
                    <td><span class="badge badge--${status}">${escapeHtml(status)}</span></td>
                    <td><button data-action="edit" data-id="${id}">Edit</button></td>
                `;
                fragment.appendChild(tr);
            });
            this.tbody.appendChild(fragment);
            this.sentinel.hidden = !hasMore;
            this.#page++;
        } finally {
            this.#loading = false;
        }
    }
}

const table = new DataTable('user-table');
```
