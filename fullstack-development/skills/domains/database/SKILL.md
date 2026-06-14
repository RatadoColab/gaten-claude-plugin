---
name: database
description: This skill should be used when modeling databases, writing queries, designing migrations, or working with data access layers. Typical triggers include "design this database schema", "which index should I add?", "optimize this slow query", "write a zero-downtime migration", "should I use SQL or NoSQL?", "fix this N+1 query". Covers relational modeling, normalization vs denormalization trade-offs, index strategies (B-Tree, composite, partial, covering), zero-downtime migration patterns, query optimization, transactions, connection pooling, ORM pitfalls, and SQL vs NoSQL decision framework.
---

# Database — Modelagem e Boas Práticas

## Visão Geral

Diretrizes para modelagem de dados, escrita de queries eficientes, gerenciamento de migrations e operação segura de bancos relacionais e não-relacionais.

---

## 1. Princípios Fundamentais

- **Integridade primeiro:** constraints, foreign keys e validações no banco garantem consistência independente da camada de aplicação.
- **Imutabilidade do histórico:** nunca altere uma migration já aplicada em produção; crie uma nova.
- **Mensurabilidade:** só é possível otimizar o que é medido. Habilite slow query log e monitore latência de queries, contagem de conexões e CPU.
- **Separação de responsabilidades:** migrations de schema e migrations de dados devem ser arquivos distintos.

---

## 2. Modelagem Relacional

### 2.1 Convenções de nomenclatura

- Chave primária: `id` — use `BIGINT UNSIGNED AUTO_INCREMENT` para tabelas de alta escrita; use `UUID` quando a geração de ID precisa ser distribuída ou quando o ID é exposto externamente.
- Timestamps padrão: `date_creation`, `date_mod` com `DEFAULT CURRENT_TIMESTAMP` e `ON UPDATE CURRENT_TIMESTAMP`.
- Soft delete: coluna `deleted_at DATETIME NULL DEFAULT NULL` — aplique apenas quando o histórico de exclusão é um requisito de negócio; evite em tabelas de alto volume onde o filtro `WHERE deleted_at IS NULL` degrada queries.

### 2.2 Normalização

Normalize até a **3ª Forma Normal (3NF)** como ponto de partida:

1. **1NF:** cada célula contém um único valor atômico; não há grupos repetidos.
2. **2NF:** todo atributo não-chave depende da chave primária completa (sem dependências parciais em chaves compostas).
3. **3NF:** nenhum atributo não-chave depende de outro atributo não-chave (sem dependências transitivas).

> Ver exemplo (violação de 3NF com `zip_code` → `city`/`state` e a correção) em [`references/normalization-examples.sql`](references/normalization-examples.sql).

### 2.3 Denormalização intencional

Denormalize **somente quando houver evidência de gargalo de leitura**, não por antecipação. Casos válidos:

- Relatórios e dashboards com joins pesados em tabelas de muitos milhões de linhas.
- Read models em arquiteturas CQRS: o lado de escrita permanece normalizado para consistência; o lado de leitura é uma projeção denormalizada para performance.
- Colunas calculadas (`total_amount`) persistidas quando o cálculo é custoso e o dado muda raramente.

> Ver exemplo de read model CQRS em [`references/normalization-examples.sql`](references/normalization-examples.sql).

---

## 3. Estratégias de Indexação

### 3.1 Tipos de índice

| Tipo | Quando usar | Limitações |
|---|---|---|
| **B-Tree** (padrão) | Igualdade, intervalos, ordenação, prefixo de string | Não eficiente para dados com cardinalidade muito baixa (ex: booleanos) |
| **Hash** | Igualdade exata com altíssima frequência | Não suporta range queries, ORDER BY ou LIKE |
| **Composto** | Queries que filtram por múltiplas colunas juntas | A ordem das colunas importa; siga a regra do prefixo mais seletivo à esquerda |
| **Parcial** | Subconjunto dos dados (ex: só registros ativos) | Só é usado quando a condição do índice é satisfeita |
| **Covering** | Query busca todas as colunas pelo índice, sem acessar a tabela | Tamanho maior; custo de manutenção em writes |

