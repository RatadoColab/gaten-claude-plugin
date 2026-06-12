---
name: glpi-vue
description: >
  This skill should be used when the user asks to "add a Vue interface to a
  GLPI plugin", "create a Vue tab in GLPI", "use Vue in a Twig template",
  "integrate Vue with GLPI dropdowns", "add Vue to a plugin without build
  tools", "create a reactive form in GLPI", "use Vue without webpack", or
  "add Vue 3 to a plugin page". Also load when the user mentions vue-loader.js,
  a global Vue build, or createApp() inside a Twig {% block javascripts %}.
version: 0.2.0
---

# GLPI — Interfaces Vue (Global Build)

Plugins GLPI não usam ferramentas de build. Vue é entregue como um **global browser build** (`Vue.createApp`, não `import from 'vue'`) e o código da aplicação fica inline em templates Twig, no bloco `{% block javascripts %}`.

Os primitivos de reatividade (`reactive`, `ref`, `computed`, `watch`) e os hooks de ciclo de vida são idênticos ao build modular. Para padrões de reatividade avançados, watchers e performance, consultar `languages/vue/SKILL.md` — tudo se aplica aqui sem modificação.

---

## 1. Quando Usar Vue em Plugins GLPI

| Cenário | Abordagem |
|---|---|
| Aba com lista + formulário de edição inline | Vue |
| Formulário com estado dependente (múltiplas seleções relacionadas) | Vue |
| Wizard multi-etapa sem reload de página | Vue |
| Formulário simples com show/hide por um campo | `on_change` JS inline |
| Dropdown que filtra outro dropdown via AJAX | jQuery + `on_change` |
| Listagem somente leitura | Twig puro |

Usar Vue quando o estado da página envolve múltiplos objetos reativos com interdependências, ou quando a UX exige atualizações otimistas sem reload.

---

## 2. Carregamento da Biblioteca Vue

### 2.1 Arquivo da biblioteca

Colocar o build de produção em `lib/vue/vue.global.prod.js`. Usar o build de produção — não o de desenvolvimento, que inclui warnings e overhead adicionais.

### 2.2 O padrão vue-loader.js

Criar `js/vue-loader.js` no plugin com três responsabilidades:

1. **Carregamento condicional** — guarda `if (!window.Vue)` evita carregar duas vezes se múltiplos plugins usam Vue
2. **Injeção via Promise** — usa `script.onload` para garantir que Vue esteja disponível antes de qualquer código que dependa de `window.Vue`
3. **Funções helper** — provê utilitários necessários para a integração Vue+GLPI (ver seção 2.3)

```javascript
var rootDoc = CFG_GLPI['root_doc'];

function loadScript(src) {
    return new Promise(function(resolve, reject) {
        var script = document.createElement('script');
        script.src     = src;
        script.onload  = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

if (!window.Vue) {
    loadScript(rootDoc + '/plugins/myplugin/lib/vue/vue.global.prod.js');
}
```

A função baseada em Promise evita a race condition silenciosa que ocorreria com `script.async = true` sem callback de `onload`. Ver nota sobre timing em `references/vue-loader.md`.

### 2.3 Funções helper obrigatórias em vue-loader.js

Incluir as quatro funções a seguir — são referenciadas pelos templates Vue:

| Função | Finalidade |
|---|---|
| `updateRelatedVueField(element)` | Bridge entre GLPI dropdowns (jQuery) e estado Vue |
| `glpiClearDropdownValue(itemtype)` | Limpa programaticamente um dropdown GLPI por itemtype |
| `glpiSetDropdownValue(itemtype, value)` | Define programaticamente um valor em dropdown GLPI |
| `closeModal(id)` | Fecha modal Bootstrap 5 pelo ID |
| `excludePrivateValuesFromObject(key, value)` | Replacer para `JSON.stringify` que omite props `_prefixadas` |

Ver arquivo completo anotado com adaptações por plugin em **`references/vue-loader.md`**.

### 2.4 Registro no setup.php

Registrar via `Hooks::ADD_JAVASCRIPT` com guarda de URL — evitar carregar Vue em todas as páginas do GLPI:

```php
if (isset($_SERVER['REQUEST_URI'])
    && strpos($_SERVER['REQUEST_URI'], 'front/minhaclasse.form.php') !== false
) {
    $PLUGIN_HOOKS[Hooks::ADD_JAVASCRIPT]['myplugin'][] = 'js/vue-loader.js';
}
```

