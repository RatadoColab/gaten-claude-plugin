# Migração de Plugin GLPI 11 → GLPI 12

Checklist agrupado por severidade, na ordem aproximada em que cada item quebra um plugin GLPI 11 ao rodar sob GLPI 12. Baseado na comparação direta do código-fonte do GLPI 12.0.0 GA (`glpi12/`) com o 11.0.x (`glpi11/`) e na seção *API changes* do `CHANGELOG.md` do 12.0.0.

> **O salto pelo GLPI 11 é obrigatório.** Este guia pressupõe um plugin já migrado e funcional sob GLPI 11. Não migrar direto do GLPI 10 — as duas migrações têm superfícies distintas e o 11 absorve a maior parte da ruptura (query builder, `public/`, Controllers, remoção de sanitização automática).

> **Conferido contra o GLPI 12.0.0 GA (2026-10-07)**; onde o código do core diverge do `CHANGELOG.md`, o código prevalece (ver itens 1 e 2 e as notas de Comportamental).

GLPI 12 mantém acesso público aos scripts em `/ajax`, `/front` e `/report` com a mesma URL — a migração pode continuar incremental, sem reescrever handlers legados como Controller de uma vez.

## Bloqueantes (erro fatal / plugin não carrega)

1. **Propriedades das classes-base com tipo nativo (erro fatal; ausente do CHANGELOG do GLPI).** `CommonGLPI`, `CommonDBTM`, `CommonDropdown`, `CommonTreeDropdown`, `CommonDBChild`, `CommonDBRelation` e `Location` tipam suas propriedades; redeclarar sem tipo (`public $dohistory`, `static $rightname`, `public static $itemtype`, `static $itemtype_1`…) dá `Fatal error: Type of X::$y must be ...` ao carregar a classe. Se a classe é carregada no `plugin_init`, **derruba o GLPI inteiro** enquanto o plugin estiver ativo; senão, derruba a tela/aba que a usa. Corrigir com o mesmo tipo (`bool $dohistory`, `static string $rightname`, `static ?string $itemtype_1`…); sem modo dual com o 11. O erro vem da falta de **tipo** — a visibilidade explícita é só estilo. Lista de propriedades/tipos, regex de varredura e teste de carga em `architecture.md` ("Propriedades tipadas das classes-base"). Sintoma na suíte unit: `Fatal error: Premature end of PHP process`.
2. **Consultas como *prepared statements* (ausente do CHANGELOG).** `Search::makeTextSearch()` devolve ` LIKE ? ` (no 11.0.10 devolvia o valor escapado inline); o retorno de `addWhere()`/`addHaving()` vira `QueryExpression` sem valores, então SQL cru que concatena esse retorno sem vincular o valor lança `StatementException`. Testes unit que só conferem a string não detectam. Padrão de correção (confirmado no GA): em `plugin_<nome>_addWhere`/`addHaving`, preferir devolver **array de critérios** do query builder; se devolver string, o core a embrulha em `QueryExpression` sem parâmetros, então os valores precisam ir inline via `$DB->quoteValue()`/`$DB->quoteName()` — nunca concatenar o retorno de `makeTextSearch()` (` LIKE ? `). O core marca o retorno string com `@FIXME` para futura depreciação.
3. Subir o requisito de PHP para **8.3** em `plugin_version_<nome>()` (`GLPI_MIN_PHP` passou de `8.2` para `8.3`; `GLPI_MAX_PHP` segue `8.5`). Revisar o código quanto a sintaxe removida/alterada no PHP 8.3.
4. Ajustar `requirements.glpi` para `['min' => '12.0.0', 'max' => '12.0.99']` e o `version_compare(GLPI_VERSION, ...)` de `plugin_<nome>_check_prerequisites()` para `version_compare(GLPI_VERSION, '12.0.0', 'lt') || version_compare(GLPI_VERSION, '12.1.0', 'ge')`.
5. Trocar `use` de `QueryExpression`, `QueryParam`, `QuerySubQuery`, `QueryUnion` — os aliases de raiz foram **removidos** (no 11 apenas moveram para `Glpi\DBAL\*` mantendo compat). Somente `Glpi\DBAL\QueryExpression` etc. funciona.
6. Substituir `Html::displayNotFoundError()` → `throw new \Glpi\Exception\Http\NotFoundHttpException()` e `Html::displayRightError()` → `throw new \Glpi\Exception\Http\AccessDeniedHttpException()`. Ambos removidos. (`Html::header`, `header_nocache`, `footer`, `redirect`, `back`, `submit`, `scriptBlock`, `hidden`, `closeForm`, `helpHeader`/`helpFooter` **permanecem**.)
7. Substituir `Toolbox::callCurl()`, `Toolbox::getURLContent()`, `Toolbox::getGuzzleClient()` por `Glpi\Toolbox\HttpClient` (`new HttpClient($context, $options)` → `->request()`/`->get()`/`->post()`/`->stream()`). Também removidas: `Toolbox::isUrlSafe()`, `Toolbox::seems_utf8()`, `Toolbox::sendFile()`, `Toolbox::addslashes_deep()`/`stripslashes_deep()` (já não deviam ser usadas no 11).
8. Ajustar referências a classes removidas: `KnowbaseItemCategory` (e right `knowbasecategory`), `Timer`, `ComputerAntivirus` → `ItemAntivirus`, `ComputerVirtualMachine` → `ItemVirtualMachine`, `Item_Plug`/`Pdu_Plug`, `Glpi\Toolbox\Sanitizer`. `QueryExpression`/`QueryParam`/`QuerySubQuery`/`QueryUnion` globais idem.
9. Remover chamadas a `Plugin::getWebDir()` — **removida** (era `@deprecated 11.0.0`). Usar caminho literal `/plugins/<nome>/...` ou `$CFG_GLPI['root_doc'] . '/plugins/<nome>/...'`.
10. Corrigir sobrescritas de `can()` / `canGlobal()` em subclasses de `CommonDBTM`/`CommonGLPI` — ganharam o parâmetro `null &$reauth_needed = null` na última posição; a assinatura da sobrescrita precisa casar.
11. Ajustar chamadas a `Migration::displayTitle()`, `displayWarning()`, `displayError()`, `addNewMessageArea()`, `setOutputHandler()` — todas removidas. Usar `$migration->addMessage()` / logging padrão.
12. Ajustar `DBmysql`: `query()`, `queryOrDie()`, `doQueryOrDie()`, `insertOrDie()`, `updateOrDie()`, `deleteOrDie()`, `truncate()`, `truncateOrDie()`, `guessTimezone()` — removidos. Usar `$DB->doQuery()`, `$DB->insert()`, `$DB->update()`, `$DB->delete()`.
13. Revisar chamadas a `countElementsInTable()`, `countDistinctElementsInTable()`, `getAllDataFromTable()` (e os métodos equivalentes em `DbUtils`) — assinaturas mudaram e toda a `DbUtils` passou a ter tipos estritos. Remover uso do parâmetro `$order` em `getAllDataFromTable()`.
14. Remoções além das listadas no CHANGELOG do GLPI: `Html::ajaxFooter/cleanInputText/cleanPostForTextArea/displayErrorAndDie/entities_deep/entity_decode_deep/glpi_flush/jsGetDropdownValue/jsGetElementbyID/jsSetDropdownValue` e os helpers de progress bar; `CommonITILObject::assign()` e `showSatisfactionTabContent()`; `Ticket_Ticket::getLinkedTicketsTo()` (→ `getLinkedTo()`, coluna `items_id`); `Ticket::getDatasToAddOLA()/olaAffect()`; `LevelAgreement::getDataForTicket()`; `ITILFollowup::ADD{ALL,GROUP,MY}TICKET`; `Search::joinDropdownTranslations()`; `Reminder`/`SavedSearch::addVisibilityRestrict()`; `Glpi\Http\Response::send*()`; `Glpi\Plugin\HookManager::enableCSRF()`; Twig `verbatim_value` e `get_plugin_web_dir()`; `Auth::getErr()`.

