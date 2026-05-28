# PHP — Padrões de Design Modernos

Padrões recomendados para código PHP 8.3.x limpo e manutenível.

---

## Value Objects

Representam um conceito do domínio por seu valor, não por identidade. São imutáveis e auto-validados.

```php
<?php
declare(strict_types=1);

final class Email
{
    private string $value;

    public function __construct(string $value)
    {
        $normalized = strtolower(trim($value));
        if (!filter_var($normalized, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("E-mail inválido: {$value}");
        }
        $this->value = $normalized;
    }

    public function value(): string
    {
        return $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}

// Uso
$email = new Email('JOAO@EXAMPLE.COM');
echo $email->value(); // joao@example.com

$other = new Email('joao@example.com');
$email->equals($other); // true
```

**Características obrigatórias:**
- `final`: impede subclasses que quebrem a invariante
- Validação no construtor: objeto inválido nunca é criado
- Imutabilidade: sem setters, sem mutação de estado
- Método `equals()`: comparação por valor

---

## DTOs (Data Transfer Objects)

Carregam dados entre camadas sem lógica de negócio.

```php
<?php
declare(strict_types=1);

// DTO de entrada (request)
final readonly class CreateOrderRequest
{
    public function __construct(
        public int    $customerId,
        public array  $items,     // array<int, OrderItemRequest>
        public string $notes = '',
    ) {}
}

// DTO de item
final readonly class OrderItemRequest
{
    public function __construct(
        public int $productId,
        public int $quantity,
    ) {}
}

// DTO de saída (response)
final readonly class OrderResponse
{
    public function __construct(
        public int    $id,
        public string $status,
        public float  $total,
        public \DateTimeImmutable $createdAt,
    ) {}
}
```

**Regras para DTOs:**
- `final readonly class`: imutável por construção
- Apenas primitivos ou outros DTOs como propriedades
- Sem métodos de lógica de negócio
- Sem getters/setters: acessar propriedades públicas diretamente

---

## Repository Pattern

Abstrai o mecanismo de persistência do domínio.

### Interface (domínio)

```php
<?php
declare(strict_types=1);

namespace App\Domain\User;

interface UserRepositoryInterface
{
    public function findById(int $id): ?User;
    public function findByEmail(Email $email): ?User;

    /** @return User[] */
    public function findAll(): array;

    public function save(User $user): User;
    public function delete(int $id): void;
    public function existsByEmail(Email $email): bool;
}
```

### Implementação (infraestrutura)

```php
<?php
declare(strict_types=1);

namespace App\Infrastructure\Persistence;

use App\Domain\User\{User, UserRepositoryInterface, Email};

final class PdoUserRepository implements UserRepositoryInterface
{
    public function __construct(
        private readonly \PDO $pdo,
    ) {}

    public function findById(int $id): ?User
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM users WHERE id = :id AND deleted_at IS NULL'
        );
        $stmt->execute([':id' => $id]);
        $row = $stmt->fetch();

        return $row !== false ? User::fromArray($row) : null;
    }

    public function existsByEmail(Email $email): bool
    {
        $stmt = $this->pdo->prepare(
            'SELECT COUNT(*) FROM users WHERE email = :email'
        );
        $stmt->execute([':email' => $email->value()]);
        return (int) $stmt->fetchColumn() > 0;
    }

    // ... demais métodos
}
```

**Benefícios:**
- Domínio independente de banco de dados
- Fácil troca de ORM ou banco sem alterar regras de negócio
- Testável com mocks da interface

---

## Dependency Injection

Injetar dependências pelo construtor. Nunca instanciar colaboradores dentro de métodos de negócio.

```php
<?php
declare(strict_types=1);

// Correto: DI pelo construtor
final class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $repository,
        private readonly HasherInterface $hasher,
        private readonly EventDispatcherInterface $dispatcher,
    ) {}

    public function create(CreateUserRequest $request): User
    {
        if ($this->repository->existsByEmail(new Email($request->email))) {
            throw new \DomainException('E-mail já cadastrado.');
        }

        $user = new User(
            name: $request->name,
            email: new Email($request->email),
            passwordHash: $this->hasher->hash($request->password),
        );

        $saved = $this->repository->save($user);
        $this->dispatcher->dispatch(new UserCreated($saved->id));

        return $saved;
    }
}

// Incorreto: new dentro do método de negócio
// public function create(array $data): User
// {
//     $hasher = new BcryptHasher(); // acoplamento rígido
//     ...
// }
```

