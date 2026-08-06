# Padrões de Runtime — Modals Bootstrap e Ciclo de Vida

Detalhamento de modais Bootstrap 5 e hooks de ciclo de vida no global build. Resumo no `SKILL.md`.

## Bootstrap Modals com Vue

**Abertura** — usar `data-bs-toggle` com binding Vue:

```html
<button data-bs-toggle="modal"
        data-bs-target="#myModal"
        :disabled="formApp.type.id === 0">
    Adicionar
</button>
```

**Fechamento programático** — chamar `closeModal()` após save bem-sucedido:

```javascript
formApp.save = function() {
    // ... fetch POST ...
    .then(() => {
        closeModal('myModal');
        formApp.clear();
    });
};
```

**Limpeza de estado** — limpar o formulário ao fechar o modal sem salvar:

```html
<button class="btn-close" @click="formApp.clear()"></button>
```

## Ciclo de Vida — Carregamento Inicial

Usar `onBeforeMount()` para buscar dados antes da primeira renderização do DOM:

```javascript
onBeforeMount(() => {
    fetch(`${rootDoc}/plugins/myplugin/ajax/handler.php`, {
        method: 'POST',
        body:   new URLSearchParams({ 'op': 'load', 'items_id': "{{ item.fields['id'] }}" })
    })
    .then(r => r.json())
    .then(json => { listApp.items = json.data; });
});
```

Usar `onMounted()` para operações que exigem o DOM pronto (injeção de HTML de dropdowns GLPI via AJAX, inicialização de widgets de terceiros):

```javascript
onMounted(() => {
    fetch(`${rootDoc}/plugins/myplugin/ajax/dropdowns.php`, {
        method: 'POST',
        body:   new URLSearchParams({ 'op': 'get_dropdowns', 'rand': Date.now() })
    })
    .then(r => r.json())
    .then(json => {
        document.getElementById('dropdown-container').innerHTML = json.html;
    });
});
```
