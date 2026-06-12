# SQL vs NoSQL — Framework de Decisão

Detalhamento da decisão entre relacional e NoSQL. Resumo no `SKILL.md`.

Em 2025, a abordagem predominante é **persistência poliglota**: usar o banco certo para cada responsabilidade.

| Use SQL (relacional) quando... | Use NoSQL quando... |
|---|---|
| ACID é mandatório (finanças, inventário) | Esquema altamente variável ou sem esquema fixo |
| Dados são fortemente relacionais com muitos joins | Escala horizontal massiva com baixa latência (feeds, IoT, logs) |
| Auditoria, conformidade regulatória | Dados hierárquicos ou documentos sem estrutura uniforme |
| Relatórios complexos com agregações | Cache e sessões (Redis) |
| Modelo de dados estável e bem definido | Busca full-text avançada (Elasticsearch) |

**Padrão de particionamento típico:**
- PostgreSQL/MySQL → dados transacionais e relacionais.
- Redis → cache, sessões, filas leves, rate limiting.
- Elasticsearch/OpenSearch → busca full-text e logs.
- MongoDB → documentos com estrutura variável.