---

## 3. Inicialização da Aplicação Vue

```twig
{% block javascripts %}
<script type="module" defer="defer">

const { createApp, reactive, ref, onBeforeMount, onMounted, watch } = Vue;

const app = createApp({
    setup() {
        // ... objetos reativos, hooks de ciclo de vida ...
        return { /* objetos expostos ao template */ };
    }
});

app.mount('#meu-app-vue');

</script>
{% endblock %}
```

Regras:
- Usar sempre `type="module" defer="defer"` — garante execução após o DOM estar pronto e evita poluir o escopo global
- Desestruturar todas as APIs Vue do objeto global `Vue` no início do script
- O seletor em `app.mount('#id')` deve referenciar um elemento que existe no HTML do template
- Um único `createApp()` por aba ou seção de página; sub-formulários em modais são parte do mesmo app

---

## 4. Estado Reativo — Padrão Multi-Objeto

Em vez de uma store centralizada (Pinia não está disponível sem build tool), usar múltiplos objetos `reactive()` focados por domínio funcional dentro de um único `setup()`:

```javascript
const errorsApp    = reactive({ /* mensagens de validação + clearErrors() */ });
const listApp      = reactive({ /* coleção + add(), remove(), find() */ });
const formApp      = reactive({ /* formulário de edição + validate(), save(), clear() */ });
```

### 4.1 Métodos dentro de objetos reativos

Métodos podem ser propriedades do `reactive()`, mantendo estado e comportamento co-localizados:

```javascript
const formApp = reactive({
    name: '',
    isValid: false,
    validate: function() { this.isValid = (this.name.trim() !== ''); },
    clear:    function() { this.name = ''; this.isValid = false; errorsApp.clearErrors(); }
});
```

Chamar do template: `@click="formApp.clear()"`. Chamar de outro objeto: `formApp.validate()`.

### 4.2 Convenção `_` para propriedades privadas

Propriedades prefixadas com `_` são estado interno que não deve ser serializado para AJAX:

| Exemplo | Significado |
|---|---|
| `_pre_items` | String JSON bruta vinda de um hidden input, aguardando parse |
| `_form_active` | Flag de visibilidade da UI |
| `_save_allowed` | Estado derivado de validação |

A função `excludePrivateValuesFromObject` em `vue-loader.js` omite essas propriedades automaticamente ao serializar com `JSON.stringify(obj, excludePrivateValuesFromObject)`.

### 4.3 IDs negativos para itens não-salvos

Ao adicionar itens a uma lista local antes do save no servidor, usar IDs negativos para distinguir itens novos de itens persistidos:

```javascript
// item novo: id negativo baseado na posição
newItem.id = (-1) * (insertIndex + 1);
list.splice(insertIndex, 0, newItem);
// Após save bem-sucedido, substituir pelo ID real retornado pelo servidor
```

---

## 5. Integração com Dropdowns GLPI

### 5.1 O problema

`Dropdown::show()` do GLPI renderiza um `<select>` gerenciado por Select2/jQuery. O sistema de reatividade do Vue não rastreia mudanças feitas pelo jQuery. Uma ponte é necessária.

### 5.2 O padrão hidden input bridge

**Lado PHP** — renderizar o dropdown com `on_change` e `data-vue-field-id`:

```php
Dropdown::show('Computer', [
    'name'          => '_myplugin_items_computers_ids',
    'specific_tags' => ['data-vue-field-id' => 'items_field'],
    'on_change'     => 'updateRelatedVueField(this)',
    'display'       => false,
]);
```

**Lado Twig** — hidden input com `v-model` ligado a `_pre_*`:

```html
<input type="hidden" id="items_field" v-model="formApp._pre_items" />
```

**Lado Vue** — `watch` no `_pre_*` que processa o JSON:

```javascript
watch(() => formApp._pre_items, () => {
    if (formApp._pre_items !== '') {
        formApp.items = JSON.parse(formApp._pre_items);
    }
});
```

A função `updateRelatedVueField()` em `vue-loader.js` lê as opções selecionadas, grava o JSON no hidden input e dispara um evento `input` para que o `v-model` do Vue capture a mudança.

### 5.3 Controle programático de dropdowns

Usar `glpiClearDropdownValue(itemtype)` e `glpiSetDropdownValue(itemtype, value)` (de `vue-loader.js`) para resetar ou definir dropdowns GLPI a partir de métodos Vue — por exemplo, ao executar `formApp.clear()`.

