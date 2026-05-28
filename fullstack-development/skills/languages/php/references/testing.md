# PHP — Testes com PHPUnit

Boas práticas para testes automatizados em PHP 8.3.x com PHPUnit 11.x.

---

## Estrutura Base de Classe de Teste

```php
<?php
declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\User\UserService;
use App\Domain\User\UserRepository;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\TestCase;

#[CoversClass(UserService::class)]
#[Small]
final class UserServiceTest extends TestCase
{
    private UserRepository $repository;
    private UserService $service;

    protected function setUp(): void
    {
        $this->repository = $this->createMock(UserRepository::class);
        $this->service = new UserService($this->repository);
    }

    #[Test]
    public function it_creates_user_with_valid_data(): void
    {
        // Arrange
        $name = 'João Silva';
        $email = 'joao@example.com';
        $this->repository->expects($this->once())
            ->method('save')
            ->willReturnArgument(0);

        // Act
        $user = $this->service->create($name, $email);

        // Assert
        $this->assertSame($name, $user->name);
        $this->assertSame($email, $user->email);
    }

    #[Test]
    public function it_throws_when_email_already_exists(): void
    {
        // Arrange
        $this->repository->method('existsByEmail')->willReturn(true);

        // Assert
        $this->expectException(\DomainException::class);
        $this->expectExceptionMessage('E-mail já cadastrado');

        // Act
        $this->service->create('João', 'joao@example.com');
    }
}
```

---

## Atributos PHP 8 no PHPUnit

PHPUnit 10+ usa atributos PHP 8 em vez de annotations de docblock.

```php
<?php
declare(strict_types=1);

use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\CoversFunction;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\DataProviderExternal;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Large;
use PHPUnit\Framework\Attributes\Medium;
use PHPUnit\Framework\Attributes\RunInSeparateProcess;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\TestDox;

// Tamanho define timeout:
// #[Small]  = 1s   (unit tests)
// #[Medium] = 10s  (integration tests)
// #[Large]  = 60s  (e2e tests)

#[CoversClass(OrderService::class)]
#[Small]
final class OrderServiceTest extends TestCase
{
    #[Test]
    #[TestDox('Lança exceção ao criar pedido com carrinho vazio')]
    public function it_throws_when_cart_is_empty(): void
    {
        $this->expectException(\DomainException::class);
        new Order(items: []);
    }
}
```

---

## Padrão AAA (Arrange / Act / Assert)

Separar visualmente as três fases com linhas em branco.

```php
#[Test]
public function it_calculates_order_total_with_discount(): void
{
    // Arrange
    $items = [
        new OrderItem(product: 'Produto A', price: 100, quantity: 2),
        new OrderItem(product: 'Produto B', price: 50, quantity: 1),
    ];
    $discount = new PercentageDiscount(10);

    // Act
    $total = $this->calculator->calculate($items, $discount);

    // Assert
    $this->assertSame(225.0, $total); // (200 + 50) * 0.90
}
```

Manter cada fase concisa. Se a fase Arrange for longa, extrair para um método `createXxx()` privado.

---

## Nomenclatura de Métodos

Usar snake_case descritivo que explica o cenário e resultado esperado.

```php
// Bom: descreve comportamento e condição
public function it_returns_null_when_user_not_found(): void
public function it_throws_when_email_is_invalid(): void
public function it_sends_welcome_email_after_registration(): void
public function it_applies_discount_only_to_active_users(): void

// Ruim: vago ou genérico
public function testUser(): void
public function testCreate(): void
public function test_something_works(): void
```

---

## Data Providers

Usar `yield` com chave nomeada para mensagens de falha legíveis.

