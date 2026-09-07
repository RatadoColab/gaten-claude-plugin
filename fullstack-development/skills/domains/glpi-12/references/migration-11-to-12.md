# Migração de Plugin GLPI 11 → GLPI 12

Checklist agrupado por severidade, na ordem aproximada em que cada item quebra um plugin GLPI 11 ao rodar sob GLPI 12. Baseado na comparação direta do código-fonte do GLPI 12.0.0 RC (`glpi12/`) com o 11.0.8 (`glpi11/`) e na seção *API changes* do `CHANGELOG.md` do RC — excepcionalmente detalhada para um release candidate.

> **O salto pelo GLPI 11 é obrigatório.** Este guia pressupõe um plugin já migrado e funcional sob GLPI 11. Não migrar direto do GLPI 10 — as duas migrações têm superfícies distintas e o 11 absorve a maior parte da ruptura (query builder, `public/`, Controllers, remoção de sanitização automática).

> **Conteúdo derivado de RC.** Os itens de estrutura são estáveis; assinaturas exatas e a lista final de remoções devem ser reconferidas contra o `CHANGELOG.md` do 12.0.0 GA (previsto para 2026-10-06). O milestone estava 98% concluído na análise, com a API efetivamente congelada.

GLPI 12 mantém acesso público aos scripts em `/ajax`, `/front` e `/report` com a mesma URL — a migração pode continuar incremental, sem reescrever handlers legados como Controller de uma vez.

## Bloqueantes (erro fatal / plugin não carrega)

1. Subir o requisito de PHP para **8.3** em `plugin_version_<nome>()` (`GLPI_MIN_PHP` passou de `8.2` para `8.3`; `GLPI_MAX_PHP` segue `8.5`). Revisar o código quanto a sintaxe removida/alterada no PHP 8.3.
2. Ajustar `requirements.glpi` para `['min' => '12.0.0', 'max' => '12.0.99']` e o `version_compare(GLPI_VERSION, ...)` de `plugin_<nome>_check_prerequisites()`.
3. Trocar `use` de `QueryExpression`, `QueryParam`, `QuerySubQuery`, `QueryUnion` — os aliases de raiz foram **removidos** (no 11 apenas moveram para `Glpi\DBAL\*` mantendo compat). Somente `Glpi\DBAL\QueryExpression` etc. funciona.
4. Substituir `Html::displayNotFoundError()` → `throw new \Glpi\Exception\Http\NotFoundHttpException()` e `Html::displayRightError()` → `throw new \Glpi\Exception\Http\AccessDeniedHttpException()`. Ambos removidos. (`Html::header`, `header_nocache`, `footer`, `redirect`, `back`, `submit`, `scriptBlock`, `hidden`, `closeForm`, `helpHeader`/`helpFooter` **permanecem**.)
5. Substituir `Toolbox::callCurl()`, `Toolbox::getURLContent()`, `Toolbox::getGuzzleClient()` por `Glpi\Toolbox\HttpClient` (`new HttpClient($context, $options)` → `->request()`/`->get()`/`->post()`/`->stream()`). Também removidas: `Toolbox::isUrlSafe()`, `Toolbox::seems_utf8()`, `Toolbox::sendFile()`, `Toolbox::addslashes_deep()`/`stripslashes_deep()` (já não deviam ser usadas no 11).
6. Ajustar referências a classes removidas: `KnowbaseItemCategory` (e right `knowbasecategory`), `Timer`, `ComputerAntivirus` → `ItemAntivirus`, `ComputerVirtualMachine` → `ItemVirtualMachine`, `Item_Plug`/`Pdu_Plug`, `Glpi\Toolbox\Sanitizer`. `QueryExpression`/`QueryParam`/`QuerySubQuery`/`QueryUnion` globais idem.
7. Remover chamadas a `Plugin::getWebDir()` — **removida** (era `@deprecated 11.0.0`). Usar caminho literal `/plugins/<nome>/...` ou `$CFG_GLPI['root_doc'] . '/plugins/<nome>/...'`.
8. Corrigir sobrescritas de `can()` / `canGlobal()` em subclasses de `CommonDBTM`/`CommonGLPI` — ganharam o parâmetro `null &$reauth_needed = null` na última posição; a assinatura da sobrescrita precisa casar.
9. Ajustar chamadas a `Migration::displayTitle()`, `displayWarning()`, `displayError()`, `addNewMessageArea()`, `setOutputHandler()` — todas removidas. Usar `$migration->addMessage()` / logging padrão.
10. Ajustar `DBmysql`: `query()`, `queryOrDie()`, `doQueryOrDie()`, `insertOrDie()`, `updateOrDie()`, `deleteOrDie()`, `truncate()`, `truncateOrDie()`, `guessTimezone()` — removidos. Usar `$DB->doQuery()`, `$DB->insert()`, `$DB->update()`, `$DB->delete()`.
11. Revisar chamadas a `countElementsInTable()`, `countDistinctElementsInTable()`, `getAllDataFromTable()` (e os métodos equivalentes em `DbUtils`) — assinaturas mudaram e toda a `DbUtils` passou a ter tipos estritos. Remover uso do parâmetro `$order` em `getAllDataFromTable()`.