### 3.2 Regras práticas

- Indexe colunas usadas em `WHERE`, `JOIN ON` e `ORDER BY` com alta frequência.
- Em índices compostos, coloque à esquerda a coluna usada como **filtro obrigatório na maioria das queries**, não necessariamente a de maior cardinalidade. A regra de seletividade se aplica quando ambas as colunas aparecem juntas nos filtros: nesse caso, prefira a mais seletiva à esquerda.

  - `(user_id, status)` — quando toda query já sabe o `user_id`; `status` vem como filtro secundário opcional
  - `(status, date_creation)` — quando queries frequentes filtram por `status` primeiro, independente do usuário
  - Em índices de cobertura (covering index), a coluna de maior cardinalidade à esquerda maximiza a eficiência de varredura

- Prefira **partial indexes** para filtros com subconjunto previsível.
- Crie **covering indexes** quando uma query crítica precisa de poucas colunas (o planner satisfaz a query sem heap fetch).

> Ver exemplos de partial index, covering index e índices compostos em [`references/indexing-patterns.sql`](references/indexing-patterns.sql).

- Cada índice adicional degrada `INSERT`, `UPDATE` e `DELETE`. Em tabelas de alto volume de escrita, prefira poucos índices precisos a muitos genéricos.
- Use `EXPLAIN`/`EXPLAIN ANALYZE` para verificar se o planner está usando o índice esperado e para detectar full table scans.

### 3.3 Índices a evitar

- Índices em colunas que raramente aparecem em `WHERE` ou `JOIN`.
- Índices redundantes: `(a)` e `(a, b)` — o composto já cobre o simples quando `a` é prefixo.
- Índices em colunas com cardinalidade muito baixa sem condição parcial (ex: `is_active BOOLEAN` com 95% dos registros `TRUE`).

---

## 4. Migrations

Regras essenciais (detalhe completo, incluindo Expand-Contract e operações de alto risco, em [`references/migrations.md`](references/migrations.md)):

- Toda alteração de schema via migration versionada com `up`/`down` — nunca SQL manual em produção.
- Migrations de schema e de dados em arquivos separados; teste em staging com volume equivalente ao de produção.
- Breaking changes (renomear/remover coluna, `NOT NULL` em tabela grande): usar o padrão **Expand-Contract** (expand → migrate/backfill → contract em deploys separados).
- `DROP COLUMN`/`DROP TABLE` são irreversíveis — backup de ponto no tempo antes.

---

## 5. Escrita de Queries

### 5.1 Segurança

- **Sempre use parâmetros preparados** (prepared statements / bind parameters) para evitar SQL injection. Nunca concatene input do usuário em strings SQL.

> Prevenção de SQL Injection em `domains/security/SKILL.md`; comparação errado/correto e demais padrões em [`references/query-patterns.sql`](references/query-patterns.sql); permissões mínimas para usuários de banco (aplicação e somente leitura) em [`references/access-control.sql`](references/access-control.sql).

### 5.2 Performance

- Selecione apenas as colunas necessárias: evite `SELECT *`.
- Aplique `LIMIT` em todas as queries de listagem; nunca retorne conjuntos ilimitados ao usuário.
- Prefira paginação por cursor (keyset pagination) a `OFFSET` em grandes datasets — OFFSET degrada linearmente; cursor mantém performance constante.
- Evite funções em colunas indexadas no `WHERE` — isso impede o uso do índice; prefira comparações em range.

> Ver exemplos de paginação e funções em colunas indexadas em [`references/query-patterns.sql`](references/query-patterns.sql).

- Evite conversões implícitas de tipo: certifique-se de que o tipo do parâmetro corresponde ao tipo da coluna.

### 5.3 Paginação e contagem

- `COUNT(*)` em tabelas grandes com filtros complexos pode ser custoso; considere manter contadores materializados ou aceitar contagens aproximadas em UIs de alto volume.

---

## 6. Transações

- Use transações para qualquer operação que modifique múltiplas tabelas ou registros de forma interdependente.
- Mantenha transações **curtas**: lock por transações longas degrada a concorrência.
- Escolha o nível de isolamento adequado ao caso de uso:

