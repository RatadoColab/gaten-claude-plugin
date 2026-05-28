# PHP — Composer

Boas práticas para gerenciamento de dependências com Composer.

---

## Estrutura Mínima do `composer.json`

```json
{
    "name": "vendor/project-name",
    "description": "Descrição do projeto",
    "type": "project",
    "license": "proprietary",
    "require": {
        "php": "^8.3",
        "ext-mbstring": "*",
        "ext-pdo": "*"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^1.10",
        "squizlabs/php_codesniffer": "^3.8"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Tests\\": "tests/"
        }
    },
    "config": {
        "sort-packages": true,
        "platform": {
            "php": "8.3.0"
        }
    }
}
```

---

## Operadores de Versão

| Operador | Exemplo | Permite |
|---|---|---|
| `^` (caret) | `^1.2.3` | `>=1.2.3 <2.0.0` |
| `~` (tilde) | `~1.2.3` | `>=1.2.3 <1.3.0` |
| `>=` | `>=1.2.3` | Qualquer versão acima |
| `*` (wildcard) | `1.2.*` | `>=1.2.0 <1.3.0` |
| Exata | `1.2.3` | Apenas essa versão |

**Regra geral:**
- Usar `^` para a maioria dos pacotes: aceita minor e patch, bloqueia major
- Usar `~` para pacotes com histórico de breaking changes em versões minor
- Evitar `>=` sem limite superior em produção

```json
{
    "require": {
        "php": "^8.3",
        "monolog/monolog": "^3.5",
        "guzzlehttp/guzzle": "^7.8"
    }
}
```

---

## Restrição de Versão do PHP

Sempre declarar a versão mínima do PHP no `require`. Isso rejeita instalação em ambientes incompatíveis.

```json
{
    "require": {
        "php": "^8.3"
    }
}
```

Combinado com `config.platform.php`, garante que o Composer resolva dependências simulando a versão exata do servidor de produção:

```json
{
    "config": {
        "platform": {
            "php": "8.3.12"
        }
    }
}
```

---

## `composer.lock`

O arquivo `composer.lock` deve **sempre** ser commitado no repositório. Garante que todos os desenvolvedores e o servidor de produção instalem as mesmas versões exatas.

```bash
# Desenvolvimento: instalar a partir do lock file
composer install

# Atualizar uma dependência específica
composer update vendor/package

# Atualizar todas (cuidado em produção)
composer update

# Não commitar vendor/, adicionar ao .gitignore
```

---

## Comandos para Produção

```bash
# Instalação sem dependências de desenvolvimento
composer install --no-dev

# Otimizar autoloader para produção
composer install --no-dev --optimize-autoloader

# Máxima otimização: classmap estático (sem busca em disco)
composer install --no-dev --optimize-autoloader --classmap-authoritative

# Verificar vulnerabilidades de segurança nas dependências
composer audit

# Equivalente ao npm audit fix (atualiza patches de segurança)
composer update --with-dependencies
```

**Diferença entre modos de autoloader:**

| Modo | Velocidade | Observação |
|---|---|---|
| Standard | Lenta | Busca em disco por arquivo |
| `--optimize-autoloader` | Média | Gera classmap, fallback para busca |
| `--classmap-authoritative` | Rápida | Apenas classmap, sem fallback |

Usar `--classmap-authoritative` apenas quando todas as classes estão no classmap (sem autoload dinâmico).

---

## Autoload PSR-4

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/",
            "App\\Tests\\": "tests/"
        },
        "files": [
            "src/helpers.php"
        ]
    }
}
```

Após alterar o `autoload`, regenerar:

```bash
composer dump-autoload
```

---

## Scripts do Composer

```json
{
    "scripts": {
        "test": "phpunit --testdox",
        "test:coverage": "phpunit --coverage-html coverage",
        "lint": "phpcs --standard=PSR12 src/ tests/",
        "fix": "phpcbf --standard=PSR12 src/ tests/",
        "analyse": "phpstan analyse src/ --level=8",
        "ci": [
            "@lint",
            "@analyse",
            "@test"
        ]
    }
}
```

```bash
composer run test
composer run ci
```

---

## Pacotes Recomendados

### Desenvolvimento e Qualidade

```json
{
    "require-dev": {
        "phpunit/phpunit": "^11.0",
        "phpstan/phpstan": "^1.10",
        "squizlabs/php_codesniffer": "^3.8",
        "rector/rector": "^1.0"
    }
}
```

- **PHPUnit**: framework de testes
- **PHPStan**: análise estática de tipos (nível 8+ recomendado)
- **PHP_CodeSniffer**: validação de PSR-12
- **Rector**: refatoração automatizada e upgrade de versão PHP

### HTTP e Comunicação

```json
{
    "require": {
        "guzzlehttp/guzzle": "^7.8",
        "nyholm/psr7": "^1.8",
        "php-http/discovery": "^1.19"
    }
}
```

### Logging (PSR-3)

```json
{
    "require": {
        "monolog/monolog": "^3.5",
        "psr/log": "^3.0"
    }
}
```

---

## Auditoria de Segurança

```bash
# Verificar CVEs conhecidos nas dependências
composer audit

# Saída inclui:
# - Package name
# - CVE ID
# - Severity (low/medium/high/critical)
# - Advisory URL
# - Affected versions
# - Fixed in version
```

Integrar `composer audit` no pipeline de CI/CD para bloquear deploys com vulnerabilidades críticas.

---

## `.gitignore` para Projetos Composer

```gitignore
/vendor/
/coverage/
.phpunit.result.cache
.phpunit.cache/
```

---

## Checklist Composer

| Item | Verificação |
|---|---|
| `"php": "^8.3"` | Declarado no require |
| `config.platform.php` | Versão exata do servidor |
| `composer.lock` | No repositório git |
| `vendor/` | No `.gitignore` |
| `--no-dev` em produção | Dependências de dev excluídas |
| `--optimize-autoloader` | Autoloader otimizado |
| `composer audit` | No pipeline de CI/CD |
| Scripts de CI | `test`, `lint`, `analyse` configurados |