## Segurança (silenciosamente quebrado ou inseguro se ignorado)

15. **Remover todo campo `_glpi_csrf_token`** de formulários Twig/HTML e todo header `X-Glpi-Csrf-Token` de chamadas `fetch`/`$.ajax`. A proteção CSRF passou a ser validação de header (`Sec-Fetch-Site`/`Origin`) no `CheckCsrfListener` do kernel, aplicada a todo método com corpo. Manter o campo não quebra o POST (o token é ignorado), mas mascara código morto e a `csrf_token()` será removida no GLPI 13 (no 12.0.0 ela devolve `""` e chama `Toolbox::deprecated()` a cada render). **Manter** `X-Requested-With: XMLHttpRequest` — o core ainda o usa (`Toolbox::isAjax()`). Só `Sec-Fetch-Site` `same-origin`/`none` passam; `same-site`/`cross-site` → 403; proxy que reescreve `Host` quebra a validação por `Origin`.
16. Remover `csrf_token()` dos templates Twig, `fields.csrfField()` (macro em `fields_macros.html.twig`) e `getAjaxCsrfToken()` no JS — todos depreciados no 12.
17. Remover `Session::getNewCSRFToken()`, `Session::validateCSRF()`, `Session::checkCSRF()`, `Session::cleanCSRFTokens()` se referenciados — depreciados; a validação é feita pelo kernel antes da rota.
18. Para itemtypes de plugin que manipulam dados sensíveis, avaliar adoção do "sudo mode": sobrescrever `protected static CommonGLPI::itemTypeRequiresReauthentication()` (retorna `false` por padrão) e, em Controller, chamar `checkReAuthenticationOrRedirect()` pela classe do itemtype (`MeuItem::…`), não pela `CommonGLPI`. **`isUserReauthenticationNeeded()` e `checkReAuthenticationOrRedirect()` são `final` no 12.0.0** — sobrescrevê-los é erro fatal. Nunca implementar prompt de senha próprio — o fluxo (`ReAuthManager` + estratégias + `ReAuthReplayListener`) é do core.
19. Documentos: `glpi_documents_items` ganhou a coluna `is_private`; código que replica anexos entre itens e não a copia torna públicos os anexos privados.
20. `Profile` agora exige re-autenticação (`itemTypeRequiresReauthentication()` = `true`) — fluxos de plugin que gravam perfis passam pelo "sudo mode". O GA adicionou a estratégia **CAS** (`ReAuthStrategyEnum::CAS`); endpoint de plugin dedicado a uma estratégia deve checar `ReAuthManager::isSelectedStrategy()` — estar disponível para o usuário não garante que seja a exigida.

