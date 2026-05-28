# PHP — Segurança

Boas práticas de segurança para aplicações PHP 8.3.x.

---

## Validação de Input

Validar toda entrada no limite do sistema (request HTTP, linha de comando, APIs externas). Nunca confiar em dados do usuário.

### `filter_var()` para tipos e formatos

```php
<?php
declare(strict_types=1);

// Validação de email
$email = filter_var($_POST['email'] ?? '', FILTER_VALIDATE_EMAIL);
if ($email === false) {
    throw new \InvalidArgumentException('E-mail inválido.');
}

// Validação de inteiro com faixa
$age = filter_var($_POST['age'] ?? '', FILTER_VALIDATE_INT, [
    'options' => ['min_range' => 0, 'max_range' => 150],
]);
if ($age === false) {
    throw new \InvalidArgumentException('Idade inválida.');
}

// Sanitização de string (remove tags HTML)
$name = filter_var($_POST['name'] ?? '', FILTER_SANITIZE_SPECIAL_CHARS);

// URL válida
$url = filter_var($_POST['url'] ?? '', FILTER_VALIDATE_URL);
```

### `filter_input()` para dados de superglobais

```php
<?php
declare(strict_types=1);

// Mais seguro que acessar $_GET diretamente
$id = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
$email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
```

---

## Prevenção de SQL Injection

Usar **sempre** prepared statements com PDO. Nunca concatenar valores do usuário em queries SQL.

### Configuração do PDO

```php
<?php
declare(strict_types=1);

$dsn = 'mysql:host=localhost;dbname=myapp;charset=utf8mb4';

$pdo = new \PDO($dsn, $username, $password, [
    \PDO::ATTR_ERRMODE            => \PDO::ERRMODE_EXCEPTION,
    \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
    // Desabilitar emulação de prepared statements (usa prepared statements reais no servidor)
    \PDO::ATTR_EMULATE_PREPARES   => false,
]);
```

### Prepared Statements

```php
<?php
declare(strict_types=1);

// Correto: prepared statement com bind de parâmetros
function findUserByEmail(\PDO $pdo, string $email): ?array
{
    $stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email LIMIT 1');
    $stmt->execute([':email' => $email]);
    $row = $stmt->fetch();
    return $row !== false ? $row : null;
}

// Incorreto: concatenação direta (SQL injection)
// $pdo->query("SELECT * FROM users WHERE email = '{$email}'");
```

---

## Prevenção de XSS

Escapar todo output HTML antes de renderizar no navegador.

```php
<?php
declare(strict_types=1);

/**
 * Escapa uma string para uso seguro em HTML.
 */
function e(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

// Uso em template
echo '<p>' . e($userInput) . '</p>';

// Nunca renderizar input bruto do usuário
// echo '<p>' . $userInput . '</p>'; // XSS vulnerability
```

**Flags importantes:**
- `ENT_QUOTES`: converte `"` e `'`
- `ENT_SUBSTITUTE`: substitui sequências inválidas por U+FFFD em vez de retornar string vazia

---

## Hashing de Senhas

Usar `password_hash()` com `PASSWORD_ARGON2ID` (recomendado em 2024+). Nunca usar MD5, SHA1 ou SHA256 para senhas.

```php
<?php
declare(strict_types=1);

// Hashing (no cadastro ou troca de senha)
function hashPassword(string $plaintext): string
{
    return password_hash($plaintext, PASSWORD_ARGON2ID, [
        'memory_cost' => 65536, // 64 MB
        'time_cost'   => 4,     // 4 iterações
        'threads'     => 3,
    ]);
}

// Verificação (no login)
function verifyPassword(string $plaintext, string $hash): bool
{
    return password_verify($plaintext, $hash);
}

// Rehash se o algoritmo ou custo mudou
function needsRehash(string $hash): bool
{
    return password_needs_rehash($hash, PASSWORD_ARGON2ID);
}
```

---

## Gerenciamento de Sessão

