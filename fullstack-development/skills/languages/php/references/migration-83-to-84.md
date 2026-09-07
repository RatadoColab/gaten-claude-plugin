# Migração PHP 8.3 → 8.4

Checklist agrupado por severidade, na ordem aproximada em que cada item quebra ou passa a alertar num código real. Fonte: manual oficial (`migration84.incompatible.php`, `migration84.deprecated.php`, `migration84.other-changes.php`). Para os recursos novos que a migração habilita, ver `php84-features.md`.

O PHP 8.4 é majoritariamente compatível: quase nada quebra em runtime sem aviso prévio. O grosso do trabalho é resolver `E_DEPRECATED` — em especial os tipos de parâmetro implicitamente nullable.

---

## Quebras em runtime (erro / `TypeError` / `ValueError`)

1. **`exit`/`die` agora se comportam como função** — respeitam `declare(strict_types=1)` e fazem coerção de tipo em vez de cast para string. `exit([])` ou `exit(new stdClass)` lançam `TypeError`. Auditar `exit()` que recebe algo diferente de `int` (0–254) ou `string`.
2. **Modificação indireta de propriedade `readonly` em `__clone()`** — `$ref = &$this->readonlyProp;` dentro de `__clone()` passou a ser `Error`. Reescrever o wither sem referência (ou migrar para `clone($this, [...])` no 8.5).
3. **`PHP_DEBUG` e `PHP_ZTS` viraram `bool`** (antes `int`). Comparações estritas `=== 1` / `=== 0` com essas constantes quebram.
4. **`round()`** lança `ValueError` para modo de arredondamento inválido; **`php_uname()`** lança `ValueError` para modo inválido; **`str_getcsv()`** lança `ValueError` se `separator`/`enclosure` não tiverem exatamente 1 byte ou `escape` não for 1 byte / vazio.
5. **`unserialize()`** — a opção `allowed_classes` lança `TypeError`/`ValueError` se não for `bool` nem array de nomes de classe.
6. **`GMP` agora é `final`** — não pode mais ser estendida.
7. **Recursão durante comparação** (`==`) lança `Error` em vez de fatal `E_ERROR` — passou a ser capturável, mas continua interrompendo o fluxo.
8. **`stream_bucket_make_writeable()` / `stream_bucket_new()`** retornam `StreamBucket` (antes `stdClass`) — código que faz `(array)` ou checa `instanceof stdClass` no filtro de stream quebra.
9. **`strcspn()`** com string de caracteres vazia agora retorna o comprimento total em vez de parar no primeiro byte nulo.
10. **Nome de arquivo temporário 13 bytes mais longo** — `tempnam()` e uploads geram nomes maiores. Ajustar validações de comprimento e colunas de banco que armazenam esses nomes.
11. **Constantes de classe de várias extensões agora são tipadas** (Date, Intl, PDO, Reflection, SPL, SQLite, XMLReader) — subclasses que redeclaram uma constante com tipo incompatível quebram.
12. **Migração de resource para objeto**: DBA (`Dba\Connection`), ODBC (`Odbc\Connection`, `Odbc\Result`), SOAP (`Soap\Url`, `Soap\Sdl`; `SoapClient::$typemap` virou array). `is_resource()` sobre esses valores passa a retornar `false`.
13. **`http_build_query()`** agora serializa enums backed corretamente — a saída muda para código que dependia do comportamento anterior.

---

## Depreciações a resolver antes de subir (`E_DEPRECATED`)

Prioridade alta — maior superfície numa base real:

14. **Tipo de parâmetro implicitamente nullable** — `function f(Foo $x = null)` deve virar `function f(?Foo $x = null)`. Vale para todo parâmetro tipado com default `null`, inclusive em métodos de interface/classe abstrata. Rector (`TYPE_DECLARATION`) e PHPStan/Psalm detectam em massa.

Demais depreciações:

