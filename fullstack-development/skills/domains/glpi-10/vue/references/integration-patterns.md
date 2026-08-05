# GLPI Vue — Padrões de Integração: Exemplos Completos

## Padrão 1: Estrutura Mínima Completa

Template mínimo funcional com carregamento de lista via AJAX.

**Twig template** (`templates/mytab.html.twig`):

```twig
{% block javascripts %}
<script type="module" defer="defer">

const { createApp, reactive, onBeforeMount } = Vue;

const app = createApp({
    setup() {
        const listApp = reactive({
            items: [],
            loading: false
        });

        onBeforeMount(() => {
            listApp.loading = true;
            fetch(`${rootDoc}/plugins/myplugin/ajax/handler.php`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
                body: new URLSearchParams({
                    'op':       'load',
                    'items_id': "{{ item.fields['id'] }}"
                }).toString()
            })
            .then(r => r.json())
            .then(json => {
                listApp.items   = json.data;
                listApp.loading = false;
            });
        });

        return { listApp };
    }
});

app.mount('#myplugin-app');

</script>
{% endblock %}

<div id="myplugin-app">
    <div v-if="listApp.loading">Carregando...</div>
    <table v-else>
        {% verbatim %}
        <tr v-for="item in listApp.items" :key="item.id">
            <td>{{ item.name }}</td>
        </tr>
        {% endverbatim %}
    </table>
</div>
```

Pontos do exemplo:
- `{% block javascripts %}` vem antes do HTML mas executa no footer do GLPI (após DOM pronto)
- `{% verbatim %}` envolve apenas as rows do `v-for`, não o `v-if` externo (que não tem `{{ }}`)
- `"{{ item.fields['id'] }}"` é avaliado pelo Twig — valor estático embutido no JS

---

## Padrão 2: Multi-Reactive com Métodos Inline

Estrutura com três objetos reativos interdependentes.

```javascript
setup() {
    // Mensagens de validação — um objeto por responsabilidade
    const errorsApp = reactive({
        form_msg:  '',
        items_msg: '',
        clearErrors: function() {
            // limpa todas as propriedades que não são funções
            Object.getOwnPropertyNames(this).forEach(prop => {
                if (typeof this[prop] !== 'function') {
                    this[prop] = '';
                }
            });
        }
    });

    // Coleção de itens — responsável pela lista persistida
    const listApp = reactive({
        items: [],
        add: function(item) {
            // IDs negativos para itens novos (não persistidos no servidor)
            let insertIndex = this.items.length;
            item.id = (-1) * (insertIndex + 1);
            this.items.splice(insertIndex, 0, item);
        },
        remove: function(id) {
            const index = this.items.findIndex(obj => obj.id === id);
            if (index >= 0) {
                this.items.splice(index, 1);
                // Reindexar IDs negativos após remoção
                for (let i = index; i < this.items.length; i++) {
                    if (this.items[i].id < 0) {
                        this.items[i].id = (-1) * (i + 1);
                    }
                }
            }
        },
        find: function(id) {
            return this.items.findIndex(obj => obj.id === id);
        }
    });

    // Formulário de edição — responsável pelo estado do form ativo
    const formApp = reactive({
        id:   0,
        name: '',
        _form_active: false,    // visibilidade do painel de edição
        _save_allowed: false,   // habilitação do botão salvar
        validate: function() {
            if (this.name.trim() === '') {
                errorsApp.form_msg  = 'Nome é obrigatório.';
                this._save_allowed = false;
                return false;
            }
            errorsApp.clearErrors();
            this._save_allowed = true;
            return true;
        },
        save: function() {
            if (!this.validate()) return;
            const snapshot = JSON.parse(
                JSON.stringify(this, excludePrivateValuesFromObject)
            );
            if (this.id === 0) {
                listApp.add(snapshot);   // chama método do listApp
            } else {
                const index = listApp.find(this.id);
                if (index >= 0) listApp.items[index] = snapshot;
            }
            this.clear();
        },
        clear: function() {
            this.id           = 0;
            this.name         = '';
            this._form_active = false;
            this._save_allowed = false;
            errorsApp.clearErrors();
        },
        edit: function(item) {
            this.id           = item.id;
            this.name         = item.name;
            this._form_active = true;
            this._save_allowed = true;
        }
    });

    return { errorsApp, listApp, formApp };
}
```

