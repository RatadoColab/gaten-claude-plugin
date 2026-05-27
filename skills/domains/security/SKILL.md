---
name: security
description: This skill should be used when implementing security features, reviewing code for vulnerabilities, or applying security best practices. Covers OWASP Top 10 2021, input validation, authentication, authorization, data protection, secrets management, logging, and supply chain security.
version: 0.2.0
---

# Security — Segurança em Aplicações Web

## Visão Geral

Diretrizes de segurança baseadas no **OWASP Top 10:2021** para aplicações web e APIs. Aplicar em revisões de código, implementação de funcionalidades e auditorias de segurança.

## Princípios Fundamentais

- **Validar na entrada:** Nunca confiar em dados do cliente — validar tipo, formato, tamanho e range
- **Sanitizar na saída:** Escapar dados antes de renderizar HTML, SQL, JSON ou qualquer contexto de saída
- **Mínimo de privilégios:** Usuários e serviços acessam somente o que precisam, negação por padrão
- **Defense in depth:** Múltiplas camadas independentes de proteção; nenhuma camada isolada é suficiente
- **Segurança por design:** Incorporar requisitos de segurança desde a fase de modelagem, não como correção posterior
- **Fail safe:** Em caso de erro, negar acesso — nunca falhar de forma permissiva

---

## OWASP Top 10:2021 — Vulnerabilidades e Mitigações

### A01 — Broken Access Control

A vulnerabilidade mais prevalente: 94% das aplicações testadas apresentam alguma falha de controle de acesso.

**Riscos:**
- Acesso a recursos de outros usuários por manipulação de IDs (IDOR)
- Escalada de privilégios horizontal e vertical
- Acesso a rotas administrativas sem verificação

**Mitigações:**
- Implementar controle de acesso no servidor em **todos** os endpoints, sem exceção
- Adotar modelo de negação por padrão (`deny-by-default`): se não há permissão explícita, o acesso é negado
- Verificar autorização em cada requisição — nunca apenas no login
- Implementar RBAC (Role-Based Access Control) ou ABAC (Attribute-Based Access Control)
- Invalidar tokens e sessões ao fazer logout
- Registrar falhas de controle de acesso e alertar para padrões suspeitos

```python
# Verificação de propriedade do recurso antes de retornar
def get_document(doc_id: int, current_user: User) -> Document:
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if not doc or doc.owner_id != current_user.id:
        raise PermissionDenied("Access denied")
    return doc
```

---

### A02 — Cryptographic Failures

**Riscos:**
- Dados sensíveis transmitidos em texto plano (sem HTTPS)
- Senhas armazenadas com hash fraco (MD5, SHA-1, SHA-256 sem salt)
- Dados sensíveis em cache, logs ou URLs
- Uso de algoritmos criptográficos obsoletos

**Mitigações:**
- Exigir HTTPS em toda a aplicação; redirecionar HTTP para HTTPS
- Usar TLS 1.2 no mínimo; preferir TLS 1.3
- Habilitar HSTS (`Strict-Transport-Security: max-age=31536000; includeSubDomains`)
- Para senhas, usar **Argon2id** (recomendado em 2025) ou bcrypt com cost factor ≥ 12
- Não armazenar dados sensíveis além do necessário
- Usar AES-256 para dados em repouso

```python
# Argon2id — configuração mínima recomendada pelo OWASP
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)
hashed = ph.hash(plain_password)
ph.verify(hashed, plain_password)  # raises exception on failure
```

> Ver exemplo completo (Argon2id + bcrypt) em [`references/authentication.py`](references/authentication.py).

---

### A03 — Injection (SQL, NoSQL, OS, LDAP)

**Riscos:**
- SQL Injection: consultas com input do usuário concatenado diretamente
- Command Injection: execução de comandos do sistema com input não sanitizado
- LDAP, XPath e NoSQL Injection

**Mitigações:**
- Usar **sempre** consultas parametrizadas ou prepared statements — nunca concatenar input em queries
- Utilizar ORM com binding de parâmetros
- Validar e restringir input no servidor (whitelist de caracteres permitidos)
- Aplicar princípio de mínimo privilégio no usuário do banco de dados

