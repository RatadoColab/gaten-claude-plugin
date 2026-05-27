-- Referência: domains/database/SKILL.md — Seção Controle de Acesso no SGBD
-- Quando usar: configuração de permissões mínimas para usuários de banco

-- Usuário de aplicação com privilégios mínimos (PostgreSQL)
CREATE ROLE app_user WITH LOGIN PASSWORD 'senha_segura';
GRANT CONNECT ON DATABASE meu_banco TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- Para sequences (auto-increment):
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Usuário somente leitura para relatórios/BI
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'outra_senha';
GRANT CONNECT ON DATABASE meu_banco TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
