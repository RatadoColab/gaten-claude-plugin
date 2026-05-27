-- Referência: domains/database/SKILL.md — Seção Queries
-- Quando usar: boas práticas de escrita de queries SQL

-- =============================================================
-- PREPARED STATEMENTS (exemplos em PHP/PDO)
-- =============================================================

-- Errado: concatenação direta do input do usuário (vulnerável a SQL injection)
-- $query = "SELECT * FROM users WHERE email = '" . $email . "'";

-- Correto: parâmetro preparado — o driver separa código de dado
-- $stmt = $pdo->prepare("SELECT id, name FROM users WHERE email = ?");
-- $stmt->execute([$email]);

-- =============================================================
-- PAGINAÇÃO: OFFSET vs CURSOR (keyset pagination)
-- =============================================================

-- OFFSET degrada linearmente conforme o offset cresce
-- Evitar em tabelas grandes:
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 10000;

-- Cursor/keyset pagination: performance constante independente da página
-- O cliente guarda o último id visto e passa na próxima requisição
SELECT * FROM orders WHERE id > :last_seen_id ORDER BY id LIMIT 20;

-- =============================================================
-- FUNÇÕES EM COLUNAS INDEXADAS — impede uso do índice
-- =============================================================

-- Errado: DATE() envolve a coluna, tornando o índice em created_at inutilizável
-- WHERE DATE(created_at) = '2025-01-01'

-- Correto: comparação por intervalo preserva o uso do índice B-Tree
WHERE created_at >= '2025-01-01' AND created_at < '2025-01-02';