## Segurança (silenciosamente quebrado ou inseguro se ignorado)

12. **Remover todo campo `_glpi_csrf_token`** de formulários Twig/HTML e todo header `X-Glpi-Csrf-Token` de chamadas `fetch`/`$.ajax`. A proteção CSRF passou a ser validação de header (`Sec-Fetch-Site`/`Origin`) no `CheckCsrfListener` do kernel, aplicada a todo método com corpo. Manter o campo não quebra o POST (o token é ignorado), mas mascara código morto e a `csrf_token()` será removida no GLPI 13.
13. Remover `csrf_token()` dos templates Twig, `fields.csrfField()` (macro em `fields_macros.html.twig`) e `getAjaxCsrfToken()` no JS — todos depreciados no 12.
14. Remover `Session::getNewCSRFToken()`, `Session::validateCSRF()`, `Session::checkCSRF()`, `Session::cleanCSRFTokens()` se referenciados — depreciados; a validação é feita pelo kernel antes da rota.
15. Para itemtypes de plugin que manipulam dados sensíveis, avaliar adoção do "sudo mode": sobrescrever `CommonGLPI::isUserReauthenticationNeeded()` (retorna `false` por padrão) e, em Controller, chamar `CommonGLPI::checkReAuthenticationOrRedirect()`. Nunca implementar prompt de senha próprio — o fluxo (`ReAuthManager` + estratégias + `ReAuthReplayListener`) é do core.

## Hooks

16. Remover `Hooks::CSRF_COMPLIANT` / `$PLUGIN_HOOKS['csrf_compliant']` — a constante foi **removida** (no 11 estava `@deprecated`, ainda existia).
17. Trocar `Hooks::SHOW_IN_TIMELINE` / `show_in_timeline` por `Hooks::TIMELINE_ITEMS` / `timeline_items` — a constante antiga foi removida.
18. Hooks novos disponíveis (opcionais): `Hooks::POST_PREPAREUPDATE` (`post_prepareupdate`), `Hooks::GET_CONTENT_TEMPLATE_PARAMETER`, `Hooks::GET_CONTENT_TEMPLATE_VALUE`, `Hooks::INVENTORY_GET_CONFIGURATION`.

## Comportamental

