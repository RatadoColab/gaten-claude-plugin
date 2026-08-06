---
name: glpi-11-vue
description: >
  This skill should be used when the user asks to "add a Vue interface to a
  GLPI plugin", "create a Vue tab in GLPI", "use Vue in a Twig template",
  "integrate Vue with GLPI dropdowns", "create a reactive form in GLPI",
  "add Vue 3 to a plugin page", "build the plugin's Vue components", or
  mentions webpack, window._vue, SFC, or defineAsyncComponent in a GLPI
  plugin context — with the target being GLPI 11 (explicit "GLPI 11"
  mention, `public/` directory present, or confirmed 11.x when asked). For
  GLPI 10.0.x (plugin loads its own global Vue build via vue-loader.js), use
  `domains/glpi-10/vue/SKILL.md` instead. If the GLPI version cannot be
  determined, ask before generating code.
---

# GLPI 11 — Interfaces Vue (Core Build + Webpack do Plugin)

> **Versão-alvo:** GLPI 11 — Vue é fornecido pelo core via `window._vue`; o plugin nunca carrega seu próprio build do Vue. Para GLPI 10.0.x (build global próprio via `vue-loader.js`), usar `domains/glpi-10/vue/SKILL.md`.

O GLPI 11 adicionou suporte nativo a Vue no core: a aplicação principal já carrega Vue 3 e o expõe globalmente em dois pontos distintos, que não devem ser confundidos:

- **`window._vue`** — a biblioteca Vue crua. Não é referenciada diretamente no código do plugin; é apenas o alvo que o `externals` do webpack usa para resolver `import ... from 'vue'` em tempo de execução, sem empacotar uma segunda cópia.
- **`window.Vue`** — fachada do core para orquestração entre plugins (`createApp`, `.components`, `defineAsyncComponent`). Usada apenas no script de montagem inline no Twig (que não passa pelo webpack e por isso não pode usar `import`), nunca dentro do código-fonte compilado do componente.

Plugins **nunca** devem carregar um segundo build do Vue — isso duplicaria a biblioteca e pode causar conflitos de instância. Em vez disso, o plugin declara Vue como dependência externa no seu próprio bundler (webpack).

Os primitivos de reatividade (`reactive`, `ref`, `computed`, `watch`) e os hooks de ciclo de vida (`onBeforeMount`, `onMounted`) são idênticos aos do build modular padrão — comportamento inalterado em relação ao GLPI 10. Para padrões de reatividade avançados, watchers e performance, consultar `languages/vue/SKILL.md` — tudo se aplica sem modificação.

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

## 2. Componentes Vue no GLPI 11 — Regras Obrigatórias

- **Apenas Single File Components (SFC) com Composition API.** Options API está proibida — segue a convenção do próprio core GLPI 11.
- **Dentro do código-fonte do componente (`.vue`, `entry.js`), importar Vue normalmente** — `import { reactive, onBeforeMount } from 'vue';` é o padrão correto. O `externals: { vue: 'window _vue' }` do webpack (seção 3) resolve esse `import` para `window._vue` em runtime, sem empacotar uma segunda cópia da biblioteca. `window.Vue.*` só aparece no script de montagem inline no Twig (seção 4), que não é processado pelo webpack.
- Componentes ficam em `js/src/Plugin/Meuplugin/` no código-fonte do plugin, compilando para o namespace `Plugin/Meuplugin/NomeDoComponente` — evita colisão com componentes do core ou de outros plugins.
- Nunca montar um app Vue global único no `<body>` — cada feature monta seu próprio app num container específico da página, como no GLPI 10.

---

## 3. Build — Webpack do Plugin

Cada plugin que traz componentes Vue mantém seu **próprio** `webpack.config.js` (não Vite — é o que o core usa para seus próprios componentes, e plugins seguem a mesma ferramenta por consistência com o ecossistema).

```javascript
// webpack.config.js (trecho relevante)
module.exports = {
    externals: {
        vue: 'window _vue',   // consome o Vue já carregado pelo core, não empacota outro
    },
    output: {
        path: path.resolve(__dirname, 'public/build/vue'),
        publicPath: '/public/build/vue/',
        chunkFormat: 'module',
    },
    // ...
};
```

Pontos-chave:
- `output.path` fica em `public/build/vue` — assets web-acessíveis no GLPI 11 sempre vivem em `public/` (ver `domains/glpi-11/SKILL.md`)
- `externals: { vue: 'window _vue' }` é o que impede o plugin de empacotar uma segunda cópia do Vue
- `chunkFormat: 'module'` é necessário para o carregamento assíncrono via `defineAsyncComponent`

Configuração completa (entry points, loaders SFC, resolve) em **`references/vue-build.md`**.

---

## 4. Registro e Montagem do Componente

No entrypoint compilado, registrar o componente em `window.Vue.components` e montá-lo via `defineAsyncComponent`:

```javascript
// js/src/Plugin/Meuplugin/entry.js — compilado para public/build/vue/
window.Vue.components = window.Vue.components || {};
window.Vue.components['Plugin/Meuplugin/MeuTab'] = {
    component: window.Vue.defineAsyncComponent(() => import('./MeuTab.vue')),
};
```

No Twig, montar o app referenciando o componente registrado:

```twig
{% block javascripts %}
<script type="module" defer="defer">
const app = window.Vue.createApp(window.Vue.components['Plugin/Meuplugin/MeuTab'].component);
app.mount('#meuplugin-app');
</script>
{% endblock %}

<div id="meuplugin-app"></div>
```

