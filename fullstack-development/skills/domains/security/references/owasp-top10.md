# OWASP Top 10:2021 — Vulnerabilidades e Mitigações (detalhado)

Catálogo completo das 10 categorias do OWASP Top 10:2021, com riscos, mitigações e
exemplos. Resumo e tabela rápida ficam no `SKILL.md`; este arquivo é o detalhamento.

## A01 — Broken Access Control

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

## A02 — Cryptographic Failures

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

> Ver exemplo completo (Argon2id + bcrypt) em [`authentication.py`](authentication.py).

## A03 — Injection (SQL, NoSQL, OS, LDAP)

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

> Ver exemplos completos (errado vs correto) em [`injection-prevention.py`](injection-prevention.py).

## A04 — Insecure Design

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

## A05 — Security Misconfiguration

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

## A06 — Vulnerable and Outdated Components

**Riscos:**
- Dependências com CVEs conhecidas
- Componentes sem manutenção ativa
- Versões de runtime desatualizadas (Node.js, Python, PHP, Java)

**Mitigações:**
- Manter inventário completo de dependências (incluindo transitivas) — gerar SBOM
- Integrar ferramenta de SCA (Software Composition Analysis) na pipeline de CI/CD
- Configurar alertas automáticos para novas CVEs nas dependências utilizadas
- Nunca usar dependências diretas de fontes não confiáveis (forks desconhecidos, URLs diretas)

Ver seção **Gerenciamento de Dependências e Supply Chain** em [`web-defenses.md`](web-defenses.md) para detalhes completos, ferramentas por ecossistema e definição de SLAs por severidade.

## A07 — Authentication and Session Management Failures

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

## A08 — Software and Data Integrity Failures

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

> Ver exemplo completo (pickle inseguro vs JSON + Pydantic) em [`deserialization.py`](deserialization.py).

## A09 — Security Logging and Monitoring Failures

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

**Formato recomendado:** Ver estrutura JSON completa em [`logging-examples.json`](logging-examples.json).

**Boas práticas:**
- Usar formato estruturado (JSON) para facilitar indexação e consulta
- Centralizar logs em serviço dedicado (ELK Stack, Datadog, CloudWatch)
- Configurar alertas para: múltiplas falhas de login, acesso fora do horário esperado, volume anômalo de requisições
- Reter logs de segurança por no mínimo **1 ano** conforme o Marco Civil da Internet (Lei 12.965/2014, Art. 15) — obrigatório para provedores de aplicação no Brasil
- PCI-DSS exige 12 meses de retenção com 3 meses online e imediatamente disponíveis (Req. 10.7)
- Aplicar a política mais restritiva entre os requisitos legais e setoriais aplicáveis

## A10 — Server-Side Request Forgery (SSRF)

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

> Ver implementação completa de `is_safe_url` com resolução DNS e bloqueio de ranges privados em [`ssrf-validation.py`](ssrf-validation.py).

> **DNS Rebinding:** um atacante pode fazer um hostname resolver para IP público durante a validação e para IP privado na requisição real. A validação deve ser feita **após** a resolução DNS, verificando o IP resultante.
