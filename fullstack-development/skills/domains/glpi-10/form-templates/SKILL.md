---
name: glpi-10-form-templates
description: >
  This skill should be used when the user asks to "create a form template",
  "add a twig form", "build a GLPI form", "create a modal with form",
  "add a dropdown to a twig template", "create a config form", "build a
  wizard form", or mentions the templates/ directory — in a GLPI 10.0.x
  plugin context (explicit "GLPI 10" mention, or project indicators such as
  `include('../../../inc/includes.php')` in front/ajax and no `public/`
  directory). For GLPI 11 (`public/` directory, `src/Controller/` with
  `#[Route]`), use `domains/glpi-11/form-templates/SKILL.md` instead. If the
  GLPI version cannot be determined, ask before generating code.
---

# GLPI 10.x — Templates de Formulários (Twig)

> **Versão-alvo:** GLPI 10.0.x. Para GLPI 11, usar `domains/glpi-11/form-templates/SKILL.md`.

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

Esqueleto: `<form method="post">` com `action` apontando para `front/item.form.php`, hidden de CSRF (`_glpi_csrf_token` via `csrf_token()`) e de `id`, conteúdo em `.card` (`card-header` com título traduzido + `card-body row` com os campos) e `card-footer` com os botões. Template completo na seção **Estrutura Base** de `references/layouts.md`.

---

## 3. Grid de Campos (Bootstrap 5)

Usar o grid moderno em todos os formulários novos. **Nunca** usar `<table class="tab_cadre_fixe">` em código novo.

```twig
<div class="form-field row col-12 col-sm-6 mb-2">
    <label class="col-form-label col-xxl-5 text-xxl-end">{{ __('Nome', 'nomedoplugin') }}<span class="required">*</span></label>
    <div class="col-xxl-7 field-container">
        <input type="text" name="name" class="form-control" value="{{ item.fields['name'] ?? '' }}" required="" />
    </div>
</div>
```

**Classes de coluna:**
- `col-12 col-sm-6` — campo em meia largura (2 colunas em telas médias+)
- `col-12` — campo em largura total
- `mb-2` — espaçamento entre campos

Formulário completo em grid 2 colunas no **Layout 2** de `references/layouts.md`.

---

## 4. Macros de Campo

Usar macros sempre que disponíveis. São mais consistentes e já lidam com `rand`, `required` e estados de lock automaticamente. Macros disponíveis: `textField`, `numberField`, `textareaField` (rich text via `enable_richtext`), `dateField`, `datetimeField`, `sliderField` (toggle), `readOnlyField`, `dropdownField`, `dropdownYesNo`.

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
| Lógica complexa (ACL, joins, filtros dinâmicos) | PHP `ob_start()` + `ob_get_clean()` → variável Twig |
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

Para exibir/ocultar seções baseado em valor de outro campo: o campo controlador recebe `on_change: 'hide_show_element(this)'` e a seção controlada usa o ID no padrão `{field_name}_div`, com `display:none` inicial quando o valor é falso. Implementação completa (incluindo a função JS) no **Layout 1** de `references/layouts.md`.

---

## 8. Modal com Formulário

Modal Bootstrap 5 com `id`/`aria-labelledby` sufixados por `{{ rand }}`, formulário com CSRF no `modal-body`, área de alerta (`d-none alert alert-danger`) no `modal-footer` e submissão via AJAX com botão desabilitado durante o envio. Template completo no **Layout 3** de `references/layouts.md`.

---

## 9. Regras de UX (Obrigatórias)

Aplicar as regras gerais de formulários de `domains/forms/SKILL.md` (label sempre visível — nunca placeholder no lugar, validação no `blur`, erros inline, preservar dados após erro, desabilitar botão durante submissão). Específicos do GLPI:

- **Campos obrigatórios** com asterisco `<span class="required">*</span>` — padrão GLPI, prevalece sobre o markup genérico de `domains/forms`
- **Botão primário à direita**, cancelar à esquerda
- **Verbos de ação** nos botões: "Salvar", "Criar item", "Enviar" — nunca "OK" ou "Confirmar"

---

## Recursos Adicionais

- **`references/layouts.md`** — Estrutura base, catálogo de macros e templates completos por tipo de layout (2 colunas, modal, wizard, config com cards)
- **`references/dropdowns.md`** — Todos os padrões de dropdown: Twig simples, condicionais, múltiplo, PHP+Twig e AJAX dinâmico