Regras:
- `window.Vue.*` é usado **apenas** no script de montagem inline do Twig, mostrado acima — dentro dos arquivos `.vue`/`entry.js` compilados pelo webpack, usar `import ... from 'vue'` normalmente (ver seção 2)
- Um único `createApp()` por aba ou seção de página; sub-formulários em modais são parte do mesmo componente ou de componentes filhos
- Passar dados iniciais do PHP para o componente via `props` no `createApp(component, { props })`, não via variáveis globais soltas
- **Garantia de ordem:** o hook `Hooks::ADD_JAVASCRIPT_MODULE` (que carrega o bundle do componente, ver `references/vue-build.md`) é injetado pelo GLPI antes do conteúdo de `{% block javascripts %}` — `window.Vue.components['Plugin/Meuplugin/...']` já existe quando o script de montagem acima executa, sem necessidade de guarda ou `await`

---

## 5. Estado Reativo — Padrão Multi-Objeto

**Inalterado** em relação ao GLPI 10 — usar múltiplos objetos `reactive()` focados por domínio funcional dentro do `setup()` do componente, em vez de uma store centralizada:

```javascript
const errorsApp = reactive({ /* mensagens de validação + clearErrors() */ });
const listApp   = reactive({ /* coleção + add(), remove(), find() */ });
const formApp   = reactive({ /* formulário de edição + validate(), save(), clear() */ });
```

A convenção `_` para propriedades privadas (não serializadas para AJAX) e o uso de IDs negativos para itens ainda não salvos continuam válidos — ver `references/integration-patterns.md`.

---

## 6. Integração com Dropdowns GLPI

O problema é idêntico ao GLPI 10: `Dropdown::show()` renderiza um `<select>` gerenciado por Select2/jQuery, e o Vue não rastreia mudanças feitas fora de seu sistema reativo. A ponte via **hidden input + `v-model`** continua sendo o padrão — só as funções helper (`updateRelatedVueField`, `glpiClearDropdownValue`, `glpiSetDropdownValue`) deixam de vir de um `vue-loader.js` próprio e passam a ser funções locais do componente ou de um módulo utilitário compartilhado do plugin. Implementação completa em `references/integration-patterns.md`.

---

## 7. AJAX a partir do Vue

Usar `fetch()` apontando para a rota do **Controller** do plugin (ver `domains/glpi-11/ajax-handlers/SKILL.md`), não mais para `ajax/handler.php` como caminho padrão — embora handlers legados continuem acessíveis se ainda não migrados:

```javascript
const payload = new URLSearchParams({
    'items_id':         String(itemsId),      // passado via prop, não Twig embutido
    '_glpi_csrf_token': csrfToken,             // idem — prop vinda do createApp()
    'data':             JSON.stringify(formApp, excludePrivateValuesFromObject),
});

fetch('/plugins/meuplugin/MeuItem', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: payload,
})
.then((response) => {
    if (!response.ok) throw new Error(response.statusText);
    return response.json();
});
```

Diferença em relação ao GLPI 10: como o componente é um SFC compilado (não inline em `{% block javascripts %}`), valores como `items_id` e o token CSRF chegam como **props** passadas no `createApp(component, { props })` do Twig, em vez de interpolação Twig direta dentro do script. Exemplo completo em `references/integration-patterns.md`.

---

## 8. Modals Bootstrap e Ciclo de Vida

Padrões detalhados em `references/runtime-patterns.md` — mecânica idêntica ao GLPI 10 (`data-bs-toggle`/`data-bs-target`, `closeModal(id)`, `onBeforeMount()`/`onMounted()`).

---

## 9. Checklist — Antes de Usar Vue em um Template GLPI 11

- [ ] Nenhum build próprio do Vue é carregado — apenas `externals: { vue: 'window _vue' }` no webpack do plugin
- [ ] Componente é SFC com Composition API — nunca Options API
- [ ] Componente fica em `js/src/Plugin/Meuplugin/`, compilado para `public/build/vue/`
- [ ] Registrado em `window.Vue.components['Plugin/Meuplugin/...']` via `defineAsyncComponent`
- [ ] Montagem via `window.Vue.createApp(window.Vue.components[...].component).mount(...)`
- [ ] Dados do servidor (IDs, CSRF token) passados como `props`, não embutidos via interpolação Twig dentro do bundle
- [ ] `{% verbatim %}` envolve apenas interpolações Vue quando ainda houver HTML inline em Twig (containers, não o componente em si)
- [ ] Propriedades internas prefixadas com `_`
- [ ] Chamadas AJAX apontam para rota de Controller (`domains/glpi-11/ajax-handlers/SKILL.md`)

---

## Recursos Adicionais

| Arquivo | Conteúdo |
|---|---|
| **`references/vue-build.md`** | `webpack.config.js` completo, entrypoint anotado, registro do componente |
| **`references/runtime-patterns.md`** | Modals Bootstrap 5 com Vue e hooks de ciclo de vida (`onBeforeMount`/`onMounted`) com exemplos |
| **`references/integration-patterns.md`** | Exemplos completos anotados: estrutura mínima, multi-reactive, hidden input bridge, AJAX save, carga de dropdowns via AJAX |
| **`references/twig-integration.md`** | Estrutura de templates Twig ao redor do componente, `{% verbatim %}`, passagem de props, ciclo de vida de renderização |
| **`languages/vue/SKILL.md`** | Reatividade avançada, watch patterns, composables, performance — todos aplicáveis |
| **`domains/glpi-11/ajax-handlers/SKILL.md`** | Controllers/handlers PHP que respondem às chamadas `fetch()` deste skill |
