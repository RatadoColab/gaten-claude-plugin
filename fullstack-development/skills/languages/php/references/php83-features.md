# PHP 8.3 — Novos Recursos

Referência dos recursos introduzidos no PHP 8.3.x com exemplos de uso.

---

## Constantes de Classe Tipadas

Adicionar tipo a constantes de classe previne atribuições incompatíveis em subclasses.

```php
<?php
declare(strict_types=1);

class Config
{
    const string VERSION = '1.0.0';
    const int MAX_RETRIES = 3;
    const float TIMEOUT = 30.0;
}

interface HasStatus
{
    // Subclasses são obrigadas a manter o tipo string
    const string STATUS = 'active';
}
```

Antes do PHP 8.3, constantes não tinham tipo declarado e poderiam ser sobrescritas com qualquer valor em subclasses sem erro.

---

## `json_validate()`

Valida se uma string é JSON válido **sem decodificá-la**. Mais eficiente que `json_decode()` quando o objetivo é apenas verificar a estrutura.

```php
<?php
declare(strict_types=1);

// Correto: validar primeiro, decodificar apenas se necessário
function processPayload(string $raw): array
{
    if (!json_validate($raw)) {
        throw new \InvalidArgumentException('Payload inválido: JSON malformado.');
    }

    return json_decode($raw, true, flags: JSON_THROW_ON_ERROR);
}

// Incorreto: usar json_decode() só para verificar (desperdiça memória)
// $data = json_decode($raw);
// if (json_last_error() !== JSON_ERROR_NONE) { ... }
```

**Parâmetros adicionais:** `json_validate($string, depth: 512, flags: 0)`

---

## Readonly Classes e Clonagem

PHP 8.2 introduziu `readonly class`; PHP 8.3 adiciona suporte a `__clone()` para permitir clonagem com valores modificados (padrão *wither*).

```php
<?php
declare(strict_types=1);

final readonly class Money
{
    public function __construct(
        public readonly int $amount,
        public readonly string $currency,
    ) {}

    // PHP 8.3: permite clonar e alterar propriedades readonly
    public function withAmount(int $amount): static
    {
        $clone = clone $this;
        // Permitido apenas dentro de __clone ou ao inicializar o clone
        return new static($amount, $this->currency);
    }
}

$price = new Money(100, 'BRL');
$discounted = $price->withAmount(80);
```

---

## Atributo `#[\Override]`

Documenta explicitamente que um método sobrescreve um método do pai ou implementa uma interface. O PHP lança erro se o método correspondente não existir na classe pai.

```php
<?php
declare(strict_types=1);

abstract class BaseRepository
{
    abstract public function findById(int $id): ?object;
}

class UserRepository extends BaseRepository
{
    #[\Override]
    public function findById(int $id): ?User
    {
        // Se findById() for renomeado no pai, este arquivo passa a dar erro
        return $this->db->find(User::class, $id);
    }
}
```

Usar `#[\Override]` em **todos** os métodos que sobrescrevem ou implementam contratos de interface.

---

## Acesso Dinâmico a Constantes de Classe

Alternativa limpa à função `constant()` para acessar constantes via variável.

```php
<?php
declare(strict_types=1);

class Status
{
    const string ACTIVE = 'active';
    const string INACTIVE = 'inactive';
}

// PHP 8.3: sintaxe direta
$key = 'ACTIVE';
$value = Status::{$key}; // 'active'

// Equivalente anterior (menos legível)
$value = constant('Status::' . $key);
```

---

## Exceções Granulares de DateTime

PHP 8.3 adicionou subclasses específicas para erros de data/hora, substituindo o genérico `\Exception`.

```php
<?php
declare(strict_types=1);

use \DateMalformedStringException;
use \DateRangeError;

function parseDate(string $input): \DateTimeImmutable
{
    try {
        return new \DateTimeImmutable($input);
    } catch (DateMalformedStringException $e) {
        throw new \InvalidArgumentException(
            "Formato de data inválido: {$input}",
            previous: $e
        );
    }
}
```

**Hierarquia de exceções de DateTime no PHP 8.3:**
- `\DateError extends \Error`
  - `\DateRangeError`
  - `\DateObjectError`
- `\DateException extends \Exception`
  - `\DateMalformedStringException`
  - `\DateMalformedIntervalStringException`
  - `\DateMalformedPeriodStringException`
  - `\DateInvalidTimeZoneException`
  - `\DateInvalidOperationException`

---

## `Randomizer::getBytesFromString()`

Gera bytes aleatórios usando apenas caracteres de um charset específico. Ideal para tokens de verificação legíveis por humanos.

```php
<?php
declare(strict_types=1);

$randomizer = new \Random\Randomizer();

// Token alfanumérico de 32 caracteres (URL-safe)
$charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
$token = $randomizer->getBytesFromString($charset, 32);

// PIN numérico de 6 dígitos
$pin = $randomizer->getBytesFromString('0123456789', 6);
```

Para tokens de segurança criptográfica, usar `\Random\Engine\Secure` (padrão do `Randomizer` sem argumento).

---

## `array_is_list()`

Verifica se um array é uma lista (chaves inteiras sequenciais a partir de 0). Disponível desde PHP 8.1, mas frequentemente usado com recursos do 8.3.

```php
<?php
declare(strict_types=1);

$list = [1, 2, 3];             // true
$map  = ['a' => 1, 'b' => 2]; // false
$gap  = [0 => 'a', 2 => 'b']; // false (gap)

array_is_list($list); // true
array_is_list($map);  // false
```

---

## Resumo Rápido

| Recurso | Versão | Benefício principal |
|---|---|---|
| Constantes tipadas | 8.3 | Previne sobrescrita com tipo errado |
| `json_validate()` | 8.3 | Validação eficiente sem alocação de memória |
| Clonagem de readonly | 8.3 | Padrão wither em objetos imutáveis |
| `#[\Override]` | 8.3 | Detecta métodos renomeados no pai |
| Acesso dinâmico a constantes | 8.3 | Alternativa limpa a `constant()` |
| Exceções DateTime granulares | 8.3 | Tratamento preciso de erros de data |
| `getBytesFromString()` | 8.3 | Tokens com charset controlado |