## Hooks

21. Remover `Hooks::CSRF_COMPLIANT` / `$PLUGIN_HOOKS['csrf_compliant']` — a constante foi **removida** (no 11 estava `@deprecated`, ainda existia).
22. Trocar `Hooks::SHOW_IN_TIMELINE` / `show_in_timeline` por `Hooks::TIMELINE_ITEMS` / `timeline_items` — a constante antiga foi removida.
23. Hooks novos disponíveis (opcionais): `Hooks::POST_PREPAREUPDATE` (`post_prepareupdate`), `Hooks::GET_CONTENT_TEMPLATE_PARAMETER`, `Hooks::GET_CONTENT_TEMPLATE_VALUE`, `Hooks::INVENTORY_GET_CONFIGURATION`.

## Comportamental

24. `Session::haveRight(string $module, int $right): bool` agora é tipada e retorna **somente** booleano. Código que comparava o retorno com inteiros ou usava `===` contra não-booleano precisa ajuste.
25. Se o plugin lida com `CommonITILValidation`: o campo `users_id_validate` **não é mais suportado** — usar `items_id_target` + `itemtype_target`. (No 11 `users_id_validate` ficava `0` até aprovação; no 12 deixa de existir como via de acesso.)
26. `CommonITILObject::getTimelineItems()` não aceita mais os parâmetros `bypass_rights`, `expose_private`, `is_self_service`. Revisar chamadas em plugins que montam timeline própria.
27. Massive actions: `Ticket:link_to_problem` e `Ticket_Ticket:add` foram removidas — usar `CommonITILObject_CommonITILObject:add`.
28. `Document::getDownloadLink()` não aceita mais parâmetros de URL adicionais; `Document::send()` removido.
29. Base de conhecimento reestruturada: `KnowbaseItemCategory` virou artigo; tabela `glpi_knowbaseitems_knowbaseitemcategories` renomeada para `glpi_knowbaseitems_knowbaseitems` (colunas `knowbaseitems_id` filho / `knowbaseitems_id_parent` pai); a coluna `knowbaseitemcategories_id` de `ITILCategory` e `TaskCategory` virou `knowbaseitems_id`. `KnowbaseItem::getForCategory()` → `KnowbaseItem::getChildrenArticles()`. Plugins que leem/gravam categorias de KB diretamente precisam reescrever essa parte.
30. `KnowbaseItem_KnowbaseItemCategory` renomeada para `KnowbaseItem_KnowbaseItem`. `KnowbaseItem_Comment` e `KnowbaseItem_Revision` agora são `final` — não estender.
31. Detecção de IP de cliente atrás de proxy reverso passou a exigir duas constantes de instalação (em `config/local_define.php`; o plugin não consegue defini-las):
    - `GLPI_TRUSTED_REVERSE_PROXIES` — IPs ou faixas CIDR; com proxies encadeados, listar todos; aceita os valores especiais `REMOTE_ADDR` e `PRIVATE_SUBNETS`.
    - `GLPI_REVERSE_PROXY_HEADERS` — `X-Forwarded-For` por padrão; `Forwarded` e `X-Forwarded-*` também suportados. Listar só os headers que o proxy realmente trata.
    - Plugin que lê `$_SERVER['REMOTE_ADDR']` para lógica própria deve usar `Glpi\Toolbox\IPUtilities::getClientIP()` (usa `Request::getClientIp()` do Symfony; devolve `null` quando os headers de proxy confiáveis divergem).
    - Depreciados no GA: `IPUtilities::isCidrMatch()` → `isIPInList()`; `IPUtilities::isTrustedReverseProxy()` → `Request::isFromTrustedProxy()`.
