# OWASP Top 10:2025 — Vulnerabilidades e Mitigações (detalhado)

Catálogo completo das 10 categorias do OWASP Top 10:2025, com riscos, mitigações e
exemplos. Resumo e tabela rápida ficam no `SKILL.md`; este arquivo é o detalhamento.

> Mudanças em relação a 2021: SSRF deixou de ser categoria própria e foi absorvido por **A01**;
> "Vulnerable and Outdated Components" foi expandido e promovido a **A03 — Software Supply Chain
> Failures**; **A10 — Mishandling of Exceptional Conditions** é categoria nova; A07 e A09 foram
> renomeados. Release candidate em nov/2025, versão final em jan/2026.

## A01 — Broken Access Control

Segue como a categoria mais prevalente: 100% das aplicações testadas apresentaram alguma falha de
controle de acesso, com 40 CWEs mapeadas. Inclui agora **SSRF (CWE-918)** — o servidor é induzido a
acessar recursos fora do escopo pretendido.

**Riscos:**
- Acesso a recursos de outros usuários por manipulação de IDs (IDOR)
- Escalada de privilégios horizontal e vertical
- Acesso a rotas administrativas sem verificação
- SSRF: acesso a serviços internos e a metadata services de nuvem via URL controlada pelo usuário

**Mitigações:**
- Implementar controle de acesso no servidor em **todos** os endpoints, sem exceção
- Adotar modelo de negação por padrão (`deny-by-default`): se não há permissão explícita, o acesso é negado
- Centralizar e reutilizar o mecanismo de autorização — não reimplementar por endpoint
- Verificar autorização em cada requisição — nunca apenas no login
- Impor propriedade do registro; aplicar regras de negócio do modelo de domínio
- Implementar RBAC (Role-Based Access Control) ou ABAC (Attribute-Based Access Control)
- Invalidar tokens e sessões ao fazer logout; preferir JWT de vida curta
- Desabilitar listagem de diretórios e remover metadados sensíveis do webroot
- Aplicar rate limiting em APIs e controllers
- Registrar falhas de controle de acesso e alertar para padrões suspeitos
- Cobrir controle de acesso em testes unitários e de integração

```python
# Verificação de propriedade do recurso antes de retornar
def get_document(doc_id: int, current_user: User) -> Document:
    doc = db.query(Document).filter(Document.id == doc_id).first()
    if not doc or doc.owner_id != current_user.id:
        raise PermissionDenied("Access denied")
    return doc
```

### SSRF — Server-Side Request Forgery (subcategoria de A01)

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

## A02 — Security Misconfiguration

Subiu de #5 (2021) para #2. Misconfigurações tornaram-se mais prevalentes nos dados do ciclo atual.

**Riscos:**
- Debug habilitado em produção
- Headers de segurança ausentes
- Credenciais padrão não alteradas
- Listagem de diretórios habilitada
- Mensagens de erro detalhadas expostas ao usuário
- Serviços de nuvem e containers com permissões amplas por padrão

**Mitigações:**
- Desabilitar modo debug em produção
- Configurar headers HTTP de segurança em todas as respostas
- Remover funcionalidades, endpoints e contas não utilizados
- Retornar mensagens de erro genéricas ao usuário; logar detalhes no servidor
- Aplicar hardening em servidores, containers e serviços de nuvem
- Processo repetível de hardening — mesmo baseline em todos os ambientes

**Headers HTTP recomendados:**

```http
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-site
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{random}' 'strict-dynamic'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'
```

> `frame-ancestors` é o controle primário contra clickjacking e torna `X-Frame-Options` obsoleto nos
> navegadores que o suportam; manter `X-Frame-Options: DENY` apenas para clientes legados.
> Detalhamento de CSP, COOP/COEP/CORP e cookies em [`web-defenses.md`](web-defenses.md).

## A03 — Software Supply Chain Failures

Evolução de "Vulnerable and Outdated Components": cobre agora todo o ecossistema de build,
distribuição e atualização de software — não só a CVE na dependência.

**Riscos:**
- Dependências com CVEs conhecidas e versões de runtime desatualizadas (Node.js, Python, PHP, Java)
- Dependências não mantidas ou sem caminho de atualização (componentes "non-updateable")
- Comprometimento da infra de build: pipeline de CI/CD, repositório de código, IDE, artifact registry
- Pacote de fornecedor comprometido (ex.: SolarWinds) e ataques auto-propagáveis (ex.: worm Shai-Hulud no npm, set/2025)
- Ausência de controle de acesso e gestão de mudança ao longo da cadeia de desenvolvimento

**Mitigações:**
- Manter inventário completo de dependências diretas e transitivas — gerar SBOM (CycloneDX/SPDX)
- Escanear continuamente por vulnerabilidades (SCA) e configurar alertas automáticos de novas CVEs
- Obter componentes de fontes confiáveis por canal seguro; preferir pacotes assinados e verificar proveniência
- Documentar e rastrear toda mudança em CI/CD, repositórios, IDEs e integrações de terceiros
- Endurecer a infra de build: MFA, menor privilégio, segregação de funções no processo de build
- Evitar atualização simultânea em toda a frota — usar rollout escalonado/canário para limitar exposição
- Nunca usar dependências de fontes não confiáveis (forks desconhecidos, URLs diretas)

