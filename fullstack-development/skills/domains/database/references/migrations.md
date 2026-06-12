# Migrations — Regras, Zero Downtime e Operações de Alto Risco

Detalhamento de migrations. Resumo no `SKILL.md`.

## Regras fundamentais

- Toda alteração de schema via migration versionada — nunca via SQL manual no banco de produção.
- Cada migration deve ter `up` (aplicar) e `down` (reverter).
- Migrations de schema e migrations de dados ficam em arquivos separados.
- Teste a migration em staging com volume de dados equivalente ao de produção — uma operação que leva milissegundos em 1.000 linhas pode travar por minutos em 100 milhões.

## Zero downtime: padrão Expand-Contract

Para alterações que seriam breaking changes em produção, use o padrão **Expand-Contract** (também chamado de Parallel Change):

**Fase 1 — Expand:** adicione a nova estrutura sem remover a antiga.
```sql
-- Migration 1: adiciona coluna nova, mantém a antiga
ALTER TABLE users ADD COLUMN full_name VARCHAR(200);
```

**Fase 2 — Migrate:** o código da aplicação escreve em ambas as colunas; backfill dos dados históricos.
```sql
-- Migration 2: preenche dados existentes
UPDATE users SET full_name = CONCAT(first_name, ' ', last_name);
```

**Fase 3 — Contract:** após o deploy completo, remova a estrutura antiga.
```sql
-- Migration 3: remove colunas antigas (deploy separado)
ALTER TABLE users DROP COLUMN first_name, DROP COLUMN last_name;
```

## Operações de alto risco

- `ADD COLUMN NOT NULL` sem `DEFAULT` em tabelas grandes pode causar lock; adicione com `DEFAULT NULL` primeiro, faça backfill, depois adicione o `NOT NULL`.
- `ADD CONSTRAINT` pode varrer toda a tabela para validação; em PostgreSQL, use `ADD CONSTRAINT ... NOT VALID` seguido de `VALIDATE CONSTRAINT` em background.
- `DROP COLUMN` / `DROP TABLE` são irreversíveis — mantenha um backup de ponto no tempo antes de executar.
- Renomear colunas ou tabelas é uma breaking change — use o padrão Expand-Contract.