32. Remoção do `DBSlave` / réplica de leitura: `DBConnection::switchToMaster()`/`switchToSlave()`, `DBmysql::$slave`/`isSlave()`, `DBSlave` — depreciados. Plugins que forçavam master/slave devem parar.
33. CronTask: novos status `ERROR` (após 5 falhas) e `ABORTED`, backoff, coluna `next_run` (`NULL` após o upgrade → toda ação roda na 1ª execução), `getStateName()` sem mapeamento para os novos status; o runner é `php front/cron.php`. Ver `architecture.md` ("CronTask").
34. HTTP de saída: `Toolbox::callCurl()` do 11 aceitava rede privada; o `Glpi\Toolbox\HttpClient` bloqueia fora de `GLPI_SERVERSIDE_URL_ALLOWED_PRIVATE_NETWORKS_CONTEXTS` (constante da instalação, em `config/local_define.php`; o plugin não consegue se auto-registrar). Integrações com serviços internos exigem ajuste de ambiente.
35. `$CFG_GLPI` agora é `Glpi\Config\ConfigContainer` (`ArrayAccess`); `front/helpdesk.faq.php` sem `id` redireciona ao artigo raiz da KB; a inclusão de `inc/includes.php` está depreciada; `CommonITILSatisfaction::showSatisactionForm()` (com typo) → `showSatisfactionForm()`.
36. Falso positivo do CHANGELOG do GLPI: `DbUtils::getEntitiesRestrictRequest()` consta como removido mas **existe** no 12.0.0 (`getEntitiesRestrictCriteria()` também).
37. `Rule::canViewItem()`/`canUpdateItem()`/`canPurgeItem()` passam a exigir que o `sub_type` da regra seja a classe que a carregou: uma subclasse concreta (ex.: `RuleTicket`) que abre regra de outro `sub_type` (ex.: `RuleAsset`) tem acesso negado. A `Rule` base não sofre a checagem. Instanciar a subclasse correspondente ao `sub_type`.
38. `/ajax/treebrowse.php` saiu da lista `STRATEGY_NO_CHECK` do Firewall e passa a seguir a estratégia padrão — revisar plugins que o chamam de contextos anônimos.

