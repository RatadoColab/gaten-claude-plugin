---
description: Executa revisão estruturada de uma especificação de feature usando as skills spec-base e spec-review. Avalia clareza, completude, critérios de aceite e escopo, produzindo relatório com status SCOPE, gaps, riscos e sugestões de melhoria.
argument-hint: <caminho-da-spec ou conteúdo da spec>
allowed-tools: [Read, Write, Grep, Glob, WebSearch]
---

# review-spec

Revisar a especificação fornecida pelo usuário aplicando o protocolo completo de avaliação de specs para desenvolvimento em IA.

## Processo

1. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/spec-base/SKILL.md` para carregar os fundamentos
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/domains/spec-review/SKILL.md` para carregar o protocolo de revisão
3. Se o argumento for um caminho de arquivo, ler o arquivo
4. Aplicar o checklist completo da skill spec-review
5. Produzir o relatório no formato definido na seção "Resultado da Revisão" da skill spec-review (Sumário com status SCOPE, Gaps, Riscos e Sugestões)
6. Perguntar ao usuário se deseja a versão revisada da spec

## Dicas de Uso

```
/fullstack-development:review-spec caminho/para/spec.md
/fullstack-development:review-spec "Descrição inline da feature aqui"
```