19. `Session::haveRight(string $module, int $right): bool` agora é tipada e retorna **somente** booleano. Código que comparava o retorno com inteiros ou usava `===` contra não-booleano precisa ajuste.
20. Se o plugin lida com `CommonITILValidation`: o campo `users_id_validate` **não é mais suportado** — usar `items_id_target` + `itemtype_target`. (No 11 `users_id_validate` ficava `0` até aprovação; no 12 deixa de existir como via de acesso.)
21. `CommonITILObject::getTimelineItems()` não aceita mais os parâmetros `bypass_rights`, `expose_private`, `is_self_service`. Revisar chamadas em plugins que montam timeline própria.
22. Massive actions: `Ticket:link_to_problem` e `Ticket_Ticket:add` foram removidas — usar `CommonITILObject_CommonITILObject:add`.
23. `Document::getDownloadLink()` não aceita mais parâmetros de URL adicionais; `Document::send()` removido.
24. Base de conhecimento reestruturada: `KnowbaseItemCategory` virou artigo; tabela `glpi_knowbaseitems_knowbaseitemcategories` renomeada para `glpi_knowbaseitems_knowbaseitems` (colunas `knowbaseitems_id` filho / `knowbaseitems_id_parent` pai); a coluna `knowbaseitemcategories_id` de `ITILCategory` e `TaskCategory` virou `knowbaseitems_id`. `KnowbaseItem::getForCategory()` → `KnowbaseItem::getChildrenArticles()`. Plugins que leem/gravam categorias de KB diretamente precisam reescrever essa parte.
25. `KnowbaseItem_KnowbaseItemCategory` renomeada para `KnowbaseItem_KnowbaseItem`. `KnowbaseItem_Comment` e `KnowbaseItem_Revision` agora são `final` — não estender.
26. Detecção de IP de cliente atrás de proxy reverso passou a exigir `GLPI_TRUSTED_REVERSE_PROXIES` + `GLPI_REVERSE_PROXY_HEADERS`. Relevante se o plugin lê `$_SERVER['REMOTE_ADDR']` para lógica própria.
27. Remoção do `DBSlave` / réplica de leitura: `DBConnection::switchToMaster()`/`switchToSlave()`, `DBmysql::$slave`/`isSlave()`, `DBSlave` — depreciados. Plugins que forçavam master/slave devem parar.

## Frontend / JS

28. Libs JS removidas do core — trocar se o plugin dependia delas: `jquery.fancytree` → `Wunderbaum`; `diff-match-patch`, `hotkeys-js`, `jquery-prettytextdiff`, `jquery.rateit` — sem substituto direto, reimplementar ou remover a feature.
29. `escapeMarkupText()` (JS) depreciada. Módulos JS removidos: `Forms/FaIconSelector`, `Knowbase`.
30. `Html::link()` depreciada (ainda presente) — preferir `<a>` explícito com `path()`/caminho literal.

## Opcional / modernização (não bloqueia a migração)

31. Adotar `AbstractController::validateInputHasExactKeys(array $input, array $keys)` para validar payload de Controller em vez de checagem manual.
32. Migrar para os Twig Components do core (`Alert` — `Info`/`Success`/`Warning`/`Danger`, `Mfa/CodeInput`) onde o plugin renderiza alertas próprios.
33. High-Level API v3.0.0 disponível — se o plugin registra schemas/endpoints via `api_controllers`/`redefine_api_schemas`, revisar contra a v3.
34. Substituir `league/csv` por `phpoffice/phpspreadsheet` e `guzzlehttp/guzzle` por `Glpi\Toolbox\HttpClient` em dependências diretas do `composer.json` do plugin.

## Ferramental

- **`glpi-project/rector-glpi`** — `composer require --dev glpi-project/rector-glpi`, depois registrar `\RectorGlpi\Set\GlpiSetList::GLPI_DEFAULT_SET` no `rector.php`. Sob GLPI ≥ 12.0.0-dev o set aplica **duas** regras, ambas de modernização (não corrigem quebras):
  - `ReplaceCommonGlpiGetTypeByClassConstantRector` — troca `Foo::getType()` por `Foo::class` onde equivalente.
  - `ReplaceHardcodedRightnameByCommonDBTMRightnamePropertyRector` — troca string de rightname literal pela propriedade `::$rightname` da classe.
  Não há regra para CSRF, `Html::`, `Query*` ou `Toolbox::` — esses itens são manuais.
- **`glpi-project/phpstan-glpi`** — detecta estaticamente boa parte dos itens "Bloqueantes" (assinaturas alteradas, classes e métodos removidos). Rodar antes e depois da migração.
- Não existe set de Rector que automatize a remoção de CSRF nem as substituições de `Html::`/`Toolbox::` — planejar essa parte como edição manual guiada por `grep`.

## Referência cruzada

Para o modelo de destino de cada item (sintaxe correta, exemplos completos), consultar `domains/glpi-12/SKILL.md` e `domains/glpi-12/references/architecture.md`. Para comparar com o comportamento de origem, `domains/glpi-11/SKILL.md` e `domains/glpi-11/references/architecture.md`.
