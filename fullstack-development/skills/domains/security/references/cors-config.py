# Referência: domains/security/SKILL.md — Seção Configuração de CORS
# Quando usar: configuração restritiva de CORS com allowlist de origens

ALLOWED_ORIGINS = {"https://app.example.com", "https://admin.example.com"}

def get_cors_origin(request_origin: str) -> str | None:
    # Return the origin only if it is explicitly allowed; never reflect blindly
    return request_origin if request_origin in ALLOWED_ORIGINS else None
