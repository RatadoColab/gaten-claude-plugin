# GLPI 11 Vue — Padrões de Runtime: Modals Bootstrap e Ciclo de Vida

Mecânica de modais e hooks de ciclo de vida **idêntica ao GLPI 10** — a única diferença é que o código roda dentro de um SFC compilado, não inline em `{% block javascripts %}`. Resumo no `SKILL.md`.

## Bootstrap Modals com Vue

**Abertura** — usar `data-bs-toggle` com binding Vue, dentro do `<template>` do componente:

```html
<button data-bs-toggle="modal"
        data-bs-target="#myModal"
        :disabled="formApp.type.id === 0">
    Adicionar
</button>
```

**Fechamento programático** — `closeModal()` vem do módulo utilitário do plugin (ver `references/integration-patterns.md`), não de `vue-loader.js`:

```javascript
import { closeModal } from './glpi-helpers.js';

formApp.save = function() {
    // ... fetch POST ...
    .then(() => {
        closeModal('myModal');
        formApp.clear();
    });
};
```

Adicionar `closeModal` ao módulo utilitário, junto das demais funções:

```javascript
// glpi-helpers.js
export function closeModal(id) {
    const modalEl = document.getElementById(id);
    const modal   = bootstrap.Modal.getInstance(modalEl);
    if (modal) {
        modal.hide();
    }
}
```

**Limpeza de estado** — limpar o formulário ao fechar o modal sem salvar:

```html
<button class="btn-close" @click="formApp.clear()"></button>
```

## Ciclo de Vida — Carregamento Inicial

Usar `onBeforeMount()` para buscar dados antes da primeira renderização do DOM. O endpoint aponta para uma rota de Controller (`domains/glpi-11/ajax-handlers/SKILL.md`); `itemsId` chega via prop:

```javascript
const props = defineProps({ itemsId: { type: Number, required: true } });

onBeforeMount(() => {
    fetch(`/plugins/meuplugin/MeuItem/${props.itemsId}`)
        .then((r) => r.json())
        .then((json) => { listApp.items = json.data; });
});
```

Usar `onMounted()` para operações que exigem o DOM pronto (injeção de HTML de dropdowns GLPI via AJAX, inicialização de widgets de terceiros):

```javascript
onMounted(() => {
    fetch(`/plugins/meuplugin/Dropdowns?rand=${Date.now()}`)
        .then((r) => r.json())
        .then((json) => {
            document.getElementById('dropdown-container').innerHTML = json.html;
        });
});
```
