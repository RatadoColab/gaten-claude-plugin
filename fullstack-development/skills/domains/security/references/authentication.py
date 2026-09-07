# Referência: domains/security/SKILL.md — Seção A04 (Cryptographic Failures)
# Quando usar: hashing seguro de senhas com Argon2id (primário) ou bcrypt (legado)

# Argon2id — perfis equivalentes do OWASP (usar o de maior memória que a infra suportar):
#   memory_cost=47104 (46 MiB), time_cost=1, parallelism=1
#   memory_cost=19456 (19 MiB), time_cost=2, parallelism=1   <- usado abaixo
#   memory_cost=12288 (12 MiB), time_cost=3, parallelism=1
#   memory_cost=9216  (9 MiB),  time_cost=4, parallelism=1
#   memory_cost=7168  (7 MiB),  time_cost=5, parallelism=1
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
# Atenção: bcrypt trunca a senha em 72 bytes — validar o comprimento antes de gerar o hash
import bcrypt

if len(password.encode()) > 72:
    raise ValueError("Password exceeds bcrypt 72-byte limit")
hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
bcrypt.checkpw(password.encode(), hashed)
