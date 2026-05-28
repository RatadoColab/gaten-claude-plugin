---
name: php
description: This skill should be used when writing, reviewing, or refactoring PHP code. Covers PHP 8.3 features (readonly classes, typed constants, json_validate, #[\Override]), PSR-12 standards, modern type system (enums, union types, intersection types, never return type, constructor promotion), design patterns (DTOs, Value Objects, Repository), dependency injection, error handling with typed exceptions, PHPUnit testing, Composer best practices, security (PDO, XSS, CSRF, password hashing), and performance optimization (OPcache, generators, N+1 prevention). Use when the user asks to "write PHP code", "review PHP", "create a PHP class", "implement a repository", "add a PHP enum", "configure OPcache", "write PHPUnit tests", or "upgrade to PHP 8.3".
version: 0.2.0
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

use App\Domain\Shared\Email;
use App\Infrastructure\Persistence\UserRepository;

final class UserService   // PascalCase, uma classe por arquivo
{
    public function __construct(           // visibilidade obrigatória
        private readonly UserRepository $repository,
    ) {}

    public function findByEmail(Email $email): ?User  // tipos sempre declarados
    {
        return $this->repository->findByEmail($email);
    }
}
```

---

## Sistema de Tipos

Declarar `strict_types=1` em **todo arquivo PHP**. Tipar todos os parâmetros, propriedades e retornos.

```php
<?php
declare(strict_types=1);

// Union types: mínimo de tipos necessários
function formatId(int|string $id): string { ... }

// Nullable shorthand
function findUser(?int $id): ?User { ... }

// never: funções que nunca retornam
function throwNotFound(string $entity): never
{
    throw new \RuntimeException("{$entity} não encontrado.");
}

// Enums com backed type
enum Status: string
{
    case Active   = 'active';
    case Inactive = 'inactive';

    public function label(): string
    {
        return match ($this) {
            Status::Active   => 'Ativo',
            Status::Inactive => 'Inativo',
        };
    }
}

// Conversão segura (tryFrom retorna null em vez de lançar)
$status = Status::tryFrom($input) ?? Status::Inactive;
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

```php
// Constante tipada (PHP 8.3)
class Config
{
    const string VERSION = '2.0.0';
    const int MAX_RETRIES = 3;
}

// json_validate — eficiente, sem alocar memória
if (!json_validate($payload)) {
    throw new \InvalidArgumentException('JSON inválido.');
}

// Override — erro se o método não existir no pai
#[\Override]
public function findById(int $id): ?User { ... }
```

Exemplos completos de cada recurso em **`references/php83-features.md`**.

---

## Boas Práticas Essenciais

### Match Expressions

```php
// match lança UnhandledMatchError para casos não cobertos (mais seguro que switch)
$label = match ($status) {
    Status::Active   => 'Ativo',
    Status::Inactive => 'Inativo',
    Status::Pending  => 'Pendente',
};
```

### Named Arguments

```php
// Clareza em chamadas com múltiplos parâmetros
$date = new \DateTimeImmutable(datetime: '2024-01-15', timezone: new \DateTimeZone('America/Sao_Paulo'));

createUser(name: 'João', email: 'joao@example.com', role: Role::Admin);
```

### First-Class Callables

```php
// PHP 8.1+: closures a partir de funções existentes
$lengths  = array_map(strlen(...), $strings);
$filtered = array_filter($values, is_int(...));
$upper    = array_map(strtoupper(...), $names);
```

Padrões completos (Value Objects, DTOs, Repository Pattern, Command/Handler) em **`references/patterns.md`**.

---

## Tratamento de Erros

```php
<?php
declare(strict_types=1);

// Hierarquia: Throwable > Error | Exception
// Capturar do mais específico ao mais geral
try {
    $date = new \DateTimeImmutable($input);
} catch (\DateMalformedStringException $e) {
    throw new \InvalidArgumentException("Data inválida: {$input}", previous: $e);
} catch (\DateException $e) {
    throw new \RuntimeException('Erro de data inesperado.', previous: $e);
}

// Exceções de domínio específicas
namespace App\Domain\User\Exception;

final class UserNotFoundException extends \DomainException
{
    public static function forId(int $id): self
    {
        return new self("Usuário #{$id} não encontrado.", 404);
    }
}

// Nunca silenciar erros com @
// $result = @file_get_contents($url); // NÃO FAZER

// Nunca capturar silenciosamente
// catch (\Exception $e) {} // NÃO FAZER — logar e re-lançar
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