Uso no template:
```html
<button @click="formApp.edit(item)">Editar</button>
<button @click="listApp.remove(item.id)">Remover</button>

<div v-if="formApp._form_active">
    {% verbatim %}
    <input v-model="formApp.name" @input="formApp.validate()" />
    <span v-if="errorsApp.form_msg">{{ errorsApp.form_msg }}</span>
    <button :disabled="!formApp._save_allowed" @click="formApp.save()">Salvar</button>
    {% endverbatim %}
</div>
```

---

## Padrão 3: Hidden Input Bridge para Dropdown GLPI

Sequência completa dos quatro componentes da ponte Vue ↔ jQuery.

**Passo 1 — PHP renderiza o dropdown com callback:**

```php
// Em displayTabContentForItem() ou showForm()
Dropdown::show('Computer', [
    'name'          => '_myplugin_items_computers_ids',
    'specific_tags' => [
        'data-vue-field-id' => 'computers_field',  // ID do hidden input destino
    ],
    'on_change'     => 'updateRelatedVueField(this)',
    'display'       => false,
]);
```

**Passo 2 — `updateRelatedVueField` em `vue-loader.js`:**

```javascript
function updateRelatedVueField(element) {
    const selectedValues = [];
    for (let i = 0; i < element.selectedOptions.length; i++) {
        selectedValues.push({
            'id':   element.selectedOptions[i].value,
            'name': element.selectedOptions[i].innerText
        });
    }
    const destId = element.getAttribute('data-vue-field-id');
    if (destId) {
        // Atualiza o valor do hidden input
        document.getElementById(destId).value = JSON.stringify(selectedValues);
        // Dispara evento input para que o v-model do Vue capture a mudança
        const event = new Event('input', { bubbles: true });
        document.getElementById(destId).dispatchEvent(event);
    }
}
```

**Passo 3 — Twig: hidden input com v-model:**

```html
<input type="hidden" id="computers_field" v-model="formApp._pre_computers" />
```

**Passo 4 — Vue: watch processa o JSON:**

```javascript
const formApp = reactive({
    computers:      [],
    _pre_computers: '',
    processComputers: function() {
        this.computers = this._pre_computers !== ''
            ? JSON.parse(this._pre_computers)
            : [];
    }
});

watch(() => formApp._pre_computers, () => {
    formApp.processComputers();
});
```

**Controle programático** — limpar ou definir o dropdown a partir de Vue:

```javascript
// Limpar (ex: no formApp.clear())
glpiClearDropdownValue('Computer');
formApp._pre_computers = '';
formApp.computers      = [];

// Definir (ex: ao editar um item existente)
glpiSetDropdownValue('Computer', item.computer_id);
```

As funções `glpiClearDropdownValue` e `glpiSetDropdownValue` em `vue-loader.js`:

```javascript
function glpiClearDropdownValue(itemtype) {
    const query   = `select[id^="dropdown__myplugin_${itemtype.toLowerCase()}s_ids"]`;
    const element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(null).trigger('change');
    }
}

function glpiSetDropdownValue(itemtype, value) {
    const query   = `select[id^="dropdown__myplugin_${itemtype.toLowerCase()}s_ids"]`;
    const element = document.querySelector(query);
    if (element) {
        $('#' + element.id).val(value).trigger('change');
    }
}
```

---

## Padrão 4: AJAX Save com Serialização de Estado

Save completo de um objeto reativo com reconciliação de IDs.

