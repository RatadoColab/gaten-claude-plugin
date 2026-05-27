---
name: user-experience
description: This skill should be used when designing or reviewing user flows, interaction patterns, loading states, empty states, or error messages. Covers UX principles, feedback patterns, and interface state management best practices.
version: 0.1.0
---

# User Experience — UX e Fluxos de Usuário

## Visão Geral

Diretrizes para criar interfaces que oferecem experiência clara, previsível e satisfatória ao usuário.

## Princípios Fundamentais

- **Feedback imediato:** O usuário sabe o que está acontecendo a todo momento
- **Previsibilidade:** Ações iguais produzem resultados iguais
- **Recuperabilidade:** Erros são recuperáveis; ações destrutivas pedem confirmação
- **Mínimo de fricção:** Remover passos desnecessários do fluxo

## Estados da Interface

Toda tela ou componente deve tratar explicitamente:
- **Loading:** Skeleton, spinner ou placeholder enquanto carrega
- **Vazio:** Mensagem informativa quando não há dados (não apenas uma lista em branco)
- **Erro:** Mensagem clara + ação para recuperação (tentar novamente, voltar)
- **Sucesso:** Confirmação visual do que foi realizado

## Feedback Visual

- Ações assíncronas: indicar progresso (loading) e resultado (sucesso/erro)
- Toasts para notificações não bloqueantes (sucesso, avisos)
- Modais/diálogos para confirmações de ações destrutivas ou importantes
- Tooltips para informações complementares, não para informações essenciais

## Fluxos de Usuário

- Definir o caminho feliz (happy path) e garantir que funcione sem fricção
- Mapear pontos de saída do fluxo e garantir que o usuário possa retornar
- Persistir estado entre navegações quando fizer sentido (ex: filtros aplicados)
