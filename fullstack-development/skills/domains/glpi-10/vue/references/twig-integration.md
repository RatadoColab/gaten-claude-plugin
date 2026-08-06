# GLPI Vue — Integração com Twig

## 1. Estrutura do Template Twig com Vue

Layout canônico de um arquivo Twig que contém um app Vue:

```twig
{# 1. Importar macros se necessário #}
{% import 'components/form/fields_macros.html.twig' as fields %}

{# 2. Bloco de scripts — o GLPI injeta este bloco no footer da página #}
{% block javascripts %}
<script type="module" defer="defer">

const { createApp, reactive, onBeforeMount, onMounted, watch } = Vue;

const app = createApp({
    setup() {
        // ... definição de objetos reativos ...
        return { /* objetos expostos ao template */ };
    }
});

app.mount('#myplugin-app');

</script>
{% endblock %}

{# 3. Container HTML da aplicação Vue #}
<div id="myplugin-app" class="spaced">
    {# ... directives Vue aqui ... #}
</div>
```

**Por que o `{% block javascripts %}` vem antes do HTML mas executa depois:**

O GLPI usa Twig para compor a página inteira. O sistema de blocos do Twig coleta o conteúdo de `{% block javascripts %}` de todos os templates incluídos e os renderiza no footer da página HTML final (`</body>`). Isso garante que o script Vue executa após o DOM estar completamente construído, independentemente de onde o bloco aparece no arquivo Twig.

---

## 2. Blocos `{% verbatim %}`

Twig e Vue usam `{{ }}` para interpolação. Dentro de um template Twig, `{{ foo }}` é avaliado pelo Twig. Para que as interpolações Vue cheguem ao browser sem serem processadas pelo Twig, usar `{% verbatim %}...{% endverbatim %}`.

**Regra:** envolver com `{% verbatim %}` qualquer trecho HTML que contenha `{{ }}` de Vue.

### Wrapping granular (preferido)

Envolver apenas as partes com interpolação Vue, mantendo o restante acessível ao Twig:

