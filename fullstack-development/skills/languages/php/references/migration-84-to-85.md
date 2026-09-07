# Migração PHP 8.4 → 8.5

Checklist agrupado por severidade, na ordem aproximada em que cada item quebra ou passa a alertar num código real. Fonte: manual oficial (`migration85.incompatible.php`, `migration85.deprecated.php`, `migration85.other-changes.php`). Para os recursos novos que a migração habilita, ver `php85-features.md`. Pressupõe a migração 8.3 → 8.4 já concluída (`migration-83-to-84.md`).

O 8.5 traz mais depreciações "de limpeza" (magic methods legados, casts não canônicos, backtick) e uma mudança operacional relevante: o OPcache passou a ser sempre embutido e carregado.

---

## Quebras em runtime (erro / `ValueError` / warning)

1. **`PDO::FETCH_GROUP`, `FETCH_UNIQUE`, `FETCH_CLASSTYPE`, `FETCH_PROPS_LATE`, `FETCH_SERIALIZE` mudaram de valor numérico.** Código que persistiu, serializou ou combinou esses inteiros por conta própria (em vez de usar as constantes) quebra silenciosamente.
2. **`PDO::FETCH_PROPS_LATE` sem `FETCH_CLASS`** lança `ValueError`; **`FETCH_INTO` em `fetchAll()`** lança `ValueError`; chamar **`PDOStatement::setFetchMode()` durante um fetch em andamento** lança `Error`.
3. **`PDO::FETCH_CLASS`** — argumentos do construtor passam a seguir semântica `call_user_func_array` (chaves string viram argumentos nomeados). O "wrapping" automático de argumento por valor para parâmetro por referência foi removido.
4. **Desestruturar valor não-array** (`[$a, $b] = $scalar;` ou `list()`) emite `E_WARNING`, exceto quando o valor é `null`.
5. **Cast com perda** — casting de `float`/string numérica para `int` quando o valor não é representável, e cast de `NAN` para qualquer tipo, passam a emitir `E_WARNING`.
6. **Comparação frouxa de objetos não comparáveis** — enums, `CurlHandle` e outras classes internas passam a se comportar consistentemente como `(bool)$object` ao comparar com booleano. `$enumCase == true` muda de resultado em alguns casos.
7. **`class_alias()`** não aceita mais `"array"` nem `"callable"` como nome do alias.
8. **`ArrayObject` não aceita mais enums**; **`SplFileObject::fwrite()`** teve o parâmetro `length` mudado de default `0` para `null` (nullable).
9. **`session_start($options)`** mais estrito — `ValueError` para array não-hashmap, `TypeError` para `read_and_close` de tipo inválido. Gravar em `$_SESSION` com chave contendo `|` emite warning.
10. **Traits são ligadas antes da classe pai** — ordem de resolução muda; conflito trait × método herdado do pai pode passar a se comportar diferente. Erros de compilação e linkagem agora são sempre adiados e tratados após a compilação.
11. **Intl exige ICU ≥ 57.1**; métodos de `Locale`/`IntlDateFormatter` lançam `ValueError`/`IntlException` para byte nulo ou classe não inicializada.
12. **Funções da família `printf`** — precisão não especificada deixou de "resetar"; passa a ser tratada como `0`. **`setlocale()`** com inteiro `0` lança `TypeError`.
13. **`gc_collect_cycles()`** — o retorno não inclui mais strings/resources coletados indiretamente.
14. **`#[\Attribute]` em classe abstrata, enum, interface ou trait** vira erro de compilação (pode ser adiado com `#[\DelayedTargetValidation]`).
15. **Byte nulo** em nome de arquivo/argumento passa a lançar `ValueError` de forma consistente em FileInfo, PCNTL, PDO_SQLite, SNMP, Sockets, POSIX (antes `TypeError` ou warning).
16. **INI `disable_classes` removida** — se o `php.ini` a define, a diretiva é ignorada; rever a estratégia de hardening.

---

## Depreciações a resolver (`E_DEPRECATED`)