15. **`trigger_error(..., E_USER_ERROR)`** — substituir por exceção ou `exit()`.
16. **`0 ** -2` / `pow(0, -2)`** (base zero com expoente negativo) — usar `fpow()` para semântica IEEE 754.
17. **Classe nomeada exatamente `_`** (`class _ {}`) — renomear. `_Nome` continua válido.
18. **Parâmetro `escape` implícito em `fputcsv()`, `fgetcsv()`, `str_getcsv()` e `SplFileObject::setCsvControl()`** — passar explicitamente (recomendado `escape: ''` para CSV RFC 4180).
19. **`SplFixedArray::__wakeup()`** — implementar `__serialize()`/`__unserialize()`.
20. **`stream_context_set_option($ctx, $options)` com 2 argumentos** — usar `stream_context_set_options()` (plural).
21. **`lcg_value()`** — usar `Random\Randomizer::getFloat()`.
22. **`ReflectionMethod::__construct()` com 1 argumento** (`new ReflectionMethod('Cls::method')`) — usar `ReflectionMethod::createFromMethodName()`.
23. **`DatePeriod::__construct(string $isostr, ...)`** — usar `DatePeriod::createFromISO8601String()`.
24. **`session_set_save_handler()` com mais de 2 argumentos** — passar um objeto `SessionHandlerInterface`.
25. **INIs de sessão depreciadas**: `session.sid_length`, `session.sid_bits_per_character`, `session.use_only_cookies`, `session.use_trans_sid`, `session.trans_sid_tags`, `session.trans_sid_hosts`, `session.referer_check`. Também a constante **`SID`**. Remover do `php.ini` e do `ini_set()` do bootstrap — a §"Gerenciamento de Sessão" de `security.md` já não depende delas.
26. **`mysqli_ping()`, `mysqli_kill()`, `mysqli_refresh()`** e as constantes `MYSQLI_REFRESH_*` — usar SQL (`KILL`, `FLUSH`) ou remover; reconexão automática deixou de existir.
27. **`xml_set_object()` e passar string não-callable para `xml_set_*_handler()`** — usar `[$obj, 'metodo']`.
28. **DOM**: constante `DOM_PHP_ERR`; propriedades `DOMDocument::$actualEncoding`, `$config`, `DOMEntity::$actualEncoding`/`$encoding`/`$version`.
29. **`CURLOPT_BINARYTRANSFER`**, **`SUNFUNCS_RET_*`**, e vários itens de Intl/LDAP/PGSQL com assinatura estendida (ver manual se o projeto os usa).

Remoção: **`E_STRICT`** foi removido (a constante ficou como depreciada, valor sem efeito). Remover de `error_reporting()` e do `php.ini`.

---

## Infra e configuração

30. **Default do JIT mudou.** Antes: `opcache.jit=tracing` com `opcache.jit_buffer_size=0` (efetivamente desligado). Agora: `opcache.jit=disable` com `opcache.jit_buffer_size=64M`. Para manter o JIT ligado é preciso `opcache.jit=tracing` explícito. **Falha de inicialização do JIT agora é erro fatal no startup** (antes era warning). Revisar a §OPcache/JIT de `performance.md` e o `php.ini`/imagem de produção.
31. **`opcache.interned_strings_buffer`** — máximo em 64 bits subiu de `4095` para `32767`.
32. **`opcache.jit_blacklist`** — nova função `opcache_jit_blacklist()` para excluir funções problemáticas da compilação JIT.
33. **PCRE atualizado para pcre2lib 10.44** — `{,3}` agora é reconhecido como quantificador `{0,3}` (antes era texto literal). Auditar regex que dependiam do comportamento antigo. Lookbehind de comprimento variável passou a ser suportado.
34. **PDO_PGSQL** — credenciais no DSN passam a ter prioridade sobre os argumentos do construtor `PDO`.
35. **PDO_MySQL / PDO_Firebird / PDO_DBLIB** — `PDO::ATTR_AUTOCOMMIT`, `ATTR_EMULATE_PREPARES`, `MYSQL_ATTR_DIRECT_QUERY`, `ATTR_STRINGIFY_UNIQUEIDENTIFIER`, `ATTR_DATETIME_CONVERT` passaram a ser atributos booleanos (antes inteiros). `getAttribute()` retorna `bool`.

---

## Execução da migração

1. Em staging, rodar a suíte com `error_reporting(E_ALL)` e `log_errors=On` para coletar todo `E_DEPRECATED` — especialmente os parâmetros nullable implícitos.
2. `composer config platform.php 8.4.<patch>` + `"php": "^8.4"` no `require`; `composer update` e revalidar dependências (várias libs publicaram releases só-8.4).
3. Rodar PHPStan/Psalm no nível que sinaliza nullable implícito; opcionalmente Rector com o set `PHP_84` para aplicar as correções mecânicas (nullable, `escape` de CSV, `DatePeriod`).
4. Ajustar `php.ini`/Containerfile: decidir explicitamente `opcache.jit`, remover INIs de sessão depreciadas e `E_STRICT`.
5. Testar caminhos com `exit()`/`die()` recebendo valores não triviais, filtros de stream e serialização de `SplFixedArray`.
