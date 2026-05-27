# Referência: domains/security/SKILL.md — Seção A02 (Falhas Criptográficas)
# Quando usar: hashing seguro de senhas com Argon2id (primário) ou bcrypt (legado)

# Argon2id — configuração mínima recomendada pelo OWASP
from argon2 import PasswordHasher

ph = PasswordHasher(
    time_cost=2,       # iterations
    memory_cost=19456, # 19 MiB
    parallelism=1,
    hash_len=32,
    salt_len=16
)
hashed = ph.hash(plain_password)
ph.verify(hashed, plain_password)  # raises exception on failure

# bcrypt — alternativa segura para sistemas existentes (cost >= 12)
import bcrypt

hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
bcrypt.checkpw(password.encode(), hashed)