```php
<?php
declare(strict_types=1);

// Configurar antes de session_start()
ini_set('session.cookie_httponly', '1');    // Inacessível via JavaScript
ini_set('session.cookie_secure', '1');      // Apenas HTTPS
ini_set('session.cookie_samesite', 'Strict'); // Previne CSRF
ini_set('session.use_strict_mode', '1');    // Rejeita IDs de sessão não iniciados pelo servidor

session_start();

// Após login bem-sucedido: regenerar ID de sessão para prevenir session fixation
function loginUser(int $userId): void
{
    session_regenerate_id(true); // true = apaga a sessão antiga
    $_SESSION['user_id'] = $userId;
    $_SESSION['logged_in_at'] = time();
}

// Logout: destruir completamente a sessão
function logoutUser(): void
{
    $_SESSION = [];
    session_destroy();
    setcookie(session_name(), '', time() - 3600, '/');
}
```

---

## Cabeçalhos de Segurança HTTP

```php
<?php
declare(strict_types=1);

// Adicionar no bootstrap da aplicação ou middleware
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');
header('Content-Security-Policy: default-src \'self\'; script-src \'self\'');
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
```

---

## Proteção contra CSRF

```php
<?php
declare(strict_types=1);

// Gerar token CSRF
function generateCsrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

// Validar token CSRF
function validateCsrfToken(string $token): bool
{
    return isset($_SESSION['csrf_token'])
        && hash_equals($_SESSION['csrf_token'], $token);
}

// Em formulários HTML
// <input type="hidden" name="csrf_token" value="<?= e(generateCsrfToken()) ?>">

// No processamento do form
if (!validateCsrfToken($_POST['csrf_token'] ?? '')) {
    throw new \RuntimeException('CSRF token inválido.');
}
```

`hash_equals()` faz comparação em tempo constante, prevenindo timing attacks.

---

## Upload de Arquivos

```php
<?php
declare(strict_types=1);

function handleUpload(array $file): string
{
    // Verificar se realmente é um upload (não um arquivo local injetado)
    if (!is_uploaded_file($file['tmp_name'])) {
        throw new \RuntimeException('Upload inválido.');
    }

    // Validar tamanho
    $maxSize = 5 * 1024 * 1024; // 5 MB
    if ($file['size'] > $maxSize) {
        throw new \InvalidArgumentException('Arquivo muito grande.');
    }

    // Validar tipo por conteúdo (não pela extensão enviada pelo cliente)
    $finfo = new \finfo(FILEINFO_MIME_TYPE);
    $mimeType = $finfo->file($file['tmp_name']);
    $allowedMimes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!in_array($mimeType, $allowedMimes, true)) {
        throw new \InvalidArgumentException('Tipo de arquivo não permitido.');
    }

    // Gerar nome seguro (nunca usar o nome enviado pelo usuário)
    $extension = match ($mimeType) {
        'image/jpeg' => 'jpg',
        'image/png'  => 'png',
        'image/gif'  => 'gif',
    };
    $filename = bin2hex(random_bytes(16)) . '.' . $extension;
    $destination = '/var/www/uploads/' . $filename;

    move_uploaded_file($file['tmp_name'], $destination);

    return $filename;
}
```

---

## Configurações PHP para Produção

```ini
; php.ini (produção)
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log
error_reporting = E_ALL

; Expor menos informações
expose_php = Off

; Limitar execução
max_execution_time = 30
memory_limit = 256M

; Sessão segura
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
```

---

## Checklist de Segurança

| Item | Verificação |
|---|---|
| SQL injection | Prepared statements com PDO, `ATTR_EMULATE_PREPARES = false` |
| XSS | `htmlspecialchars()` com `ENT_QUOTES \| ENT_SUBSTITUTE` em todo output |
| CSRF | Token em formulários, `hash_equals()` na validação |
| Senhas | `password_hash()` com `PASSWORD_ARGON2ID` |
| Sessões | `session_regenerate_id(true)` após login |
| Cookies | `HttpOnly`, `Secure`, `SameSite=Strict` |
| Uploads | Validar MIME por conteúdo, gerar nome aleatório |
| Headers | CSP, HSTS, X-Frame-Options |
| Erros | `display_errors=Off` em produção |
| Input | `filter_var()` / `filter_input()` em dados externos |
