---
description: Inicia o desenvolvimento de uma nova feature fullstack, identificando a stack em uso e acionando os agentes backend-dev e frontend-dev com as skills relevantes para cada contexto.
argument-hint: <nome-da-feature>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-feature

Guiar o desenvolvimento de uma nova feature com fluxo spec-first: gera especificação estruturada, submete à revisão paralela de domínio e consolida um plano final para aprovação antes de qualquer implementação.

## Processo

### Fase 1 — Identificação de stack

1. Identificar a stack do projeto (linguagens, frameworks, estrutura de diretórios)
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/backend-base/SKILL.md`
3. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/frontend-base/SKILL.md`
4. Com base na stack identificada, carregar skills de linguagem pertinentes

### Fase 2 — Especificação da feature (spec-dev)

5. Usar o agente `spec-dev` para criar a especificação a partir da demanda:
   - Se o usuário já tiver uma spec, validá-la e melhorá-la em vez de criar do zero
   - Dividir explicitamente em seção **Backend** e seção **Frontend**
   - Incluir: objetivo, critérios de aceite, restrições, fluxo de dados e arquivos esperados
   - Salvar a spec em `.claude/specs/<nome-da-feature>.md`

### Fase 3 — Revisão paralela de domínio

6. Acionar **em paralelo** os dois agentes de domínio, cada um revisando apenas sua seção:
   - `backend-dev` — instrução: **"Revise apenas a seção Backend da spec em `.claude/specs/<nome>.md`. Aponte lacunas, riscos técnicos e ajustes necessários. NÃO escreva código — retorne somente o relatório de revisão e a seção Backend corrigida."**
   - `frontend-dev` — instrução: **"Revise apenas a seção Frontend da spec em `.claude/specs/<nome>.md`. Aponte lacunas, riscos de UX/integração e ajustes necessários. NÃO escreva código — retorne somente o relatório de revisão e a seção Frontend corrigida."**
   - Cada agente deve carregar suas skills de domínio conforme a stack identificada na Fase 1

   Formato esperado de cada relatório de revisão:
   ```markdown
   ## Revisão [Backend|Frontend] — <nome-da-feature>

   ### Gaps identificados
   - [gap]: descrição

   ### Riscos
   - [risco]: descrição e mitigação sugerida

   ### Seção [Backend|Frontend] corrigida
   [texto revisado da seção]
   ```

### Fase 4 — Plano final e aprovação

7. Consolidar spec original + feedbacks dos dois agentes em um **Plano Final** contendo:
   - Spec revisada unificada (backend + frontend)
   - Lista de arquivos a criar/modificar separados por escopo
   - Pontos de atenção levantados pelos agentes
   - Estimativa de impacto em arquivos existentes
8. Apresentar o Plano Final ao usuário e **aguardar aprovação explícita** antes de continuar

### Fase 5 — Implementação (somente após aprovação)

9. Para cada parte aprovada (backend/frontend):
   - Carregar skills de domínio conforme o contexto da feature
   - Implementar seguindo o Plano Final aprovado
10. Ao final, listar arquivos criados/modificados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-feature autenticacao-usuario
/fullstack-development:new-feature modulo-relatorios
```