```python
# SQL Injection — CORRETO (parametrizado)
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))

# Command Injection — CORRETO
subprocess.run(["ls", user_input], shell=False)
```

> Ver exemplos completos (errado vs correto) em [`references/injection-prevention.py`](references/injection-prevention.py).

---

### A04 — Insecure Design

Categoria nova no OWASP 2021: falhas arquiteturais que nenhuma implementação perfeita consegue corrigir a posteriori.

**Riscos:**
- Ausência de modelagem de ameaças (threat modeling)
- Fluxos de negócio sem validação de limites e regras
- Ausência de padrões de design seguro desde o início

**Mitigações:**
- Realizar threat modeling em funcionalidades críticas (autenticação, pagamento, acesso a dados)
- Definir e validar limites de recursos: rate limits, quotas, paginação obrigatória
- Documentar e implementar regras de negócio no backend — nunca apenas no frontend
- Revisar design de segurança antes de iniciar a implementação

---

### A05 — Security Misconfiguration

**Riscos:**
- Debug habilitado em produção
- Headers de segurança ausentes
- Credenciais padrão não alteradas
- Listagem de diretórios habilitada
- Mensagens de erro detalhadas expostas ao usuário

**Mitigações:**
- Desabilitar modo debug em produção
- Configurar headers HTTP de segurança em todas as respostas
- Remover funcionalidades, endpoints e contas não utilizados
- Retornar mensagens de erro genéricas ao usuário; logar detalhes no servidor
- Aplicar hardening em servidores, containers e serviços de nuvem

**Headers HTTP recomendados:**

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}'; object-src 'none'
```

---

### A06 — Vulnerable and Outdated Components

**Riscos:**
- Dependências com CVEs conhecidas
- Componentes sem manutenção ativa
- Versões de runtime desatualizadas (Node.js, Python, PHP, Java)

**Mitigações:**
- Manter inventário completo de dependências (incluindo transitivas) — gerar SBOM
- Integrar ferramenta de SCA (Software Composition Analysis) na pipeline de CI/CD
- Configurar alertas automáticos para novas CVEs nas dependências utilizadas
- Nunca usar dependências diretas de fontes não confiáveis (forks desconhecidos, URLs diretas)

Ver seção **Gerenciamento de Dependências e Supply Chain** para detalhes completos, ferramentas por ecossistema e definição de SLAs por severidade.

---

### A07 — Authentication and Session Management Failures

**Riscos:**
- Senhas fracas ou sem política de complexidade
- Ausência de proteção contra brute force
- Tokens sem expiração ou sem rotação
- Sessões não invalidadas após logout

**Mitigações:**
- Exigir senhas com comprimento mínimo de 12 caracteres
- Implementar rate limiting e bloqueio temporário em endpoints de autenticação
- Usar MFA (Multi-Factor Authentication) para operações críticas
- JWT: access token com expiração curta (15 min) + refresh token rotativo; assinar com RS256 ou ES256
- Invalidar refresh tokens no logout e detectar reutilização de tokens revogados
- Nunca armazenar JWT em localStorage — preferir cookies HttpOnly + Secure + SameSite=Strict

```python
# JWT — configuração segura (PyJWT)
import jwt
from datetime import datetime, timedelta, timezone

payload = {
    "sub": str(user_id),
    "iat": datetime.now(timezone.utc),
    "exp": datetime.now(timezone.utc) + timedelta(minutes=15),
    "jti": generate_unique_token_id(),  # permite revogação por jti
}
token = jwt.encode(payload, PRIVATE_KEY, algorithm="RS256")
```

---

### A08 — Software and Data Integrity Failures

**Riscos:**
- Desserialização de dados não confiáveis
- Pipeline de CI/CD sem verificação de integridade de artefatos
- Plugins ou dependências carregados de fontes não verificadas

**Mitigações:**
- Verificar assinaturas digitais de pacotes e artefatos antes de instalar ou executar
- Usar lock files (`package-lock.json`, `Pipfile.lock`, `composer.lock`) e verificar checksums
- Configurar acesso restrito ao pipeline de CI/CD; separar ambientes de build e deploy
- Nunca desserializar dados de fontes não confiáveis sem validação de schema e tipo
- Preferir formatos de serialização seguros (JSON com schema validation) em vez de formatos binários nativos

```python
# Alternativa segura — JSON com schema validation
from pydantic import BaseModel
class Payload(BaseModel):
    action: str
    value: int
