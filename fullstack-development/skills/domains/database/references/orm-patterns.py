# Referência: domains/database/SKILL.md — Seção ORM
# Quando usar: identificação e correção de N+1 queries em ORMs

# =============================================================
# N+1 QUERY — problema
# =============================================================
# Dispara 1 query para buscar todos os users +
# 1 query adicional por user para carregar orders
users = User.query.all()
for user in users:
    print(user.orders)  # query disparada a cada iteração

# =============================================================
# EAGER LOADING — solução com joinedload (SQLAlchemy)
# =============================================================
# Dispara 1 query com JOIN, carregando users e orders juntos
users = User.query.options(joinedload(User.orders)).all()

# =============================================================
# NOTAS
# =============================================================
# - Lazy loading é conveniente em desenvolvimento, perigoso em produção
# - Ative logging de queries do ORM para verificar o SQL gerado
#   antes de ir a produção em pontos críticos de performance
# - Adicione índices explicitamente nas migrations — o ORM cria a
#   tabela mas raramente cria os índices que a aplicação precisa
