-- Referência: domains/database/SKILL.md — Seção Normalização e Denormalização
-- Quando usar: exemplos de modelagem relacional correto vs incorreto

-- Violação de 3NF: zip_code determina city e state (dependência transitiva)
CREATE TABLE orders (
    id          BIGINT PRIMARY KEY,
    customer_id BIGINT,
    zip_code    VARCHAR(10),
    city        VARCHAR(100), -- deve estar em uma tabela de endereços
    state       CHAR(2)       -- deve estar em uma tabela de endereços
);

-- Correto: separar a dependência transitiva em tabela própria
CREATE TABLE zip_codes (
    zip_code VARCHAR(10) PRIMARY KEY,
    city     VARCHAR(100) NOT NULL,
    state    CHAR(2)      NOT NULL
);

-- Referência orders corrigida (usa FK para zip_codes)
CREATE TABLE orders (
    id          BIGINT PRIMARY KEY,
    customer_id BIGINT,
    zip_code    VARCHAR(10) REFERENCES zip_codes(zip_code)
);

-- Projeção denormalizada para leitura (read model CQRS)
-- O lado de escrita permanece normalizado; este é o lado de leitura
CREATE TABLE order_summary_view (
    order_id        BIGINT PRIMARY KEY,
    customer_name   VARCHAR(200),
    total_amount    DECIMAL(12,2),
    item_count      INT,
    last_updated_at DATETIME
);
