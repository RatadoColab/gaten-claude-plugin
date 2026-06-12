# Defesas Web — Detalhamento

Detalhamento das defesas de aplicação web. Resumo e ponteiros ficam no `SKILL.md`.
Autenticação/JWT/Rate Limiting permanecem no corpo do `SKILL.md` por serem de uso diário.

## Proteção contra XSS

- Escapar output HTML em todo contexto de renderização (atributos, texto, URLs)
- Configurar Content Security Policy (CSP) restritiva:
  - Proibir `unsafe-inline` e `unsafe-eval`
  - Usar nonces criptográficos ou hashes para scripts inline legítimos
  - Bloquear `object-src 'none'` e `base-uri 'self'`

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{base64_random_per_request}';
  style-src 'self' 'nonce-{base64_random_per_request}';
  img-src 'self' data: https:;
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  frame-ancestors 'none'
```

- Usar `Content-Security-Policy-Report-Only` em fase de rollout para detectar violações sem bloquear:

```http
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self' 'nonce-{random}'; report-uri /csp-report
```

- Migrar para `Content-Security-Policy` (bloqueio real) após estabilizar as violações
- Monitorar os relatórios de violação como indicador de tentativas de XSS

## Proteção contra CSRF

- Usar tokens CSRF sincronizados (padrão Synchronizer Token Pattern) em formulários e requisições de mutação
- Alternativa moderna: SameSite cookies com `SameSite=Strict` ou `SameSite=Lax`
- Verificar o header `Origin` ou `Referer` como camada adicional de defesa
- APIs JSON-only: verificar `Content-Type: application/json` (browsers não enviam cross-origin sem CORS explícito)

```python
# Sempre usar compare_digest — nunca == — para evitar timing attacks
secrets.compare_digest(session_token, request_token)
```

> Ver implementação completa de geração e validação em [`csrf-protection.py`](csrf-protection.py).

> **Timing attacks:** Sempre usar `secrets.compare_digest()` em vez de `==` para comparar tokens, hashes e segredos. O operador `==` interrompe a comparação no primeiro byte diferente (short-circuit), criando variação de tempo mensurável que permite inferir o valor correto byte a byte. `compare_digest` garante tempo de execução constante independente da posição da diferença.

## Upload de Arquivos

Upload de arquivos é uma das superfícies de ataque mais exploradas:

- Validar tipo pelo **conteúdo (magic bytes)**, não pela extensão ou header `Content-Type` do cliente
- Renomear o arquivo no servidor — nunca usar o nome original fornecido pelo cliente
- Armazenar uploads **fora do webroot** e servir via endpoint controlado com autenticação
- Definir tamanho máximo por arquivo e por requisição
- Restringir tipos permitidos por allowlist explícita

```python
# Validar por conteúdo (magic bytes), nunca por extensão
detected = magic.from_buffer(file_bytes, mime=True)
if detected not in ALLOWED_MIME_TYPES:
    raise ValueError(f'File type not allowed: {detected}')
# Salvar com nome gerado pelo servidor (UUID), nunca o nome original
safe_name = f"{uuid.uuid4().hex}{ext}"
```

> Ver implementação completa de `validate_upload` e `save_upload` em [`file-upload-security.py`](file-upload-security.py).

## Configuração de CORS

- Nunca usar `Access-Control-Allow-Origin: *` em APIs autenticadas
- Definir allowlist explícita de origens; validar `Origin` contra a lista no servidor
- Restringir métodos e headers expostos ao mínimo necessário
- Não refletir automaticamente o header `Origin` sem validação

> Ver implementação completa de allowlist de origens em [`cors-config.py`](cors-config.py).

## Gerenciamento de Secrets

- **Nunca** armazenar credenciais, chaves de API ou tokens no código-fonte ou em repositórios git
- Usar variáveis de ambiente para configuração local de desenvolvimento
- Em produção, preferir serviços dedicados: HashiCorp Vault, AWS Secrets Manager, Azure Key Vault ou GCP Secret Manager
- Rotacionar secrets regularmente; usar credenciais de curta duração quando possível
- Configurar alertas para detecção de secrets expostos em commits (GitGuardian, truffleHog, git-secrets)
- Revogar imediatamente qualquer secret que tenha sido exposto, mesmo que brevemente

```bash
# Verificar secrets antes de commitar (pre-commit hook)
# pip install detect-secrets
detect-secrets scan --update .secrets.baseline
detect-secrets audit .secrets.baseline
```

## Gerenciamento de Dependências e Supply Chain

- Manter `lock files` atualizados e verificar integridade via checksums
- Escanear dependências em cada build via ferramentas de SCA:
  - JavaScript: `npm audit`, Snyk
  - Python: `pip-audit`, Safety
  - PHP: `composer audit`
  - Java: OWASP Dependency-Check
- Gerar e manter SBOM (Software Bill of Materials) para rastreabilidade
- Definir processo de triage com SLAs por severidade de CVE
- Revisar permissões solicitadas por pacotes de terceiros (especialmente scripts de instalação)

## Dados Sensíveis e Privacidade

- Nunca incluir em logs: senhas, tokens, CPF, e-mail, número de cartão, dados de saúde
- Mascarar dados sensíveis em respostas de API quando não estritamente necessários (ex: retornar `****1234` para cartões)
- Aplicar criptografia em repouso para dados classificados como sensíveis
- Definir política de retenção de dados e implementar exclusão efetiva
- Retornar apenas os campos necessários em respostas de API (evitar over-fetching de dados pessoais)
