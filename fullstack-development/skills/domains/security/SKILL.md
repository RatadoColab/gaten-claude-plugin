---
name: security
description: This skill should be used when implementing security features, reviewing code for vulnerabilities, or applying security best practices. Typical triggers include "review this for security", "is this vulnerable to SQL injection?", "how do I prevent XSS/CSRF/SSRF?", "secure this authentication flow", "how should I store passwords?", "audit this endpoint for OWASP issues", "secure this LLM/AI feature", "prevent prompt injection". Covers OWASP Top 10:2025, input validation, authentication, authorization, data protection, secrets management, application supply chain, safe error handling, logging, and LLM application security.
---

# Security — Segurança em Aplicações Web

## Visão Geral

Diretrizes de segurança baseadas no **OWASP Top 10:2025** para aplicações web e APIs. Aplicar em
revisões de código, implementação de funcionalidades e auditorias de segurança.

## Princípios Fundamentais

- **Validar na entrada:** Nunca confiar em dados do cliente — validar tipo, formato, tamanho e range
- **Sanitizar na saída:** Escapar dados antes de renderizar HTML, SQL, JSON ou qualquer contexto de saída
- **Mínimo de privilégios:** Usuários e serviços acessam somente o que precisam, negação por padrão
- **Defense in depth:** Múltiplas camadas independentes de proteção; nenhuma camada isolada é suficiente
- **Segurança por design:** Incorporar requisitos de segurança desde a fase de modelagem, não como correção posterior
- **Fail safe:** Em caso de erro, negar acesso e reverter a transação — nunca falhar de forma permissiva

---

## OWASP Top 10:2025 — Resumo

| # | Categoria | Mitigação-chave |
|---|-----------|-----------------|
| A01 | Broken Access Control (inclui **SSRF**) | Autorização no servidor em todos os endpoints; `deny-by-default`; RBAC/ABAC; allowlist de URLs + bloqueio de ranges privados |
| A02 | Security Misconfiguration | Debug off em prod; headers de segurança; hardening repetível; erros genéricos |
| A03 | Software Supply Chain Failures | SBOM (dir. + transitivas); SCA na CI/CD; pacotes assinados + proveniência; rollout escalonado; infra de build endurecida |
| A04 | Cryptographic Failures | HTTPS/TLS 1.3 (1.2 mínimo); HSTS; senhas com Argon2id/bcrypt; AES-256-GCM em repouso |
| A05 | Injection (inclui XSS) | Queries parametrizadas; ORM com binding; allowlist de input; escape por contexto |
| A06 | Insecure Design | Threat modeling; limites/quotas; regras de negócio no backend; paved road |
| A07 | Authentication Failures | Senha ≥ 15 chars (8 c/ MFA); rate limit; passkeys/WebAuthn; JWT curto + refresh rotativo |
| A08 | Software/Data Integrity Failures | Sem desserialização não confiável; assinar dados de estado; validar schema |
| A09 | Security Logging & Alerting Failures | Logar eventos de segurança; nunca secrets/PII; logs íntegros; alertas com playbook |
| A10 | Mishandling of Exceptional Conditions | Tratar erro no ponto de origem; handler global; fail closed; rollback total; quotas |

> Detalhe completo de cada categoria (riscos, mitigações e exemplos) em [`references/owasp-top10.md`](references/owasp-top10.md).

---

## Autenticação e Autorização

### Senhas

- Comprimento mínimo: **15 caracteres** quando a senha é o único autenticador; **8 caracteres** se
  combinada com MFA (NIST SP 800-63B-4)
- Suportar senhas de até no mínimo 64 caracteres; aceitar todo caractere imprimível (espaços e Unicode inclusos)
- **Não impor regras de composição** (maiúscula/número/símbolo) nem perguntas de segurança (KBA)
- Verificar a senha nova contra lista de senhas comprometidas conhecidas (haveibeenpwned API)
- Hash: **Argon2id** para projetos novos; bcrypt (cost ≥ 12, senha truncada em 72 bytes) para sistemas existentes
- Preferir autenticadores resistentes a phishing (passkeys / WebAuthn) para operações críticas
- Nunca armazenar ou logar senhas em texto plano, nem mesmo temporariamente

### Tokens JWT

- Assinar com RS256 ou ES256 (assimétrico); evitar HS256 em sistemas distribuídos
- Access token: expiração de 15 minutos; refresh token: expiração de 7–30 dias com rotação
- Validar `iss`, `aud`, `exp` e `jti` em cada requisição
- Manter blocklist de `jti` de tokens revogados (logout, troca de senha, suspeita de comprometimento)
- Ao usar cookie para o token, aplicar o prefixo `__Host-` + `HttpOnly` + `Secure` + `SameSite=Strict`

### Rate Limiting

- Aplicar rate limiting por **múltiplos critérios simultâneos**: IP, identificador de usuário e device fingerprint
- Rate limiting apenas por IP é bypassável via IPv6, proxies rotacionados e endereços dinâmicos
- Para endpoints críticos (login, recuperação de senha), considerar CAPTCHA acessível após N falhas consecutivas
- Implementar backoff exponencial no bloqueio: 1s → 5s → 30s → 15min
- Endpoints de API gerais: implementar rate limiting por usuário autenticado
- Comunicar o limite via `RateLimit` e `RateLimit-Policy` (structured fields do draft IETF
  `draft-ietf-httpapi-ratelimit-headers`) + `Retry-After` no `429`. O formato antigo
  `RateLimit-Limit`/`RateLimit-Remaining`/`RateLimit-Reset` permanece comum em APIs existentes

