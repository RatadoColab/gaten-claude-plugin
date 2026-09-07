---
name: glpi-12-form-templates
description: >
  This skill should be used when the user asks to "create a form template",
  "add a twig form", "build a GLPI form", "create a modal with form",
  "add a dropdown to a twig template", "create a config form", "build a
  wizard form", or mentions the templates/ directory — in a GLPI 12 plugin
  context (explicit "GLPI 12" mention, `requirements.glpi.min` starting with
  "12.", or no `csrf_token()` / `_glpi_csrf_token` in existing forms). For
  GLPI 11 (`csrf_token()` in Twig, `_glpi_csrf_token` fields), use
  `domains/glpi-11/form-templates/SKILL.md`; for GLPI 10.0.x, use
  `domains/glpi-10/form-templates/SKILL.md`. If the GLPI version cannot be
  determined, ask before generating code.
---

# GLPI 12 — Templates de Formulários (Twig)

> **Versão-alvo:** GLPI 12. Para GLPI 11, usar `domains/glpi-11/form-templates/SKILL.md`; para GLPI 10.0.x, `domains/glpi-10/form-templates/SKILL.md`.

## Visão Geral

Formulários em plugins GLPI 12 continuam sendo implementados com templates Twig, as mesmas macros nativas para campos e o grid Bootstrap 5 para layout — o sistema de templates **não muda**. O único delta relevante em relação ao GLPI 11: **o hidden de CSRF (`csrf_token()` / `_glpi_csrf_token`) deixou de existir** — a proteção passou a ser validação de header no kernel. URLs continuam via `path('/plugins/nomedoplugin/...')`.

---

## 1. Import de Macros (Obrigatório)

Idêntico ao GLPI 10:

```twig
{% import 'components/form/fields_macros.html.twig' as fields %}
```

---

## 2. Estrutura Base do Formulário

Esqueleto: `<form method="post">` com `action` apontando para a rota do plugin, hidden de `id`, conteúdo em `.card` (`card-header` + `card-body row`) e `card-footer` com os botões. **Sem** hidden de CSRF — `csrf_token()` / `_glpi_csrf_token` não são mais usados no GLPI 12 (removidos; a checagem é por header no kernel).

URL: se o formulário submete para um Controller, usar `path('/plugins/nomedoplugin/MeuItem')`; se ainda submete para `front/item.form.php` legado, `path('/plugins/nomedoplugin/front/item.form.php')`. `get_plugin_web_dir()` e `Plugin::getWebDir()` foram removidas — só caminho literal. Template completo na seção **Estrutura Base** de `references/layouts.md`.

---

## 3. Grid de Campos (Bootstrap 5)

**Inalterado.** Usar o grid moderno em todos os formulários novos. Nunca usar `<table class="tab_cadre_fixe">`.

```twig
<div class="form-field row col-12 col-sm-6 mb-2">
    <label class="col-form-label col-xxl-5 text-xxl-end">{{ __('Nome', 'nomedoplugin') }}<span class="required">*</span></label>
    <div class="col-xxl-7 field-container">
        <input type="text" name="name" class="form-control" value="{{ item.fields['name'] ?? '' }}" required="" />
    </div>
</div>
```

Formulário completo em grid 2 colunas no **Layout 2** de `references/layouts.md`.

---

## 4. Macros de Campo

**Inalterado.** Macros disponíveis: `textField`, `numberField`, `textareaField` (rich text via `enable_richtext`), `dateField`, `datetimeField`, `sliderField`, `readOnlyField`, `dropdownField`, `dropdownYesNo`.

```twig
{{ fields.textField('name', item.fields['name'], __('Nome', 'nomedoplugin'), options) }}
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

Exemplo de cada macro na seção **Catálogo de Macros de Campo** de `references/layouts.md`.

---

## 5. Dropdowns

### Regra de uso:

| Situação | Abordagem |
|----------|-----------|
| Dropdown de classe GLPI padrão | Macro Twig `fields.dropdownField()` |
| Dropdown Sim/Não | Macro Twig `fields.dropdownYesNo()` |
| Lógica complexa (ACL, joins, filtros dinâmicos) | PHP `ob_start()` + `ob_get_clean()` → variável Twig, com `htmlescape()` aplicado a qualquer valor de usuário interpolado no HTML gerado |
| Código legado com `{% do call('Dropdown::show...') %}` | Refatorar para macro Twig |

Para exemplos completos de todos os padrões de dropdown, consultar **`references/dropdowns.md`**.

---

## 6. Campos Obrigatórios

Via macro: `options|merge({'required': true})`. Via HTML manual: atributo `required` no input + asterisco no label:

```twig
{{ __('Campo', 'nomedoplugin') }}<span class="required">*</span>
```

---

## 7. Show/Hide Condicional

**Inalterado.** Campo controlador recebe `on_change: 'hide_show_element(this)'`, seção controlada usa `{field_name}_div` com `display:none` inicial. Implementação completa no **Layout 1** de `references/layouts.md`.

---

## 8. Modal com Formulário

Modal Bootstrap 5 idêntico ao GLPI 10 em estrutura. A submissão via AJAX aponta para a rota do Controller em vez de `ajax/nomedoplugin/clone.php`, quando o handler já foi migrado. Template completo no **Layout 3** de `references/layouts.md`.

---

## 9. Escape e CSRF

`|verbatim_value` continua inexistente (removido no 11). `|raw` apenas para HTML gerado por código PHP controlado — nunca em dado de usuário sem `htmlescape()` antes.

**CSRF:** remover de todo template herdado o hidden `<input type="hidden" name="_glpi_csrf_token" value="{{ csrf_token() }}">`, a chamada `{{ csrf_token() }}` e a macro `{{ fields.csrfField() }}` — no GLPI 12 a função Twig `csrf_token()` está depreciada (removida no 13) e o campo é ignorado. Nenhuma substituição: POSTs same-origin passam pela validação de header automaticamente.

---

## 10. Regras de UX (Obrigatórias)

Aplicar as regras gerais de formulários de `domains/forms/SKILL.md` (label sempre visível, validação no `blur`, erros inline, preservar dados após erro, desabilitar botão durante submissão). Específicos do GLPI:

- **Campos obrigatórios** com asterisco `<span class="required">*</span>` — padrão GLPI, prevalece sobre o markup genérico de `domains/forms`
- **Botão primário à direita**, cancelar à esquerda
- **Verbos de ação** nos botões: "Salvar", "Criar item", "Enviar" — nunca "OK" ou "Confirmar"

---

## Recursos Adicionais

- **`references/layouts.md`** — Estrutura base, catálogo de macros e templates completos por tipo de layout (2 colunas, modal, wizard, config com cards)
- **`references/dropdowns.md`** — Todos os padrões de dropdown: Twig simples, condicionais, múltiplo, PHP+Twig e AJAX dinâmico