---

## First-Class Callables

PHP 8.1+ permite criar closures a partir de funções/métodos existentes sem wrappers.

```php
<?php
declare(strict_types=1);

// Antes (verboso)
$lengths = array_map(fn(string $s) => strlen($s), $strings);

// Com first-class callable
$lengths = array_map(strlen(...), $strings);

// Com métodos de instância
$emailObjects = array_map($this->parseEmail(...), $emailStrings);

// Com funções nativas
$filtered = array_filter($values, is_int(...));
usort($names, strcmp(...));
```

---

## Command / Handler Pattern

Separa a intenção (Command) da execução (Handler). Útil em aplicações com múltiplos use cases.

```php
<?php
declare(strict_types=1);

// Command (DTO de intenção)
final readonly class TransferMoneyCommand
{
    public function __construct(
        public int   $fromAccountId,
        public int   $toAccountId,
        public float $amount,
    ) {}
}

// Handler (executa o caso de uso)
final class TransferMoneyHandler
{
    public function __construct(
        private readonly AccountRepositoryInterface $accounts,
        private readonly EventDispatcherInterface $dispatcher,
    ) {}

    public function handle(TransferMoneyCommand $command): void
    {
        $from = $this->accounts->findById($command->fromAccountId)
            ?? throw new \DomainException('Conta de origem não encontrada.');

        $to = $this->accounts->findById($command->toAccountId)
            ?? throw new \DomainException('Conta de destino não encontrada.');

        $from->debit($command->amount);
        $to->credit($command->amount);

        $this->accounts->save($from);
        $this->accounts->save($to);

        $this->dispatcher->dispatch(new MoneyTransferred(
            $command->fromAccountId,
            $command->toAccountId,
            $command->amount,
        ));
    }
}
```

---

## Specification Pattern

Encapsula regras de negócio complexas em objetos reutilizáveis e combináveis.

```php
<?php
declare(strict_types=1);

interface SpecificationInterface
{
    public function isSatisfiedBy(mixed $candidate): bool;
}

final class ActiveUserSpecification implements SpecificationInterface
{
    public function isSatisfiedBy(mixed $user): bool
    {
        return $user instanceof User && $user->status === UserStatus::Active;
    }
}

final class AdminUserSpecification implements SpecificationInterface
{
    public function isSatisfiedBy(mixed $user): bool
    {
        return $user instanceof User && $user->role === UserRole::Admin;
    }
}

final class AndSpecification implements SpecificationInterface
{
    public function __construct(
        private readonly SpecificationInterface $left,
        private readonly SpecificationInterface $right,
    ) {}

    public function isSatisfiedBy(mixed $candidate): bool
    {
        return $this->left->isSatisfiedBy($candidate)
            && $this->right->isSatisfiedBy($candidate);
    }
}

// Uso
$canAccessAdmin = new AndSpecification(
    new ActiveUserSpecification(),
    new AdminUserSpecification(),
);

if (!$canAccessAdmin->isSatisfiedBy($currentUser)) {
    throw new \RuntimeException('Acesso negado.');
}
```

---

## Anti-Patterns a Evitar

| Anti-Pattern | Problema | Solução |
|---|---|---|
| God Object | Classe com responsabilidades demais | Dividir em classes menores (SRP) |
| `new` em métodos de negócio | Acoplamento rígido, difícil de testar | Injetar via construtor |
| Herança para reaproveitamento | Acoplamento forte, fragilidade | Composição e interfaces |
| Variáveis globais | Estado imprevisível | Injeção de dependência |
| Strings mágicas | Sem type safety, sem autocomplete | Enums ou constantes tipadas |
| Números mágicos | Sem semântica | Constantes nomeadas |
| Catch silencioso | Engole erros, dificulta debug | Logar e re-lançar |
| Operator `@` para silenciar erros | Oculta problemas reais | Try/catch explícito |
| Getters/setters gerados automaticamente | Quebra encapsulamento | Expor comportamento, não estado |
