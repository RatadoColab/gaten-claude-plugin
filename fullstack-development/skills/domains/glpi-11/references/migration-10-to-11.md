# Migração de Plugin GLPI 10 → GLPI 11

Checklist agrupado por severidade, na ordem aproximada em que cada item quebra um plugin GLPI 10 ao rodar sob GLPI 11. Baseado no guia oficial de upgrade (`upgradeguides/glpi-11.0.html`) e no `CHANGELOG.md` do core GLPI (`11.0/bugfixes`) — o guia oficial cobre principalmente sanitização/HTTP/URLs; a maior parte do bloco "Bloqueantes" e "Comportamental" abaixo vem do CHANGELOG, não do guia.

GLPI 11 mantém acesso público aos scripts em `/ajax`, `/front` e `/report` com a mesma URL, para facilitar a migração incremental — não é necessário reescrever tudo como Controller de uma vez.

## Bloqueantes (erro fatal / plugin não carrega)

1. Remover `include('../../../inc/includes.php')` de todo `front/`, `ajax/`, `report/` — o bootstrap agora roda automaticamente via `public/index.php`.
2. Substituir `$DB->query()` / `$DB->queryOrDie()` por `$DB->request()` (query builder) ou `$DB->doQuery()` (SQL self-crafted). SQL cru via `query()`/`queryOrDie()` está **proibido**, não apenas depreciado.
3. Trocar a sintaxe de 2 parâmetros do `$DB->request('table', [...])` pela sintaxe de array único (`['FROM' => 'table', 'WHERE' => [...]]`).
4. Ajustar/remover referências a arquivos removidos: `inc/autoload.function.php`, `inc/based_config.php`, `inc/config.php`, `inc/db.function.php`, `inc/define.php` (constantes de direito agora carregam automaticamente).
5. Trocar `Computer_Item` por `\Glpi\Asset\Asset_PeripheralAsset`.
6. Atualizar `use` de `QueryExpression`, `QueryParam`, `QuerySubQuery`, `QueryUnion` para `Glpi\DBAL\*`.
7. Remover chamadas a métodos `Html::` removidos — em especial `Html::autocompletionTextField()`, `Html::clean()`, `Html::displayAjaxMessageAfterRedirect()`, `Html::getCoreVariablesForJavascript()`, `Html::openArrowMassives()`/`closeArrowMassives()`, `Html::showTimeField()`.
8. Corrigir sobrescritas de `can*()` (`canView`, `canCreate` etc.) em subclasses de `CommonDBTM`/`CommonGLPI` — agora exigem type hints estritos de parâmetro e retorno.
9. Renomear comandos de console de plugin para o prefixo normalizado `plugins:XXX` (`XXX` = chave do plugin).
10. Renomear a constante `PLUGINS_DIRECTORIES` → `GLPI_PLUGINS_DIRECTORIES`.

## Segurança (silenciosamente inseguro se ignorado)

11. Remover todo uso de `Toolbox::addslashes_deep()` / `stripslashes_deep()` — no 11 eles **corrompem** dados em vez de protegê-los, pois a auto-sanitização de `$_GET`/`$_POST` foi removida.
12. Adicionar `htmlescape()` em **toda** saída HTML dinâmica e `jsescape()` em saída JS — este é o item de maior superfície de trabalho numa migração real.
13. Remover o filtro `|verbatim_value` dos templates Twig — não é mais necessário.
14. Declarar estratégias de firewall (`Firewall::addPluginStrategyForLegacyScripts()`) para scripts legados que precisam de acesso não-padrão (público, FAQ, central).
15. Registrar paths stateless de API via `SessionManager::registerPluginStatelessPath()`, idealmente dentro de `plugin_<nome>_boot()`.

## Estrutura e URLs

16. Mover assets estáticos e scripts PHP web-acessíveis para `myplugin/public/` — o diretório não aparece na URL final.
17. Trocar `Plugin::getWebDir()` por caminhos literais `/plugins/myplugin/...` (ou `$CFG_GLPI['root_doc'] . '/plugins/myplugin/...'`).
18. Trocar a variável JS `GLPI_PLUGINS_PATH` e a função Twig `get_plugin_web_dir()` por caminhos literais / `path('/plugins/myplugin/...')`.
19. Auditar uso de `$_SERVER['PHP_SELF']`, `SCRIPT_NAME`, `PATH_INFO` — no 11 apontam para `public/index.php`, não para o script solicitado.
20. Migrar URLs que ainda usam o prefixo `/marketplace/...` para `/plugins/...` (suportado mas depreciado).