---

## Defesas Web

Pontos essenciais por superfície de ataque. Implementações completas (CSP, tokens CSRF,
validação de upload, CORS, cookies, secrets, supply chain) em [`references/web-defenses.md`](references/web-defenses.md).

- **XSS:** escapar output em todo contexto; CSP restritiva sem `unsafe-inline`/`unsafe-eval`, com nonce por requisição + `'strict-dynamic'`
- **Injeção (SQL/HTML/shell) em Python 3.14+:** t-strings (PEP 750) separam trecho estático de valor interpolado; processar o `Template` aplicando binding do driver ou `html.escape` impede a concatenação de input por construção — ver `languages/python/references/python314-features.md`
- **CSRF:** Synchronizer Token Pattern + `SameSite=Strict/Lax`; comparar tokens com `compare_digest` (constante no tempo)
- **Clickjacking:** `Content-Security-Policy: frame-ancestors 'none'` (torna `X-Frame-Options` obsoleto; manter só para clientes legados)
- **Upload:** validar por magic bytes (não extensão); renomear no servidor; armazenar fora do webroot; allowlist + limite de tamanho
- **CORS:** allowlist explícita de origens; nunca `*` em APIs autenticadas; não refletir `Origin` sem validar
- **Secrets:** nunca no código/git; env em dev, vault em produção; rotação e revogação imediata se exposto
- **Supply chain da aplicação (A03):** lock files + verificação de proveniência; SCA por ecossistema (`npm audit`, `pip-audit`, `composer audit`, OSV-Scanner); SBOM CycloneDX/SPDX; pin por digest. Segurança do pipeline em `domains/devsecops/SKILL.md`
- **Tratamento de erros (A10):** handler global; `fail closed` + rollback total; mensagem genérica ao cliente; alertar sobre padrões repetidos de erro
- **Dados sensíveis:** nunca em logs; mascarar em respostas; criptografia em repouso; retornar só campos necessários

---

## Segurança de Aplicações com LLM

Para funcionalidades que consomem modelos de linguagem (chatbots, copilots, RAG, agentes com tool
calling), aplicar o **OWASP Top 10 for LLM Applications** — ponto de partida:

- Tratar a **saída do modelo como input não confiável**: escapar/validar antes de renderizar, executar em shell ou usar em query
- Prompt injection: separar instruções de sistema de conteúdo do usuário e de documentos recuperados; nunca confiar em delimitadores textuais
- Tool calling: permissões mínimas por ferramenta, human-in-the-loop em ações destrutivas ou irreversíveis
- Isolamento multi-tenant em bases vetoriais / RAG; teto de custo e quota de tokens por usuário

> Detalhamento das 10 categorias e mitigações em [`references/llm-security.md`](references/llm-security.md).

---

## Checklist de Revisão de Segurança

Usar como referência rápida em code reviews e antes de merges para produção:

- [ ] Input validado no servidor (tipo, tamanho, formato, range)
- [ ] Queries parametrizadas — sem concatenação de input em SQL
- [ ] Autorização verificada em todos os endpoints (não apenas autenticação)
- [ ] URLs fornecidas pelo usuário validadas contra allowlist; ranges privados bloqueados (SSRF)
- [ ] Dados sensíveis ausentes de logs, URLs e respostas desnecessárias
- [ ] Secrets não hardcoded; variáveis de ambiente ou vault em uso
- [ ] Headers HTTP de segurança configurados (HSTS, `nosniff`, `Referrer-Policy`, COOP/CORP)
- [ ] CSP definida com nonce + `'strict-dynamic'`, sem `unsafe-inline`/`unsafe-eval`; `frame-ancestors` restrito
- [ ] Proteção CSRF ativa em mutações de estado
- [ ] Rate limiting em endpoints de autenticação
- [ ] Política de senha conforme NIST 800-63B-4 (≥ 15 chars ou ≥ 8 com MFA; sem regra de composição)
- [ ] Dependências: SBOM gerado, sem CVEs críticas/altas pendentes, proveniência verificada
- [ ] Erros retornam mensagens genéricas ao cliente; caminho de erro faz `fail closed` + rollback
- [ ] Login e recuperação de senha retornam a **mesma mensagem e tempo de resposta** para usuário existente e inexistente (previne user enumeration e timing attacks)
- [ ] Logs de eventos de segurança registrando contexto suficiente, com integridade garantida e alerta configurado
- [ ] Saída de LLM tratada como não confiável antes de renderizar/executar (quando aplicável)

---

## Referências

- [`references/owasp-top10.md`](references/owasp-top10.md) — catálogo detalhado das 10 categorias
- [`references/web-defenses.md`](references/web-defenses.md) — XSS, CSRF, upload, CORS, cookies, secrets, supply chain
- [`references/llm-security.md`](references/llm-security.md) — segurança de aplicações que consomem LLM
- Ver `domains/devsecops/SKILL.md` para segurança no pipeline e na infraestrutura (SAST/SCA/DAST, IaC/image scanning, SBOM assinado, cosign/SLSA, supply chain, secrets) — escopo de DevSecOps complementar a este
- Ver `domains/api-rest/SKILL.md` para autenticação, autorização e contratos de API
- Ver `domains/database/SKILL.md` para queries parametrizadas e proteção de dados
- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)
- [OWASP Application Security Verification Standard (ASVS) 5.0](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/)
- [NIST SP 800-63B — Digital Identity Guidelines](https://pages.nist.gov/800-63-4/sp800-63b.html)
