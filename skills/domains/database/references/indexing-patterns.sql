-- Referência: domains/database/SKILL.md — Seção Indexação
-- Quando usar: padrões de criação de índices por tipo de query

-- Partial index: apenas pedidos pendentes precisam de acesso rápido
-- Reduz tamanho do índice e melhora writes nas linhas fora do subconjunto
CREATE INDEX idx_orders_pending ON orders (created_at)
WHERE status = 'pending';

-- Covering index: a query busca apenas company_id, email e name
-- O planner satisfaz a query inteira pelo índice, sem heap fetch
-- Query beneficiada: SELECT email, name FROM users WHERE company_id = ?
CREATE INDEX idx_users_company_covering ON users (company_id, email, name);

-- Índice composto: filtro obrigatório à esquerda
-- Toda query já conhece user_id; status é filtro secundário opcional
CREATE INDEX idx_orders_user_status ON orders (user_id, status);

-- Índice composto orientado a status: quando queries frequentes
-- filtram por status primeiro, independente do usuário
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
