# Defesas Web — Detalhamento

Detalhamento das defesas de aplicação web. Resumo e ponteiros ficam no `SKILL.md`.
Autenticação/JWT/Rate Limiting permanecem no corpo do `SKILL.md` por serem de uso diário.

## Proteção contra XSS

- Escapar output HTML em todo contexto de renderização (atributos, texto, URLs)
- Configurar Content Security Policy (CSP) restritiva:
  - Proibir `unsafe-inline` e `unsafe-eval`
  - Usar nonce criptográfico por requisição (preferível a hash) para scripts inline legítimos
  - Combinar com `'strict-dynamic'`: scripts carregados por um script confiável herdam a confiança, sem precisar de nonce próprio
  - Bloquear `object-src 'none'` e `base-uri 'none'`

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{base64_random_per_request}' 'strict-dynamic';
  style-src 'self' 'nonce-{base64_random_per_request}';
  img-src 'self' data: https:;
  object-src 'none';
  base-uri 'none';
  form-action 'self';
  frame-ancestors 'none';
  report-to csp-endpoint
```

- `frame-ancestors` é o controle primário contra clickjacking e torna `X-Frame-Options` obsoleto
  nos navegadores que o suportam; manter `X-Frame-Options: DENY` apenas para clientes legados
- Reportar violações com `report-to` + o header `Reporting-Endpoints` (CSP Level 3); manter
  `report-uri` apenas como fallback para navegadores antigos:

```http
Reporting-Endpoints: csp-endpoint="https://example.com/csp-report"
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self' 'nonce-{random}' 'strict-dynamic'; report-to csp-endpoint; report-uri /csp-report
```

- Usar `Content-Security-Policy-Report-Only` em fase de rollout para detectar violações sem bloquear
- Migrar para `Content-Security-Policy` (bloqueio real) após estabilizar as violações
- Monitorar os relatórios de violação como indicador de tentativas de XSS
- Em aplicações que manipulam DOM dinamicamente, considerar Trusted Types
  (`require-trusted-types-for 'script'`) para eliminar sinks de DOM XSS

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

## Cookies e Sessão

- Cookies de sessão e de autenticação: `HttpOnly` + `Secure` + `SameSite=Strict` (ou `Lax` quando
  houver navegação cross-site legítima de entrada)
- Usar o prefixo `__Host-` no nome do cookie: o navegador só aceita se vier com `Secure`, `Path=/` e
  **sem** `Domain` — impede sobrescrita a partir de subdomínio ou de conexão insegura
- `Partitioned` (CHIPS) para cookies usados em contexto de terceiros, alinhado ao fim dos cookies de terceiros
- Definir expiração explícita; rotacionar o identificador de sessão após login e após elevação de privilégio
- `Clear-Site-Data: "cookies", "storage"` na resposta de logout para limpar o estado do cliente

```http
Set-Cookie: __Host-session=<id>; Path=/; Secure; HttpOnly; SameSite=Strict; Max-Age=3600
```

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

Corresponde ao **A03:2025 — Software Supply Chain Failures**. Escopo desta seção: a aplicação e suas
dependências. A segurança do pipeline (SAST/SCA na CI, SBOM assinado, cosign/Sigstore, SLSA,
pinning de actions) fica em `domains/devsecops/SKILL.md`.

- Manter `lock files` atualizados e verificar integridade via checksums
- Escanear dependências em cada build via ferramentas de SCA:
  - JavaScript: `npm audit`, `npm audit signatures` (verifica proveniência), OSV-Scanner, Snyk
  - Python: `pip-audit`, Safety
  - PHP: `composer audit`
  - Java: OWASP Dependency-Check
  - Multi-ecossistema: OSV-Scanner, OpenSSF Scorecard (higiene do projeto upstream)
- Obter pacotes apenas de registries oficiais por canal seguro; preferir pacotes publicados com
  proveniência (npm provenance / trusted publishing, PyPI trusted publishing)
- Fixar dependências por versão exata e, quando possível, por digest/hash — não por range móvel
- Gerar e manter SBOM (Software Bill of Materials) em CycloneDX ou SPDX para rastreabilidade
- Tratar dependências não mantidas ou sem caminho de atualização como dívida de segurança ativa
- Definir processo de triage com SLAs por severidade de CVE (usar CVSS v4.0 quando disponível)
- Revisar permissões e scripts de instalação de pacotes de terceiros; desabilitar scripts de
  postinstall não essenciais (`npm ci --ignore-scripts`)
- Aplicar atualizações de forma escalonada/canário — evitar propagar um pacote comprometido para toda a frota

## Dados Sensíveis e Privacidade

- Nunca incluir em logs: senhas, tokens, CPF, e-mail, número de cartão, dados de saúde
- Mascarar dados sensíveis em respostas de API quando não estritamente necessários (ex: retornar `****1234` para cartões)
- Aplicar criptografia em repouso para dados classificados como sensíveis
- Definir política de retenção de dados e implementar exclusão efetiva
- Retornar apenas os campos necessários em respostas de API (evitar over-fetching de dados pessoais)
