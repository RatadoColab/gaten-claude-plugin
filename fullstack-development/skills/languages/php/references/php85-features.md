# PHP 8.5 — Novos Recursos

Referência dos recursos introduzidos no PHP 8.5 com exemplos de uso. Pressupõe `php83-features.md` e `php84-features.md`. Para o que quebra ao subir de 8.4, ver `migration-84-to-85.md`.

---

## Operador Pipe `|>`

Passa o valor da esquerda como único argumento do callable da direita, encadeando transformações da esquerda para a direita em vez de aninhar chamadas.

```php
<?php
declare(strict_types=1);

$slug = $title
    |> trim(...)
    |> strtolower(...)
    |> fn (string $s): string => preg_replace('/[^a-z0-9]+/', '-', $s)
    |> fn (string $s): string => trim($s, '-');

// Equivalente aninhado (lê-se de dentro para fora)
// $slug = trim(preg_replace(..., strtolower(trim($title))), '-');
```

**Restrições:** o lado direito precisa ser um callable **unário** (um argumento). Funções com mais parâmetros exigem um wrapper (`fn ($x) => str_replace('_', '-', $x)`) ou first-class callable com os demais argumentos já ligados. O operador não faz spread nem passa por referência.

---

## `#[\NoDiscard]`

Marca funções/métodos cujo retorno carrega o resultado útil da chamada (ou um aviso que não deve se perder). Ignorar o retorno emite `E_USER_WARNING`.

```php
<?php
declare(strict_types=1);

#[\NoDiscard('o resultado da validação precisa ser verificado')]
function validate(Payload $p): Result { /* ... */ }

validate($payload);        // Warning: return value not used
$r = validate($payload);   // ok
(void) validate($payload); // ok — descarte explícito e intencional
```

O cast `(void)` existe apenas para silenciar esse aviso de forma legível.

---

## `clone` com Reatribuição de Propriedades

`clone($object, array $withProperties = [])` como função aceita um mapa de propriedades a sobrescrever na cópia, dispensando o `__clone()` manual do padrão *wither* documentado em `php83-features.md`.

```php
<?php
declare(strict_types=1);

final readonly class Money
{
    public function __construct(
        public int $amount,
        public string $currency,
    ) {}

    public function withAmount(int $amount): static
    {
        return clone($this, ['amount' => $amount]);
    }
}
```

As propriedades no mapa são atribuídas após a cópia, ignorando `readonly` — é a forma canônica de wither a partir do 8.5. A palavra-chave `clone $object` sem argumentos continua válida.

---

## Closures em Expressões Constantes

Closures e first-class callables passam a ser válidos em defaults de parâmetro/propriedade, argumentos de atributo e constantes.

```php
<?php
declare(strict_types=1);

class Pipeline
{
    // default de propriedade
    public \Closure $normalizer = strtolower(...);

    public function run(
        array $items,
        \Closure $each = trim(...), // default de parâmetro
    ): array {
        return array_map($each, $items);
    }
}

#[Validate(rule: fn (mixed $v): bool => $v !== null)]
class Config {}
```

A closure é criada uma vez e não pode capturar variáveis por `use` (não há escopo de runtime na definição).

---

## Atributos em Constantes e `#[\Override]` em Propriedades

```php
<?php
declare(strict_types=1);

class Api
{
    #[\Deprecated(since: '3.0', message: 'Usar API_BASE.')]
    const string ENDPOINT = 'https://old.example.com';
}

class SqlUserRepository extends UserRepository
{
    #[\Override] // erro em compilação se o pai não declarar $connection
    protected string $connection = 'default';
}
```

`#[\Override]` em propriedade tem a mesma função que em método: falha se não houver membro correspondente para sobrescrever.

---

## Promotion de Propriedades `final` e Assimetria em Estáticas

```php
<?php
declare(strict_types=1);

class Handler
{
    public function __construct(
        final protected LoggerInterface $logger, // promovida e final
    ) {}
}

class Registry
{
    // visibilidade assimétrica agora vale para estáticas
    public private(set) static array $items = [];
}
```

---

## `array_first()` / `array_last()`

Primeiro e último valor de um array sem mover o ponteiro interno nem depender de `array_key_first()`/`array_key_last()`.

