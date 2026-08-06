# GLPI 11 Vue — Build do Plugin (Webpack)

## Propósito

No GLPI 11, o core carrega Vue 3 uma única vez e o expõe via `window._vue`. Cada plugin que traz componentes Vue precisa do próprio bundler para compilar SFCs (`.vue`) em JS consumível pelo browser, **sem** empacotar uma segunda cópia do Vue. Este arquivo documenta o `webpack.config.js` completo e o entrypoint de registro.

## `webpack.config.js` — Completo

```javascript
const path = require('path');
const { VueLoaderPlugin } = require('vue-loader');

module.exports = {
    mode: 'production',

    entry: {
        'meuplugin-vue': path.resolve(__dirname, 'js/src/Plugin/Meuplugin/entry.js'),
    },

    output: {
        path: path.resolve(__dirname, 'public/build/vue'),
        // public/ não aparece na URL final — o publicPath usa o caminho servido, não o caminho em disco
        publicPath: '/plugins/meuplugin/build/vue/',
        filename: '[name].js',
        chunkFormat: 'module',
        // Necessário para chunks assíncronos via defineAsyncComponent
        chunkFilename: '[name].chunk.js',
    },

    externals: {
        // Consome o Vue já carregado pelo core GLPI — nunca empacotar outra cópia
        vue: 'window _vue',
    },

    module: {
        rules: [
            {
                test: /\.vue$/,
                loader: 'vue-loader',
            },
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: 'babel-loader',
            },
        ],
    },

    plugins: [
        new VueLoaderPlugin(),
    ],

    resolve: {
        extensions: ['.js', '.vue'],
    },
};
```

Notas:
- `externals: { vue: 'window _vue' }` é o item obrigatório — sem ele, o webpack tentaria resolver `import ... from 'vue'` via `node_modules`, empacotando uma segunda instância. **Com** o `externals` configurado, o código-fonte dos componentes (`.vue`, `entry.js`) importa Vue normalmente (`import { reactive } from 'vue'`) — o webpack substitui essa importação por `window._vue.reactive` na compilação; nunca é necessário (nem correto) referenciar `window._vue` diretamente no código-fonte.
- `output.path` (caminho em disco) aponta para `public/build/vue/` — todo asset web-acessível no GLPI 11 vive em `public/`. `output.publicPath` (caminho servido, usado pelos chunks assíncronos) é diferente: como `public/` não aparece na URL final, o valor correto é `/plugins/meuplugin/build/vue/`.
- `chunkFormat: 'module'` é necessário para que `defineAsyncComponent(() => import('./MeuComponente.vue'))` funcione como chunk separado carregado sob demanda.
- `vue-loader` e `vue` (como `devDependency`, apenas para tipos/compilação, não para runtime) vão em `package.json`; **não** em `composer.json`.

## Entrypoint — Registro de Componentes

```javascript
// js/src/Plugin/Meuplugin/entry.js

window.Vue.components = window.Vue.components || {};

window.Vue.components['Plugin/Meuplugin/MeuTab'] = {
    component: window.Vue.defineAsyncComponent(() => import('./MeuTab.vue')),
};

window.Vue.components['Plugin/Meuplugin/MeuModal'] = {
    component: window.Vue.defineAsyncComponent(() => import('./MeuModal.vue')),
};
```

- O namespace `Plugin/Meuplugin/NomeDoComponente` evita colisão com componentes do core ou de outros plugins — sempre prefixar com `Plugin/<NomeDoPlugin>/`.
- `defineAsyncComponent` permite que o chunk do componente só seja baixado quando efetivamente necessário — importante em páginas onde nem toda aba usa Vue.

## Exemplo de SFC (Composition API apenas)

```vue
<!-- js/src/Plugin/Meuplugin/MeuTab.vue -->
<script setup>
import { reactive, onBeforeMount } from 'vue';

const props = defineProps({
    itemsId: { type: Number, required: true },
    csrfToken: { type: String, required: true },
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
            listApp.items = json.data;
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

`<script setup>` é a forma recomendada de Composition API — mais concisa que `setup()` explícito, mas ambas são aceitas; nunca usar `export default { data() {...}, methods: {...} }` (Options API).

## Registro no `setup.php`

```php
use Glpi\Plugin\Hooks;

function plugin_init_meuplugin(): void
{
    global $PLUGIN_HOOKS;

    if (isset($_SERVER['REQUEST_URI'])
        && strpos($_SERVER['REQUEST_URI'], '/MeuItem') !== false
    ) {
        $PLUGIN_HOOKS[Hooks::ADD_JAVASCRIPT_MODULE]['meuplugin'][] = 'build/vue/meuplugin-vue.js';
    }
}
```

Usar `Hooks::ADD_JAVASCRIPT_MODULE` (não `ADD_JAVASCRIPT`) — o bundle é um módulo ES (`chunkFormat: 'module'`), carregado com `type="module"`.

## Montagem no Twig

```twig
{% block javascripts %}
<script type="module" defer="defer">
const app = window.Vue.createApp(
    window.Vue.components['Plugin/Meuplugin/MeuTab'].component,
    {
        itemsId: {{ item.fields['id'] }},
        csrfToken: "{{ csrf_token() }}",
    }
);
app.mount('#meuplugin-app');
</script>
{% endblock %}

<div id="meuplugin-app"></div>
```

Os valores `itemsId` e `csrfToken` continuam sendo interpolados pelo Twig no momento da renderização — a diferença em relação ao GLPI 10 é que eles são passados como **props** para `createApp(component, props)`, não lidos soltos dentro de um script inline com toda a lógica do app.
