---
name: forms
description: This skill should be used when implementing forms, input validation, or form-related UX. Covers validation strategies, error feedback patterns, accessibility requirements, and user experience best practices for forms.
version: 0.1.0
---

# Forms — Formulários Frontend

## Visão Geral

Diretrizes para implementação de formulários acessíveis, com boa experiência de usuário e validação robusta.

## Princípios Fundamentais

- **Validação imediata:** Feedback ao sair do campo (on blur), não só no submit
- **Mensagens claras:** Erros descrevem o problema e como corrigir ("Mínimo 8 caracteres" em vez de "Campo inválido")
- **Estado de loading:** Desabilitar o botão de submit durante o envio
- **Acessibilidade:** Labels vinculados aos inputs, mensagens de erro associadas via `aria-describedby`

## Estrutura de Validação

- Validação no cliente para UX rápida
- Validação no servidor como garantia de segurança (nunca só no cliente)
- Erros de campo exibidos próximos ao campo correspondente
- Resumo de erros no topo do formulário para formulários longos

## Estados do Formulário

- **Inicial:** Campos vazios, sem erros visíveis
- **Interagindo:** Validação ao sair do foco
- **Submetendo:** Loading indicator, inputs desabilitados
- **Erro de servidor:** Mensagem global + erros de campo quando disponíveis
- **Sucesso:** Feedback claro, redirect ou limpeza do formulário

## Acessibilidade

- Usar `<label>` para todos os campos
- `required` e `aria-required="true"` em campos obrigatórios
- `role="alert"` em mensagens de erro dinâmicas
- Navegação por teclado funcionando corretamente
