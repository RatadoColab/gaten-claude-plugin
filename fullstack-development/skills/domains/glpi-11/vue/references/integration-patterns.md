# GLPI 11 Vue — Padrões de Integração: Exemplos Completos

As funções helper deste documento (`updateRelatedVueField`, `glpiClearDropdownValue`, `glpiSetDropdownValue`, `excludePrivateValuesFromObject`) não vêm mais de um `vue-loader.js` global — GLPI 11 não usa esse arquivo. Definir essas funções num módulo utilitário compartilhado do plugin (ex.: `js/src/Plugin/Meuplugin/glpi-helpers.js`) e importá-las nos componentes que precisam delas.

## `js/src/Plugin/Meuplugin/glpi-helpers.js` — Módulo Utilitário

```javascript
export function updateRelatedVueField(element) {
    const selectedValues = [];
    for (let i = 0; i < element.selectedOptions.length; i++) {
        selectedValues.push({
            id:   element.selectedOptions[i].value,
            name: element.selectedOptions[i].innerText,
        });
    }
    const destId = element.getAttribute('data-vue-field-id');
    if (destId) {
        document.getElementById(destId).value = JSON.stringify(selectedValues);
        const event = new Event('input', { bubbles: true });
        document.getElementById(destId).dispatchEvent(event);
    }
}

export function glpiClearDropdownValue(itemtype) {
    const query   = `select[id^="dropdown__meuplugin_${itemtype.toLowerCase()}s_ids"]`;
    const element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(null).trigger('change');
    }
}

export function glpiSetDropdownValue(itemtype, value) {
    const query   = `select[id^="dropdown__meuplugin_${itemtype.toLowerCase()}s_ids"]`;
    const element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(value).trigger('change');
    }
}

export function excludePrivateValuesFromObject(key, value) {
    if (key.startsWith('_')) {
        return undefined;
    }
    return value;
}
```

Importar no componente: `import { glpiClearDropdownValue, excludePrivateValuesFromObject } from './glpi-helpers.js';`

---

## Padrão 1: Estrutura Mínima Completa (SFC)

```vue
<!-- js/src/Plugin/Meuplugin/MeuTab.vue -->
<script setup>
import { reactive, onBeforeMount } from 'vue';

const props = defineProps({
    itemsId: { type: Number, required: true },
});

const listApp = reactive({
    items: [],
    loading: false,
});

onBeforeMount(() => {
    listApp.loading = true;
    fetch(`/plugins/meuplugin/MeuItem/${props.itemsId}`)
        .then((r) => r.json())
        .then((json) => {
            listApp.items   = json.data;
            listApp.loading = false;
        });
});
</script>

<template>
    <div v-if="listApp.loading">Carregando...</div>
    <table v-else>
        <tr v-for="item in listApp.items" :key="item.id">
            <td>{{ item.name }}</td>
        </tr>
    </table>
</template>
```

Diferença em relação ao GLPI 10: sem `{% verbatim %}` — o SFC tem sua própria sintaxe de template, compilada pelo `vue-loader`, e nunca é interpretada pelo Twig. O `items_id` chega como prop (via `createApp(component, { itemsId: ... })` no Twig), não como valor Twig embutido diretamente no script.

---

## Padrão 2: Multi-Reactive com Métodos Inline

**Idêntico ao GLPI 10 na forma** — estrutura com três objetos reativos interdependentes dentro de `<script setup>` ou `setup()`:

```javascript
const errorsApp = reactive({
    form_msg: '',
    clearErrors: function() {
        Object.getOwnPropertyNames(this).forEach((prop) => {
            if (typeof this[prop] !== 'function') {
                this[prop] = '';
            }
        });
    },
});

const listApp = reactive({
    items: [],
    add: function(item) {
        const insertIndex = this.items.length;
        item.id = (-1) * (insertIndex + 1);
        this.items.splice(insertIndex, 0, item);
    },
    remove: function(id) {
        const index = this.items.findIndex((obj) => obj.id === id);
        if (index >= 0) this.items.splice(index, 1);
    },
    find: function(id) {
        return this.items.findIndex((obj) => obj.id === id);
    },
});

const formApp = reactive({
    id: 0,
    name: '',
    _form_active: false,
    _save_allowed: false,
    validate: function() {
        if (this.name.trim() === '') {
            errorsApp.form_msg = 'Nome é obrigatório.';
            this._save_allowed = false;
            return false;
        }
        errorsApp.clearErrors();
        this._save_allowed = true;
        return true;
    },
    save: function() {
        if (!this.validate()) return;
        const snapshot = JSON.parse(JSON.stringify(this, excludePrivateValuesFromObject));
        if (this.id === 0) {
            listApp.add(snapshot);
        } else {
            const index = listApp.find(this.id);
            if (index >= 0) listApp.items[index] = snapshot;
        }
        this.clear();
    },
    clear: function() {
        this.id = 0;
        this.name = '';
        this._form_active = false;
        this._save_allowed = false;
        errorsApp.clearErrors();
    },
});
```

Uso no template (SFC — sem `{% verbatim %}`):

