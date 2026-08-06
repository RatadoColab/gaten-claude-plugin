# GLPI 11 Vue — Integração com Twig

## 1. Estrutura do Template Twig ao Redor do Componente

No GLPI 11, a lógica do app Vue vive inteiramente no SFC compilado (`.vue` → bundle via webpack) — o Twig só monta o app e passa props, em vez de conter a definição completa do `setup()` inline como no GLPI 10.

```twig
{# 1. Bloco de scripts — o GLPI injeta este bloco no footer da página #}
{% block javascripts %}
<script type="module" defer="defer">
const app = window.Vue.createApp(
    window.Vue.components['Plugin/Meuplugin/MeuTab'].component,
    {
        itemsId:   {{ item.fields['id'] }},
        csrfToken: "{{ csrf_token() }}",
    }
);
app.mount('#meuplugin-app');
</script>
{% endblock %}

{# 2. Container HTML da aplicação Vue — vazio, o componente renderiza dentro #}
<div id="meuplugin-app"></div>
```

O bundle do plugin (`public/build/vue/meuplugin-vue.js`, ver `references/vue-build.md`) precisa estar registrado via `Hooks::ADD_JAVASCRIPT_MODULE` em `setup.php` para que `window.Vue.components[...]` exista no momento em que este script executa.

**Por que o bloco de scripts vem antes do HTML mas executa depois:** inalterado em relação ao GLPI 10 — o Twig coleta `{% block javascripts %}` de todos os templates incluídos e os renderiza no footer da página final, garantindo que o script executa após o DOM estar pronto.

---

## 2. `{% verbatim %}` — Quando Ainda é Necessário

Como o template do componente vive no arquivo `.vue` (compilado pelo `vue-loader`, nunca passado pelo parser Twig), **`{% verbatim %}` não é necessário dentro do SFC** — essa é a principal simplificação em relação ao GLPI 10.

`{% verbatim %}` continua sendo necessário apenas se houver markup Vue **residual diretamente em um arquivo `.html.twig`** — por exemplo, ao migrar incrementalmente um template do GLPI 10 antes de convertê-lo em SFC, ou em pontos onde um container é preenchido por Twig mas ainda expõe uma diretiva Vue pontual:

```twig
{% for key, label in itemtype_options %}
<div v-show="(formApp.itemtype === '{{ key }}')">
    {# {{ key }} aqui é Twig — avaliado antes de chegar ao browser #}
    <label>{{ label }}</label>
    <div id="dropdown_{{ key|lower }}"></div>
</div>
{% endfor %}
```

Este padrão não precisa de `{% verbatim %}` porque não há `{{ }}` de interpolação Vue no trecho — apenas a diretiva `v-show` como atributo, que o Twig não tenta avaliar. `{% verbatim %}` só é obrigatório quando o HTML contém `{{ algumaCoisa }}` que deve ser resolvido pelo Vue em runtime, não pelo Twig no render — situação que se torna rara fora de componentes migrados, já que o template do componente normalmente já está isolado no `.vue`.

---

## 3. Passagem de Dados PHP para o Componente — Via Props

Diferente do GLPI 10 (onde valores eram embutidos como constantes soltas dentro do script inline), no GLPI 11 os dados do servidor chegam como **props** declaradas explicitamente no componente:

```twig
{% block javascripts %}
<script type="module" defer="defer">
const app = window.Vue.createApp(
    window.Vue.components['Plugin/Meuplugin/MeuTab'].component,
    {
        itemsId:    {{ item.fields['id'] }},
        isReadOnly: {{ can_edit ? 'false' : 'true' }},
        csrfToken:  "{{ csrf_token() }}",
    }
);
app.mount('#meuplugin-app');
</script>
{% endblock %}
```

```vue
<script setup>
const props = defineProps({
    itemsId:    { type: Number, required: true },
    isReadOnly: { type: Boolean, default: false },
    csrfToken:  { type: String, required: true },
});
</script>
```

Para coleções e dados que exigem query ao banco, preferir `onBeforeMount()` + `fetch()` dentro do componente (ver `references/runtime-patterns.md`) em vez de serializar arrays grandes como props — mantém o Twig simples e evita HTML gigante embutido no script de montagem.

**Estado pré-populado via hidden input** (edição de formulário, quando o PHP já tem os dados e um fetch adicional seria redundante) continua válido como no GLPI 10:

```twig
<input type="hidden" id="initial_state_field" value="{{ initial_state|json_encode }}" />
```