## Frontend / JS

39. Libs JS removidas do core — trocar se o plugin dependia delas: `jquery.fancytree` → `Wunderbaum`; `jquery.rateit` → componente `components/form/rating.html.twig` do core (módulo carregado por `<script type="module">`; conferir em conteúdo inserido via `.html()`); `diff-match-patch`, `hotkeys-js`, `jquery-prettytextdiff` — sem substituto direto, reimplementar ou remover a feature.
40. `escapeMarkupText()` (JS) depreciada. Módulos JS removidos: `Forms/FaIconSelector`, `Knowbase`.
41. `Html::link()` depreciada (ainda presente) — preferir `<a>` explícito com `path()`/caminho literal.
42. Select2 passou para a 4.1.0 — conferir plugins que estendem o componente.

## Opcional / modernização (não bloqueia a migração)

43. Adotar `AbstractController::validateInputHasExactKeys(array $input, array $keys)` para validar payload de Controller em vez de checagem manual.
44. Migrar para os Twig Components do core (`Alert` — `Info`/`Success`/`Warning`/`Danger`, `Mfa/CodeInput`) onde o plugin renderiza alertas próprios.
45. High-Level API v3.0.0 disponível — se o plugin registra schemas/endpoints via `api_controllers`/`redefine_api_schemas`, revisar contra a v3.
46. Substituir `league/csv` por `phpoffice/phpspreadsheet` e `guzzlehttp/guzzle` por `Glpi\Toolbox\HttpClient` em dependências diretas do `composer.json` do plugin.

## Ferramental

- **`glpi-project/rector-glpi`** — `composer require --dev glpi-project/rector-glpi`, depois registrar `\RectorGlpi\Set\GlpiSetList::GLPI_DEFAULT_SET` no `rector.php`. Conferido na release 1.1.1 (2026-09-17): o set só ativa quando o Rector roda dentro de uma instalação GLPI (`plugins/<chave>/vendor/...`, lendo `version/` do core) com versão ≥ 12.0.0-dev, e aplica **duas** regras, ambas de modernização (não corrigem quebras):
  - `ReplaceCommonGlpiGetTypeByClassConstantRector` — troca `Foo::getType()` por `Foo::class` onde equivalente.
  - `ReplaceHardcodedRightnameByCommonDBTMRightnamePropertyRector` — troca string de rightname literal pela propriedade `::$rightname` da classe.
  Não há regra para CSRF, `Html::`, `Query*`, `Toolbox::` nem para as propriedades tipadas — esses itens são manuais.
- **`glpi-project/phpstan-glpi`** — detecta estaticamente boa parte dos itens "Bloqueantes" (assinaturas alteradas, classes e métodos removidos). Rodar antes e depois da migração.
- Não existe set de Rector que automatize a remoção de CSRF nem as substituições de `Html::`/`Toolbox::` — planejar essa parte como edição manual guiada por `grep`.

## Referência cruzada

Para o modelo de destino de cada item (sintaxe correta, exemplos completos), consultar `domains/glpi-12/SKILL.md` e `domains/glpi-12/references/architecture.md`. Para comparar com o comportamento de origem, `domains/glpi-11/SKILL.md` e `domains/glpi-11/references/architecture.md`.