```html
<template>
    <button @click="formApp.edit(item)">Editar</button>
    <button @click="listApp.remove(item.id)">Remover</button>

    <div v-if="formApp._form_active">
        <input v-model="formApp.name" @input="formApp.validate()" />
        <span v-if="errorsApp.form_msg">{{ errorsApp.form_msg }}</span>
        <button :disabled="!formApp._save_allowed" @click="formApp.save()">Salvar</button>
    </div>
</template>
```

---

## Padrão 3: Hidden Input Bridge para Dropdown GLPI

Mecânica idêntica ao GLPI 10 — a diferença é apenas de onde as funções vêm (módulo local, não `vue-loader.js` global).

**Passo 1 — PHP renderiza o dropdown com callback (Twig ao redor do componente, ou no `showForm()` legado):**

```php
Dropdown::show('Computer', [
    'name'          => '_meuplugin_items_computers_ids',
    'specific_tags' => ['data-vue-field-id' => 'computers_field'],
    'on_change'     => 'window.meupluginUpdateRelatedVueField(this)',
    'display'       => false,
]);
```

Como o componente é um SFC compilado, o `on_change` inline (avaliado como string HTML, fora do bundle) precisa referenciar uma função exposta em `window` — expor a partir do entrypoint:

```javascript
// entry.js
import { updateRelatedVueField } from './glpi-helpers.js';
window.meupluginUpdateRelatedVueField = updateRelatedVueField;
```

**Passo 2 — Template do SFC: hidden input com `v-model`** (não é Twig — vive no `<template>` do componente `.vue`, compilado pelo webpack):

```html
<input type="hidden" id="computers_field" v-model="formApp._pre_computers" />
```

**Passo 3 — Vue: `watch` processa o JSON:**

```javascript
const formApp = reactive({
    computers: [],
    _pre_computers: '',
    processComputers: function() {
        this.computers = this._pre_computers !== '' ? JSON.parse(this._pre_computers) : [];
    },
});

watch(() => formApp._pre_computers, () => {
    formApp.processComputers();
});
```

**Controle programático:**

```javascript
import { glpiClearDropdownValue, glpiSetDropdownValue } from './glpi-helpers.js';

glpiClearDropdownValue('Computer');
formApp._pre_computers = '';
formApp.computers = [];

glpiSetDropdownValue('Computer', item.computer_id);
```

---

## Padrão 4: AJAX Save com Serialização de Estado

```javascript
import { excludePrivateValuesFromObject } from './glpi-helpers.js';

const listApp = reactive({
    items: [],

    saveAll: function(itemsId, csrfToken) {
        const payload = JSON.stringify({ items: this.items }, excludePrivateValuesFromObject);

        fetch(`/plugins/meuplugin/MeuItem/${itemsId}/SaveAll`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body: new URLSearchParams({
                '_glpi_csrf_token': csrfToken,
                'data': payload,
            }).toString(),
        })
        .then((response) => {
            if (!response.ok) {
                throw new Error('Save failed: HTTP ' + response.status);
            }
            return response.json();
        })
        .then((json) => {
            if (json.success && json.id_map) {
                this.items.forEach((item) => {
                    if (item.id < 0 && json.id_map[item.id] !== undefined) {
                        item.id = json.id_map[item.id];
                    }
                });
            }
        });
    },
});
```

`itemsId` e `csrfToken` chegam como props do componente (`defineProps`), não como valores Twig embutidos no meio do script — ver `references/twig-integration.md`. O endpoint aponta para uma rota de Controller (`domains/glpi-11/ajax-handlers/SKILL.md`), que retorna o mesmo formato `{ "id_map": { "-1": 42 } }` esperado no GLPI 10.

---

## Padrão 5: Carregamento de Dropdown HTML via AJAX no `onMounted`

```javascript
onMounted(() => {
    fetch(`/plugins/meuplugin/Dropdowns?item_id=${props.itemsId}`)
        .then((r) => r.json())
        .then((json) => {
            Object.entries(json.dropdowns).forEach(([containerId, html]) => {
                const container = document.getElementById(containerId);
                if (container) {
                    container.innerHTML = html;
                    // GLPI gera scripts de inicialização inline dentro do HTML do dropdown.
                    // <script> injetado via innerHTML não executa automaticamente — é
                    // preciso recriar cada tag para que o browser a rode.
                    container.querySelectorAll('script').forEach((oldScript) => {
                        const newScript = document.createElement('script');
                        newScript.textContent = oldScript.textContent;
                        oldScript.parentNode.replaceChild(newScript, oldScript);
                    });
                }
            });
        });
});
```

Container correspondente no template do componente:

```html
<div id="dropdown_computer"></div>
<input type="hidden" id="computers_field" v-model="formApp._pre_computers" />
```

---

## Padrão 6: `excludePrivateValuesFromObject` — Quando e Por Quê

**Inalterado** em relação ao GLPI 10 — a única diferença é que a função vem de `import` em vez de estar disponível globalmente:

```javascript
import { excludePrivateValuesFromObject } from './glpi-helpers.js';

JSON.stringify(formApp, excludePrivateValuesFromObject);
// omite todas as propriedades prefixadas com "_"
```

Usar sempre que um objeto reativo inteiro for enviado como payload AJAX ou precisar ser copiado para persistência.