17. **`__sleep()` / `__wakeup()`** — migrar para `__serialize()` / `__unserialize()`. Vale também para `SplObjectStorage` e afins.
18. **Casts não canônicos** `(boolean)`, `(integer)`, `(double)`, `(binary)` — usar `(bool)`, `(int)`, `(float)`, `(string)`.
19. **Operador backtick** (`` `ls -la` ``) como alias de `shell_exec()` — chamar `shell_exec()` explicitamente.
20. **`;` terminando um `case`** (`case 1;` em vez de `case 1:`) — corrigir para `:`.
21. **`null` como offset de array** (`$arr[null]`) — usar string vazia `''` explicitamente.
22. **Incremento de string não numérica** (`$s = 'a'; $s++;` fora do intervalo alfanumérico esperado) — usar `str_increment()`.
23. **Redeclaração de constante** (mesmo `const`/`define()` duas vezes) passa a alertar.
24. **`$http_response_header`** (variável mágica) — usar `http_get_last_response_headers()`.
25. **Retornar `null` de `__debugInfo()`** — retornar array vazio.
26. **Objetos liberados automaticamente — funções `*_close`/`*_free` depreciadas**: `curl_close()`, `curl_share_close()`, `finfo_close()`, `imagedestroy()`, `xml_parser_free()`. Podem simplesmente ser removidas.
27. **`ReflectionProperty::setAccessible()` / `ReflectionMethod::setAccessible()`** — sem efeito desde o 8.1 (acesso já é liberado); remover as chamadas.
28. **`SplObjectStorage::contains()` / `attach()` / `detach()`** — usar `offsetExists()` / `offsetSet()` / `offsetUnset()`.
29. **PDO — constantes e métodos específicos de driver na classe base `PDO`** (`PDO::MYSQL_ATTR_*`, `PDO::pgsqlCopyFromArray()`, `PDO::sqliteCreateFunction()`, etc.) — migrar para as classes `Pdo\Mysql`, `Pdo\Pgsql`, `Pdo\Sqlite` introduzidas no 8.4 (`php84-features.md`). O esquema de DSN `"uri:"` também foi depreciado.
30. **`socket_set_timeout()`** — usar `stream_set_timeout()`.
31. **`chr()` fora de `[0, 255]`** e **`ord()` com string de mais de 1 byte** passam a alertar; passar `null` para `readdir()`/`rewinddir()`/`closedir()` idem.
32. **INI `report_memleaks`** depreciada; **`register_argc_argv`** depreciada para SAPIs não-CLI.
33. **`intl.error_level` INI**, **`MHASH_*`**, **`DATE_RFC7231` / `DateTimeInterface::RFC7231`**, **`key_length` em `openssl_pkey_derive()`** — depreciados; relevantes só se o projeto os usa.
34. **Binding de closure problemático** — rebind de closure estática, bind com objeto de classe incompatível e "unbind" de `$this` passam a alertar.
35. **Produzir saída dentro de um output handler de usuário** (callback de `ob_start()`) passa a alertar.

---

## Infra e configuração

36. **OPcache é sempre embutido e sempre carregado.** As flags `--enable-opcache` / `--disable-opcache` do `configure` foram removidas. Declarar `zend_extension=opcache.so` (ou `php_opcache.dll`) no `php.ini` **emite warning** — remover essa linha. Ajustar Containerfile/imagem base e provisionamento que instalavam/ativavam o OPcache manualmente. A configuração de comportamento (`opcache.enable`, `opcache.jit`, memória) permanece igual.
37. **`opcache_is_script_cached_in_file_cache()`** — nova função para diagnosticar o cache em arquivo.
38. **PCRE** compilado sem `PCRE2_EXTRA_ALLOW_LOOKAROUND_BSK` — padrões que usavam `\K` dentro de lookaround deixam de compilar.
39. **MBString** — tabelas Unicode atualizadas para Unicode 17.0 (mudanças de classificação de caracteres em casos de borda).
40. **ODBC** — assume ODBC ≥ 3.5; flags de build especiais removidas (exceto DB2).

---

## Execução da migração

1. Em staging, suíte com `error_reporting(E_ALL)` e `log_errors=On` para colher `E_DEPRECATED` — foco em `__sleep`/`__wakeup`, casts não canônicos, backtick e `setAccessible()`.
2. `composer config platform.php 8.5.<patch>` + `"php": "^8.5"`; `composer update`.
3. PHPStan/Psalm atualizados; opcionalmente Rector com o set `PHP_85` para os itens mecânicos (casts, `setAccessible`, magic methods, `$http_response_header`).
4. **Ajustar `php.ini`/imagem: remover `zend_extension=opcache.so`** e qualquer passo de instalação separada do OPcache; remover `disable_classes` e `report_memleaks`.
5. Auditar uso direto dos valores inteiros de `PDO::FETCH_*` (persistência, bitmask manual) e migrar constantes/métodos de driver para `Pdo\*`.
6. Testar serialização de objetos com `__sleep`/`__wakeup`, fetch modes do PDO e regex com `\K` em lookaround.
