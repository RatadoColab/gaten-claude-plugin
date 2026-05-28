# GLPI Vue — vue-loader.js: Arquivo Completo Anotado

## Propósito

`vue-loader.js` é o arquivo JavaScript que deve existir em `js/vue-loader.js` de cada plugin que usa Vue. Ele tem três responsabilidades:

1. Carregar a biblioteca Vue de forma condicional (evita carregar duas vezes se múltiplos plugins usam Vue)
2. Expor `rootDoc` como variável global para que os templates possam construir URLs de AJAX
3. Prover funções helper reutilizáveis para a integração Vue+GLPI

## Arquivo Completo

```javascript
/**
 * Vue loader and helper functions for GLPI plugin.
 *
 * Loads Vue 3 global build and exposes integration utilities.
 */

// rootDoc is used in all AJAX fetch() calls
var rootDoc = CFG_GLPI['root_doc'];

/**
 * Loads a script and returns a Promise that resolves when the script is ready.
 *
 * @param {string} src - Absolute URL of the script to load
 * @returns {Promise}
 */
function loadScript(src) {
    return new Promise(function(resolve, reject) {
        var script = document.createElement('script');
        script.src    = src;
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

// Load Vue only if not already available (another plugin may have loaded it)
if (!window.Vue) {
    loadScript(rootDoc + '/plugins/myplugin/lib/vue/vue.global.prod.js')
        .catch(function() {
            console.error('Failed to load Vue from plugin assets.');
        });
}

// ─── Integration Helpers ──────────────────────────────────────────────────────

/**
 * Bridge between a GLPI jQuery-managed dropdown and Vue reactive state.
 *
 * Call this from Dropdown::show()'s on_change option:
 *   'on_change' => 'updateRelatedVueField(this)'
 *
 * The dropdown must have a data-vue-field-id attribute pointing to the
 * id of the hidden <input> bound with v-model in the Vue template.
 *
 * @param {HTMLSelectElement} element - The <select> element that changed
 */
function updateRelatedVueField(element) {
    var selectedValues = [];
    for (var i = 0; i < element.selectedOptions.length; i++) {
        selectedValues.push({
            id:   element.selectedOptions[i].value,
            name: element.selectedOptions[i].innerText
        });
    }
    var destId = element.getAttribute('data-vue-field-id');
    if (destId) {
        // Write JSON to the hidden input that v-model watches
        document.getElementById(destId).value = JSON.stringify(selectedValues);
        // Dispatch input event so Vue's v-model picks up the change
        var event = new Event('input', { bubbles: true });
        document.getElementById(destId).dispatchEvent(event);
    }
}

/**
 * Programmatically clears a GLPI dropdown by itemtype name.
 *
 * Uses jQuery + Select2 which GLPI uses internally for all dropdowns.
 * The selector pattern matches GLPI's generated select id conventions.
 *
 * @param {string} itemtype - The itemtype name (e.g. 'Computer', 'Software')
 */
function glpiClearDropdownValue(itemtype) {
    var query   = 'select[id^="dropdown__myplugin_' + itemtype.toLowerCase() + 's_ids"]';
    var element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(null).trigger('change');
    }
}

/**
 * Programmatically sets a value in a GLPI dropdown by itemtype name.
 *
 * @param {string} itemtype - The itemtype name (e.g. 'Computer', 'Software')
 * @param {string|number} value - The id value to select
 */
function glpiSetDropdownValue(itemtype, value) {
    var query   = 'select[id^="dropdown__myplugin_' + itemtype.toLowerCase() + 's_ids"]';
    var element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(value).trigger('change');
    }
}

/**
 * Hides a Bootstrap 5 modal by its element id.
 *
 * @param {string} id - The id of the modal element
 */
function closeModal(id) {
    var modalEl = document.getElementById(id);
    var modal   = bootstrap.Modal.getInstance(modalEl);
    if (modal) {
        modal.hide();
    }
}

/**
 * JSON.stringify replacer that omits properties whose keys start with '_'.
 *
 * Use this when serializing a reactive object for an AJAX payload to strip
 * internal/private state before sending to the PHP backend.
 *
 * Usage: JSON.stringify(reactiveObj, excludePrivateValuesFromObject)
 *
 * @param {string} key
 * @param {*} value
 * @returns {*} undefined to omit, value to include
 */
function excludePrivateValuesFromObject(key, value) {
    if (key.startsWith('_')) {
        return undefined;
    }
    return value;
}
```

## Adaptações por Plugin

Os dois trechos que devem ser alterados ao copiar para um novo plugin:

1. **Path da biblioteca Vue** (linha `loadScript(rootDoc + '/plugins/...`):
   Substituir `myplugin` pelo nome real do plugin.

2. **Seletor dos dropdowns** (funções `glpiClearDropdownValue` e `glpiSetDropdownValue`):
   O prefixo `_myplugin_` nos seletores CSS deve corresponder ao atributo `name` definido em `Dropdown::show()`. GLPI gera `id="dropdown__myplugin_computers_ids_<rand>"` a partir do `name="_myplugin_computers_ids"` passado para o dropdown.

## Registro no setup.php

```php
// Carregar apenas nas páginas que usam Vue — evita overhead nas demais
if (isset($_SERVER['REQUEST_URI'])
    && strpos($_SERVER['REQUEST_URI'], 'front/minhaclasse.form.php') !== false
) {
    $PLUGIN_HOOKS[Hooks::ADD_JAVASCRIPT]['myplugin'][] = 'js/vue-loader.js';
}
```

## Nota sobre Timing

`loadScript()` retorna uma Promise, mas o código do app Vue (no `{% block javascripts %}` do Twig) executa de forma independente. O GLPI garante a ordem correta porque:

1. O hook `Hooks::ADD_JAVASCRIPT` injeta `vue-loader.js` antes do conteúdo dos blocos `{% block javascripts %}`
2. O script do app Vue usa `type="module" defer="defer"`, que executa após o parser completar o HTML
3. `vue-loader.js` não tem `type="module"` — executa como script clássico antes dos módulos

Esse ordenamento garante que `window.Vue` esteja disponível quando o `<script type="module">` do app Vue executar, sem necessidade de `await`.
