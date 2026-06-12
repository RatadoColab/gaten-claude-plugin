---
name: backend-base
description: This skill should be used when developing backend features, services, APIs, or data layers. Covers architecture principles, code organization patterns, and general best practices for backend development.
version: 0.2.1
---

# Backend Base — Fundamentos de Desenvolvimento Backend

## Visão Geral

Fornece os princípios de arquitetura e boas práticas gerais aplicáveis ao desenvolvimento backend, independente da linguagem ou framework.

## Princípios Fundamentais

- **Separação de responsabilidades:** Cada camada (controller, service, repository) tem um papel claro
- **Single Responsibility:** Cada classe ou função deve ter um único motivo para mudar
- **Fail fast:** Validar entradas o mais cedo possível, retornar erros claros
- **Idempotência:** Operações que podem ser repetidas devem produzir o mesmo resultado
- **Mínimo de privilégios:** Acesso apenas ao que é necessário para a operação

## Camadas Típicas

- **Controller/Handler:** Recebe a requisição, delega ao service, retorna a resposta
- **Service/Use Case:** Contém a lógica de negócio
- **Repository:** Abstrai o acesso a dados
- **Model/Entity:** Representa os dados do domínio

## Práticas Gerais

- Logs estruturados em operações críticas
- Tratamento explícito de erros com mensagens informativas
- Evitar lógica de negócio em controllers ou repositórios
- Injeção de dependência para facilitar testes — quando o framework permitir; em frameworks que usam globais por design (ex.: GLPI), respeitar as convenções do framework

## Padrões de Implementação

- Estruturar código preferencialmente em orientação a objetos: classes, métodos e encapsulamento
- Documentar funções, classes e métodos com o padrão adequado da linguagem:
  - **PHP/Java**: docblocks `/** */`
  - **Python**: docstrings `""" """`
  - **JavaScript/Node.js**: JSDoc `/** */`
- Seguir princípios SOLID e DRY para coesão e baixo acoplamento

## Adaptação por Framework

As camadas acima são genéricas. Frameworks com arquitetura própria exigem adaptação: em projetos GLPI, carregar `domains/glpi/SKILL.md` — a tabela de equivalências de camadas e as convenções do framework vivem lá e **prevalecem** sobre os padrões genéricos desta base.

## Referências

- Ver `domains/api-rest/SKILL.md` para padrões de APIs REST
- Ver `domains/database/SKILL.md` para modelagem e queries
- Ver `domains/security/SKILL.md` para práticas de segurança
- Ver `domains/glpi/SKILL.md` para plugins GLPI 10.0.x