## Hooks

21. Remover `$PLUGIN_HOOKS['csrf_compliant']` — hook depreciado (`@deprecated 11.0.0`), não deve mais ser declarado; `csrf_token()` no Twig continua obrigatório, a checagem em si deixou de ser opt-in por plugin.
22. Remover `$PLUGIN_HOOKS['debug_tabs']`, `['migratetypes']`, `['planning_scheduler_key']` — hooks removidos.
23. Renomear `show_in_timeline` → `timeline_items`.
24. Renomear `ruleImportComputer_addGlobalCriteria`/`ruleImportComputer_getSqlRestriction` → `ruleImportAsset_addGlobalCriteria`/`ruleImportAsset_getSqlRestriction`.

## Comportamental

25. Substituir `exit()`/`die()`/`http_response_code()` por exceções `Glpi\Exception\Http\*HttpException` (`NotFoundHttpException`, `AccessDeniedHttpException`, `BadRequestHttpException`, etc.). Quando `exit()` só interrompia o script sem sinalizar erro, usar `return`.
26. Renomear `Migration::updateRight()` → `Migration::replaceRight()`.
27. Adicionar a trait `Glpi\Features\AssignableItem` a classes registradas em `$CFG_GLPI['directconnect_types']`.
28. Tratar `groups_id`/`groups_id_tech` de assets como **arrays**, não inteiros; leitura direta no banco requer a tabela `glpi_groups_items`.
29. Revisar chamadas a `NotificationEvent::raiseEvent()` — novo parâmetro `$trigger` na 4ª posição.
30. Se o plugin lida com `CommonITILValidation`: `users_id_validate` agora fica `0` até aprovação; usar `itemtype_target`/`items_id_target`.
31. Renomear a constante `GLPI_STRICT_DEPRECATED` → `GLPI_STRICT_ENV`, se referenciada.
32. Revalidar qualquer código que assumia `GLPIMailer` herdando diretamente de `PHPMailer\PHPMailer\PHPMailer` — a herança direta não existe mais (camada de compatibilidade parcial).
33. Remover referências às demais constantes/globais eliminadas: `GLPI_USE_CSRF_CHECK`, `GLPI_USE_IDOR_CHECK`, `GLPI_DEMO_MODE`, `GLPI_DUMP_DIR`, `GLPI_SQL_DEBUG`, `$GLPI`, `$LANG`, `$AJAX_INCLUDE`, `$CFG_GLPI_PLUGINS`, `$SECURITY_STRATEGY`, `$SQLLOGGER`, `$DBCONNECTION_REQUIRED`, `$USEDBREPLICATE`, `$PLUGINS_EXCLUDED`, `$PLUGINS_INCLUDED`, `$_SESSION['glpiroot']`.

## Opcional / modernização (não bloqueia a migração)

34. Migrar `inc/*.class.php` → `src/` com namespace PSR-4 `GlpiPlugin\Meuplugin\` (autoloader legado continua funcionando, então isso pode ser incremental).
35. Migrar `front/` e `ajax/` para Controllers em `src/Controller/` com atributo `#[Route]` — caminho recomendado para features novas, não obrigatório para código existente.
36. Adicionar `plugin_myplugin_boot()` se o plugin precisar de setup que rode antes da sessão carregar.
37. Migrar saída HTML para templates Twig com `TemplateRenderer::getInstance()->display('@myplugin/...')`.

## Ferramental

- `glpi-project/phpstan-glpi` ajuda a detectar boa parte dos itens acima estaticamente (assinaturas alteradas, classes removidas).
- `glpi-project/rector-glpi` **não** tem um set de migração 10→11 pronto — contém apenas regras `Glpi120x` (para a migração 11→12, ainda em desenvolvimento). Não depender dele para automatizar esta migração.
- Ferramental de lint do core migrou de `phpcs`/`phpcbf` para PHP-CS-Fixer + Rector + PHPStan + ESLint + Stylelint + TwigCS (`make lint`) — não é obrigatório adotar no plugin, mas indica a direção do ecossistema.

## Referência cruzada

Para o modelo de destino de cada item acima (sintaxe correta, exemplos completos), consultar `domains/glpi-11/SKILL.md` e `domains/glpi-11/references/architecture.md`. Para comparar com o comportamento de origem, `domains/glpi-10/SKILL.md` e `domains/glpi-10/references/architecture.md`.
