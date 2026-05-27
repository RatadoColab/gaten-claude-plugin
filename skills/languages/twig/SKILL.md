---
name: twig
description: This skill should be used when writing, reviewing, or refactoring Twig templates. Covers template syntax, inheritance, macros, filters, functions, and Twig best practices for maintainable templates.
version: 0.1.0
---

# Twig — Convenções e Boas Práticas

## Visão Geral

Diretrizes para escrita de templates Twig limpos, reutilizáveis e seguros.

## Sintaxe Básica

- `{{ variavel }}` — exibição de variável (auto-escapada por padrão)
- `{% tag %}` — tags de controle (if, for, block, extends)
- `{# comentário #}` — comentários (não renderizados no HTML)

## Herança de Templates

```twig
{# layout.html.twig #}
<!DOCTYPE html>
<html>
  <body>
    {% block content %}{% endblock %}
    {% block scripts %}{% endblock %}
  </body>
</html>

{# page.html.twig #}
{% extends 'layout.html.twig' %}

{% block content %}
  <h1>Conteúdo da Página</h1>
{% endblock %}
```

## Boas Práticas

- **Herança:** Usar `extends` para evitar duplicação de layout
- **Includes:** `{% include %}` para fragmentos reutilizáveis
- **Macros:** Para componentes reutilizáveis dentro de templates
- **Filtros:** Usar filtros nativos (`|date`, `|upper`, `|slice`) antes de criar customizados
- **Escape:** Nunca desabilitar auto-escape (`|raw`) sem necessidade justificada

## Lógica nos Templates

- Manter lógica mínima nos templates (sem computações complexas)
- Processar dados no controller/service antes de passar ao template
- Usar variáveis descritivas; evitar acesso profundo como `obj.a.b.c.d`

## Referências

- Ver `languages/html/SKILL.md` para estrutura HTML semântica