> Ferramentas por ecossistema, verificação de proveniência e SLAs por severidade em
> [`web-defenses.md`](web-defenses.md) (§Gerenciamento de Dependências e Supply Chain).
> Segurança do **pipeline** (SAST/SCA/DAST na CI, SBOM assinado, cosign/Sigstore, SLSA) em
> `domains/devsecops/SKILL.md` — escopo complementar.

## A04 — Cryptographic Failures

**Riscos:**
- Dados sensíveis transmitidos em texto plano (sem HTTPS)
- Senhas armazenadas com hash fraco (MD5, SHA-1, SHA-256 sem salt)
- Dados sensíveis em cache, logs ou URLs
- Uso de algoritmos criptográficos obsoletos

**Mitigações:**
- Exigir HTTPS em toda a aplicação; redirecionar HTTP para HTTPS
- Preferir TLS 1.3; aceitar TLS 1.2 como piso mínimo
- Habilitar HSTS (`Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`)
- Para senhas, usar **Argon2id**; bcrypt permanece aceitável para sistemas existentes
- Não armazenar dados sensíveis além do necessário
- Usar AES-256 (GCM) para dados em repouso

**Argon2id — perfis equivalentes recomendados pelo OWASP (usar o de maior memória que a infra suportar):**

| memory_cost | time_cost | parallelism |
|-------------|-----------|-------------|
| 47104 (46 MiB) | 1 | 1 |
| 19456 (19 MiB) | 2 | 1 |
| 12288 (12 MiB) | 3 | 1 |
| 9216 (9 MiB)   | 4 | 1 |
| 7168 (7 MiB)   | 5 | 1 |

**bcrypt:** work factor (cost) ≥ 10, tão alto quanto a performance de verificação permitir; a senha é
truncada em **72 bytes** — validar o comprimento antes de gerar o hash. Não fazer pre-hash ingênuo
(risco de null bytes e password shucking).

```python
# Argon2id — perfil m=19456, t=2, p=1
from argon2 import PasswordHasher
ph = PasswordHasher(time_cost=2, memory_cost=19456, parallelism=1)
hashed = ph.hash(plain_password)
ph.verify(hashed, plain_password)  # raises exception on failure
```

> Ver exemplo completo (Argon2id + bcrypt) em [`authentication.py`](authentication.py).

## A05 — Injection (SQL, NoSQL, OS, LDAP)

Inclui Cross-Site Scripting (XSS), tratado como injeção no contexto do navegador.

**Riscos:**
- SQL Injection: consultas com input do usuário concatenado diretamente
- Command Injection: execução de comandos do sistema com input não sanitizado
- LDAP, XPath e NoSQL Injection
- XSS: dados não escapados renderizados no navegador

**Mitigações:**
- Usar **sempre** consultas parametrizadas ou prepared statements — nunca concatenar input em queries
- Utilizar ORM com binding de parâmetros
- Validar e restringir input no servidor (allowlist de caracteres permitidos)
- Aplicar princípio de mínimo privilégio no usuário do banco de dados
- Escapar output por contexto de renderização; CSP restritiva (ver [`web-defenses.md`](web-defenses.md))

```python
# SQL Injection — CORRETO (parametrizado)
query = "SELECT * FROM users WHERE username = %s"
cursor.execute(query, (username,))

# Command Injection — CORRETO
subprocess.run(["ls", user_input], shell=False)
```

> Ver exemplos completos (errado vs correto) em [`injection-prevention.py`](injection-prevention.py).

## A06 — Insecure Design

Falhas arquiteturais que nenhuma implementação perfeita consegue corrigir a posteriori.

**Riscos:**
- Ausência de modelagem de ameaças (threat modeling)
- Fluxos de negócio sem validação de limites e regras
- Ausência de padrões de design seguro desde o início

**Mitigações:**
- Realizar threat modeling em funcionalidades críticas (autenticação, pagamento, acesso a dados)
- Definir e validar limites de recursos: rate limits, quotas, paginação obrigatória
- Documentar e implementar regras de negócio no backend — nunca apenas no frontend
- Revisar design de segurança antes de iniciar a implementação
- Usar padrões e componentes de design seguro comprovados (paved road)

## A07 — Authentication Failures

Renomeado (era "Identification and Authentication Failures").

**Riscos:**
- Senhas fracas ou sem verificação contra listas de senhas comprometidas
- Ausência de proteção contra brute force
- Tokens sem expiração ou sem rotação
- Sessões não invalidadas após logout
- Autenticação por conhecimento (perguntas de segurança / KBA)

**Mitigações:**
- Política de senha alinhada ao **NIST SP 800-63B-4**: mínimo de 15 caracteres quando a senha é o
  único autenticador (8 com MFA); suportar ≥ 64 caracteres; permitir todo caractere imprimível
  (incl. espaços e Unicode); **sem regras obrigatórias de composição** e **sem KBA**
