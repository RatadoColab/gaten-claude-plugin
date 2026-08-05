# GLPI 11 Form Templates — Dropdowns

## Regra Geral

**Idêntica ao GLPI 10** — nenhuma API de dropdown mudou de assinatura.

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
{{ fields.dropdownYesNo(
    'is_active',
    item.fields['is_active'],
    __('Ativo', 'nomedoplugin'),
    {'rand': rand, 'is_horizontal': true}
) }}

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

Usar quando a lógica de construção é complexa demais para Twig: ACL por entidade, joins customizados, filtros dinâmicos.

### No PHP (`src/MinhaClasse.php` ou Controller)

```php
ob_start();
User::dropdown([
    'name'   => '_nomedoplugin_responsible_users_id',
    'value'  => (int) ($fields['responsible_users_id'] ?? 0),
    'right'  => 'all',
    'entity' => (int) ($fields['entities_id'] ?? 0),
    'width'  => '100%',
]);
$responsible_dropdown = ob_get_clean();

TemplateRenderer::getInstance()->display(
    '@nomedoplugin/item.extrafields.html.twig',
    [
        'responsible_dropdown' => $responsible_dropdown,
        'fields'               => $fields,
    ]
);
```

### No Twig (`templates/item.extrafields.html.twig`)

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
</div>
```

**Regra:** usar `|raw` somente para HTML gerado por código PHP controlado (classes GLPI). Nunca usar `|raw` em dado de usuário sem antes aplicar `htmlescape()` no PHP — a auto-sanitização que protegia contra isso no GLPI 10 não existe mais no 11.

---

## 7. Dropdown de Array Estático (showFromArray)

```php
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

Dropdown filho cujos valores dependem de outro dropdown, preenchido a partir de um Controller (recomendado) ou de um handler legado sem `include`/`$AJAX_INCLUDE`.

### Controller (`src/Controller/DropdownController.php`)

```php
<?php

declare(strict_types=1);

namespace GlpiPlugin\Meuplugin\Controller;

use Glpi\Controller\AbstractController;
use Glpi\Exception\Http\BadRequestHttpException;
use GlpiPlugin\Meuplugin\MinhaSubClasse;
use Symfony\Component\HttpFoundation\{Request, Response};
use Symfony\Component\Routing\Attribute\Route;

final class DropdownController extends AbstractController
{
    #[Route("/DropdownSub", name: "meuplugin_dropdown_sub", methods: "GET")]
    public function __invoke(Request $request): Response
    {
        $parent_id = (int) $request->query->get('parent_id', 0);
        $rand      = (int) $request->query->get('rand', 0);

        if ($parent_id <= 0) {
            throw new BadRequestHttpException();
        }

        ob_start();
        MinhaSubClasse::dropdown([
            'name'      => 'sub_items_id',
            'condition' => ['parent_id' => $parent_id],
            'value'     => 0,
            'rand'      => $rand,
            'width'     => '100%',
        ]);
        $html = ob_get_clean();

        return new Response($html, 200, ['Content-Type' => 'text/html; charset=UTF-8']);
    }
}
```

### Template Twig

```twig
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

    fetch('{{ path("/plugins/nomedoplugin/DropdownSub") }}?' + new URLSearchParams({
        rand: rand,
        parent_id: parentId,
    }))
    .then((response) => response.text())
    .then((html) => {
        $('#div-sub-' + rand).html(html);
        $('#sub-group-' + rand).show();
    })
    .catch(() => console.error('Erro ao carregar subcategorias'));
}
</script>
{% endblock %}
```

---

## Referência: Parâmetros Comuns de Dropdown PHP

**Inalterados** em relação ao GLPI 10:

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
