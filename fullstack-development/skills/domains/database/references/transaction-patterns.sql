-- Referência: domains/database/SKILL.md — Seção Transações e Deadlocks
-- Quando usar: padrões de transação segura e prevenção de deadlocks

-- =============================================================
-- TRANSAÇÃO COM ROLLBACK EXPLÍCITO (exemplo em PHP/PDO)
-- =============================================================
--
-- $pdo->beginTransaction();
-- try {
--     $pdo->exec("UPDATE accounts SET balance = balance - 100 WHERE id = 1");
--     $pdo->exec("UPDATE accounts SET balance = balance + 100 WHERE id = 2");
--     $pdo->commit();
-- } catch (Exception $e) {
--     $pdo->rollBack();
--     throw $e;
-- }

-- Regras:
-- - Nunca faça chamadas HTTP, e-mail ou I/O dentro de transação aberta
-- - Mantenha transações curtas; lock prolongado degrada concorrência
-- - Trate rollback explicitamente — não deixe transações pendentes

-- =============================================================
-- PREVENÇÃO DE DEADLOCK — ordem consistente de aquisição de locks
-- =============================================================

-- Sempre adquirir locks na mesma ordem (menor id primeiro)
-- para evitar deadlock circular entre transações concorrentes
BEGIN;
SELECT * FROM accounts WHERE id = 1 FOR UPDATE; -- menor id primeiro
SELECT * FROM accounts WHERE id = 2 FOR UPDATE;
-- operações seguras aqui
COMMIT;

-- Em PostgreSQL, deadlocks são detectados automaticamente
-- e uma das transações é abortada com erro 40P01.
-- A aplicação deve capturar esse erro e retentar a operação.