- Verificar a senha nova contra listas de senhas vazadas (ex.: haveibeenpwned)
- Implementar rate limiting e bloqueio temporário em endpoints de autenticação
- Preferir autenticadores resistentes a phishing (passkeys / WebAuthn) para operações críticas; MFA como mínimo
- JWT: access token com expiração curta (15 min) + refresh token rotativo; assinar com RS256 ou ES256
- Invalidar refresh tokens no logout e detectar reutilização de tokens revogados
- Nunca armazenar JWT em localStorage — preferir cookies `__Host-` + HttpOnly + Secure + SameSite=Strict

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

Escopo reduzido: o que era comprometimento de pipeline e de dependências migrou para **A03**. Aqui
ficam desserialização insegura e integridade de dados em trânsito na aplicação.

**Riscos:**
- Desserialização de dados não confiáveis
- Atualizações automáticas sem verificação de integridade
- Dados de estado (cookies, campos ocultos, tokens) alterados pelo cliente sem verificação de assinatura

**Mitigações:**
- Nunca desserializar dados de fontes não confiáveis sem validação de schema e tipo
- Preferir formatos de serialização seguros (JSON com schema validation) em vez de formatos binários nativos
- Assinar e verificar dados de estado que trafeguem pelo cliente
- Verificar assinaturas digitais de pacotes e artefatos antes de instalar ou executar

```python
# Alternativa segura — JSON com schema validation
from pydantic import BaseModel
class Payload(BaseModel):
    action: str
    value: int
obj = Payload(**json.loads(user_input))  # validates type and structure
```

> Ver exemplo completo (pickle inseguro vs JSON + Pydantic) em [`deserialization.py`](deserialization.py).

## A09 — Security Logging and Alerting Failures

Renomeado (era "…and Monitoring") para enfatizar o **alerting**: detectar sem acionar resposta em
tempo hábil não reduz o impacto do incidente.

**Riscos:**
- Ausência de logs de eventos de segurança
- Logs sem contexto suficiente para investigação
- Alertas não configurados para comportamentos anômalos
- Logs sem proteção contra adulteração

**O que registrar (obrigatório):**
- Autenticações: sucesso, falha e bloqueio por brute force
- Alterações de permissão e escalada de privilégio; decisões e falhas de controle de acesso
- Acesso a dados sensíveis ou operações críticas de negócio (com trilha de auditoria completa)
- Erros de validação de entrada no servidor, com contexto de usuário
- Erros de integridade de tokens e sessões

**O que NÃO registrar:**
- Senhas, tokens, chaves de API ou secrets de qualquer tipo
- Dados pessoais identificáveis (CPF, e-mail, número de cartão)
- Stack traces completos em respostas de API (apenas no servidor)

**Formato recomendado:** Ver estrutura JSON completa em [`logging-examples.json`](logging-examples.json).

**Boas práticas:**
- Usar formato estruturado (JSON) e encoding correto para evitar log injection
- Garantir integridade: armazenamento append-only ou WORM; logs fora do alcance da aplicação que os gera
- Centralizar logs em serviço dedicado (ELK Stack, Datadog, CloudWatch)
- Definir casos de uso de detecção com **playbooks** e procedimento de resposta a incidente
- Configurar alertas para: múltiplas falhas de login, acesso fora do horário esperado, volume anômalo de requisições
- Reter logs de segurança por no mínimo **6 meses** conforme o Marco Civil da Internet (Lei
  12.965/2014, Art. 15) — obrigatório para provedores de aplicação constituídos como pessoa
  jurídica com fins econômicos (o prazo de 1 ano do Art. 13 aplica-se a provedores de **conexão**)
- PCI-DSS v4.0.1 (Req. 10.5.1): 12 meses de retenção, com os 3 meses mais recentes imediatamente disponíveis
- Aplicar a política mais restritiva entre os requisitos legais e setoriais aplicáveis

## A10 — Mishandling of Exceptional Conditions

Categoria nova: tratamento impróprio de erros e condições anormais deixa o sistema em estado
imprevisível e explorável. Cobre 24 CWEs, entre elas CWE-209 (mensagem de erro expõe informação
interna), CWE-476 (null pointer dereference), CWE-636 ("failing open" — falha para estado
inseguro), CWE-369 (divisão por zero).

**Riscos:**
- Exaustão de recursos, corrupção de estado e exposição de dados em caminhos de erro
- Bypass de autenticação/autorização quando uma exceção interrompe o fluxo antes da checagem
- Vazamento de detalhes de implementação em stack traces retornados ao cliente

**Mitigações:**
- Tratar exceções no ponto onde ocorrem; validar e sanitizar entrada de forma estrita
- Tratamento de erros centralizado e consistente em toda a aplicação
- Handler global de exceções como rede de segurança final
- **Fail closed:** em erro, negar acesso e reverter a transação por completo (rollback total)
- Rate limiting, quotas e throttling para prevenir exaustão de recursos
- Monitorar e alertar sobre padrões repetidos de erro — indicam ataque em curso
- Retornar mensagem genérica ao cliente; detalhes apenas no log do servidor
- Considerar tratamento de erros no threat modeling e na revisão de design