```php
<?php
declare(strict_types=1);

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;

final class EmailValidatorTest extends TestCase
{
    public static function provideInvalidEmails(): \Generator
    {
        yield 'email sem arroba'    => ['plainaddress'];
        yield 'email sem domínio'   => ['user@'];
        yield 'email sem usuário'   => ['@domain.com'];
        yield 'domínio sem TLD'     => ['user@domain'];
        yield 'espaço no meio'      => ['user @domain.com'];
    }

    #[Test]
    #[DataProvider('provideInvalidEmails')]
    public function it_rejects_invalid_email(string $email): void
    {
        $this->assertFalse(EmailValidator::isValid($email));
    }

    public static function provideValidEmails(): \Generator
    {
        yield 'email simples'       => ['user@example.com'];
        yield 'email com subdomínio' => ['user@mail.example.com'];
        yield 'email com mais'      => ['user+tag@example.com'];
    }

    #[Test]
    #[DataProvider('provideValidEmails')]
    public function it_accepts_valid_email(string $email): void
    {
        $this->assertTrue(EmailValidator::isValid($email));
    }
}
```

---

## Mocks vs Stubs

```php
<?php
declare(strict_types=1);

final class NotificationServiceTest extends TestCase
{
    #[Test]
    public function it_sends_email_on_user_creation(): void
    {
        // Mock: verifica que o método FOI chamado com os parâmetros corretos
        $mailer = $this->createMock(MailerInterface::class);
        $mailer->expects($this->once())
            ->method('send')
            ->with(
                $this->equalTo('welcome@example.com'),
                $this->stringContains('Bem-vindo')
            );

        $service = new NotificationService($mailer);
        $service->notifyWelcome('welcome@example.com', 'João');
    }

    #[Test]
    public function it_returns_empty_list_when_no_users(): void
    {
        // Stub: apenas retorna um valor, sem verificar chamadas
        $repository = $this->createStub(UserRepositoryInterface::class);
        $repository->method('findAll')->willReturn([]);

        $service = new UserService($repository);
        $result = $service->listAll();

        $this->assertEmpty($result);
    }
}
```

**Regra geral:**
- `createMock()` → quando a interação (chamada ao método) é o comportamento testado
- `createStub()` → quando o colaborador apenas fornece dados para o teste

---

## Exceções em Testes

```php
#[Test]
public function it_throws_domain_exception_for_negative_amount(): void
{
    // Declarar antes de executar o código que lança
    $this->expectException(\DomainException::class);
    $this->expectExceptionMessage('Valor não pode ser negativo');
    $this->expectExceptionCode(422);

    new Money(-1, 'BRL');
}
```

---

## Configuração `phpunit.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         requireCoverageMetadata="true"
         failOnWarning="true"
         failOnRisky="true"
         failOnIncomplete="true">

    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>

    <coverage>
        <include>
            <directory>src</directory>
        </include>
        <report>
            <html outputDirectory="coverage"/>
            <clover outputFile="coverage.xml"/>
        </report>
    </coverage>

    <php>
        <ini name="error_reporting" value="-1"/>
    </php>
</phpunit>
```

---

## Organização de Diretórios

```
tests/
├── Unit/                    # Testes sem I/O, sem banco, sem HTTP
│   ├── Domain/
│   │   ├── User/
│   │   │   └── UserServiceTest.php
│   │   └── Order/
│   │       └── OrderTest.php
│   └── Application/
│       └── CreateUserHandlerTest.php
├── Integration/             # Testes com banco real ou serviços externos
│   ├── Repository/
│   │   └── UserRepositoryTest.php
│   └── Http/
│       └── CreateUserControllerTest.php
└── fixtures/                # Dados de teste reutilizáveis
    └── users.php
```

---

## Checklist de Qualidade de Testes

| Item | Verificação |
|---|---|
| Classe `final` | Evita herança acidental |
| `declare(strict_types=1)` | Consistência com produção |
| `#[CoversClass]` | Vincula teste à classe coberta |
| `#[Small/Medium/Large]` | Define timeout adequado |
| Nomenclatura descritiva | `it_throws_when_x()` |
| Padrão AAA | Arrange / Act / Assert separados |
| `createStub()` vs `createMock()` | Usar o correto para cada caso |
| Data providers com `yield` nomeado | Mensagens de falha legíveis |
| `expectException` antes do Act | Ordem correta de assertions |
| Sem lógica nos testes | Sem `if`/`for` em métodos de teste |
