# PHP 8.4 — Novos Recursos

Referência dos recursos introduzidos no PHP 8.4 com exemplos de uso. Pressupõe o conteúdo de `php83-features.md`. Para o que quebra ao subir de 8.3, ver `migration-83-to-84.md`.

---

## Property Hooks

Adicionam lógica de `get`/`set` diretamente na declaração da propriedade, sem método explícito nem propriedade de apoio.

```php
<?php
declare(strict_types=1);

final class User
{
    // Hook de leitura: valor derivado, sem armazenamento
    public string $fullName {
        get => $this->firstName . ' ' . $this->lastName;
    }

    // Hook de escrita: normaliza antes de gravar no backing store implícito
    public string $email {
        set => strtolower(trim($value));
    }

    public function __construct(
        private string $firstName,
        private string $lastName,
    ) {}
}
```

**Regras práticas:**
- Dentro do `set` abreviado (`set => expr`), a expressão é gravada no backing store implícito; na forma de bloco (`set { ... }`), atribuir a `$this->prop` grava no backing store sem recursão. Referenciar `$this->prop` dentro do `get` **causa** recursão — derivar de outras propriedades.
- Uma interface pode exigir uma propriedade com hook: `interface HasName { public string $name { get; } }`.
- `readonly` aceita hook de `get`, mas **não** de `set`. Propriedades promovidas no construtor podem declarar hooks com a sintaxe de bloco após o parâmetro.
- Hook só de `get` sem `set` torna a propriedade efetivamente somente-leitura de fora.

---

## Visibilidade Assimétrica

Define visibilidades diferentes para leitura e escrita da mesma propriedade.

```php
<?php
declare(strict_types=1);

final class Order
{
    // Lê-se de qualquer lugar; escreve-se apenas dentro da classe
    public private(set) OrderStatus $status = OrderStatus::Draft;

    // Lê-se de fora; escreve-se na classe ou em subclasses
    public protected(set) int $version = 1;

    public function markPaid(): void
    {
        $this->status = OrderStatus::Paid; // permitido: contexto interno
    }
}
```

Substitui o par "propriedade privada + getter público" nos DTOs e entidades de `patterns.md`. A visibilidade de escrita deve ser igual ou mais restrita que a de leitura.

---

## Encadeamento de `new` sem Parênteses

```php
<?php
declare(strict_types=1);

// 8.4: acesso direto a método, propriedade, constante ou índice
$name = new ReflectionClass($obj)->getShortName();
$total = new Cart($items)->total;

// Antes: parênteses obrigatórios ao redor do new
// $name = (new ReflectionClass($obj))->getShortName();
```

---

## Atributo `#[\Deprecated]`

Marca funções, métodos e constantes de classe como obsoletos, emitindo `E_USER_DEPRECATED` no uso. Substitui a anotação `@deprecated` de docblock, que não tinha efeito em runtime.

```php
<?php
declare(strict_types=1);

class PaymentGateway
{
    #[\Deprecated(message: 'Usar charge() com Money.', since: '2.3.0')]
    public function chargeAmount(int $cents): void { /* ... */ }

    public function charge(Money $amount): void { /* ... */ }
}
```

`ReflectionClassConstant::isDeprecated()` e `ReflectionClassConstant`/`ReflectionMethod` expõem o estado para ferramentas.

---

## `array_find`, `array_find_key`, `array_any`, `array_all`

Encerram o padrão `array_filter()` + `reset()` / `array_key_first()` e os laços manuais de verificação.

```php
<?php
declare(strict_types=1);

$users = [/* ... */];

// Primeiro elemento que casa (ou null)
$admin = array_find($users, fn (User $u): bool => $u->role === Role::Admin);

// Chave do primeiro elemento que casa (ou null)
$key = array_find_key($users, fn (User $u): bool => $u->id === $target);

// Ao menos um casa
$hasAdmin = array_any($users, fn (User $u): bool => $u->role === Role::Admin);

// Todos casam
$allActive = array_all($users, fn (User $u): bool => $u->isActive());
```

O callback recebe `($value, $key)`; a busca para no primeiro casamento (`array_find`/`array_any`) ou na primeira falha (`array_all`).

---

## Objetos Lazy (Reflection)

`ReflectionClass::newLazyGhost()` e `newLazyProxy()` criam instâncias cuja inicialização é adiada até o primeiro acesso a uma propriedade. Uso típico: containers de DI e ORMs que evitam construir dependências caras que podem nunca ser usadas.

```php
<?php
declare(strict_types=1);

$reflector = new ReflectionClass(ReportService::class);

$service = $reflector->newLazyGhost(function (ReportService $proxy): void {
    // Executado só no primeiro uso real de $service
    $proxy->__construct(new SlowMetricsClient());
});
```

