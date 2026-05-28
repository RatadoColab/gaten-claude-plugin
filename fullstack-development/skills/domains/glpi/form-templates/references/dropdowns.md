# GLPI Form Templates — Dropdowns

## Regra Geral

| Situação | Abordagem |
|----------|-----------|
| Dropdown de classe GLPI simples | Macro Twig `fields.dropdownField()` |
| Dropdown Yes/No | Macro Twig `fields.dropdownYesNo()` |
| Dropdown com lógica complexa (ACL, filtros dinâmicos, joins) | PHP `ob_start()` + `ob_get_clean()` → variável Twig |
| Dropdown legado com `{% do call() %}` | Refatorar para macro Twig quando possível |

---

## 1. Dropdown de Classe GLPI (Macro — Preferido)

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}

{% set options = {'rand': rand, 'is_horizontal': true} %}

{# Dropdown de entidade #}
{{ fields.dropdownField(
    'Entity',
    'entities_id',
    item.fields['entities_id'],
    __('Entidade', 'nomedoplugin'),
    options|merge({'width': 'auto'})
) }}

{# Dropdown de usuário com direito específico #}
{{ fields.dropdownField(
    'User',
    'users_id',
    item.fields['users_id'],
    __('Responsável', 'nomedoplugin'),
    options|merge({'right': 'all', 'width': 'auto'})
) }}

{# Dropdown de grupo #}
{{ fields.dropdownField(
    'Group',
    'groups_id',
    item.fields['groups_id'],
    __('Grupo', 'nomedoplugin'),
    options
) }}

{# Dropdown de localização #}
{{ fields.dropdownField(
    'Location',
    'locations_id',
    item.fields['locations_id'],
    __('Localização', 'nomedoplugin'),
    options|merge({'entity': item.fields['entities_id']})
) }}

{# Dropdown de categoria ITIL com condição #}
{{ fields.dropdownField(
    'ITILCategory',
    'itilcategories_id',
    item.fields['itilcategories_id'],
    __('Categoria', 'nomedoplugin'),
    options|merge({
        'condition': {'OR': {'is_incident': true, 'is_request': true}},
        'entity': item.fields['entities_id'],
    })
) }}
```

---

## 2. Dropdown Sim/Não

```twig
{# Padrão básico #}
{{ fields.dropdownYesNo(
    'is_active',
    item.fields['is_active'],
    __('Ativo', 'nomedoplugin'),
    {'rand': rand, 'is_horizontal': true}
) }}

{# Com show/hide condicional #}
{{ fields.dropdownYesNo(
    'enable_feature',
    item.fields['enable_feature'],
    __('Habilitar funcionalidade', 'nomedoplugin'),
    {'rand': rand, 'is_horizontal': true, 'on_change': 'hide_show_element(this)'}
) }}
```

---

## 3. Dropdown com Seleção Múltipla

```twig
{# Múltipla seleção via macro #}
{{ fields.dropdownField(
    'Entity',
    'restricted_entities',
    item.fields['restricted_entities'],
    __('Entidades restritas', 'nomedoplugin'),
    {'rand': rand, 'is_horizontal': true, 'multiple': true, 'width': 'auto'}
) }}
```

---

## 4. Dropdown com Items Excluídos (used)

```twig
{# Excluir IDs já utilizados (evitar duplicatas) #}
{{ fields.dropdownField(
    'User',
    'users_id',
    0,
    __('Adicionar usuário', 'nomedoplugin'),
    {
        'rand': rand,
        'is_horizontal': true,
        'used': already_assigned_users_ids,
    }
) }}
```

---

## 5. Dropdown com on_change

```twig
{# Chamar função JS ao mudar valor #}
{{ fields.dropdownField(
    'ITILCategory',
    'itilcategories_id',
    item.fields['itilcategories_id'],
    __('Categoria', 'nomedoplugin'),
    {
        'rand': rand,
        'is_horizontal': true,
        'on_change': 'loadSubcategoryDropdown(' ~ rand ~ ')',
    }
) }}
```

---

## 6. Dropdown PHP Complexo → Twig (ob_start / ob_get_clean)

Usar quando a lógica de construção do dropdown é complexa demais para Twig: ACL por entidade, joins customizados, filtros dinâmicos.

### No PHP (src/MinhaClasse.php ou front/item.form.php)

```php
// Constrói dropdown de usuário com direitos de entidade específicos
ob_start();
User::dropdown([
    'name'   => '_nomedoplugin_responsible_users_id',
    'value'  => (int) ($fields['responsible_users_id'] ?? 0),
    'right'  => 'all',
    'entity' => (int) ($fields['entities_id'] ?? 0),
    'width'  => '100%',
]);
$responsible_dropdown = ob_get_clean();

// Constrói dropdown de localização com recursividade controlada
ob_start();
Location::dropdown([
    'name'        => '_nomedoplugin_locations_id',
    'value'       => (int) ($fields['locations_id'] ?? 0),
    'entity'      => (int) ($fields['entities_id'] ?? 0),
    'entity_sons' => true,
    'width'       => '100%',
]);
$location_dropdown = ob_get_clean();

// Passa para o template Twig
TemplateRenderer::getInstance()->display(
    '@nomedoplugin/item.extrafields.html.twig',
    [
        'responsible_dropdown' => $responsible_dropdown,
        'location_dropdown'    => $location_dropdown,
        'fields'               => $fields,
    ]
);
```

### No Twig (templates/item.extrafields.html.twig)

```twig
<div class="card-body row">

    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Responsável', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            {{ responsible_dropdown|raw }}
        </div>
    </div>

    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Localização', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            {{ location_dropdown|raw }}
        </div>
    </div>

</div>
```

**Regra:** Usar `|raw` somente para HTML gerado por código PHP controlado (classes GLPI). Nunca usar `|raw` em dados de usuário.

---

## 7. Dropdown de Array Estático (showFromArray)

Quando os valores são uma lista fixa, não de um CommonDBTM.

```php
// No PHP, antes de chamar o template
ob_start();
Dropdown::showFromArray('status', [
    0 => __('Inativo'),
    1 => __('Ativo'),
    2 => __('Pendente'),
], [
    'value' => (int) ($fields['status'] ?? 0),
    'rand'  => $rand,
    'width' => '100%',
]);
$status_dropdown = ob_get_clean();
```

```twig
{# No Twig #}
<div class="form-field row col-12 col-sm-6 mb-2">
    <label class="col-form-label col-xxl-5 text-xxl-end">
        {{ __('Status', 'nomedoplugin') }}
    </label>
    <div class="col-xxl-7 field-container">
        {{ status_dropdown|raw }}
    </div>
</div>
```

---

## 8. Dropdown Dinâmico (preenchido via AJAX)

Dropdown filho cujos valores dependem de outro dropdown. O container começa vazio e é preenchido via AJAX.

### Handler AJAX (ajax/dropdown_sub.php)

```php
<?php

$AJAX_INCLUDE = 1;
$_SERVER['HTTP_X_GLPI_CSRF_TOKEN'] = $_POST['_glpi_csrf_token'] ?? '';
include('../../../inc/includes.php');

header('Content-Type: text/html; charset=UTF-8');
Html::header_nocache();

if (!defined('GLPI_ROOT')) {
    http_response_code(403);
    die();
}

Session::checkCentralAccess();

$parent_id = (int) filter_input(INPUT_POST, 'parent_id', FILTER_SANITIZE_NUMBER_INT);
$rand      = (int) filter_input(INPUT_POST, 'rand', FILTER_SANITIZE_NUMBER_INT);

if ($parent_id <= 0) {
    http_response_code(400);
    die();
}

// Renderiza o dropdown filtrado pelo parent
MinhaSubClasse::dropdown([
    'name'      => 'sub_items_id',
    'condition' => ['parent_id' => $parent_id],
    'value'     => 0,
    'rand'      => $rand,
    'width'     => '100%',
]);

exit;
```

### Template Twig

```twig
{# Dropdown pai com on_change #}
<div class="form-group mb-4" id="parent-group-{{ rand }}">
    <label class="form-label">{{ __('Categoria', 'nomedoplugin') }}</label>
    {{ fields.dropdownField(
        'MinhaClasse',
        'items_id',
        selected_id,
        '',
        {'rand': rand, 'no_label': true, 'on_change': 'loadSubDropdown(' ~ rand ~ ')'}
    ) }}
</div>

{# Dropdown filho — começa vazio ou com valor salvo #}
<div class="form-group mb-4" id="sub-group-{{ rand }}"
     style="{{ selected_id ? '' : 'display:none' }}">
    <label class="form-label">{{ __('Subcategoria', 'nomedoplugin') }}</label>
    <div id="div-sub-{{ rand }}">
        {{ sub_dropdown|raw }}
    </div>
</div>

{% block javascripts %}
<script>
function loadSubDropdown(rand) {
    var parentId = $('[name="items_id"]').val();

    if (!parentId || parentId == 0) {
        $('#sub-group-' + rand).hide();
        return;
    }

    $.ajax({
        url:  '{{ baseurl }}/ajax/nomedoplugin/dropdown_sub.php',
        type: 'POST',
        data: {
            '_glpi_csrf_token': '{{ csrf_token() }}',
            'rand':             rand,
            'parent_id':        parentId,
        },
        dataType: 'html',
    })
    .done(function(data) {
        $('#div-sub-' + rand).html(data);
        $('#sub-group-' + rand).show();
    })
    .fail(function() {
        console.error('Erro ao carregar subcategorias');
    });
}
</script>
{% endblock %}
```

---

## Referência: Parâmetros Comuns de Dropdown PHP

```php
SomeClass::dropdown([
    'name'        => 'field_name',       // name do input HTML
    'value'       => $current_value,     // valor selecionado atual
    'rand'        => $rand,              // sufixo único para IDs
    'entity'      => $entities_id,       // filtrar por entidade
    'entity_sons' => true,               // incluir subentidades
    'condition'   => ['is_active' => 1], // WHERE adicional
    'used'        => [1, 2, 3],          // IDs a excluir da lista
    'multiple'    => false,              // seleção múltipla
    'right'       => 'all',              // ACL de usuário (para User::dropdown)
    'on_change'   => 'myFunction(this)', // callback JS no change
    'width'       => '100%',             // CSS width
    'addicon'     => false,              // oculta ícone de edição/adição
    'emptylabel'  => '---',              // texto da opção vazia
    'display_emptychoice' => true,       // exibir opção vazia
]);
```