---
description: Inicia o desenvolvimento de uma nova feature fullstack, identificando a stack em uso e acionando os agentes backend-dev e frontend-dev com as skills relevantes para cada contexto.
argument-hint: <nome-da-feature>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-feature

Guiar o desenvolvimento de uma nova feature identificando a stack do projeto e coordenando as implementações backend e frontend com as skills adequadas.

## Processo

1. Identificar a stack do projeto (linguagens, frameworks, estrutura de diretórios)
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/backend-base/SKILL.md`
3. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/frontend-base/SKILL.md`
4. Com base na stack identificada, carregar skills de linguagem pertinentes
5. Perguntar ao usuário:
   - Existe especificação disponível? (oferecer `/fullstack-development:review-spec` se houver)
   - A feature tem backend, frontend ou ambos?
6. Para cada parte (backend/frontend):
   - Carregar skills de domínio conforme o contexto da feature
   - Planejar a implementação antes de escrever código
   - Implementar seguindo as práticas carregadas
7. Ao final, listar arquivos criados/modificados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-feature autenticacao-usuario
/fullstack-development:new-feature modulo-relatorios
```