| Nível | Protege contra | Overhead |
|---|---|---|
| `READ COMMITTED` | Dirty reads | Baixo — padrão seguro para a maioria dos casos |
| `REPEATABLE READ` | Dirty + non-repeatable reads | Médio — padrão do MySQL/InnoDB |
| `SERIALIZABLE` | Todas as anomalias | Alto — use apenas quando a correção é crítica |

- Nunca faça chamadas HTTP, envio de e-mail ou operações de I/O dentro de uma transação aberta.
- Trate rollbacks explicitamente em caso de erro — não deixe transações pendentes.

> Ver padrão BEGIN/COMMIT/ROLLBACK com try-catch em [`references/transaction-patterns.sql`](references/transaction-patterns.sql).

### Deadlocks

- Para evitar deadlocks, sempre acesse tabelas e linhas na **mesma ordem** em transações concorrentes
- Em PostgreSQL, deadlocks são detectados automaticamente e uma das transações é abortada com erro `40P01` — a aplicação deve capturar e retentar
- Indício de deadlock frequente: rever granularidade do lock ou serializar a lógica
- Nunca manter uma transação aberta aguardando interação do usuário ou resposta de I/O externo

> Ver padrão `FOR UPDATE` em ordem consistente em [`references/transaction-patterns.sql`](references/transaction-patterns.sql).

---

## 7. Auditoria de Dados

> Auditoria implementada via código da aplicação ou triggers no banco. Em plugins GLPI, todo acesso passa pelo `$DB` do framework (nunca configurar conexão própria) — ver `domains/glpi/SKILL.md` (§Acesso ao Banco de Dados).

Para rastrear quem alterou o quê e quando (além de `date_creation`/`date_mod`):

> Ver estrutura completa de `audit_log` com índices em [`references/audit-table.sql`](references/audit-table.sql).

- Registrar `old_data` e `new_data` como JSONB para auditoria completa
- Popular via triggers no banco ou na camada de repositório da aplicação
- Nunca registrar senhas, tokens ou dados sensíveis nos logs de auditoria

---

## 8. Armadilhas de ORM

- **N+1 queries:** ao iterar sobre uma coleção e carregar relacionamentos dentro do loop, o ORM dispara uma query por item. Use eager loading (`with()`, `include`, `joinedload`) para resolver.

> Ver comparação N+1 vs eager loading (SQLAlchemy) em [`references/orm-patterns.py`](references/orm-patterns.py).

- **Lazy loading silencioso:** entenda o comportamento padrão do ORM — lazy loading é conveniente em desenvolvimento mas perigoso em produção.
- **Queries geradas opacas:** em pontos críticos de performance, verifique o SQL gerado pelo ORM com logging de queries ativado antes de ir a produção.
- **Ignorar índices:** o ORM cria a tabela, mas raramente cria os índices que a aplicação precisa — adicione-os explicitamente nas migrations.
- **Transações implícitas:** alguns ORMs encapsulam cada operação em uma transação automática; entenda como agrupar operações em uma única transação.

---

## 9. SQL vs NoSQL — Decisão

Abordagem predominante: **persistência poliglota** — o banco certo para cada responsabilidade. SQL para ACID, dados relacionais com joins, auditoria e relatórios; NoSQL para esquema variável, escala horizontal massiva, cache/sessões (Redis) e busca full-text (Elasticsearch).

> Tabela de decisão completa e padrão de particionamento em [`references/sql-vs-nosql.md`](references/sql-vs-nosql.md).

---

## 10. Observabilidade

- Habilite slow query log e defina threshold (ex: queries > 100ms).
- Monitore: latência de queries (p50, p95, p99), conexões ativas vs pool size, taxa de cache hit (para queries com índice), crescimento de tabelas.
- Use `EXPLAIN ANALYZE` regularmente nas queries mais frequentes, especialmente após mudanças de volume de dados.
- Em produção, evite executar `EXPLAIN ANALYZE` em tabelas muito grandes sem `LIMIT` — o planner executa a query para análise.

