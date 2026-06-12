# GLPI Form Templates — Layouts

## Estrutura Base do Formulário

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

<form method="post" action="{{ baseurl }}/plugins/nomedoplugin/front/item.form.php">
    <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />
    <input type="hidden" name="id" value="{{ item.fields['id'] ?? 0 }}" />

    <div class="card">
        <div class="card-header">
            <h3 class="card-title">{{ __('Título da seção', 'nomedoplugin') }}</h3>
        </div>
        <div class="card-body row">

            {# Campos aqui #}

        </div>
    </div>

    <div class="card-footer d-flex justify-content-end gap-2 mt-3">
        <button type="submit" class="btn btn-primary">
            {{ __('Salvar', 'nomedoplugin') }}
        </button>
        <a href="{{ baseurl }}/plugins/nomedoplugin/front/item.php" class="btn btn-outline-secondary">
            {{ __('Cancelar', 'nomedoplugin') }}
        </a>
    </div>
</form>
```

---

## Catálogo de Macros de Campo

```twig
{% set options = {
    'rand': rand,
    'is_horizontal': true,
    'fields_template': itiltemplate,
} %}

{# Texto simples #}
{{ fields.textField('name', item.fields['name'], __('Nome', 'nomedoplugin'), options) }}

{# Número #}
{{ fields.numberField('quantity', item.fields['quantity'], __('Quantidade', 'nomedoplugin'), options) }}

{# Textarea com rich text (TinyMCE) #}
{{ fields.textareaField('content', item.fields['content']|raw, __('Descrição', 'nomedoplugin'),
    options|merge({'enable_richtext': true, 'enable_fileupload': true})
) }}

{# Data #}
{{ fields.dateField('date_start', item.fields['date_start'], __('Data de início', 'nomedoplugin'), options) }}

{# Data e hora #}
{{ fields.datetimeField('date_mod', item.fields['date_mod'], __('Modificado em', 'nomedoplugin'), options) }}

{# Checkbox (toggle) #}
{{ fields.sliderField('is_active', item.fields['is_active'], __('Ativo', 'nomedoplugin'), options) }}

{# Campo somente leitura #}
{{ fields.readOnlyField('created_by', item.fields['created_by'], __('Criado por', 'nomedoplugin'), options) }}

{# Campo obrigatório #}
{{ fields.textField('name', item.fields['name'], __('Nome', 'nomedoplugin'),
    options|merge({'required': true})
) }}
```

---

## Layout 1: Formulário de Configuração com Múltiplos Cards

Padrão para formulários de configuração de plugin (`front/config.form.php`).

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

{% set options = {
    'rand': rand,
    'is_horizontal': true,
    'fields_template': null,
} %}

<form method="post" action="{{ baseurl }}/plugins/nomedoplugin/front/config.form.php">
    <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />

    {# Card 1: Configurações gerais #}
    <div class="card mb-4">
        <div class="card-header">
            <h3 class="card-title">{{ __('Configurações gerais', 'nomedoplugin') }}</h3>
        </div>
        <div class="card-body">

            {{ fields.dropdownYesNo(
                'enable_feature',
                item.fields['enable_feature'],
                __('Habilitar funcionalidade', 'nomedoplugin'),
                options|merge({'on_change': 'hide_show_element(this)'})
            ) }}

            <div id="enable_feature_div"
                 style="{{ item.fields['enable_feature'] ? '' : 'display:none' }}">

                {{ fields.dropdownField(
                    'Entity',
                    'default_entity',
                    item.fields['default_entity'],
                    __('Entidade padrão', 'nomedoplugin'),
                    options|merge({'width': 'auto'})
                ) }}

            </div>

            {{ fields.dropdownYesNo(
                'notify_users',
                item.fields['notify_users'],
                __('Notificar usuários', 'nomedoplugin'),
                options
            ) }}

        </div>
    </div>

    {# Card 2: Configurações avançadas #}
    <div class="card mb-4">
        <div class="card-header">
            <h3 class="card-title">{{ __('Configurações avançadas', 'nomedoplugin') }}</h3>
        </div>
        <div class="card-body">

            {{ fields.numberField(
                'max_items',
                item.fields['max_items'],
                __('Máximo de itens', 'nomedoplugin'),
                options
            ) }}

            {{ fields.textField(
                'api_key',
                item.fields['api_key'],
                __('Chave de API', 'nomedoplugin'),
                options
            ) }}

        </div>
    </div>

    <div class="d-flex justify-content-end mt-2">
        <button type="submit" name="save" class="btn btn-primary">
            {{ __('Salvar', 'nomedoplugin') }}
        </button>
    </div>

</form>

{% block javascripts %}
<script>
function hide_show_element(element) {
    var display = ($(element).val() == 0) ? 'none' : '';
    var name    = $(element).prop('name') + '_div';
    document.getElementById(name).style.display = display;
}
</script>
{% endblock %}
```

---

## Layout 2: Formulário de Entidade com Grid 2 Colunas

Padrão para formulários de criação/edição de entidade (`src/MinhaClasse.php` → `showForm()`).

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

{% set options = {
    'rand': rand,
    'is_horizontal': true,
} %}

<div class="card-body row">

    {# Linha 1: Nome (meia coluna) + Status (meia coluna) #}
    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Nome', 'nomedoplugin') }}<span class="required">*</span>
        </label>
        <div class="col-xxl-7 field-container">
            <input type="text" name="name"
                   class="form-control"
                   value="{{ item.fields['name'] ?? '' }}"
                   required="" />
        </div>
    </div>

    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Ativo', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            {{ dropdown_is_active|raw }}
        </div>
    </div>

    {# Linha 2: Entidade (meia coluna) + Grupo (meia coluna) #}
    {{ fields.dropdownField('Entity', 'entities_id', item.fields['entities_id'],
        __('Entidade', 'nomedoplugin'), options|merge({'width': 'auto'})
    ) }}

    {{ fields.dropdownField('Group', 'groups_id', item.fields['groups_id'],
        __('Grupo', 'nomedoplugin'), options|merge({'width': 'auto'})
    ) }}

    {# Linha 3: Data início + Data fim #}
    {{ fields.dateField('date_start', item.fields['date_start'],
        __('Data de início', 'nomedoplugin'), options)
    }}

    {{ fields.dateField('date_end', item.fields['date_end'],
        __('Data de fim', 'nomedoplugin'), options)
    }}

    {# Linha 4: Código SIORG (meia coluna) + Responsável (meia coluna) #}
    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Código SIORG', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            <input type="text" name="siorg_code"
                   class="form-control"
                   value="{{ item.fields['siorg_code'] ?? '' }}" />
        </div>
    </div>

    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Responsável', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            {# Dropdown PHP passado como variável (ver references/dropdowns.md) #}
            {{ manager_dropdown|raw }}
        </div>
    </div>

    {# Linha 5: Descrição (largura total) #}
    {{ fields.textareaField('comment', item.fields['comment'],
        __('Descrição', 'nomedoplugin'),
        options|merge({'full_width': true, 'rows': 4})
    ) }}

</div>
```

---

## Layout 3: Modal com Formulário e AJAX

Padrão para modais lançadas via botão em listagem ou detalhe de item.

```twig
{# Botão que abre o modal #}
<button type="button" class="btn btn-sm btn-outline-secondary"
        data-bs-toggle="modal" data-bs-target="#modal-clone-{{ rand }}">
    {{ __('Clonar', 'nomedoplugin') }}
</button>

{# Modal #}
<div class="modal fade" id="modal-clone-{{ rand }}" tabindex="-1"
     aria-labelledby="modal-clone-title-{{ rand }}" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modal-clone-title-{{ rand }}">
                    {{ __('Clonar item', 'nomedoplugin') }}
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"
                        aria-label="{{ __('Fechar') }}"></button>
            </div>

            <div class="modal-body">
                <form id="form-clone-{{ rand }}" method="post">
                    <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />
                    <input type="hidden" name="items_id" value="{{ item.fields['id'] }}" />

                    <div class="mb-3">
                        <p>{{ __('Selecione as opções de clonagem:', 'nomedoplugin') }}</p>

                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="radio" name="clone_type"
                                   value="full" id="clone-full-{{ rand }}" checked />
                            <label class="form-check-label" for="clone-full-{{ rand }}">
                                {{ __('Clonagem completa', 'nomedoplugin') }}
                            </label>
                        </div>

                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="radio" name="clone_type"
                                   value="partial" id="clone-partial-{{ rand }}" />
                            <label class="form-check-label" for="clone-partial-{{ rand }}">
                                {{ __('Apenas dados básicos', 'nomedoplugin') }}
                            </label>
                        </div>
                    </div>

                    <div class="mb-3">
                        {{ fields.textField('new_name', '',
                            __('Nome do novo item', 'nomedoplugin'),
                            {'rand': rand, 'required': true, 'full_width': true})
                        }}
                    </div>
                </form>
            </div>

            <div class="modal-footer">
                <div id="modal-alert-{{ rand }}" class="d-none alert alert-danger w-100" role="alert"></div>
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                    {{ __('Cancelar') }}
                </button>
                <button type="button" id="btn-clone-submit-{{ rand }}" class="btn btn-primary">
                    {{ __('Clonar', 'nomedoplugin') }}
                </button>
            </div>
        </div>
    </div>
</div>

{% block javascripts %}
<script>
$('#btn-clone-submit-{{ rand }}').on('click', function() {
    var btn = $(this);
    btn.prop('disabled', true);

    $.ajax({
        url:      '{{ baseurl }}/ajax/nomedoplugin/clone.php',
        type:     'POST',
        data:     $('#form-clone-{{ rand }}').serialize(),
        dataType: 'json',
    })
    .fail(function() {
        $('#modal-alert-{{ rand }}')
            .text('{{ __("Erro de comunicação. Tente novamente.", "nomedoplugin") }}')
            .removeClass('d-none');
        btn.prop('disabled', false);
    })
    .done(function(data) {
        if (data.success) {
            window.location.href = data.redirecturl || window.location.href;
        } else {
            $('#modal-alert-{{ rand }}')
                .text(data.message || '{{ __("Erro ao processar.", "nomedoplugin") }}')
                .removeClass('d-none');
            btn.prop('disabled', false);
        }
    });
});
</script>
{% endblock %}
```

---

## Layout 4: Wizard com Steps (jQuery Steps)

Padrão para formulários complexos divididos em etapas.

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

<div id="wizard-{{ rand }}" class="card-group">
    <div class="wizard-container">
        <form method="post" id="wizard-form-{{ rand }}"
              action="{{ baseurl }}/ajax/nomedoplugin/wizard.php">
            <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />
            <input type="hidden" name="type" value="{{ type }}" />

            <div>
                {# Step 1: Informações básicas #}
                <h3>{{ __('Informações básicas', 'nomedoplugin') }}</h3>
                <fieldset>
                    <div class="row">
                        <div class="col-lg-6">
                            <div class="form-group mb-4">
                                <label class="form-label">
                                    {{ __('Nome', 'nomedoplugin') }}<span class="required">*</span>
                                </label>
                                <input type="text" name="name" class="form-control" required="" />
                            </div>
                        </div>
                        <div class="col-lg-6">
                            <div class="form-group mb-4">
                                <label class="form-label">
                                    {{ __('Categoria', 'nomedoplugin') }}
                                </label>
                                <div id="div-category-{{ rand }}">
                                    {# Preenchido via AJAX #}
                                </div>
                            </div>
                        </div>
                    </div>
                </fieldset>

                {# Step 2: Detalhes #}
                <h3>{{ __('Detalhes', 'nomedoplugin') }}</h3>
                <fieldset>
                    <div class="form-group mb-4">
                        <label class="form-label">
                            {{ __('Descrição', 'nomedoplugin') }}<span class="required">*</span>
                        </label>
                        {{ fields.textareaField('content', '',
                            __('Descrição', 'nomedoplugin'),
                            {'rand': rand, 'enable_richtext': true, 'no_label': true, 'full_width': true})
                        }}
                    </div>
                </fieldset>

                {# Step 3: Confirmação #}
                <h3>{{ __('Confirmação', 'nomedoplugin') }}</h3>
                <fieldset>
                    <div id="div-summary-{{ rand }}">
                        {# Preenchido via JS antes de submeter #}
                    </div>
                </fieldset>
            </div>
        </form>
    </div>
</div>

{% block javascripts %}
<script>
$(document).ready(function() {
    $('#wizard-{{ rand }} > .wizard-container > form > div').steps({
        headerTag:    'h3',
        bodyTag:      'fieldset',
        transitionEffect: 'slideLeft',
        labels: {
            previous: '{{ __("Anterior") }}',
            next:     '{{ __("Próximo") }}',
            finish:   '{{ __("Finalizar") }}',
        },
        onStepChanging: function(event, currentIndex, newIndex) {
            // Validar step atual antes de avançar
            return true;
        },
        onFinished: function(event, currentIndex) {
            $('#wizard-form-{{ rand }}').submit();
        },
    });
});
</script>
{% endblock %}
```

---

## Layout 5: Formulário de Aba/Tab em Detalhe de Item

Padrão para formulários exibidos em abas do detalhe de um item GLPI (via `getTabNameForItem` / `displayTabContentForItem`).

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

<form method="post" action="{{ baseurl }}/plugins/nomedoplugin/front/extra.form.php">
    <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />
    <input type="hidden" name="items_id" value="{{ item_id }}" />
    <input type="hidden" name="itemtype" value="{{ itemtype }}" />

    <div class="card-body row">

        {{ fields.textField('reference_code', reference_code,
            __('Código de referência', 'nomedoplugin'),
            {'rand': rand, 'is_horizontal': true})
        }}

        {{ fields.dropdownField('User', 'responsible_users_id', responsible_id,
            __('Responsável técnico', 'nomedoplugin'),
            {'rand': rand, 'is_horizontal': true, 'width': 'auto'})
        }}

        {{ fields.textareaField('notes', notes,
            __('Observações', 'nomedoplugin'),
            {'rand': rand, 'is_horizontal': true, 'full_width': true})
        }}

    </div>

    <div class="d-flex justify-content-end p-3">
        <button type="submit" name="update" class="btn btn-primary">
            {{ __('Salvar alterações', 'nomedoplugin') }}
        </button>
    </div>
</form>
```

---

## Layout 6: Dropdown Dinâmico (carregado via AJAX em cascata)

Padrão quando um dropdown depende do valor de outro.

```twig
{# Dropdown pai (carregado inicialmente) #}
<div class="form-group mb-4">
    <label class="form-label">{{ __('Categoria pai', 'nomedoplugin') }}</label>
    <div id="div-parent-category-{{ rand }}">
        {{ parent_dropdown|raw }}
    </div>
</div>

{# Dropdown filho (preenchido via AJAX após seleção do pai) #}
<div class="form-group mb-4">
    <label class="form-label">{{ __('Subcategoria', 'nomedoplugin') }}</label>
    <div id="div-sub-category-{{ rand }}">
        <select class="form-select" disabled>
            <option value="">{{ __('Selecione uma categoria pai primeiro', 'nomedoplugin') }}</option>
        </select>
    </div>
</div>

{% block javascripts %}
<script>
// Listener no dropdown pai — busca filhos via AJAX
$(document).on('change', '[name="parent_categories_id"]', function() {
    var parentId = $(this).val();

    if (!parentId || parentId == 0) {
        $('#div-sub-category-{{ rand }}').html(
            '<select class="form-select" disabled>' +
            '<option value="">{{ __("Selecione uma categoria pai primeiro", "nomedoplugin") }}</option>' +
            '</select>'
        );
        return;
    }

    $.ajax({
        url:      '{{ baseurl }}/ajax/nomedoplugin/dropdown_sub.php',
        type:     'POST',
        data: {
            '_glpi_csrf_token':  '{{ csrf_token() }}',
            'rand':              '{{ rand }}',
            'parent_id':         parentId,
        },
        dataType: 'html',
    })
    .fail(function() {
        console.error('Erro ao carregar subcategorias');
    })
    .done(function(data) {
        $('#div-sub-category-{{ rand }}').html(data);
    });
});
</script>
{% endblock %}
```