```javascript
const listApp = reactive({
    items: [],

    saveAll: function() {
        // excludePrivateValuesFromObject omite props _prefixadas
        const payload = JSON.stringify(
            { items: this.items },
            excludePrivateValuesFromObject
        );

        fetch(`${rootDoc}/plugins/myplugin/ajax/handler.php`, {
            method:  'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
            body:    new URLSearchParams({
                'op':               'save_all',
                'items_id':         "{{ item.fields['id'] }}",
                '_glpi_csrf_token': "{{ csrf_token() }}",
                'data':             payload
            }).toString()
        })
        .then(response => {
            if (!response.ok) {
                displayAjaxMessageAfterRedirect();
                throw new Error('Save failed: HTTP ' + response.status);
            }
            return response.json();
        })
        .then(json => {
            if (json.success) {
                // Reconciliar IDs negativos (locais) com IDs reais do servidor
                if (json.id_map) {
                    this.items.forEach(item => {
                        if (item.id < 0 && json.id_map[item.id] !== undefined) {
                            item.id = json.id_map[item.id];
                        }
                    });
                }
                displayAjaxMessageAfterRedirect();
            }
        });
    }
});
```

O servidor deve retornar um mapa de IDs no formato `{ "id_map": { "-1": 42, "-2": 43 } }` para que os IDs negativos temporários sejam substituídos pelos IDs reais após persistência.

---

## Padrão 5: Carregamento de Dropdown HTML via AJAX no onMounted

Quando o HTML do dropdown precisa ser carregado dinamicamente (e não pré-renderizado em Twig).

```javascript
onMounted(() => {
    fetch(`${rootDoc}/plugins/myplugin/ajax/dropdowns.php`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
        body:    new URLSearchParams({
            'op':       'get_dropdowns',
            'rand':     Date.now(),
            'item_id':  "{{ item.fields['id'] }}"
        }).toString()
    })
    .then(r => r.json())
    .then(json => {
        // json.dropdowns é um mapa { "container_id": "<html do dropdown>" }
        Object.entries(json.dropdowns).forEach(([containerId, html]) => {
            const container = document.getElementById(containerId);
            if (container) {
                container.innerHTML = html;
                // GLPI gera scripts de inicialização inline dentro do HTML do dropdown.
                // <script> injetado via innerHTML não executa automaticamente — é
                // preciso recriar cada tag para que o browser a rode.
                container.querySelectorAll('script').forEach(oldScript => {
                    const newScript = document.createElement('script');
                    newScript.textContent = oldScript.textContent;
                    oldScript.parentNode.replaceChild(newScript, oldScript);
                });
            }
        });
    });
});
```

Containers correspondentes no template Twig:

```html
<div id="dropdown_computer">
    {# HTML do dropdown será injetado via AJAX no onMounted #}
</div>
<input type="hidden" id="computers_field" v-model="formApp._pre_computers" />
```

---

## Padrão 6: `excludePrivateValuesFromObject` — Quando e Por Quê

Objeto reativo com mistura de dados de negócio e estado interno:

```javascript
const formApp = reactive({
    id:           0,
    name:         'Servidor Web',
    type:         { id: 2, name: 'Produção' },
    items:        [{ id: 10, name: 'srv-001' }],
    _pre_items:   '[{"id":10,"name":"srv-001"}]',  // estado interno
    _form_active:  true,                             // estado interno
    _save_allowed: true,                             // estado interno
});

// Sem replacer — inclui propriedades internas
JSON.stringify(formApp);
// → {"id":0,"name":"Servidor Web","type":{...},"items":[...],"_pre_items":"...","_form_active":true,"_save_allowed":true}

// Com replacer — apenas dados de negócio
JSON.stringify(formApp, excludePrivateValuesFromObject);
// → {"id":0,"name":"Servidor Web","type":{...},"items":[...]}
```

Função completa:

```javascript
function excludePrivateValuesFromObject(key, value) {
    if (key.startsWith('_')) {
        return undefined;  // omite a propriedade da serialização
    }
    return value;
}
```

Usar sempre que um objeto reativo inteiro for enviado como payload AJAX ou precisar ser copiado para persistência: `JSON.parse(JSON.stringify(obj, excludePrivateValuesFromObject))`.