```javascript
onMounted(() => {
    const field = document.getElementById('initial_state_field');
    if (field && field.value) {
        Object.assign(formApp, JSON.parse(field.value));
    }
});
```

---

## 4. Containers Twig ao Redor de Múltiplos Componentes

Quando uma página tem mais de um app Vue independente (ex.: uma aba com lista + um modal com formulário próprio), montar cada um em seu próprio container, sem tentar compartilhar estado entre `createApp()` distintos via Twig:

```twig
{% block javascripts %}
<script type="module" defer="defer">
window.Vue.createApp(
    window.Vue.components['Plugin/Meuplugin/MeuTab'].component,
    { itemsId: {{ item.fields['id'] }} }
).mount('#meuplugin-tab');

window.Vue.createApp(
    window.Vue.components['Plugin/Meuplugin/MeuModal'].component,
    { itemsId: {{ item.fields['id'] }} }
).mount('#meuplugin-modal');
</script>
{% endblock %}

<div id="meuplugin-tab"></div>
<div id="meuplugin-modal"></div>
```

Se os dois apps precisarem compartilhar estado reativo, preferir um único componente pai que renderiza ambos (lista + modal) via componentes filhos internos, em vez de dois `createApp()` sincronizados manualmente.

---

## 5. Decomposição em Componentes Filhos

Em vez do `{{ include() }}` de arquivos Twig usado no GLPI 10 para quebrar HTML de sub-formulários, no GLPI 11 a decomposição usa **componentes Vue filhos** dentro do próprio SFC:

```vue
<!-- MeuTab.vue -->
<script setup>
import { reactive } from 'vue';
import EditForm from './EditForm.vue';

const formApp = reactive({ /* ... */ });
</script>

<template>
    <table>
        <tr v-for="item in listApp.items" :key="item.id">...</tr>
    </table>

    <div class="modal fade" id="editModal">
        <div class="modal-body">
            <EditForm :form-app="formApp" />
        </div>
    </div>
</template>
```

```vue
<!-- EditForm.vue -->
<script setup>
defineProps({ formApp: { type: Object, required: true } });
</script>

<template>
    <form>
        <input v-model="formApp.name" />
        <span v-if="formApp._errors.form_msg">{{ formApp._errors.form_msg }}</span>
    </form>
</template>
```

Regras:
- Estado compartilhado passa explicitamente por `props` (como acima) ou `provide`/`inject` para árvores mais profundas — nunca via variável global
- Cada `.vue` é uma unidade de compilação isolada; não há necessidade de coordenar blocos Twig entre eles

---

## 6. Ciclo de Vida de Renderização — Ordem dos Eventos

```
1. PHP executa
   └─ Consulta banco, instancia objetos, prepara variáveis (props)

2. Twig renderiza
   └─ Avalia {{ }}, {% for %}, {{ csrf_token() }}
   └─ Produz HTML estático + script de montagem com props embutidas

3. Browser recebe o HTML
   └─ Bundle do componente (public/build/vue/meuplugin-vue.js) carrega via
      Hooks::ADD_JAVASCRIPT_MODULE, registrando window.Vue.components[...]
   └─ Script de montagem está em <script type="module" defer> no footer

4. DOM está completamente pronto
   └─ Script de montagem executa
   └─ window.Vue.createApp(component, props) — componente instanciado com as props
   └─ app.mount('#id') — Vue assume controle do container

5. onBeforeMount() dispara dentro do componente
   └─ DOM ainda não está conectado ao Vue
   └─ Ideal para fetch de dados iniciais (lista, opções)

6. onMounted() dispara
   └─ DOM está disponível e Vue está renderizado
   └─ Ideal para: injetar HTML de dropdowns GLPI, inicializar widgets externos
```

**Implicação prática:** ao contrário do GLPI 10 (onde valores Twig eram strings estáticas embutidas no meio do script), no GLPI 11 os valores chegam como **props reativas do ponto de vista do componente** — ainda assim representam o estado do servidor no momento do carregamento da página; para dados que mudam depois, usar `onBeforeMount()` + fetch, exatamente como antes.

**Nota sobre garantia de ordem:** diferente do GLPI 10 (onde `vue-loader.js` precisava de uma Promise com `script.onload` para evitar race condition), no GLPI 11 a ordem é garantida pelo próprio mecanismo de hooks do core — `Hooks::ADD_JAVASCRIPT_MODULE` injeta o bundle do componente antes do conteúdo de `{% block javascripts %}` na página renderizada. Não é necessário nenhum guard (`if (!window.Vue.components[...])`) nem `await` antes de referenciar `window.Vue.components[...]` no script de montagem.
