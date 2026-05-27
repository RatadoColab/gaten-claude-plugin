# Referência: domains/security/SKILL.md — Seção Upload de Arquivos
# Quando usar: validação segura de uploads por conteúdo (não extensão) e salvamento

import magic  # pip install python-magic
import uuid
import os

ALLOWED_MIME_TYPES = {'image/jpeg', 'image/png', 'application/pdf'}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB

def validate_upload(file_bytes: bytes, filename: str) -> bool:
    if len(file_bytes) > MAX_FILE_SIZE:
        raise ValueError('File too large')

    # Validate by content, not by extension or Content-Type header
    detected = magic.from_buffer(file_bytes, mime=True)
    if detected not in ALLOWED_MIME_TYPES:
        raise ValueError(f'File type not allowed: {detected}')

    return True

def save_upload(file_bytes: bytes, original_name: str, upload_dir: str) -> str:
    ext = os.path.splitext(original_name)[1].lower()
    safe_name = f"{uuid.uuid4().hex}{ext}"  # Never use the original filename
    path = os.path.join(upload_dir, safe_name)
    with open(path, 'wb') as f:
        f.write(file_bytes)
    return safe_name
