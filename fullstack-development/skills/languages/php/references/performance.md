# PHP — Performance

Técnicas de otimização de performance para aplicações PHP 8.3.x.

---

## OPcache

O OPcache armazena em memória o bytecode compilado dos arquivos PHP, eliminando o overhead de parse e compilação a cada request.

### Configuração para Produção

```ini
; php.ini
[opcache]
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=256          ; MB — ajustar conforme tamanho da aplicação
opcache.interned_strings_buffer=16      ; MB para strings internadas
opcache.max_accelerated_files=65536     ; máximo de arquivos em cache
opcache.revalidate_freq=0               ; 0 = nunca verificar alterações (produção)
opcache.validate_timestamps=0           ; desabilitar em produção (requer reinício para refletir mudanças)
opcache.save_comments=1                 ; necessário para anotações de frameworks
opcache.fast_shutdown=1

; JIT (PHP 8.0+) — beneficia código com processamento intensivo (não I/O-bound)
opcache.jit=tracing
opcache.jit_buffer_size=64M
```

**Desenvolvimento:** Manter `validate_timestamps=1` e `revalidate_freq=2` para refletir alterações automaticamente.

### Monitoramento

```php
<?php
declare(strict_types=1);

$status = opcache_get_status();

// Hit rate deve ser > 99% em produção
$hitRate = $status['opcache_statistics']['opcache_hit_rate'];

// Verificar se o cache está cheio
$usedMemory = $status['memory_usage']['used_memory'];
$freeMemory = $status['memory_usage']['free_memory'];
$usagePercent = $usedMemory / ($usedMemory + $freeMemory) * 100;

// Preload (PHP 7.4+): carregar classes no cache na inicialização do FPM
// opcache.preload=/var/www/app/preload.php
// opcache.preload_user=www-data
```

---

## Prevenção de N+1 Queries

O problema N+1 ocorre quando um loop executa uma query por iteração.

```php
<?php
declare(strict_types=1);

// Problema: 1 query para usuários + N queries para pedidos
$users = $pdo->query('SELECT * FROM users')->fetchAll();
foreach ($users as $user) {
    // 1 query por usuário (N+1!)
    $orders = $pdo->query("SELECT * FROM orders WHERE user_id = {$user['id']}")->fetchAll();
}

// Solução 1: JOIN
$rows = $pdo->query('
    SELECT u.*, o.id as order_id, o.total
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
')->fetchAll();

// Solução 2: IN clause (melhor para coleções grandes)
$userIds = array_column($users, 'id');
$placeholders = implode(',', array_fill(0, count($userIds), '?'));
$stmt = $pdo->prepare("SELECT * FROM orders WHERE user_id IN ({$placeholders})");
$stmt->execute($userIds);
$orders = $stmt->fetchAll();

// Agrupar por user_id em PHP
$ordersByUser = [];
foreach ($orders as $order) {
    $ordersByUser[$order['user_id']][] = $order;
}
```

---

## Lazy Initialization com `??=`

O operador `??=` inicializa uma variável apenas se ela for `null` — evita recalcular valores.

```php
<?php
declare(strict_types=1);

class ReportGenerator
{
    private ?array $cachedData = null;

    public function getData(): array
    {
        // Calcula apenas na primeira chamada
        $this->cachedData ??= $this->fetchExpensiveData();
        return $this->cachedData;
    }

    private function fetchExpensiveData(): array
    {
        // Operação custosa (query, API, etc.)
        return [];
    }
}

// Também útil em arrays
$cache = [];
$cache['key'] ??= computeExpensiveValue('key');
```

---

## Generators para Grandes Conjuntos de Dados

Generators processam dados um elemento por vez, sem carregar tudo na memória.

```php
<?php
declare(strict_types=1);

// Problema: carregar 1 milhão de registros na memória
function getAllUsers(\PDO $pdo): array
{
    return $pdo->query('SELECT * FROM users')->fetchAll(); // pode esgotar memória
}

// Solução: generator — processa um registro por vez
function streamUsers(\PDO $pdo): \Generator
{
    $stmt = $pdo->query('SELECT * FROM users');
    while ($row = $stmt->fetch()) {
        yield $row;
    }
}

// Uso — memória constante independente do volume
foreach (streamUsers($pdo) as $user) {
    processUser($user);
}

// Generator com chave
function indexedItems(\PDO $pdo): \Generator
{
    $stmt = $pdo->query('SELECT id, name FROM products');
    while ($row = $stmt->fetch()) {
        yield $row['id'] => $row['name'];
    }
}
```

---

## Evitar Concatenação em Loop

Concatenação com `.=` em loops cria uma nova string a cada iteração.

```php
<?php
declare(strict_types=1);

$items = ['a', 'b', 'c', 'd', 'e'];

// Problema: O(n²) — cria nova string em cada iteração
$result = '';
foreach ($items as $item) {
    $result .= $item . ', ';
}

// Solução 1: implode (mais idiomático, mais eficiente)
$result = implode(', ', $items);

// Solução 2: array_map + implode para transformações
$result = implode(', ', array_map(strtoupper(...), $items));

// Solução 3: output buffering para HTML
ob_start();
foreach ($items as $item) {
    echo "<li>{$item}</li>\n";
}
$html = ob_get_clean();
```

---

## Caching de Queries

```php
<?php
declare(strict_types=1);

final class CachedUserRepository implements UserRepositoryInterface
{
    private array $cache = [];

    public function __construct(
        private readonly UserRepositoryInterface $inner,
    ) {}

    public function findById(int $id): ?User
    {
        // Cache em memória (válido apenas dentro do request)
        if (!array_key_exists($id, $this->cache)) {
            $this->cache[$id] = $this->inner->findById($id);
        }

        return $this->cache[$id];
    }
}
```

Para cache persistente entre requests, usar Redis (via Predis ou phpredis) ou Memcached.

---

## Preload (PHP 7.4+)

Carregar classes críticas no OPcache na inicialização do PHP-FPM.

```php
<?php
// preload.php — executado uma vez na inicialização
declare(strict_types=1);

$files = new \RecursiveIteratorIterator(
    new \RecursiveDirectoryIterator(__DIR__ . '/src')
);

foreach ($files as $file) {
    if ($file->getExtension() === 'php') {
        opcache_compile_file($file->getPathname());
    }
}
```

```ini
; php.ini
opcache.preload=/var/www/app/preload.php
opcache.preload_user=www-data
```

---

## Profiling

Identificar gargalos antes de otimizar. Nunca otimizar sem medir.

```bash
# Xdebug profiling
XDEBUG_MODE=profile php script.php

# Blackfire (integrado com frameworks)
blackfire run php script.php

# SPX (simples, sem agente externo)
SPX_ENABLED=1 SPX_FP_LIVE=1 php script.php
```

---

## Checklist de Performance

| Área | Verificação |
|---|---|
| OPcache | Habilitado em produção, `validate_timestamps=0` |
| JIT | Ativado para workloads CPU-bound |
| N+1 queries | Usar JOIN ou IN clause em loops |
| Lazy init | `??=` para cálculos custosos |
| Grandes datasets | Generators em vez de `fetchAll()` |
| Loops de string | `implode()` em vez de concatenação |
| Autoloader | `--classmap-authoritative` em produção |
| Preload | Classes críticas no OPcache |
| Profiling | Medir antes de otimizar |