`ghost` inicializa a própria instância no lugar; `proxy` delega a um objeto real construído sob demanda. Complementa a §"Lazy Initialization com `??=`" de `performance.md` no nível do objeto inteiro.

---

## Novas Funções de String e Número

```php
<?php
declare(strict_types=1);

// Multibyte trim/case — sem depender de regex ou ctype
mb_trim("  áção  ");        // "áção"
mb_ltrim("···título", "·"); // "título"
mb_ucfirst("ática");        // "Ática"
mb_lcfirst("Ática");        // "ática"

// Exponenciação IEEE 754 (0 ** -2 deixou de ser válido — ver migração)
fpow(0.0, -2.0); // INF

// BCMath ganhou arredondamento e divisão com resto
bcround('3.14159', 2); // "3.14"
bcceil('3.1');         // "4"
bcfloor('3.9');        // "3"
[$q, $r] = bcdivmod('17', '5'); // ["3", "2"]
```

---

## Enum `RoundingMode`

Substitui as constantes `PHP_ROUND_HALF_*` com nomes mais claros e habilita quatro modos novos (`TowardsZero`, `AwayFromZero`, `NegativeInfinity`, `PositiveInfinity`).

```php
<?php
declare(strict_types=1);

round(2.5, mode: RoundingMode::HalfEven);      // 2.0
round(-1.5, mode: RoundingMode::TowardsZero);  // -1.0
```

`round()` passa a lançar `ValueError` para modo inválido (ver migração).

---

## `DateTime`/`DateTimeImmutable` — Timestamp e Microssegundos

```php
<?php
declare(strict_types=1);

$dt = DateTimeImmutable::createFromTimestamp(1_700_000_000);      // int
$dt = DateTimeImmutable::createFromTimestamp(1_700_000_000.5001); // float com fração
$us = $dt->getMicrosecond();          // int
$dt = $dt->setMicrosecond(123_456);   // clona com o valor ajustado
```

---

## PDO — Subclasses por Driver

`PDO::connect()` retorna uma subclasse específica do driver (`Pdo\Mysql`, `Pdo\Pgsql`, `Pdo\Sqlite`, `Pdo\Odbc`, `Pdo\Dblib`, `Pdo\Firebird`), com métodos antes espalhados como constantes/atributos genéricos.

```php
<?php
declare(strict_types=1);

$pdo = PDO::connect('sqlite:app.db');
// $pdo instanceof Pdo\Sqlite === true
$pdo->createFunction('slugify', slugify(...));

$pg = PDO::connect($pgDsn, $user, $pass);
$pg->setNoticeCallback(static fn (string $msg) => error_log($msg));
```

O construtor `new PDO(...)` continua funcionando e devolvendo a base `PDO`. Manter a configuração de segurança da §"Prevenção de SQL Injection" de `security.md` (`ATTR_ERRMODE`, `ATTR_EMULATE_PREPARES => false`). No PHP 8.5, as constantes/métodos específicos de driver na classe base `PDO` passam a emitir depreciação — ver `migration-84-to-85.md`.

---

## `request_parse_body()`

Faz o parsing de corpo `multipart/form-data` em requisições que não são `POST` (ex.: `PUT`, `PATCH`), preenchendo arrays equivalentes a `$_POST`/`$_FILES` sob demanda.

```php
<?php
declare(strict_types=1);

[$fields, $files] = request_parse_body();
```

---

## OpenSSL — `PASSWORD_ARGON2`

Com OpenSSL 3.2 (build NTS), `password_hash()` aceita `PASSWORD_ARGON2` mesmo sem a extensão Sodium. A recomendação da §"Hashing de Senhas" de `security.md` (`PASSWORD_ARGON2ID` com perfil de custo explícito) permanece; este recurso apenas amplia a disponibilidade do algoritmo.

---

## Resumo Rápido

| Recurso | Mín. | Benefício principal |
|---|---|---|
| Property hooks | 8.4 | Getter/setter sem método nem propriedade de apoio |
| Visibilidade assimétrica | 8.4 | Leitura pública + escrita restrita numa só propriedade |
| `new X()->m()` | 8.4 | Encadeamento sem parênteses no `new` |
| `#[\Deprecated]` | 8.4 | Obsolescência com efeito em runtime |
| `array_find/any/all` | 8.4 | Fim do `array_filter()` + `reset()` |
| Objetos lazy (Reflection) | 8.4 | Adiar construção de dependências caras |
| `mb_trim`/`mb_ucfirst`/... | 8.4 | Trim e case multibyte na stdlib |
| `RoundingMode` enum | 8.4 | Modos de arredondamento nomeados |
| `DateTime::createFromTimestamp()` | 8.4 | Construção a partir de epoch com fração |
| PDO subclasses por driver | 8.4 | API específica do driver sem constantes genéricas |
| `request_parse_body()` | 8.4 | Corpo multipart em `PUT`/`PATCH` |
