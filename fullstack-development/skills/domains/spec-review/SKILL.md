---
name: spec-review
description: This skill should be used when performing a structured review of a feature specification, evaluating completeness, clarity, and suitability for AI-driven development. Covers review protocol, quality checklist, output format, and scoring criteria.
version: 0.2.0
---

# Spec Review — Protocolo de Revisão de Especificações

## Visão Geral

Protocolo estruturado para revisão de especificações de features destinadas ao desenvolvimento por LLMs.

---

## Coleta de Contexto (passo obrigatório antes de revisar)

Antes de avaliar qualquer spec:

1. Leia o `CLAUDE.md` na raiz do diretório de trabalho atual
2. Extraia: stack, convenções, módulos protegidos e restrições do projeto
3. Use esse contexto para calibrar os critérios **S** e **P** do SCOPE

Se não houver `CLAUDE.md` ou ele não descrever o stack:
- Não invente contexto
- Marque o critério **S (System Context)** como ⚠️ e aponte a ausência no relatório

---

## Checklist de Revisão

### S — System Context
- [ ] Linguagem e framework principal identificados
- [ ] Módulos e pastas afetadas mencionados
- [ ] Dependências externas relevantes listadas

### C — Core Objective
- [ ] Objetivo da feature em 1–3 frases sem ambiguidade
- [ ] Problema sendo resolvido (não apenas a solução)
- [ ] Critério claro de sucesso definido
- [ ] Termos de domínio definidos ou autoexplicativos
- [ ] Sem requisitos dependentes de conhecimento implícito

### O — Output Contract
- [ ] Arquivos/módulos a criar ou modificar identificados
- [ ] Formato de entrega esperado explícito
- [ ] Estado final da implementação descrito

### P — Preconditions & Constraints
- [ ] Restrições específicas desta feature declaradas
- [ ] O que NÃO deve ser alterado está explícito (guardrails)
- [ ] Pré-condições necessárias listadas
- [ ] Fases ou iterações delimitadas se for entrega parcial

### E — Examples & Edge Cases
- [ ] Ao menos 1 exemplo de input/output ou comportamento esperado
- [ ] Ao menos 1 caso de erro ou fluxo alternativo coberto
- [ ] Comportamentos limítrofes explícitos (lista vazia, campo nulo, etc.)

### Critérios Adicionais
- [ ] Spec descreve uma única feature coesa (atomicidade)
- [ ] É possível escrever teste automatizado baseado só na spec (testabilidade)
- [ ] Não há instruções conflitantes entre si ou com o `CLAUDE.md`
- [ ] Nenhum termo ambíguo que o agente possa interpretar de formas diferentes

---

## Formato de Saída Obrigatório

Sempre responda exatamente nesta estrutura:

```markdown
# Revisão da Especificação

## Sumário
[2–3 frases descrevendo o estado geral da spec: o que está bom e o que precisa de atenção]

## Score de Qualidade
| Critério              | Status        | Observação                        |
|-----------------------|---------------|-----------------------------------|
| System Context (S)    | ✅ / ⚠️ / ❌  | [observação curta]                |
| Core Objective (C)    | ✅ / ⚠️ / ❌  | [observação curta]                |
| Output Contract (O)   | ✅ / ⚠️ / ❌  | [observação curta]                |
| Constraints (P)       | ✅ / ⚠️ / ❌  | [observação curta]                |
| Examples (E)          | ✅ / ⚠️ / ❌  | [observação curta]                |
| Atomicidade           | ✅ / ⚠️ / ❌  | [observação curta]                |
| Testabilidade         | ✅ / ⚠️ / ❌  | [observação curta]                |

Legenda: ✅ Presente e adequado · ⚠️ Parcial ou vago · ❌ Ausente

## Avaliação Numérica
- **System Context:** _/10
- **Core Objective:** _/10
- **Output Contract:** _/10
- **Constraints:** _/10
- **Examples:** _/10
- **Nota geral:** _/10

## Gaps Identificados
[Lista numerada dos problemas, do mais crítico ao menos crítico.
Para cada gap: descreva o problema e por que impacta a implementação.]

## Sugestões de Melhoria
[Lista de sugestões concretas e acionáveis, vinculadas aos gaps acima.]

---

# Spec Reescrita

[Versão melhorada da especificação original, incorporando todas as sugestões.
Mantenha o estilo e a voz do autor. Adicione apenas o que está faltando —
não reescreva o que já estava correto sem necessidade.]
```

---

## Regras de Comportamento

1. **Leia o `CLAUDE.md` antes de avaliar.** Ele é a fonte de verdade sobre contexto global.
2. **Não invente contexto.** Se algo não está na spec nem no `CLAUDE.md`, aponte como gap.
3. **Seja específico nos gaps.** "Falta definir o comportamento quando a lista estiver vazia" é melhor que "falta detalhe".
4. **Na spec reescrita, preserve a intenção original.** Você está melhorando, não redesenhando.
5. **Use o idioma do autor.** Português quando o usuário escrever em português; inglês quando escrever em inglês.
6. **Não adicione requisitos não-funcionais** (performance, segurança, escalabilidade) a menos que o usuário os tenha mencionado.
7. **Seja direto.** O usuário quer feedback útil, não elogios.