{# NÃO FAZER: expressão Twig {{ itemtype_key }} dentro de {% verbatim %} — será ignorada pelo Twig #}
```twig
<table>
    {% for itemtype_key, itemtype_label in itemtype_options %}
    <tr data-type="{{ itemtype_key }}">
        {% verbatim %}
        <td v-if="(listApp.activeType === '{{ itemtype_key }}')">
        {# ERRADO: {{ itemtype_key }} está dentro de verbatim — Twig não o avalia #}
        </td>
        <td>{{ listApp.count }}</td>
        {% endverbatim %}
    </tr>
    {% endfor %}
</table>
```

**Correto — passar valores Twig para Vue fora do bloco verbatim:**

```twig
{% for itemtype_key, itemtype_label in itemtype_options %}
<div v-show="(formApp.itemtype === '{{ itemtype_key }}')">
    {# {{ itemtype_key }} aqui é Twig — avaliado antes de chegar ao browser #}
    <div id="dropdown_{{ itemtype_key|lower }}">
        {# container para dropdown injetado via AJAX #}
    </div>
</div>
{% endfor %}
```

**Não misturar:** não colocar expressões Twig dentro de um bloco `{% verbatim %}` — elas serão tratadas como texto literal.

### Wrapping amplo (para templates simples)

Quando não há expressões Twig dentro do container Vue, envolver o bloco inteiro:

```twig
<div id="myplugin-app">
{% verbatim %}
    <template v-if="listApp.items.length === 0">
        <p>Nenhum item cadastrado.</p>
    </template>
    <table v-else>
        <tr v-for="item in listApp.items" :key="item.id">
            <td>{{ item.name }}</td>
            <td>{{ item.type.name }}</td>
        </tr>
    </table>
{% endverbatim %}
</div>
```

---

## 3. Injeção de Dados PHP no Estado Inicial Vue

Três padrões para transferir dados PHP/banco para o estado Vue inicial.

### Padrão A — Embedding literal de escalares

Para IDs, strings únicas, booleanos e outros escalares conhecidos no momento da renderização:

```twig
{# No bloco {% block javascripts %} — avaliado pelo Twig, estático no JS #}
const itemId       = {{ item.fields['id'] }};
const isReadOnly   = {{ can_edit ? 'false' : 'true' }};
const pluginName   = '{{ plugin_name }}';
const csrfToken    = "{{ csrf_token() }}";
```

Usar para: IDs de contexto, flags de permissão, valores de configuração. Os valores são baked no JS no momento do render e não podem reagir a mudanças de estado Vue.

### Padrão B — Fetch em `onBeforeMount` (coleções)

Para arrays, objetos complexos e dados que requerem queries ao banco:

```javascript
onBeforeMount(() => {
    fetch(`${rootDoc}/plugins/myplugin/ajax/handler.php`, {
        method: 'POST',
        body:   new URLSearchParams({
            'op':     'load',
            'parent': "{{ item.fields['id'] }}"
        })
    })
    .then(r => r.json())
    .then(json => {
        listApp.items = json.data;         // array de objetos
        formApp.types = json.type_options; // dados de suporte
    });
});
```

Usar para: listas de itens, opções de dropdown, dados relacionados.

### Padrão C — JSON em hidden input para estado pré-populado

Para pré-popular o estado do formulário quando a página abre em modo de edição — útil quando o PHP já tem os dados disponíveis e o fetch adicional seria redundante:

```twig
{# PHP serializa o estado para JSON e o Twig embute no HTML #}
<input type="hidden"
       id="initial_state_field"
       value="{{ initial_state|json_encode }}" />
```

```javascript
onMounted(() => {
    const field = document.getElementById('initial_state_field');
    if (field && field.value) {
        const initialState = JSON.parse(field.value);
        // Transferir propriedades para o objeto reativo
        Object.assign(formApp, initialState);
    }
});
```

Usar quando: o PHP já carregou o objeto e seria ineficiente fazer um segundo fetch; estado de edição de formulário que deve estar disponível imediatamente.

---

## 4. Misturando Twig e Diretivas Vue no Mesmo Elemento

### Padrão seguro — Twig no elemento pai, Vue nos filhos

```twig
{# Twig aplica classe condicional no container estático #}
<div class="{{ item.fields['is_active'] ? '' : 'disabled-section' }}">
    {# Vue controla visibilidade dos filhos em runtime #}
    <span v-if="formApp.isLoading">Carregando...</span>
    <form v-else>...</form>
</div>
```

### Padrão seguro — Twig `{% for %}` gerando elementos com diretivas Vue

```twig
{# Twig gera um div por itemtype em tempo de render #}
{# Vue usa v-show para alternar visibilidade em runtime #}
{% for key, label in itemtype_options %}
<div class="dropdown-section"
     v-show="(formApp.itemtype === '{{ key }}')">
    <label>{{ label }}</label>
    <div id="dropdown_{{ key|lower }}"></div>
    <input type="hidden"
           id="items_{{ key|lower }}_field"
           v-model="formApp._pre_items_{{ key|lower }}" />
</div>
{% endfor %}
```

### Padrão inseguro — evitar

```twig
{# NÃO fazer: v-for e Twig {% for %} no mesmo nível sobre os mesmos dados #}
{% for item in php_items %}
<tr v-for="item in vueItems">  {# conflito de nomes e lógica #}
    ...
</tr>
{% endfor %}
```

Usar `v-for` Vue quando os dados chegam via AJAX ou são gerenciados reativamente. Usar `{% for %}` Twig quando os dados são disponíveis no momento da renderização PHP e a lista é estática.

---

## 5. Decomposição via `{{ include() }}`

Para abas com múltiplos sub-formulários (modais com conteúdo próprio), quebrar o HTML em arquivos Twig incluídos:

**Template principal** (`templates/mytab.html.twig`):

```twig
{% block javascripts %}
<script type="module" defer="defer">
const { createApp, reactive, ... } = Vue;

const app = createApp({
    setup() {
        const formApp = reactive({ ... });
        const listApp = reactive({ ... });
        return { formApp, listApp };
    }
});

app.mount('#myplugin-app');
</script>
{% endblock %}

<div id="myplugin-app">
    {# Tabela principal #}
    {% verbatim %}
    <table>
        <tr v-for="item in listApp.items" :key="item.id">...</tr>
    </table>
    {% endverbatim %}

    {# Modal de edição em arquivo separado #}
    <div class="modal fade" id="editModal">
        <div class="modal-body">
            {{ include('@myplugin/components/edit_form.html.twig', {
                'options': options
            }) }}
        </div>
    </div>
</div>
```

**Arquivo incluído** (`templates/components/edit_form.html.twig`):

```twig
{# Sem createApp() — este HTML é parte do app Vue do template pai #}
{# Sem {% block javascripts %} — todo setup Vue fica no template pai #}

<form>
    {% verbatim %}
    <input v-model="formApp.name" />
    <span v-if="errorsApp.form_msg">{{ errorsApp.form_msg }}</span>
    {% endverbatim %}

    {# Valores Twig passados pelo include() são acessíveis aqui #}
    {% for key, label in options %}
    <div v-show="(formApp.type === '{{ key }}')">
        <label>{{ label }}</label>
    </div>
    {% endfor %}
</form>
```

Regras para arquivos de include:
- Não colocar `{% block javascripts %}` — todo setup Vue fica no template pai
- Não criar um segundo `createApp()` — o HTML incluído é parte do DOM do app pai
- Objetos reativos retornados pelo `setup()` do pai são acessíveis automaticamente
- Passar apenas variáveis de contexto Twig (PHP) para o include; estado Vue é compartilhado via o app pai

---

## 6. Ciclo de Vida de Renderização — Ordem dos Eventos

Entender esta sequência evita a categoria mais comum de bugs (tentar usar um valor que ainda não existe):

```
1. PHP executa
   └─ Consulta banco, instancia objetos, prepara variáveis

2. Twig renderiza
   └─ Avalia {{ }}, {% for %}, {{ csrf_token() }}, {{ include() }}
   └─ Produz HTML estático + strings JS com valores PHP embutidos

3. Browser recebe o HTML
   └─ Faz parse do HTML
   └─ Script Vue está em <script type="module" defer> no footer da página

4. DOM está completamente pronto
   └─ Vue script executa
   └─ createApp().setup() roda — objetos reativos são criados
   └─ app.mount('#id') — Vue assume controle do container

5. onBeforeMount() dispara
   └─ DOM ainda não está conectado ao Vue
   └─ Ideal para fetch de dados iniciais (lista, opções)
   └─ Estado reativo pode ser atualizado

6. onMounted() dispara
   └─ DOM está disponível e Vue está renderizado
   └─ Ideal para: injetar HTML de dropdowns GLPI, inicializar widgets externos
   └─ document.getElementById() funciona aqui com segurança
```

**Implicação prática:** Valores Twig embutidos no JS (passo 2) são strings estáticas no momento em que o Vue executa (passo 4). Não é possível atualizar esses valores reativamente — eles representam o estado do servidor no momento do carregamento da página. Para dados que mudam, usar `onBeforeMount()` + fetch.
