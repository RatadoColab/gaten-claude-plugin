---
name: security
description: This skill should be used when implementing security features, reviewing code for vulnerabilities, or applying security best practices. Typical triggers include "review this for security", "is this vulnerable to SQL injection?", "how do I prevent XSS/CSRF?", "secure this authentication flow", "how should I store passwords?", "audit this endpoint for OWASP issues". Covers OWASP Top 10 2021, input validation, authentication, authorization, data protection, secrets management, logging, and supply chain security.
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

## OWASP Top 10:2021 — Resumo

| # | Categoria | Mitigação-chave |
|---|-----------|-----------------|
| A01 | Broken Access Control | Autorização no servidor em todos os endpoints; `deny-by-default`; RBAC/ABAC |
| A02 | Cryptographic Failures | HTTPS/TLS 1.2+; HSTS; senhas com Argon2id/bcrypt; AES-256 em repouso |
| A03 | Injection | Queries parametrizadas; ORM com binding; allowlist de input |
| A04 | Insecure Design | Threat modeling; limites/quotas; regras de negócio no backend |
| A05 | Security Misconfiguration | Debug off em prod; headers de segurança; hardening; erros genéricos |
| A06 | Vulnerable Components | SBOM; SCA na CI/CD; alertas de CVE; sem fontes não confiáveis |
| A07 | Auth & Session Failures | Senha ≥ 12 chars; rate limit; MFA; JWT curto + refresh rotativo |
| A08 | Software/Data Integrity | Assinaturas/checksums; lock files; sem desserialização não confiável |
| A09 | Logging & Monitoring | Logar eventos de segurança; nunca secrets/PII; alertas e retenção |
| A10 | SSRF | Allowlist de URLs; bloquear ranges privados; validar pós-resolução DNS |

> Detalhe completo de cada categoria (riscos, mitigações e exemplos) em [`references/owasp-top10.md`](references/owasp-top10.md).

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

## Defesas Web

Pontos essenciais por superfície de ataque. Implementações completas (CSP, tokens CSRF,
validação de upload, CORS, secrets, supply chain) em [`references/web-defenses.md`](references/web-defenses.md).

- **XSS:** escapar output em todo contexto; CSP restritiva sem `unsafe-inline`/`unsafe-eval`, usando nonces por requisição
- **CSRF:** Synchronizer Token Pattern + `SameSite=Strict/Lax`; comparar tokens com `compare_digest` (constante no tempo)
- **Upload:** validar por magic bytes (não extensão); renomear no servidor; armazenar fora do webroot; allowlist + limite de tamanho
- **CORS:** allowlist explícita de origens; nunca `*` em APIs autenticadas; não refletir `Origin` sem validar
- **Secrets:** nunca no código/git; env em dev, vault em produção; rotação e revogação imediata se exposto
- **Supply chain:** lock files + checksums; SCA por ecossistema (`npm audit`, `pip-audit`, `composer audit`); SBOM
- **Dados sensíveis:** nunca em logs; mascarar em respostas; criptografia em repouso; retornar só campos necessários

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

---

## Referências

- [`references/owasp-top10.md`](references/owasp-top10.md) — catálogo detalhado das 10 categorias
- [`references/web-defenses.md`](references/web-defenses.md) — XSS, CSRF, upload, CORS, secrets, supply chain
- Ver `../devsecops/SKILL.md` para segurança no pipeline e na infraestrutura (SAST/SCA/DAST, IaC/image scanning, SBOM, supply chain, secrets) — escopo de DevSecOps complementar a este
- Ver `../api-rest/SKILL.md` para autenticação, autorização e contratos de API
- Ver `../database/SKILL.md` para queries parametrizadas e proteção de dados
- [OWASP Top 10:2021](https://owasp.org/Top10/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
