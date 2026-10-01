# Pendências

Tarefas e dívida técnica em aberto. Cada entrada: data de registro, contexto suficiente
para retomada sem reinvestigação, dono e critério de "pronto".

---

## Revalidar a skill `domains/glpi-12` contra o GLPI 12.0.0 GA

- **Registrado em:** 2026-09-07
- **Dono:** sem dono
- **Contexto:** A árvore `fullstack-development/skills/domains/glpi-12/` (introduzida na v0.7.0)
  foi construída a partir da comparação direta do código-fonte do **GLPI 12.0.0 RC**
  (`../glpi12`, version `12.0.0`) com o 11.0.8 (`../glpi11`; o conteúdo da atualização de 2026-09-30 compara com o 11.0.10), mais a seção *API changes* do
  `CHANGELOG.md` do RC. Não há documentação oficial de desenvolvimento de plugins para o 12.
  Na análise, o milestone 12.0.0 (`glpi-project/glpi` milestone 74) estava 98% concluído
  (335 fechados / 4 abertos), due **2026-10-06**, com a superfície de API efetivamente congelada.
- **Atualização 2026-09-30:** a skill foi conferida contra o **12.0.0-rc3** (migração de 8 plugins
  reais) e corrigida (propriedades tipadas, re-autenticação `final`, CSRF, `version_compare` no RC,
  prepared statements, CronTask — ver `CHANGELOG.md`, seção "Não lançado"). A revalidação contra o GA
  continua pendente e segue as ações abaixo.
- **Itens em aberto da revisão de 2026-09-30:** (a) confirmar no core o padrão de correção de
  `addWhere()`/`addHaving()` com *prepared statements* (hoje marcado "a confirmar no GA" nas
  skills); (b) confirmar se `checkReAuthenticationOrRedirect()` é estático e depende de
  `static::itemTypeRequiresReauthentication()` (as skills orientam chamar pela classe do itemtype).
- **Risco conhecido:** itens de **estrutura** (Firewall, Controllers, roteamento legado,
  `public/`, PSR-4, `plugin_<nome>_boot()`, query builder) são estáveis e não devem mudar.
  Itens de **detalhe** podem divergir no GA: assinaturas exatas de método, lista final de
  classes/métodos removidos, nomes de constantes de hook novas, comportamento do "sudo mode"
  (`Glpi\Security\ReAuth\*`).
- **Ação:** quando o 12.0.0 GA for publicado —
  1. Substituir `../glpi12` pelo código do GA e refazer os `diff` que embasaram
     `glpi-12/references/architecture.md` e `glpi-12/references/migration-11-to-12.md`
     (seções "Bloqueantes" e "Comportamental" em especial).
  2. Conferir o `CHANGELOG.md` do GA (`## [12.0.0]`) contra o do RC — em particular a
     subseção *Removed* de `API changes` e os 4 itens que estavam abertos no milestone.
  3. Reconferir o set `Glpi120x` de `glpi-project/rector-glpi` (na análise: só 2 regras,
     `ReplaceCommonGlpiGetTypeByClassConstantRector` e
     `ReplaceHardcodedRightnameByCommonDBTMRightnamePropertyRector`) — se ganhar regras de
     CSRF/`Html::`/`Query*`, atualizar a seção "Ferramental" do guia de migração.
  4. Rodar `grep -rn 'RC3\|rc3' fullstack-development/skills/domains/glpi-12` e reconferir cada
     afirmação específica do RC3 contra o GA (CronTask `???`, nome de constantes, comportamento
     sem `Sec-Fetch-Site`/`Origin`, `GLPI_PLUGINS_PATH`).
  5. Remover as ressalvas "derivado de RC / revalidar contra o GA" dos cabeçalhos de
     `glpi-12/SKILL.md`, `glpi-12/references/architecture.md` e
     `glpi-12/references/migration-11-to-12.md`, e a nota correspondente em
     `fullstack-development/CLAUDE.md` (§Assimetrias intencionais do conjunto GLPI) e no
     `README.md`.
- **Critério de pronto:** `diff` do `CHANGELOG.md` GA × RC sem impacto não incorporado em
  plugins, e as três skills sem ressalva de RC.

---

## Promover a nota de Vue 3.6 (Vapor Mode) em `languages/vue` quando o 3.6 estabilizar

- **Registrado em:** 2026-09-07
- **Dono:** sem dono
- **Contexto:** A skill `fullstack-development/skills/languages/vue` foi atualizada para o Vue
  **3.5.x** (estável em 2026-09; `defineModel`, reactive props destructure, `useTemplateRef`,
  `useId`, `onWatcherCleanup`, `WatchHandle`, lazy hydration). O Vue **3.6** (Vapor Mode +
  reescrita de `@vue/reactivity` sobre alien-signals) estava em `3.6.0-rc.7` na data do registro —
  entrou na skill apenas como seção "Horizonte" no fim de `references/performance.md`, com aviso
  explícito de RC e instrução de **não gerar código Vapor por padrão**.
- **Ação:** quando o Vue 3.6.0 estável for publicado —
  1. Atualizar a linha "Versões de referência" de `languages/vue/SKILL.md` e as notas de cabeçalho
     dos `references/*` afetados.
  2. Promover a seção "Horizonte: Vue 3.6" de `references/performance.md` a conteúdo normal (opt-in
     Vapor, `createVaporApp`, `vaporInteropPlugin`, lista de recursos não suportados).
  3. Reavaliar as recomendações de performance à luz do Vapor — `v-memo` **não existe** em Vapor
     Mode; a tabela de técnicas e o checklist precisam distinguir VDOM × Vapor.
  4. Rever se o conjunto GLPI (`glpi-*/vue`) herda algo. Situação apurada em 2026-09-07: os cores
     GLPI 11.0.8 e 12.0.0-rc1 empacotam Vue **3.5.x** (`window._vue`), e o GLPI 10 não traz Vue no
     core (o plugin embarca o próprio, com piso 3.5 recomendado nas skills). Nenhum herda Vapor
     hoje — revisitar apenas quando algum core GLPI passar a empacotar Vue 3.6.
- **Critério de pronto:** `languages/vue` sem a ressalva "RC / não usar em produção" e com o
  Vapor Mode documentado como recurso normal, versão-alvo.