```php
<?php
declare(strict_types=1);

array_first([10, 20, 30]); // 10
array_last(['a' => 1, 'b' => 2]); // 2
array_first([]); // null
```

---

## `get_error_handler()` / `get_exception_handler()`

Recuperam o handler atualmente registrado sem o truque de `set_error_handler(fn () => null)` seguido de restauração. Úteis para middlewares e bibliotecas de teste que precisam encadear handlers.

```php
<?php
declare(strict_types=1);

$previous = get_exception_handler();
set_exception_handler(function (\Throwable $e) use ($previous): void {
    report($e);
    if ($previous !== null) {
        $previous($e);
    }
});
```

---

## `FILTER_THROW_ON_FAILURE`

Flag para `filter_var()`/`filter_input()` que lança `FilterException` em vez de retornar `false` na falha de validação, eliminando a checagem `=== false` da §"Validação de Input" do `SKILL.md`.

```php
<?php
declare(strict_types=1);

try {
    $age = filter_var($input, FILTER_VALIDATE_INT, [
        'options' => ['min_range' => 0, 'max_range' => 150],
        'flags'   => FILTER_THROW_ON_FAILURE,
    ]);
} catch (\FilterException $e) {
    throw new \InvalidArgumentException('Idade inválida.', previous: $e);
}
```

---

## Backtrace em Erros Fatais

Erros fatais não capturáveis (ex.: exceder `memory_limit`, `max_execution_time`) passam a incluir stack trace no log, encurtando o diagnóstico em produção. Nenhuma mudança de código necessária; garantir `log_errors = On`.

---

## Cookies `Partitioned` (CHIPS)

`setcookie()`, `setrawcookie()` e a sessão aceitam a opção `partitioned` para isolar o cookie por site incorporador (CHIPS). A orientação de atributos de cookie (`__Host-`, `SameSite`, `Partitioned`) é mantida em `domains/security/references/web-defenses.md` — seguir aquele arquivo; aqui apenas registra-se que a API nativa passou a suportar a flag.

```php
<?php
declare(strict_types=1);

setcookie('sid', $value, [
    'secure'      => true,
    'httponly'    => true,
    'samesite'    => 'None',
    'partitioned' => true,
]);
```

---

## Extensão `URI`

Nova extensão com parsers para RFC 3986 (`Uri\Rfc3986\Uri`) e WHATWG URL (`Uri\WhatWg\Url`), substituindo `parse_url()` para validação e normalização confiáveis. Relevante para validação anti-SSRF — usar em conjunto com a orientação de `domains/security` (validação de host/esquema, bloqueio de IP privado) em vez de parsing manual.

```php
<?php
declare(strict_types=1);

$uri = new Uri\Rfc3986\Uri($userInput);
if ($uri->getScheme() !== 'https') {
    throw new \InvalidArgumentException('Somente HTTPS.');
}
$host = $uri->getHost(); // normalizado
```

---

## Resumo Rápido

| Recurso | Mín. | Benefício principal |
|---|---|---|
| Operador pipe `\|>` | 8.5 | Encadear transformações unárias sem aninhar |
| `#[\NoDiscard]` | 8.5 | Aviso quando o retorno é ignorado; `(void)` para descartar |
| `clone($o, [...])` | 8.5 | Wither sem `__clone()` manual |
| Closures em expressões constantes | 8.5 | Callable em default/atributo/constante |
| Atributos em constantes / `#[\Override]` em propriedades | 8.5 | Metadados e checagem de sobrescrita mais amplos |
| Promotion de `final` / assimetria em estáticas | 8.5 | Menos boilerplate em construtores e registries |
| `array_first()` / `array_last()` | 8.5 | Extremos do array sem `reset()`/`end()` |
| `get_error_handler()` / `get_exception_handler()` | 8.5 | Encadear handlers sem hacks |
| `FILTER_THROW_ON_FAILURE` | 8.5 | Validação que lança em vez de retornar `false` |
| Backtrace em erros fatais | 8.5 | Diagnóstico de OOM/timeout em produção |
| Cookies `Partitioned` | 8.5 | CHIPS na API nativa de cookie/sessão |
| Extensão `URI` | 8.5 | Parsing RFC 3986 / WHATWG confiável |
