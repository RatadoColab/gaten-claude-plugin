-- Referência: domains/database/SKILL.md — Seção Auditoria de Dados
-- Quando usar: estrutura de tabela para audit trail de operações

-- Tabela de auditoria genérica para rastrear quem alterou o quê e quando
CREATE TABLE audit_log (
    id          BIGSERIAL    PRIMARY KEY,
    table_name  VARCHAR(100) NOT NULL,
    record_id   BIGINT       NOT NULL,
    action      CHAR(1)      NOT NULL CHECK (action IN ('I', 'U', 'D')),
    changed_by  VARCHAR(100),
    changed_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    old_data    JSONB,
    new_data    JSONB
);

-- Índice para busca por tabela + registro específico
CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);

-- Índice para busca por janela temporal
CREATE INDEX idx_audit_log_changed_at ON audit_log (changed_at);
