---
name: glpi-form-templates
description: >
  This skill should be used when the user asks to "create a form template",
  "add a twig form", "build a GLPI form", "create a modal with form",
  "add a dropdown to a twig template", "create a config form", "build a
  wizard form", or mentions the templates/ directory in a GLPI plugin context.
version: 0.1.0
---

# GLPI — Templates de Formulários (Twig)

## Visão Geral

Formulários em plugins GLPI 10.x são implementados com templates Twig, utilizando macros nativas do GLPI para campos e o grid Bootstrap 5 para layout. Esta skill cobre os padrões modernos — evitar padrões legados baseados em `<table>`.

---

## 1. Import de Macros (Obrigatório)

Todo template de formulário deve importar as macros GLPI no topo:

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}
```

Este import dá acesso a todos os tipos de campo padronizados do GLPI.

---

## 2. Estrutura Base do Formulário

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

## 3. Grid de Campos (Bootstrap 5)

Usar o grid moderno em todos os formulários novos. **Nunca** usar `<table class="tab_cadre_fixe">` em código novo.

```twig
<div class="card-body row">

    {# Campo em meia coluna (padrão para a maioria dos campos) #}
    <div class="form-field row col-12 col-sm-6 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Nome', 'nomedoplugin') }}
            <span class="required">*</span>
        </label>
        <div class="col-xxl-7 field-container">
            <input type="text" name="name"
                   class="form-control"
                   value="{{ item.fields['name'] ?? '' }}"
                   required="" />
        </div>
    </div>

    {# Campo em coluna inteira #}
    <div class="form-field row col-12 mb-2">
        <label class="col-form-label col-xxl-5 text-xxl-end">
            {{ __('Descrição', 'nomedoplugin') }}
        </label>
        <div class="col-xxl-7 field-container">
            <textarea name="comment" class="form-control" rows="4">
                {{- item.fields['comment'] ?? '' -}}
            </textarea>
        </div>
    </div>

</div>
```

**Classes de coluna:**
- `col-12 col-sm-6` — campo em meia largura (2 colunas em telas médias+)
- `col-12` — campo em largura total
- `mb-2` — espaçamento entre campos

---

## 4. Macros de Campo

Usar macros sempre que disponíveis. São mais consistentes e já lidam com `rand`, `required` e estados de lock automaticamente.

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
```

**Opções comuns das macros:**

| Opção | Tipo | Descrição |
|-------|------|-----------|
| `rand` | int | Sufixo único para IDs (obrigatório) |
| `is_horizontal` | bool | Label ao lado do campo (padrão: true) |
| `required` | bool | Marca campo como obrigatório |
| `disabled` | bool | Desabilita o campo |
| `readonly` | bool | Campo somente leitura |
| `full_width` | bool | Ocupa `col-12` em vez de `col-12 col-sm-6` |
| `input_addclass` | string | Classes CSS adicionais no input |
| `on_change` | string | Código JS executado no `change` event |
| `fields_template` | object | Template GLPI (controla campos ocultos/obrigatórios) |

---

## 5. Dropdowns

### Regra de uso:

| Situação | Abordagem |
|----------|-----------|
| Dropdown de classe GLPI padrão | Macro Twig `fields.dropdownField()` |
| Dropdown Sim/Não | Macro Twig `fields.dropdownYesNo()` |
| Lógica complexa (ACL, joins, filtros dinâmicos) | PHP `ob_start()` + `ob_get_clean()` → variável Twig |
| Código legado com `{% do call('Dropdown::show...') %}` | Refatorar para macro Twig |

Para exemplos completos de todos os padrões de dropdown, consultar **`references/dropdowns.md`**.

---

## 6. Campos Obrigatórios

```twig
{# Via macro — usar opção required #}
{{ fields.textField('name', item.fields['name'], __('Nome', 'nomedoplugin'),
    options|merge({'required': true})
) }}

{# Via HTML manual — usar atributo required e asterisco no label #}
<div class="form-field row col-12 col-sm-6 mb-2">
    <label class="col-form-label col-xxl-5 text-xxl-end">
        {{ __('Campo', 'nomedoplugin') }}<span class="required">*</span>
    </label>
    <div class="col-xxl-7 field-container">
        <input type="text" name="field" class="form-control" required="" />
    </div>
</div>
```

---

## 7. Show/Hide Condicional

Padrão para exibir/ocultar seções baseado em valor de outro campo:

```twig
{# Campo que controla a visibilidade #}
{{ fields.dropdownYesNo(
    'enable_feature',
    item.fields['enable_feature'],
    __('Habilitar funcionalidade', 'nomedoplugin'),
    options|merge({'on_change': 'hide_show_element(this)'})
) }}

{# Seção que aparece/desaparece — ID segue o padrão: {field_name}_div #}
<div id="enable_feature_div"
     style="{{ item.fields['enable_feature'] ? '' : 'display:none' }}">

    {{ fields.textField('feature_config', item.fields['feature_config'],
        __('Configuração', 'nomedoplugin'), options)
    }}

</div>

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

## 8. Modal com Formulário

```twig
<div class="modal fade" id="modal-{{ rand }}" tabindex="-1"
     aria-labelledby="modal-title-{{ rand }}" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modal-title-{{ rand }}">
                    {{ __('Título do Modal', 'nomedoplugin') }}
                </h5>
                <button type="button" class="btn-close"
                        data-bs-dismiss="modal" aria-label="{{ __('Fechar') }}">
                </button>
            </div>
            <div class="modal-body">
                <form id="form-modal-{{ rand }}" method="post"
                      action="{{ baseurl }}/ajax/nomedoplugin/handler.php">
                    <input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}" />

                    <div class="mb-3">
                        {{ fields.textField('name', '', __('Nome', 'nomedoplugin'),
                            {'rand': rand, 'required': true, 'full_width': true})
                        }}
                    </div>

                    <div class="mb-3">
                        {{ fields.dropdownYesNo('is_active', 1,
                            __('Ativo', 'nomedoplugin'), {'rand': rand, 'full_width': true})
                        }}
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <div id="modal-alert-{{ rand }}" class="d-none alert alert-danger w-100" role="alert"></div>
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                    {{ __('Cancelar') }}
                </button>
                <button type="submit" form="form-modal-{{ rand }}" class="btn btn-primary">
                    {{ __('Confirmar', 'nomedoplugin') }}
                </button>
            </div>
        </div>
    </div>
</div>
```

---

## 9. Regras de UX (Obrigatórias)

Critérios de UX obrigatórios para formulários GLPI:

- **Labels acima dos campos** em formulários verticais — nunca substituir label por placeholder
- **Indicar campos obrigatórios** com asterisco `<span class="required">*</span>`
- **Validação no `blur`** (quando o campo perde foco), nunca keystroke-a-keystroke
- **Erros inline** abaixo do campo, não em alert genérico
- **Nunca limpar o formulário** após erro — preservar o que o usuário digitou
- **Botão primário à direita**, cancelar à esquerda
- **Desabilitar o botão** durante submissão (evitar duplo clique)
- **Verbos de ação** nos botões: "Salvar", "Criar item", "Enviar" — nunca "OK" ou "Confirmar"

---

## Recursos Adicionais

- **`references/layouts.md`** — Templates completos por tipo de layout (2 colunas, modal, wizard, config com cards)
- **`references/dropdowns.md`** — Todos os padrões de dropdown: Twig simples, condicionais, múltiplo, PHP+Twig e AJAX dinâmico