# Referência: domains/security/SKILL.md — Seção Proteção contra CSRF
# Quando usar: implementação de Synchronizer Token Pattern para formulários

import secrets

def generate_csrf_token() -> str:
    # Generate a cryptographically secure random token for the session
    return secrets.token_urlsafe(32)

def validate_csrf_token(session_token: str, request_token: str) -> bool:
    # Use compare_digest to avoid timing attacks (constant-time comparison)
    return secrets.compare_digest(session_token, request_token)
