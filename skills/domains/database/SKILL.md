---
name: database
description: This skill should be used when modeling databases, writing queries, designing migrations, or working with data access layers. Covers relational modeling, indexing strategies, migration patterns, and query best practices.
version: 0.1.0
---

# Database — Modelagem e Boas Práticas

## Visão Geral

Diretrizes para modelagem de dados, escrita de queries eficientes e gerenciamento de migrations.

## Princípios Fundamentais

- **Normalização:** Evitar redundância; dados em um único lugar
- **Integridade referencial:** Foreign keys para garantir consistência
- **Migrations versionadas:** Toda mudança de schema via migration, nunca manual
- **Índices estratégicos:** Indexar colunas usadas em WHERE, JOIN e ORDER BY frequentes
- **Queries explícitas:** Selecionar apenas as colunas necessárias, evitar `SELECT *`

## Modelagem

- Nomear tabelas no plural em snake_case: `user_orders`
- Chave primária: `id` (auto-increment ou UUID conforme o projeto)
- Timestamps padrão: `created_at`, `updated_at`
- Soft delete com `deleted_at` quando histórico é necessário

## Migrations

- Cada migration deve ser reversível (up + down)
- Nunca alterar uma migration já aplicada em produção
- Migrations de dados separadas das de schema

## Práticas de Query

- Usar parâmetros preparados para evitar SQL injection
- Paginação em listagens (evitar retornar todo o conjunto)
- Transações para operações que modificam múltiplas tabelas

## Referências

- Ver `domains/security/SKILL.md` para proteção contra SQL injection
