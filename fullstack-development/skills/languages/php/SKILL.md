---
name: php
description: This skill should be used when writing, reviewing, or refactoring PHP code. Covers PHP 8.3 features (readonly classes, typed constants, json_validate, #[\Override]), PSR-12 standards, modern type system (enums, union types, intersection types, never return type, constructor promotion), design patterns (DTOs, Value Objects, Repository), dependency injection, error handling with typed exceptions, PHPUnit testing, Composer best practices, security (PDO, XSS, CSRF, password hashing), and performance optimization (OPcache, generators, N+1 prevention). Use when the user asks to "write PHP code", "review PHP", "create a PHP class", "implement a repository", "add a PHP enum", "configure OPcache", "write PHPUnit tests", or "upgrade to PHP 8.3".
version: 0.2.1
---

# PHP — Convenções e Boas Práticas (8.3.x)

Diretrizes para escrita de código PHP moderno com base no PHP 8.3.x e padrões PSR.

---

## PSR Standards

| PSR | Escopo | Regras principais |
|---|---|---|
| PSR-1 | Codificação básica | PascalCase em classes; camelCase em métodos; UPPER_SNAKE_CASE em constantes |
| PSR-4 | Autoload | Namespace = estrutura de diretórios; configurar `autoload` no `composer.json` |
| PSR-12 | Estilo de código | 4 espaços; limite suave de 120 chars; visibilidade em tudo; uma classe por arquivo |

```php
<?php
declare(strict_types=1);    // sempre após <?php

namespace App\Domain\User;  // namespace = caminho de diretório

final class UserService     // PascalCase, uma classe por arquivo
{
    public function __construct(private readonly UserRepository $repository) {}
}
```

---

## Sistema de Tipos

Declarar `strict_types=1` em **todo arquivo PHP**. Tipar todos os parâmetros, propriedades e retornos.

```php
function formatId(int|string $id): string { ... }   // union types: mínimo necessário
function findUser(?int $id): ?User { ... }          // nullable shorthand
function throwNotFound(string $e): never { ... }    // never: funções que nunca retornam

enum Status: string { case Active = 'active'; case Inactive = 'inactive'; }
$status = Status::tryFrom($input) ?? Status::Inactive;  // tryFrom: null em vez de lançar
```

Para referência completa de tipos, intersection types, `readonly`, constructor promotion e `final readonly class` para DTOs, consultar **`references/type-system.md`**.

---

## PHP 8.3 — Principais Recursos

| Recurso | Uso recomendado |
|---|---|
| Constantes tipadas | `const string VERSION = '1.0'` em todas as constantes de classe |
| `json_validate()` | Validar JSON antes de armazenar; não duplicar com `json_decode()` |
| `#[\Override]` | Todo método que sobrescreve pai ou implementa interface |
| Clonagem de `readonly` | Padrão wither em objetos imutáveis |
| Acesso dinâmico a constantes | `Status::{$key}` em vez de `constant('Status::' . $key)` |
| Exceções granulares de DateTime | Capturar `DateMalformedStringException` em vez do genérico `\Exception` |
| `Randomizer::getBytesFromString()` | Tokens de verificação com charset controlado |

Exemplos completos de cada recurso em **`references/php83-features.md`**.

---

## Boas Práticas Essenciais

| Padrão | Regra | Exemplo compacto |
|---|---|---|
| Match expressions | Preferir a `switch` — lança `UnhandledMatchError` para casos não cobertos | `$label = match ($status) { Status::Active => 'Ativo', ... };` |
| Named arguments | Clareza em chamadas com múltiplos parâmetros | `createUser(name: 'João', role: Role::Admin)` |
| First-class callables (8.1+) | Closures a partir de funções existentes | `array_map(strlen(...), $strings)` |

Padrões completos (Value Objects, DTOs, Repository Pattern, Command/Handler) em **`references/patterns.md`**.

---

## Tratamento de Erros

Hierarquia: `Throwable` > `Error` | `Exception`. Capturar do mais específico ao mais geral, encadeando a causa com `previous:`. Definir exceções de domínio com factory estático (ex.: `UserNotFoundException::forId($id)` estendendo `\DomainException`). Nunca silenciar erros com `@` nem capturar sem tratar (ver Anti-Patterns).

```php
try {
    $date = new \DateTimeImmutable($input);
} catch (\DateMalformedStringException $e) {
    throw new \InvalidArgumentException("Data inválida: {$input}", previous: $e);
}
```

---

## Segurança — Resumo

```php
// Escape de output HTML
echo htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');

// Hashing de senhas (Argon2id recomendado)
$hash = password_hash($plain, PASSWORD_ARGON2ID);
$ok   = password_verify($plain, $hash);

// Validação de input
$email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
```

Guia completo com PDO, CSRF, uploads, cabeçalhos HTTP e configurações de produção em **`references/security.md`**.

---

## Anti-Patterns a Evitar

| Anti-Pattern | Solução |
|---|---|
| Operator `@` | Try/catch explícito |
| Strings/números mágicos | Enums ou constantes tipadas |
| Catch silencioso | Logar e re-lançar |
| SQL concatenado | Prepared statements |
| `declare(strict_types=1)` ausente | Declarar em todo arquivo |

---

## Recursos de Referência

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/php83-features.md`** | Exemplos completos de todos os recursos do PHP 8.3 |
| **`references/type-system.md`** | Sistema de tipos: enums, readonly, intersection types, DTOs |
| **`references/patterns.md`** | Value Objects, DTOs, Repository, DI, Command/Handler |
| **`references/security.md`** | PDO, XSS, CSRF, uploads, sessões, cabeçalhos HTTP |
| **`references/testing.md`** | PHPUnit 11: atributos, AAA, mocks, data providers |
| **`references/performance.md`** | OPcache, N+1, generators, lazy init |
| **`references/composer.md`** | Versioning, autoload, scripts, audit, produção |

Também consultar:
- `domains/security/SKILL.md` — proteção contra injeções e XSS no contexto do framework
- `domains/api-rest/SKILL.md` — APIs REST em PHP
