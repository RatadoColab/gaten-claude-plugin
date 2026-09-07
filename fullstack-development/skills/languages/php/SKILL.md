---
name: php
description: This skill should be used when writing, reviewing, refactoring, or migrating PHP code across PHP 8.3, 8.4 and 8.5. The SKILL.md body covers only what is common to all three versions; version-specific features and migration checklists live in references/. Determine the target version before generating code: check composer.json (`require.php`, `config.platform.php`), then the environment (`.php-version`, `php -v`, Dockerfile), then syntax already in the codebase (property hooks or `public private(set)` imply >= 8.4; `|>` or `#[\NoDiscard]` imply >= 8.5); if unresolved, ask the user and assume no default. Use when the user asks to "write PHP code", "review PHP", "create a PHP class", "implement a repository", "add a PHP enum", "configure OPcache", "write PHPUnit tests", "migrate to PHP 8.4", "migrate to PHP 8.5", "upgrade PHP 8.4 to 8.5", "what breaks in PHP 8.5", "use property hooks", or "use the pipe operator".
---

# PHP — Convenções e Boas Práticas (8.3+)

Diretrizes para escrita de código PHP moderno (8.3, 8.4 e 8.5) e padrões PSR. O corpo desta skill cobre apenas o que é comum às três versões; recursos e quebras específicos de cada versão estão em `references/`.

---

## Detecção de Versão-Alvo

Antes de gerar ou revisar código, determinar a versão-alvo nesta ordem:

1. **`composer.json`** — chave `require.php` (ex.: `"php": "^8.4"`) e `config.platform.php`.
2. **Ambiente** — `.php-version`, saída de `php -v`, imagem base no `Dockerfile`/`Containerfile`.
3. **Sintaxe já presente no código** — property hooks ou `public private(set)` ⇒ ≥ 8.4; operador `|>` ou `#[\NoDiscard]` ⇒ ≥ 8.5.
4. **Sem indício em nenhuma direção** — perguntar ao usuário ("PHP 8.3, 8.4 ou 8.5?") antes de gerar código. Não assumir default.

Com a versão-alvo confirmada, usar livremente os recursos até aquela versão (ver §Recursos por Versão). Sem confirmação, restringir-se ao subconjunto comum a 8.3–8.5.

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

## Recursos por Versão

Aplicar apenas recursos disponíveis na versão-alvo confirmada (§Detecção de Versão-Alvo). Abaixo dela, usar o subconjunto comum a 8.3–8.5.

| Recurso | Mín. | Uso recomendado |
|---|---|---|
| Constantes de classe tipadas | 8.3 | `const string VERSION = '1.0'` em toda constante de classe |
| `#[\Override]` | 8.3 | Todo método que sobrescreve pai ou implementa interface |
| `json_validate()` | 8.3 | Validar JSON antes de decodificar; não duplicar com `json_decode()` |
| Property hooks | 8.4 | Getter/setter derivado sem método explícito nem propriedade de apoio |
| Visibilidade assimétrica (`private(set)`) | 8.4 | Propriedade pública para leitura, mutável só internamente |
| `array_find` / `array_any` / `array_all` | 8.4 | Substituem `array_filter()` + `reset()` / laços de verificação |
| `#[\Deprecated]` | 8.4 | Marcar função/método/constante obsoleto (substitui `@deprecated` de docblock) |
| `new X()->metodo()` | 8.4 | Encadear sem parênteses ao redor do `new` |
| Operador pipe `\|>` | 8.5 | Encadear transformações unárias em vez de aninhar chamadas |
| `#[\NoDiscard]` | 8.5 | Função cujo retorno não pode ser ignorado; silenciar com `(void)` |
| `clone(...)` com `$withProperties` | 8.5 | Wither de objeto imutável sem `__clone()` manual |
| `array_first()` / `array_last()` | 8.5 | Primeiro/último elemento sem `reset()` / `end()` |

Sintaxe e semântica de cada recurso (com exemplos) em **`references/php83-features.md`**, **`references/php84-features.md`** e **`references/php85-features.md`**. Para subir de versão, ver os guias de migração (§Recursos de Referência).

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
} catch (\DateMalformedStringException $e) { // exceção granular disponível desde 8.3
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
| **`references/php83-features.md`** | Recursos introduzidos no PHP 8.3 (constantes tipadas, `json_validate()`, `#[\Override]`) |
| **`references/php84-features.md`** | Recursos do PHP 8.4 (property hooks, visibilidade assimétrica, lazy objects, `array_find`) |
| **`references/php85-features.md`** | Recursos do PHP 8.5 (operador `\|>`, `#[\NoDiscard]`, `clone` com propriedades) |
| **`references/migration-83-to-84.md`** | Checklist de migração 8.3 → 8.4: quebras, depreciações, JIT, execução |
| **`references/migration-84-to-85.md`** | Checklist de migração 8.4 → 8.5: quebras, depreciações, OPcache, execução |
| **`references/type-system.md`** | Sistema de tipos: enums, readonly, intersection types, DTOs |
| **`references/patterns.md`** | Value Objects, DTOs, Repository, DI, Command/Handler |
| **`references/security.md`** | PDO, XSS, CSRF, uploads, sessões, cabeçalhos HTTP |
| **`references/testing.md`** | PHPUnit 11: atributos, AAA, mocks, data providers |
| **`references/performance.md`** | OPcache, N+1, generators, lazy init |
| **`references/composer.md`** | Versioning, autoload, scripts, audit, produção |

Também consultar:
- `domains/security/SKILL.md` — proteção contra injeções e XSS no contexto do framework
- `domains/api-rest/SKILL.md` — APIs REST em PHP
