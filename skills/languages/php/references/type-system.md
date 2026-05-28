# PHP — Sistema de Tipos Moderno

Guia completo do sistema de tipos do PHP 8.x com exemplos práticos.

---

## `declare(strict_types=1)`

Declarar `strict_types=1` no topo de **todo arquivo PHP** faz o engine rejeitar coerções implícitas de tipo em chamadas de função.

```php
<?php
declare(strict_types=1); // Sempre na primeira linha após <?php

// Com strict_types: erro de tipo em tempo de execução
function add(int $a, int $b): int
{
    return $a + $b;
}

add(1, '2'); // TypeError: Argument #2 must be of type int, string given
```

Sem `strict_types`, PHP converteria `'2'` para `2` silenciosamente, ocultando bugs.

---

## Union Types

Aceitar múltiplos tipos quando necessário. Minimizar o número de tipos na união.

```php
<?php
declare(strict_types=1);

// Correto: mínimo de tipos necessários
function formatId(int|string $id): string
{
    return (string) $id;
}

// Nullable shorthand: ?string equivale a string|null
function findUser(?int $id): ?User
{
    if ($id === null) {
        return null;
    }
    return $this->repository->find($id);
}
```

---

## Intersection Types

Exigir que um valor implemente múltiplas interfaces. Usar apenas com interfaces/classes, não com tipos primitivos.

```php
<?php
declare(strict_types=1);

interface Countable
{
    public function count(): int;
}

interface Stringable
{
    public function __toString(): string;
}

// O valor deve implementar ambas as interfaces
function process(Countable&Stringable $collection): void
{
    echo "Count: {$collection->count()}, String: {$collection}";
}
```

---

## Return Type `never`

Declarar `never` em funções que **nunca retornam**: sempre lançam exceção ou chamam `exit()`/`die()`.

```php
<?php
declare(strict_types=1);

function throwNotFound(string $entity, int $id): never
{
    throw new \RuntimeException("{$entity} #{$id} não encontrado.");
}

function abort(int $statusCode): never
{
    http_response_code($statusCode);
    exit();
}

// Uso: o analisador estático sabe que o código após a chamada é inalcançável
function findOrFail(int $id): User
{
    $user = $this->repository->find($id);
    if ($user === null) {
        throwNotFound('User', $id); // never — PHP sabe que não há retorno aqui
    }
    return $user;
}
```

---

## Enums

Enums substituem constantes de classe e strings mágicas com tipos seguros.

### Enum Puro (Unit Enum)

```php
<?php
declare(strict_types=1);

enum Direction
{
    case North;
    case South;
    case East;
    case West;
}

function move(Direction $direction): void
{
    match ($direction) {
        Direction::North => $this->moveNorth(),
        Direction::South => $this->moveSouth(),
        Direction::East  => $this->moveEast(),
        Direction::West  => $this->moveWest(),
    };
}
```

### Backed Enum (com valor escalar)

```php
<?php
declare(strict_types=1);

enum Status: string
{
    case Active   = 'active';
    case Inactive = 'inactive';
    case Pending  = 'pending';

    // Métodos são permitidos em enums
    public function label(): string
    {
        return match ($this) {
            Status::Active   => 'Ativo',
            Status::Inactive => 'Inativo',
            Status::Pending  => 'Pendente',
        };
    }
}

// Conversão segura: tryFrom() retorna null em vez de lançar exceção
$status = Status::tryFrom($input) ?? Status::Pending;

// from() lança ValueError se o valor não existir
$status = Status::from('active'); // Status::Active
```

### Enum em Constante Tipada (PHP 8.3)

```php
<?php
declare(strict_types=1);

class Order
{
    const Status DEFAULT_STATUS = Status::Pending;
}
```

---

## Constructor Property Promotion

Reduz boilerplate em classes com propriedades injetadas via construtor.

```php
<?php
declare(strict_types=1);

// Sem promotion — verboso
class UserService
{
    private UserRepository $repository;
    private LoggerInterface $logger;

    public function __construct(UserRepository $repository, LoggerInterface $logger)
    {
        $this->repository = $repository;
        $this->logger = $logger;
    }
}

// Com promotion — conciso e equivalente
class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly LoggerInterface $logger,
    ) {}
}
```

---

## `final readonly class` para DTOs

DTOs (Data Transfer Objects) devem ser imutáveis e sem lógica de negócio.

```php
<?php
declare(strict_types=1);

final readonly class CreateUserRequest
{
    public function __construct(
        public string $name,
        public string $email,
        public string $password,
        public \DateTimeImmutable $birthDate,
    ) {}
}

// Uso
$request = new CreateUserRequest(
    name: 'João Silva',
    email: 'joao@example.com',
    password: 'secret123',
    birthDate: new \DateTimeImmutable('1990-01-15'),
);
```

`final` previne herança; `readonly` garante imutabilidade; constructor promotion elimina boilerplate.

---

## Fibers (PHP 8.1+)

Para código assíncrono cooperativo sem bibliotecas externas.

```php
<?php
declare(strict_types=1);

$fiber = new \Fiber(function (): void {
    $value = \Fiber::suspend('first');
    echo "Received: {$value}\n";
});

$first = $fiber->start();       // 'first'
$fiber->resume('hello');        // Received: hello
```

Fibers são a base de frameworks assíncronos como Revolt/ReactPHP. Em código síncrono comum, não há necessidade de usá-los diretamente.

---

## Tabela de Referência Rápida

| Recurso | Desde | Exemplo |
|---|---|---|
| `strict_types` | 7.0 | `declare(strict_types=1)` |
| Union types | 8.0 | `int\|string` |
| Named arguments | 8.0 | `func(name: 'João')` |
| Match expression | 8.0 | `match($x) { 1 => 'um' }` |
| Nullsafe operator | 8.0 | `$obj?->method()` |
| Enums | 8.1 | `enum Status: string` |
| Intersection types | 8.1 | `A&B` |
| `never` return type | 8.1 | `function fail(): never` |
| `readonly` properties | 8.1 | `public readonly int $id` |
| `readonly` classes | 8.2 | `readonly class DTO` |
| Constantes tipadas | 8.3 | `const string NAME = 'x'` |
| `#[\Override]` | 8.3 | `#[\Override] public function foo()` |