obj = Payload(**json.loads(user_input))  # validates type and structure
```

> Ver exemplo completo (pickle inseguro vs JSON + Pydantic) em [`references/deserialization.py`](references/deserialization.py).

---

### A09 — Security Logging and Monitoring Failures

**Riscos:**
- Ausência de logs de eventos de segurança
- Logs sem contexto suficiente para investigação
- Alertas não configurados para comportamentos anômalos

**O que registrar (obrigatório):**
- Autenticações: sucesso, falha e bloqueio por brute force
- Alterações de permissão e escalada de privilégio
- Acesso a dados sensíveis ou operações críticas de negócio
- Erros de validação de entrada e violações de acesso
- Erros de integridade de tokens e sessões

**O que NÃO registrar:**
- Senhas, tokens, chaves de API ou secrets de qualquer tipo
- Dados pessoais identificáveis (CPF, e-mail, número de cartão)
- Stack traces completos em respostas de API (apenas no servidor)

**Formato recomendado:** Ver estrutura JSON completa em [`references/logging-examples.json`](references/logging-examples.json).

**Boas práticas:**
- Usar formato estruturado (JSON) para facilitar indexação e consulta
- Centralizar logs em serviço dedicado (ELK Stack, Datadog, CloudWatch)
- Configurar alertas para: múltiplas falhas de login, acesso fora do horário esperado, volume anômalo de requisições
- Reter logs de segurança por no mínimo **1 ano** conforme o Marco Civil da Internet (Lei 12.965/2014, Art. 15) — obrigatório para provedores de aplicação no Brasil
- PCI-DSS exige 12 meses de retenção com 3 meses online e imediatamente disponíveis (Req. 10.7)
- Aplicar a política mais restritiva entre os requisitos legais e setoriais aplicáveis

---

### A10 — Server-Side Request Forgery (SSRF)

**Riscos:**
- Acesso a serviços internos via URL fornecida pelo usuário
- Roubo de credenciais de metadata services em cloud (AWS IMDSv1, GCP, Azure)
- Acesso a sistemas internos não expostos publicamente

**Mitigações:**
- Validar e sanitizar toda URL fornecida pelo usuário
- Usar **allowlist** de domínios e IPs permitidos — nunca blocklist
- Bloquear ranges de IP privados: `127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`
- Desabilitar redirecionamentos HTTP automáticos em requisições do servidor
- Em cloud: usar IMDSv2 (AWS) e desabilitar IMDSv1; restringir acesso ao endpoint de metadata por firewall
- Segmentar a rede: serviços públicos não devem ter acesso direto a serviços internos

> Ver implementação completa de `is_safe_url` com resolução DNS e bloqueio de ranges privados em [`references/ssrf-validation.py`](references/ssrf-validation.py).

> **DNS Rebinding:** um atacante pode fazer um hostname resolver para IP público durante a validação e para IP privado na requisição real. A validação deve ser feita **após** a resolução DNS, verificando o IP resultante.

---

## Autenticação e Autorização

### Senhas

- Comprimento mínimo: 12 caracteres; não impor regras excessivas de complexidade (NIST SP 800-63B)
- Verificar senhas contra lista de senhas conhecidas comprometidas (haveibeenpwned API)
- Hash: **Argon2id** para projetos novos; bcrypt (cost ≥ 12) para sistemas existentes
- Nunca armazenar ou logar senhas em texto plano, nem mesmo temporariamente

### Tokens JWT

- Assinar com RS256 ou ES256 (assimétrico); evitar HS256 em sistemas distribuídos
- Access token: expiração de 15 minutos; refresh token: expiração de 7–30 dias com rotação
- Validar `iss`, `aud`, `exp` e `jti` em cada requisição
- Manter blocklist de `jti` de tokens revogados (logout, troca de senha, suspeita de comprometimento)

### Rate Limiting

- Aplicar rate limiting por **múltiplos critérios simultâneos**: IP, identificador de usuário e device fingerprint
- Rate limiting apenas por IP é bypassável via IPv6, proxies rotacionados e endereços dinâmicos
- Para endpoints críticos (login, recuperação de senha), considerar CAPTCHA acessível após N falhas consecutivas
- Implementar backoff exponencial no bloqueio: 1s → 5s → 30s → 15min
- Endpoints de API gerais: implementar rate limiting por usuário autenticado
- Usar cabeçalhos de resposta padronizados: `RateLimit-Limit`, `RateLimit-Remaining`, `Retry-After`

---

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

---

## Proteção contra CSRF

- Usar tokens CSRF sincronizados (padrão Synchronizer Token Pattern) em formulários e requisições de mutação
- Alternativa moderna: SameSite cookies com `SameSite=Strict` ou `SameSite=Lax`
- Verificar o header `Origin` ou `Referer` como camada adicional de defesa
- APIs JSON-only: verificar `Content-Type: application/json` (browsers não enviam cross-origin sem CORS explícito)

```python
# Sempre usar compare_digest — nunca == — para evitar timing attacks
secrets.compare_digest(session_token, request_token)
```

> Ver implementação completa de geração e validação em [`references/csrf-protection.py`](references/csrf-protection.py).

> **Timing attacks:** Sempre usar `secrets.compare_digest()` em vez de `==` para comparar tokens, hashes e segredos. O operador `==` interrompe a comparação no primeiro byte diferente (short-circuit), criando variação de tempo mensurável que permite inferir o valor correto byte a byte. `compare_digest` garante tempo de execução constante independente da posição da diferença.

---

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

> Ver implementação completa de `validate_upload` e `save_upload` em [`references/file-upload-security.py`](references/file-upload-security.py).

---

## Configuração de CORS

- Nunca usar `Access-Control-Allow-Origin: *` em APIs autenticadas
- Definir allowlist explícita de origens; validar `Origin` contra a lista no servidor
- Restringir métodos e headers expostos ao mínimo necessário
- Não refletir automaticamente o header `Origin` sem validação

> Ver implementação completa de allowlist de origens em [`references/cors-config.py`](references/cors-config.py).

---

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

---

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

---

## Dados Sensíveis e Privacidade

- Nunca incluir em logs: senhas, tokens, CPF, e-mail, número de cartão, dados de saúde
- Mascarar dados sensíveis em respostas de API quando não estritamente necessários (ex: retornar `****1234` para cartões)
- Aplicar criptografia em repouso para dados classificados como sensíveis
- Definir política de retenção de dados e implementar exclusão efetiva
- Retornar apenas os campos necessários em respostas de API (evitar over-fetching de dados pessoais)

---

## Checklist de Revisão de Segurança

Usar como referência rápida em code reviews e antes de merges para produção:

- [ ] Input validado no servidor (tipo, tamanho, formato, range)
- [ ] Queries parametrizadas — sem concatenação de input em SQL
- [ ] Autorização verificada em todos os endpoints (não apenas autenticação)
- [ ] Dados sensíveis ausentes de logs, URLs e respostas desnecessárias
- [ ] Secrets não hardcoded; variáveis de ambiente ou vault em uso
- [ ] Headers HTTP de segurança configurados
- [ ] CSP definida e sem `unsafe-inline`/`unsafe-eval`
- [ ] Proteção CSRF ativa em mutações de estado
- [ ] Rate limiting em endpoints de autenticação
- [ ] Dependências verificadas (sem CVEs críticas ou altas pendentes)
- [ ] Erros retornam mensagens genéricas ao cliente
- [ ] Login e recuperação de senha retornam a **mesma mensagem e tempo de resposta** para usuário existente e inexistente (previne user enumeration e timing attacks)
- [ ] Logs de eventos de segurança registrando contexto suficiente