---

## 6. AJAX a partir do Vue

Usar `fetch()` com `URLSearchParams` e `application/x-www-form-urlencoded` — formato esperado pelos handlers `ajax/` do GLPI. O payload embute valores via Twig e serializa o estado reativo omitindo props privadas:

```javascript
const payload = new URLSearchParams({
    'op':               'save',
    'items_id':         "{{ item.fields['id'] }}",   // Twig embute o valor
    '_glpi_csrf_token': "{{ csrf_token() }}",         // Token CSRF via Twig
    'data':             JSON.stringify(formApp, excludePrivateValuesFromObject)
});
// POST com Content-Type x-www-form-urlencoded; em !response.ok, chamar displayAjaxMessageAfterRedirect()
```

> Exemplo `fetch` completo (com tratamento de erro e atualização do estado) em [`references/integration-patterns.md`](references/integration-patterns.md) (seção "AJAX save").

Pontos-chave:
- `"{{ csrf_token() }}"` é avaliado pelo Twig no momento da renderização e fica estático no JS — é suficiente para a sessão atual
- `rootDoc` é uma variável global definida por `vue-loader.js` (`var rootDoc = CFG_GLPI['root_doc']`)
- `displayAjaxMessageAfterRedirect()` é uma função global do GLPI que exibe mensagens geradas por `Session::addMessageAfterRedirect()` no PHP
- Ver handler correspondente em `domains/glpi/ajax-handlers/SKILL.md`

---

## 7. Modals Bootstrap e Ciclo de Vida

Padrões detalhados com exemplos em [`references/runtime-patterns.md`](references/runtime-patterns.md):

- **Modals Bootstrap 5:** abrir via `data-bs-toggle`/`data-bs-target`; fechar com `closeModal(id)` após save; limpar estado (`formApp.clear()`) ao fechar sem salvar
- **Ciclo de vida:** `onBeforeMount()` para buscar dados antes da renderização; `onMounted()` para operações que exigem o DOM pronto (injeção de dropdowns GLPI via AJAX)

---

## 8. Compatibilidade com `languages/vue/SKILL.md`

Todos os primitivos de reatividade e hooks do `languages/vue/SKILL.md` (`reactive()`, `ref()`, `computed()`, `watch()`, `onMounted()` etc.) e as diretivas de template funcionam de forma idêntica no global build. A diferença é apenas de entrega: `const { createApp } = Vue` em vez de `import { createApp } from 'vue'`, sem SFCs, sem TypeScript, sem Pinia.

---

## 9. Checklist — Antes de Usar Vue em um Template

- [ ] `lib/vue/vue.global.prod.js` presente no plugin
- [ ] `js/vue-loader.js` criado com as funções helper (ver `references/vue-loader.md`)
- [ ] `vue-loader.js` registrado no `setup.php` com guarda de URL
- [ ] `{% block javascripts %}` com `type="module" defer="defer"`
- [ ] `app.mount('#id')` referencia elemento existente no HTML do template
- [ ] Blocos `{% verbatim %}` envolvem **apenas** as interpolações Vue `{{ }}` — não envolver trechos com expressões Twig (ver `references/twig-integration.md` seção 2)
- [ ] CSRF token embutido via `"{{ csrf_token() }}"` nos payloads AJAX
- [ ] Propriedades internas prefixadas com `_`

---

## Recursos Adicionais

| Arquivo | Conteúdo |
|---|---|
| **`references/vue-loader.md`** | Arquivo `vue-loader.js` completo e anotado com todas as funções helper; nota sobre timing de carregamento |
| **`references/runtime-patterns.md`** | Modals Bootstrap 5 com Vue e hooks de ciclo de vida (`onBeforeMount`/`onMounted`) com exemplos |
| **`references/integration-patterns.md`** | Exemplos completos anotados: estrutura mínima, multi-reactive, hidden input bridge, AJAX save, carga de dropdowns via AJAX |
| **`references/twig-integration.md`** | Estrutura de templates Twig, blocos `{% verbatim %}`, injeção de dados PHP, decomposição via `include`, ciclo de vida de renderização |
| **`languages/vue/SKILL.md`** | Reatividade avançada, watch patterns, composables, performance — todos aplicáveis ao global build |
| **`domains/glpi/ajax-handlers/SKILL.md`** | Handlers PHP que respondem às chamadas `fetch()` deste skill |
