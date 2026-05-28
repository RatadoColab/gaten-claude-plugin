---
name: spec-base
description: This skill should be used when reviewing, evaluating, or improving specifications for AI-driven development. Covers quality criteria, structure standards, and completeness checks for feature and system specifications.
version: 0.2.0
---

# Spec Base — Fundamentos de Especificações para IA

## Visão Geral

Fornece os princípios fundamentais para avaliação e criação de especificações destinadas ao desenvolvimento guiado por LLMs.

## Princípios Fundamentais

- **Clareza:** Cada requisito deve ser interpretável de forma única, sem ambiguidade
- **Completude:** A spec deve cobrir fluxo principal, fluxos alternativos e casos de erro
- **Mensurabilidade:** Critérios de aceite devem ser verificáveis objetivamente
- **Contexto suficiente:** O LLM precisa entender o domínio sem conhecimento externo implícito
- **Escopo delimitado:** O que está dentro e fora do escopo deve ser explícito

---

## Framework de Qualidade — SCOPE

Avalie toda spec contra os cinco critérios abaixo. Cada um é obrigatório para que um agente execute a tarefa com precisão.

### S — System Context
O que deve estar presente:
- Linguagem de programação e/ou framework principal
- Estrutura relevante do projeto (pastas, módulos afetados)
- Dependências externas envolvidas

Sinal de ausência: a spec poderia ser implementada em qualquer stack sem adaptação.

> Se o stack estiver descrito no `CLAUDE.md` do projeto mas ausente na spec, aponte como sugestão — não como gap crítico. O agente já terá esse contexto via CLAUDE.md na execução.

### C — Core Objective
O que deve estar presente:
- O objetivo principal em 1–3 frases diretas
- O problema que está sendo resolvido (não apenas a solução)
- Critério claro de sucesso: como saber que a feature está pronta?

Sinal de ausência: o objetivo está implícito, vago, ou misturado com detalhes de implementação.

### O — Output Contract
O que deve estar presente:
- Quais arquivos/módulos serão criados ou modificados
- Formato de entrega esperado (ex: componente, endpoint, script)
- O que deve existir ao final da implementação

Sinal de ausência: não está claro o que o agente deve produzir como entregável.

### P — Preconditions & Constraints
O que deve estar presente:
- Restrições explícitas desta feature ("não usar biblioteca X", "manter compatibilidade com Y")
- O que NÃO deve ser alterado nesta implementação (guardrails)
- Pré-condições necessárias para a feature funcionar

> Restrições globais já definidas no `CLAUDE.md` não precisam ser repetidas na spec. Avalie apenas restrições específicas desta feature.

Sinal de ausência: o agente pode tomar decisões livres que quebram partes existentes do sistema.

### E — Examples & Edge Cases
O que deve estar presente:
- Pelo menos 1 exemplo de input/output ou comportamento esperado
- Pelo menos 1 caso de erro ou fluxo alternativo tratado
- Comportamentos limítrofes explícitos (ex: "se o campo estiver vazio, deve...")

Sinal de ausência: a spec depende de interpretação para casos não-triviais.

---

## Critérios Adicionais

Além do SCOPE, toda spec deve ser avaliada em:

- **Atomicidade:** A spec descreve uma única feature coesa, ou mistura múltiplas responsabilidades?
- **Testabilidade:** É possível escrever um teste automatizado baseado apenas na spec?
- **Ausência de contradições:** Há instruções conflitantes entre si ou com o `CLAUDE.md`?
- **Clareza de linguagem:** Há termos ambíguos que o agente poderia interpretar de formas diferentes?

---

## Estrutura Esperada de uma Spec

1. **Objetivo** — o que a feature resolve e por quê
2. **Contexto** — sistema, usuários e dependências relevantes
3. **Requisitos funcionais** — comportamentos esperados
4. **Requisitos não-funcionais** — performance, segurança, acessibilidade
5. **Critérios de aceite** — condições verificáveis de conclusão
6. **Restrições e exclusões** — o que está fora do escopo
7. **Plano de teste** *(opcional)* — cenários de validação da implementação

---

## Formatos Recomendados para Critérios de Aceite

**Given/When/Then (Gherkin)** — preferido para fluxos condicionais e transições de estado:
```
Cenário: [nome do cenário]
  Dado que [pré-condição]
  Quando [ação do usuário ou evento]
  Então [resultado esperado]
```

**Checklist SMART** — para requisitos objetivos e diretos:
- Specific: descreve um comportamento único
- Measurable: pode ser verificado sem interpretação
- Achievable: realizável dentro do escopo
- Relevant: alinhado ao objetivo da feature
- Testable: pode ser automatizado

---

## Referências

- Ver `domains/spec-review/SKILL.md` para protocolo detalhado de revisão e formato de saída
