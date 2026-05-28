# Referência: domains/security/SKILL.md — Seção A08 (Integridade de Software e Dados)
# Quando usar: deserialização segura evitando pickle em dados não confiáveis

# Desserialização insegura — EVITAR
# import pickle
# obj = pickle.loads(user_input)  # arbitrary code execution risk

# Alternativa segura — JSON com schema validation
import json
from pydantic import BaseModel

class Payload(BaseModel):
    action: str
    value: int

# Validates type and structure before accepting the data
obj = Payload(**json.loads(user_input))
