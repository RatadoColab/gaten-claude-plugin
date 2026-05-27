---
name: security
description: This skill should be used when implementing security features, reviewing code for vulnerabilities, or applying security best practices. Covers OWASP Top 10, input validation, authentication, authorization, and data protection.
version: 0.1.0
---

# Security — Segurança em Aplicações Web

## Visão Geral

Diretrizes mínimas de segurança baseadas no OWASP Top 10 para aplicações backend.

## Princípios Fundamentais

- **Validar na entrada:** Nunca confiar em dados do cliente
- **Sanitizar na saída:** Escapar dados antes de renderizar
- **Mínimo de privilégios:** Usuários e serviços acessam apenas o necessário
- **Defense in depth:** Múltiplas camadas de proteção

## Vulnerabilidades Críticas (OWASP Top 10)

- **Injection (SQL, LDAP, OS):** Usar parâmetros preparados, nunca concatenar input em queries
- **Broken Authentication:** Senhas com hash forte (bcrypt/argon2), tokens com expiração
- **Sensitive Data Exposure:** HTTPS obrigatório, não logar dados sensíveis
- **Broken Access Control:** Verificar permissões no servidor, nunca só no cliente
- **Security Misconfiguration:** Remover debug em produção, headers de segurança ativos
- **XSS:** Escapar output HTML, CSP headers
- **CSRF:** Tokens CSRF em formulários e requisições de mutação

## Autenticação e Autorização

- Tokens JWT com expiração curta + refresh tokens
- Senhas nunca em texto plano; usar bcrypt com cost factor ≥ 12
- Rate limiting em endpoints de login
- Verificar autorização em cada endpoint, não apenas no login

## Dados Sensíveis

- Nunca logar senhas, tokens ou dados pessoais
- Variáveis de ambiente para credenciais, nunca hardcoded
- Mascarar dados em respostas de API quando possível
