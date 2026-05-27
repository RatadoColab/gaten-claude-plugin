---
name: php
description: This skill should be used when writing, reviewing, or refactoring PHP code. Covers PSR-12 standards, modern PHP patterns, project structure, type declarations, and PHP-specific best practices.
version: 0.1.0
---

# PHP — Convenções e Boas Práticas

## Visão Geral

Diretrizes para escrita de código PHP moderno (8.x), seguindo padrões PSR e práticas atuais.

## Convenções (PSR-12)

- Indentação com 4 espaços
- Classes em `PascalCase`, métodos e variáveis em `camelCase`
- Constantes em `UPPER_SNAKE_CASE`
- Uma classe por arquivo
- Namespace correspondendo à estrutura de diretórios

## Declarações de Tipo

- Usar `declare(strict_types=1)` em todos os arquivos
- Tipar todos os parâmetros e retornos de métodos
- Usar tipos de união (`int|string`) e nullable (`?string`) quando necessário
- Return types `void` para métodos sem retorno

## Estrutura de Projeto

```
src/
├── Controller/
├── Service/
├── Repository/
├── Model/
└── Exception/
```

## Práticas Recomendadas

- **Injeção de dependência:** Via construtor; evitar `new` em métodos de negócio
- **Exceções tipadas:** Criar exceções de domínio específicas
- **Match expressions:** Preferir a `switch` para retornos simples
- **Named arguments:** Para clareza em chamadas com múltiplos parâmetros

## Referências

- Ver `domains/security/SKILL.md` para proteção contra injeções e XSS
- Ver `domains/api-rest/SKILL.md` para APIs REST em PHP
