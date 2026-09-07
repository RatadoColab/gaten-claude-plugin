# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não publicado]

Atualização da skill `languages/vue` para o baseline **Vue 3.5.x** (estável em ago/2026), fechando
um gap desde ~3.3. O `SKILL.md` ganhou a linha de versões de referência (Vue 3.5.x / Pinia 4.x /
Vue Router 5.x), a tabela "Macros de `<script setup>`" (`defineProps`, `defineEmits`, `defineModel`,
`defineSlots`, `defineOptions`, `defineExpose` com a versão de cada uma) e a mini-tabela
"Utilitários de composição (3.5+)" (`useTemplateRef`, `useId`, `onWatcherCleanup`, `WatchHandle`).
`references/components.md`: reactive props destructure com defaults nativos passa a padrão
recomendado (o `withDefaults` permanece documentado como alternativa suportada — não é deprecado);
`v-model` reescrito em torno de `defineModel`
(model nomeado, `[model, modifiers]` com `set()`), com o par manual `modelValue` +
`update:modelValue` mantido como "compatibilidade ≤ 3.3"; novas seções `useTemplateRef`, `useId`
(apontando acessibilidade para `domains/ui-components` e `domains/forms`), `defineSlots` e a prop
`Teleport defer`. `references/composition-api.md`: `onWatcherCleanup` e `WatchHandle`
(`pause`/`resume`/`stop`) documentados; corrigido o snippet do `useFetch` (faltavam os imports de
`toValue` e `type Ref`; cleanup migrado para `onWatcherCleanup` com a nota de registro síncrono).
`references/state-management.md` e `references/routing.md` ganharam nota de versão (Pinia 4 é
ESM-only e exige `@vue/devtools-api` instalado ao lado; Vue Router 5 não tem breaking changes vindo
do 4) e o `routing.md` seções curtas sobre roteamento por arquivos (`vue-router/unplugin`) e Data
Loaders experimentais. `references/performance.md`: lazy hydration de `defineAsyncComponent`
(`hydrateOnVisible`/`hydrateOnIdle`/`hydrateOnMediaQuery`/`hydrateOnInteraction`, só SSR) e seção
"Horizonte: Vue 3.6" cobrindo Vapor Mode e a reescrita de reatividade sobre alien-signals — marcada
como **RC, não usar em produção**, com a lista do que o Vapor não suporta (Options API, `v-memo`,
template refs de componente, `getCurrentInstance`, `app.config.globalProperties`, eventos
`@vue:*`). Nenhum conteúdo removido — os padrões pré-3.5 permanecem rotulados como legado. Duas
pendências registradas em `PENDENCIAS.md` (promover a nota de 3.6 no GA; verificar a versão de Vue
empacotada pelos cores GLPI 10/11/12, que hoje apontam para `languages/vue` sem ressalva de
versão). Sem bump de versão em `plugin.json`.

Nova árvore de skills `domains/glpi-12` para desenvolvimento e migração de plugins **GLPI 12**,
espelhando a estrutura de `glpi-10`/`glpi-11` (`SKILL.md` + sub-skills `ajax-handlers`,
`form-templates`, `plugin-creation`, `vue` + `references/architecture.md` e
`references/migration-11-to-12.md`). O conteúdo foi extraído da comparação direta do código-fonte
do GLPI 12.0.0 RC com o 11.0.8 — não há documentação oficial de plugins para o 12. A arquitetura
de plugins **não mudou** entre 11 e 12 (Firewall, Controllers, `public/`, PSR-4, query builder,
`plugin_<nome>_boot()` idênticos); o `glpi-12/SKILL.md` cobre apenas os deltas: PHP mínimo 8.3,
**CSRF por validação de header** no kernel (fim do token por requisição — remover `_glpi_csrf_token`,
`csrf_token()`, `X-Glpi-Csrf-Token`, `fields.csrfField()`), re-autenticação "sudo mode"
(`Glpi\Security\ReAuth\*`, `CommonGLPI::isUserReauthenticationNeeded()`), remoção dos aliases de
raiz `Query*` (só `Glpi\DBAL\*`), remoção de `Plugin::getWebDir()`, `Html::displayNotFoundError()`/
`displayRightError()`, `Toolbox::callCurl()` (→ `Glpi\Toolbox\HttpClient`), `KnowbaseItemCategory`,
`Timer`, `ComputerAntivirus`/`ComputerVirtualMachine`, e das constantes de hook `CSRF_COMPLIANT`
e `SHOW_IN_TIMELINE`; novos hooks `POST_PREPAREUPDATE`, `GET_CONTENT_TEMPLATE_PARAMETER`/`_VALUE`,
`INVENTORY_GET_CONFIGURATION`; Twig Components (`Alert`, `Mfa`). O salto pelo GLPI 11 é obrigatório
na migração — não há caminho 10→12 direto. Ferramental: `glpi-project/rector-glpi` (set `Glpi120x`)
traz só 2 regras de modernização, nenhuma cobre CSRF/`Html::`/`Query*` — o grosso é manual.
`agents/backend-dev.md` passou a detectar as três versões; regra "carregar apenas uma árvore"
estendida a três. **Derivado de um RC** — revalidar contra o 12.0.0 GA (previsto 2026-10-06),
pendência registrada em `PENDENCIAS.md` na raiz. Sem bump de versão em `plugin.json`.

Atualização da skill `domains/security` para o **OWASP Top 10:2025** (RC nov/2025, final jan/2026),
que reordena as categorias, absorve SSRF no A01, promove a cadeia de suprimentos a A03 (*Software
Supply Chain Failures*) e cria a categoria nova A10 (*Mishandling of Exceptional Conditions*).
Nenhum conteúdo foi removido — o material existente foi remapeado para a nova taxonomia. Requisitos
correlatos revisados contra as fontes correntes (set/2026): NIST SP 800-63B-4, OWASP Password
Storage / HTTP Headers / CSP Cheat Sheets, PCI-DSS v4.0.1, draft IETF de headers de rate limit,
ASVS 5.0, SLSA v1.1+. Sem bump de versão em `plugin.json`.

Atualização da skill `languages/python` para o baseline **Python 3.14** (lançado out/2025), fechando
um gap de três versões — o corpo estava preso ao 3.11. Adotado o modelo de alvo único das skills
`golang`/`nodejs` (§"Runtime e Versões" com matriz de suporte, §"Novidades 3.11 → 3.14" apontando
para um catálogo único). Além das features novas, corrigida orientação que se tornou incorreta: o
conselho de usar `from __future__ import annotations` "em todo arquivo" contradiz a PEP 649 (3.14),
que torna as anotações lazy por padrão sem convertê-las em string; a sintaxe de genéricos foi migrada
para a PEP 695 (`def f[T]`, `class C[T]`, `type X = ...`); a tabela de concorrência deixou de tratar
o GIL como absoluto (PEP 779 — free-threading suportado). Dois references renomeados
(`modern-features.md` → `patterns.md`, `async-patterns.md` → `concurrency.md`) e dois novos
(`python314-features.md`, `tooling.md`). Sem bump de versão em `plugin.json`.

Generalização da skill `languages/php` para a faixa **8.3–8.5**. O corpo do `SKILL.md` deixou de
ser preso ao PHP 8.3: passa a cobrir apenas o que é comum às três versões, com uma §"Detecção de
Versão-Alvo" que segue o mesmo contrato das skills `glpi-10`/`glpi-11` (lê `composer.json` →
ambiente → sintaxe no código → pergunta, sem default). Recursos e quebras específicos de versão
foram movidos para `references/` — dois catálogos de features novos (8.4 e 8.5) e dois guias de
migração baseados no manual oficial (`migration84.php`, `migration85.php`). Sem bump de versão em
`plugin.json`.

Novo command `new-bugfix` e skill `domains/debugging` para cobrir a **correção de bugs**, que até
agora entrava pelo `new-feature` — um fluxo *spec-first* inadequado para um comportamento que já
existe e está errado. O `new-bugfix` tem fluxo **diagnóstico-first** simétrico ao `new-feature` (6
fases, revisão paralela de domínio, portão de aprovação), mas com o eixo invertido: o artefato
central é o laudo de causa raiz em `.claude/specs/bugfix-<id>.md`, não a spec. O `spec-dev`
estrutura o laudo (Fase 3) e consolida o Plano de Correção (Fase 5); `backend-dev`/`frontend-dev`/
`mobile-dev`/`devops-cicd` revisam em paralelo (Fase 4), cada um confirmando ou refutando a causa
raiz na sua camada; o `devops-cicd` só entra sob a regra "se, e apenas se" — a falha ter de ser de
pipeline/build/deploy/infra, não uma aplicação que apenas roda em container. A Fase 6 exige teste
de regressão **fail-before/pass-after**. A skill `domains/debugging` torna o método reaproveitável
pelos quatro agentes de implementação (linha condicional em `## Skills a carregar`). Fronteiras
declaradas para não duplicar: instrumentação fica em `domains/observability`, sintaxe de teste nos
`languages/*/references/testing.md`, vulnerabilidade em `domains/security`. Sem `domains/testing`
por ora — registrado como gatilho de split futuro. Sem bump de versão em `plugin.json`.

### Adicionado

#### Commands
- `commands/new-bugfix.md` — correção de bug com fluxo diagnóstico-first: detecção de escopo
  (backend/frontend/mobile/devops com a regra "se, e apenas se" para DevOps), Fase 1 reprodução e
  delimitação com portão duro (não avançar sem reprodução ou evidência), Fase 2 diagnóstico de
  causa raiz por hipótese/refutação, Fase 3 laudo estruturado pelo `spec-dev` em
  `.claude/specs/bugfix-<id>.md`, Fase 4 revisão paralela de domínio, Fase 5 Plano de Correção
  consolidado pelo `spec-dev` (correção mínima × estrutural, fora de escopo → `PENDENCIAS.md`),
  Fase 6 correção pelo agente da camada com teste de regressão fail-before/pass-after

#### Skills novas
- `domains/debugging/SKILL.md` — método de diagnóstico transversal: reprodução determinística,
  hipótese e refutação, isolamento (`git bisect`, delta debugging), leitura de evidência (stack
  trace de fora para dentro, erro de origem × propagado), 10 classes recorrentes de defeito,
  correção mínima × estrutural, teste de regressão por nível da pirâmide; §"Fronteiras com Outras
  Skills" contra `observability`, `languages/*/testing.md` e `security`
- `domains/debugging/references/root-cause.md` — protocolo passo a passo, checklist de bug que não
  reproduz (dados, timing, estado acumulado, ambiente, concorrência, permissão, rede), roteiro de
  `git bisect` (manual e `bisect run`), erros de diagnóstico a evitar
- `domains/debugging/references/regression-tests.md` — método fail-before/pass-after, escolha do
  nível na pirâmide, nomear o teste pelo defeito, casos de borda a cobrir junto, ponte para os
  `references/testing.md` de `python`/`php`/`golang`/`nodejs` via `../../../languages/`

#### Agentes
- `agents/backend-dev.md`, `frontend-dev.md`, `mobile-dev.md`, `devops-cicd.md` — linha condicional
  em `## Skills a carregar` para `domains/debugging`, carregada só quando a tarefa for diagnóstico
  de falha existente e não implementação nova

#### Skills existentes
- `languages/php/references/php84-features.md` — catálogo dos recursos do PHP 8.4 (property hooks,
  visibilidade assimétrica, `new X()->m()`, `#[\Deprecated]`, `array_find`/`array_any`/`array_all`,
  objetos lazy via Reflection, `mb_trim`/`RoundingMode`/`fpow`, `DateTime::createFromTimestamp()`,
  subclasses de PDO por driver)
- `languages/php/references/php85-features.md` — catálogo dos recursos do PHP 8.5 (operador pipe
  `|>`, `#[\NoDiscard]`, `clone($o, [...])`, closures em expressões constantes, atributos em
  constantes, `array_first()`/`array_last()`, `FILTER_THROW_ON_FAILURE`, extensão `URI`)
- `languages/php/references/migration-83-to-84.md` — checklist de migração 8.3 → 8.4 por severidade
  (quebras em runtime, depreciações — com destaque para parâmetros implicitamente nullable —,
  mudança do default do JIT, roteiro de execução)
- `languages/php/references/migration-84-to-85.md` — checklist de migração 8.4 → 8.5 (mudanças de
  `PDO::FETCH_*`, magic methods legados, casts não canônicos, OPcache sempre embutido/carregado,
  roteiro de execução)
- `languages/python/references/python314-features.md` — catálogo das novidades 3.12 → 3.14 (PEP 695,
  `@override`, PEP 701, `TypeIs`, defaults de TypeVar, `ReadOnly`, `warnings.deprecated`, PEP 649/749
  anotações lazy + `annotationlib`, PEP 750 t-strings com exemplos de SQL/HTML, PEP 758, PEP 765,
  PEP 734 subinterpretadores, PEP 779 free-threading, PEP 784 zstd, PEP 768, introspecção asyncio,
  `pathlib.Path.copy/move`) + seção "O que muda ao subir de 3.11" (anotações, `forkserver`,
  `ByteString` removido, extensões C)
- `languages/python/references/tooling.md` — toolchain 3.14: `uv` (pacotes, venv, versão do Python,
  `uv.lock`), `ruff` (lint + format), `mypy --strict`/`pyright`/`ty`, `pyproject.toml` de referência,
  pre-commit, Docker (`python:3.14-slim` e build free-threaded), ponteiro de supply chain para
  `domains/security` e `domains/devsecops`
- `domains/security/references/llm-security.md` — segurança de aplicações que consomem LLM, ancorado
  no OWASP Top 10 for LLM Applications (prompt injection, excessive agency, saída do modelo como
  input não confiável, isolamento multi-tenant em RAG, quotas de custo/token); nova §"Segurança de
  Aplicações com LLM" no `SKILL.md` aponta para o reference
- `domains/security/references/web-defenses.md` — nova §"Cookies e Sessão" (prefixo `__Host-`,
  `SameSite`, `Partitioned`/CHIPS, `Clear-Site-Data` no logout)
- `domains/security/SKILL.md` — categoria A10 e subcategoria SSRF (dentro de A01) na tabela-resumo;
  itens de fail-closed, SBOM/proveniência e headers cross-origin no checklist de revisão

### Alterado

#### Skills existentes
- `domains/security/SKILL.md` — `description` e §Visão Geral ancoradas em OWASP Top 10:2025; tabela
  reescrita nas 10 categorias 2025 com mitigação-chave por linha; §Senhas alinhada ao NIST SP
  800-63B-4 (mínimo 15 chars como autenticador único / 8 com MFA, suportar ≥64, sem regras de
  composição nem KBA, passkeys/WebAuthn); §Rate Limiting passa a `RateLimit`/`RateLimit-Policy`;
  §Referências com Top 10:2025, ASVS 5.0 e LLM Top 10
- `domains/security/references/owasp-top10.md` — reescrito na ordem 2025: A01 incorpora SSRF; A03
  expandido (pipeline/registry/IDE, casos SolarWinds e worm Shai-Hulud, rollout escalonado); A04
  com a tabela de perfis Argon2id do OWASP e o limite de 72 bytes do bcrypt; A07/A09 renomeados;
  A10 nova; estatística de A01 atualizada para o ciclo 2025
- `domains/security/references/web-defenses.md` — CSP estrita com `'strict-dynamic'`, `report-to` +
  `Reporting-Endpoints`, nota de Trusted Types e de `frame-ancestors` tornando `X-Frame-Options`
  obsoleto; §Supply Chain ampliada (proveniência, `npm audit signatures`, OSV-Scanner, OpenSSF
  Scorecard, SBOM CycloneDX/SPDX, pin por digest, CVSS v4.0)
- `domains/security/references/*.py` — cabeçalhos renumerados para a taxonomia 2025
  (`authentication.py` A02→A04 com perfis Argon2id alternativos e checagem do limite de 72 bytes do
  bcrypt; `ssrf-validation.py` A10→A01/SSRF; `injection-prevention.py` A03→A05)
- `domains/devsecops/SKILL.md` — referências cruzadas para "OWASP Top 10:2025"; supply chain
  identificada como A03:2025; proveniência de pacotes e SLSA v1.1+ na §Supply Chain
- `domains/api-rest/SKILL.md` e `references/http-patterns.md` — headers `RateLimit`/`RateLimit-Policy`
  como forma corrente (formato `RateLimit-Limit/-Remaining/-Reset` marcado como legado); TLS passa a
  "1.3 preferencial, 1.2 mínimo"; HSTS com `max-age=63072000; preload`
- `skills/base/devops-base/SKILL.md`, `README.md` (plugin) — menção a "OWASP Top 10:2025"
- `languages/php/SKILL.md` — `description` e corpo generalizados para 8.3–8.5; nova §"Detecção de
  Versão-Alvo"; §"PHP 8.3 — Principais Recursos" substituída por §"Recursos por Versão" (tabela com
  a coluna `Mín.` cobrindo 8.3/8.4/8.5); tabela de referências ampliada com os quatro arquivos novos
- `languages/php/references/*.md` — cabeçalhos "PHP 8.3.x" neutralizados para "PHP 8.3+ (8.3, 8.4 e
  8.5)" em `type-system.md`, `patterns.md`, `testing.md`, `security.md`, `performance.md`;
  `composer.md` com `"php": "^8.4"` nos exemplos e nota para espelhar a versão-alvo; `performance.md`
  com bloco de mudanças de OPcache/JIT por versão; `security.md` anotando `PASSWORD_ARGON2` (8.4) e
  `FILTER_THROW_ON_FAILURE` (8.5); `php83-features.md` com ponteiro para `clone` do 8.5
- `languages/python/SKILL.md` — `description` e corpo movidos de "3.11+" para o baseline 3.14; H1
  "(3.14.x)"; nova §"Runtime e Versões" (matriz 3.14–3.11); §"Python 3.10–3.11 — Principais Recursos"
  substituída por §"Novidades 3.11 → 3.14" (tabela `Recurso | Desde | Resumo`); §Sistema de Tipos com
  exemplo PEP 695 e linhas para `type X`, `TypeIs`, `@override`; §Tratamento de Erros com PEP 758 e
  PEP 765; nova §Ferramentas (uv/ruff/mypy); §Anti-Patterns com f-string→t-string para SQL/HTML,
  `from __future__ import annotations` obsoleto, `TypeVar`+`Generic` → PEP 695; `requires-python`
  passa a `>=3.14`
- `languages/python/references/type-hints.md` — reescrito no baseline 3.14: §`from __future__ import
  annotations` substituída por §"Anotações em 3.14 (PEP 649)"; genéricos migrados para a sintaxe
  PEP 695 (bounds, constraints, defaults de TypeVar, `**P`), com a forma legada só como nota de
  leitura; novas seções `@override`, `TypeIs` × `TypeGuard`, `ReadOnly`; Pydantic fixado em ≥ 2.12;
  `from __future__ import annotations` removido de todos os blocos
- `languages/python/references/modern-features.md` → **`patterns.md`** (renomeado): deixa de ser
  changelog "3.10–3.11" e vira catálogo de idiomas no baseline 3.14 (match/case, `ExceptionGroup`/
  `except*`, `tomllib`, `Self`, walrus, comprehensions, context managers); removidas "Fine-grained
  Error Locations (3.11)" e "Performance — Python 3.11"; `TypeVarTuple` movido para `type-hints.md`
- `languages/python/references/async-patterns.md` → **`concurrency.md`** (renomeado + ampliado):
  tabela do modelo de concorrência com free-threading e `concurrent.interpreters`, sem tratar o GIL
  como absoluto; `asyncio.TaskGroup` promovido a primitiva preferida sobre `gather`; `Queue.shutdown()`
  (3.13), `eager_task_factory` (3.12), `python -m asyncio ps|pstree` (3.14); novas §"Free-threading
  (PEP 779)" e §"Subinterpretadores (PEP 734)" com ressalvas de maturidade
- `languages/python/references/testing.md` — cabeçalho para o baseline 3.14; `from __future__ import
  annotations` removido dos exemplos; nova §"Execução sob o build free-threaded" (`pytest-run-parallel`)
- `domains/security/SKILL.md` — item na §Defesas Web sobre t-strings (PEP 750) como defesa de injeção
  em Python 3.14+, apontando para `languages/python/references/python314-features.md`

#### Projeto
- `CLAUDE.md` — assimetria "security × devsecops" atualizada para :2025 e para os dois ângulos da
  cadeia de suprimentos; novo gatilho de split futuro `ai-security` ← `references/llm-security.md`;
  novo gatilho de split futuro `php-migration` ← guias de migração de `languages/php`; novo gatilho de
  split futuro `python-concurrency` ← `languages/python/references/concurrency.md`
- `CLAUDE.md` — contagem de commands (3 → 4) e de skills de domínio (22 → 23); `debugging` na lista
  de domínios; nova §"Assimetrias intencionais de `domains/debugging`" (fronteiras com
  `observability`, `testing.md` por linguagem e `security`); novo gatilho de split futuro `testing`
  ← `debugging/references/regression-tests.md`
- `README.md` (plugin) — entrada de `languages/python` expandida com o escopo 3.14 (tipos PEP 695,
  t-strings, asyncio, free-threading)
- `README.md` (plugin e raiz do repositório) — `/fullstack-development:new-bugfix` na tabela de
  commands; `domains/debugging` no catálogo de skills de domínio

### Corrigido

- `domains/security/references/owasp-top10.md` — **erro factual de conformidade**: a retenção de logs
  de segurança citava "no mínimo 1 ano conforme o Art. 15 do Marco Civil". O Art. 15 (provedores de
  aplicação) exige **6 meses**; o prazo de 1 ano é do Art. 13 (provedores de conexão). Texto
  corrigido e a distinção entre os dois artigos explicitada
- `domains/security/references/owasp-top10.md` — requisito de retenção do PCI-DSS citado como "Req.
  10.7"; na v4.0.1 é o **Req. 10.5.1** (12 meses, 3 meses imediatamente disponíveis)

## [0.6.1] - 2026-08-24

### Fix

- Correção de erro no parâmetro 'author' do arquivo plugin.json.

## [0.6.0] - 2026-08-24

Adição de duas skills de linguagem — `nodejs` e `golang` — cobrindo backend Node.js e Go, ausentes até então (Node.js estava diluído em `languages/javascript`, sem orientação de runtime; Go não tinha skill alguma). Conteúdo pesquisado contra as versões estáveis mais atuais de cada ecossistema (ago/2026): Node.js 26.x (TypeScript nativo estável via type stripping, test runner nativo, permission model) e Go 1.27.x (métodos genéricos, `encoding/json/v2` GA, `goroutineleak` estável). `nodejs` foi desenhada como skill de runtime — plataforma, módulos, toolchain, deploy —, deliberadamente separada de `languages/javascript`, que permanece responsável apenas pela sintaxe da linguagem; as duas se carregam juntas em projeto Node, evitando tanto a duplicação quanto a lacuna anterior.

### Adicionado

#### Skills de linguagem
- `languages/nodejs` — runtime Node.js 26.x/24.x LTS: ESM e resolução de módulos, TypeScript nativo (type stripping), `package.json`/npm/pnpm, test runner nativo (`node:test`), streams/`worker_threads`/`AsyncLocalStorage`, erros e graceful shutdown, comparativo de frameworks HTTP (Fastify/Hono/NestJS/Express), permission model e supply chain (`npm ci`, provenance, trusted publishing); refs: `modules-esm.md`, `typescript-runtime.md`, `testing.md`, `streams-workers.md`, `packaging-deploy.md`, `security-supply-chain.md`
- `languages/golang` — Go 1.27.x: toolchain e `go.mod`, nomenclatura e layout `cmd`/`internal`/`pkg`, erros (`errors.Is/As/Join`), concorrência (`context`, `errgroup`, `synctest`, detecção de vazamento de goroutine), `net/http` idiomático, `log/slog`, testes table-driven, novidades 1.25→1.27, `golangci-lint`/`govulncheck`; refs: `errors.md`, `concurrency.md`, `project-layout.md`, `testing.md`, `stdlib-http-slog.md`, `go127-features.md`, `tooling-build.md`

### Alterado

#### Agentes
- `backend-dev` — carrega `languages/nodejs` junto de `languages/javascript` em projeto Node, e `languages/golang` para Go
- `devops-cicd` — bullet de "scripts Node.js" passa a apontar `languages/nodejs`; adicionado `languages/golang` para CLIs/build em Go

#### Projeto
- `plugin.json` — versão `0.6.0`; corrigida a chave malformada `"author,"` (vírgula dentro do nome da chave) para `"author"`; valor convertido de array (fora do schema documentado, que só aceita objeto único ou string) para string única com os dois coautores
- `CLAUDE.md` — inventário de skills de linguagem (9→11); nova subseção "Assimetrias intencionais do conjunto JavaScript/Node" documentando a fronteira runtime × linguagem; Decisão de Design sobre JavaScript cobrindo Node.js revista; novo gatilho de split futuro (`typescript`, se crescer além de `nodejs`)
- `README.md` (raiz e do plugin) — catálogo de linguagens atualizado com `nodejs` e `golang`; versão do plugin atualizada para `0.6.0`; instrução de manifesto corrigida de `authors` (campo inexistente no schema) para `author`
- `commands/code-review.md`, `commands/new-feature.md` — detecção de stack e exemplos de skill de linguagem passam a citar Node.js/Go; `code-review.md` ganha bullet explícito para o par `javascript`+`nodejs`, em paridade com os bullets de Mobile/DevOps

#### Skills existentes
- `languages/javascript` — `description` delimita explicitamente sintaxe (esta skill) × runtime Node (`nodejs`); "Também consultar" passa a apontar `languages/nodejs/SKILL.md`
- `domains/containers/references/examples.md` — exemplo Dockerfile Node.js atualizado de `node:20-slim` para `node:24-alpine`, alinhado ao `engines.node >=24` recomendado por `languages/nodejs`
- `languages/nodejs/references/packaging-deploy.md` — Dockerfile multi-stage completo removido por duplicar `domains/containers/references/examples.md`; mantido apenas o delta específico de Node (pnpm, `--permission` no `CMD`, distroless); seção `--permission em Produção` removida por duplicar `references/security-supply-chain.md`
- `languages/golang` — corrigida frase truncada e descrição incorreta do modernizer `slicesbackward` em `references/go127-features.md`; corrigido exemplo de método genérico em `SKILL.md` (constraint `intType` inexistente); adicionado ponteiro para `domains/security/SKILL.md`

### Removido
- Árvore legada `skills/domains/glpi/` (duplicava `glpi-10/`, renomeada na 0.5.0 mas deixada no disco por engano)

## [0.5.0] - 2026-08-05

Divisão da skill `glpi` (GLPI 10.0.x) em duas árvores independentes e mutuamente exclusivas — `glpi-10` e `glpi-11` — para cobrir tecnicamente o GLPI 11 (estável desde out/2025) sem risco de o agente aplicar padrão de uma versão em plugin da outra. As 4 sub-skills (`plugin-creation`, `ajax-handlers`, `form-templates`, `vue`) foram duplicadas por versão em vez de compartilhadas, dado o número de rupturas reais entre 10 e 11 (fim de `include inc/includes.php`, `csrf_compliant` depreciado, `$DB->query()`/`queryOrDie()` proibidos, auto-sanitização removida, Controllers Symfony, assets em `public/`, Vue fornecido pelo core via `window._vue`). Conteúdo do `glpi-11` verificado contra o `CHANGELOG.md` e `src/Glpi/Plugin/Hooks.php` do core GLPI (branch `11.0/bugfixes`) onde a doc oficial de plugins está desatualizada. Revisado pelo agente `plugin-dev:skill-reviewer`, com correções de nomenclatura (`plugin_init_<nome>()`), do modelo `window._vue`/`window.Vue` na sub-skill `vue`, de exemplos que contradiziam regras do próprio texto (prefixo `/ajax`, exceção de `exit()` em handler legado), e de duas divergências deixadas fora da árvore GLPI pela duplicação (`ui-components`, `forms`).

### Adicionado

#### Skills de domínio
- `domains/glpi-11` — plugins GLPI 11: Controllers Symfony (`src/Controller/`, `#[Route]`) como caminho recomendado com suporte a `front/`/`ajax/` legados via `Firewall::addPluginStrategyForLegacyScripts()`, `$DB->request()`/`doQuery()` (query builder obrigatório, `query()`/`queryOrDie()` proibidos), fim da auto-sanitização (`htmlescape()`/`jsescape()`), namespace PSR-4 `GlpiPlugin\Nomedoplugin\`, diretório `public/` para assets web-acessíveis, tabela de hooks removidos/depreciados/novos (`csrf_compliant`, `show_in_timeline`→`timeline_items`, ~50 hooks novos); refs: `architecture.md`, `migration-10-to-11.md` (checklist de migração agrupado por severidade, ~35 itens)
  - `glpi-11/plugin-creation` — scaffold completo com `setup.php` + `boot()` opcional, Controller de exemplo, `install.php` via `Migration`+`doQuery`; ref: `plugin-structure.md`
  - `glpi-11/ajax-handlers` — duas rotas documentadas (Controller recomendado + `ajax/` legado sem `$AJAX_INCLUDE`), erros via `Glpi\Exception\Http\*`; ref: `patterns.md`; preserva a sobreposição intencional com `api-rest` (RFC 9457)
  - `glpi-11/form-templates` — mesmas macros/grid Bootstrap 5 do GLPI 10.x com os deltas do 11 (`|verbatim_value` removido, `path()` no lugar de `get_plugin_web_dir()`); refs: `layouts.md`, `dropdowns.md`; preserva a sobreposição intencional com `domains/forms` (asterisco de campo obrigatório)
  - `glpi-11/vue` — reescrita: Vue consumido via `window._vue` do core (não um build próprio do plugin), webpack com `externals: { vue: 'window _vue' }`, SFC exclusivamente Composition API, componentes em `js/src/Plugin/Nomedoplugin/`; refs: `vue-build.md` (novo), `integration-patterns.md`, `runtime-patterns.md`, `twig-integration.md`

### Alterado

#### Skills de domínio
- `domains/glpi` → renomeada para `domains/glpi-10` (conteúdo preservado, escopo GLPI 10.0.x inalterado); `references/glpi-architecture.md` → `references/architecture.md`; `description` de todas as 10 SKILL.md GLPI (2 pais + 8 sub-skills) ganhou heurísticas explícitas de detecção de versão, cláusula de fallback cruzado e instrução de perguntar ao usuário quando a versão for indeterminável; `glpi-10/form-templates` trocou um indício negativo (ausência de `|verbatim_value`) por indícios positivos observáveis
- `domains/ui-components` — orientação de API de componente Vue em plugins GLPI (§3) e nota sobre testes (§7) qualificadas por versão — descreviam só o modelo GLPI 10 (global build/Options API/PHPUnit) e contradiziam `glpi-11/vue` (SFC/Composition API/webpack)
- `domains/forms` — referência a `Sanitizer::sanitize()` como mecanismo GLPI de proteção contra XSS qualificada por versão (depreciada no GLPI 11 em favor de `htmlescape()`)

#### Agente
- `backend-dev` — carregamento de skill GLPI passa por detecção de versão-alvo (indícios em `setup.php`/estrutura de diretório/menção do usuário) antes de escolher entre `domains/glpi-10` e `domains/glpi-11`; sem indício em nenhuma direção, o agente pergunta ao usuário antes de gerar código; corrigida instrução de registro de hooks (`Plugin::addHook()`, que não existe no GLPI, → array `$PLUGIN_HOOKS`)

#### Projeto
- `plugin.json` — versão `0.5.0`
- `CLAUDE.md` — inventário de domínios (20→21); lista de domínios GLPI atualizada; precedência de carregamento "GLPI > Languages > Domains" reinterpretada para a árvore da versão detectada; sobreposições intencionais GLPI reescritas para valer nas duas versões; nova assimetria documentando a duplicação deliberada `glpi-10`/`glpi-11` e o contrato de detecção de versão; gap pré-existente (`frontend-dev` sem sub-skills GLPI) registrado em Próximos Passos
- `README.md` (raiz e do plugin) — catálogo de skills e versão atualizados para refletir `glpi-10`/`glpi-11`

## [0.4.0] - 2026-07-28

Especialização do agente `devops-cicd` em infraestrutura de containers moderna: duas novas skills de domínio (`podman` e `kubernetes`), executando o split de orquestração já previsto em `CLAUDE.md`, e refatoração de `containers` para a camada de imagem OCI runtime-agnóstica. Conteúdo alinhado aos padrões atuais do ecossistema (jul/2026): Quadlet como padrão de produção do Podman, Pod Security Standards `restricted`, e Gateway API como padrão de tráfego norte-sul após o fim de vida do `ingress-nginx` (24/03/2026).

### Adicionado

#### Skills de domínio
- `domains/podman` — runtime OCI daemonless/rootless; paridade de CLI com Docker, Quadlet + systemd em produção (`.container`/`.pod`/`.volume`/`.network`/`.kube`), rootless (subuid/subgid, portas privilegiadas), `podman-auto-update`, ecossistema (Buildah/Skopeo), ponte `podman kube play` para Kubernetes; refs: `quadlet-units.md`, `rootless-e-cli.md`
- `domains/kubernetes` — workloads de aplicação (Deployment/StatefulSet/DaemonSet/Job/CronJob), as três probes, QoS/resources, confiabilidade (PDB, topologySpreadConstraints, HPA/VPA), Pod Security Standards `restricted`, RBAC de menor privilégio, NetworkPolicy, Gateway API (primário) e Ingress (legado, com nota de migração via `ingress2gateway`), Kustomize × Helm, validação de manifests; refs: `manifests.md`, `gateway-api.md`, `packaging.md`

### Alterado

#### Skills de domínio
- `domains/containers` (550→~610 palavras) — vira camada de imagem OCI runtime-agnóstica (Docker/Podman/Buildah); adicionado Containerfile≡Dockerfile, pin por digest, `.containerignore`, labels `org.opencontainers.image.*`, nota sobre `HEALTHCHECK` vs probes; seção "Fundamentos de Kubernetes" removida (migrada para `domains/kubernetes`); `references/examples.md` ganhou variante de Dockerfile com digest pinado e labels OCI, Deployment YAML movido para `domains/kubernetes/references/manifests.md`
- `domains/openshift` — cross-refs realinhados para `kubernetes` (orquestração) + `containers` (imagem); notas curtas SCC×Pod Security Standards e Route×Gateway API

#### Skill base
- `base/devops-base` — tabela de precedência de domínios atualizada com `podman` e `kubernetes`; description e listagem de domínios atualizadas

#### Agente
- `devops-cicd` — gatilhos e exemplo para Podman/Quadlet; skills a carregar incluem `podman`/`kubernetes`; nota de exclusividade reescrita (`containers` soma a `podman`/`kubernetes`, não é alternativa)

#### Commands
- `/fullstack-development:new-feature` — sinais de detecção DevOps ampliados (Podman/Quadlet/rootless, Gateway API, Helm/Kustomize)

#### Projeto
- `plugin.json` — versão `0.4.0`
- `CLAUDE.md` — inventário de domínios (18→20); gatilho de split `kubernetes` consumido e substituído por `gateway-api`/`helm`; nova assimetria documentando o eixo imagem→runtime→orquestração→plataforma e a exclusividade `podman`×`kubernetes`
- `README.md` — catálogo de skills e versão atualizados

## [0.3.0] - 2026-06-14

Expansão do plugin para desenvolvimento mobile: novo agente `mobile-dev` com suporte a Android nativo (Kotlin + Jetpack Compose) e Flutter (Dart), acompanhado de skill base, 3 domínios e 3 linguagens com política de progressive disclosure.

### Adicionado

#### Agente
- `mobile-dev` — desenvolvimento mobile Android nativo (Kotlin/Compose) e Flutter (Dart) (color magenta); carregamento mínimo de skills por stack detectada; Compose e Flutter mutuamente exclusivos

#### Skill base
- `base/mobile-base` — fundamentos mobile independentes de stack: Clean Architecture (camadas data/domain/ui), MVVM/MVI, estados obrigatórios (loading/erro/vazio/sucesso), ciclo de vida Android e Flutter, KDoc/DartDoc

#### Skills de domínio mobile
- `domains/android-architecture` — ViewModel + StateFlow, Lifecycle (`repeatOnLifecycle`), Navigation Component, Hilt (DI), Repository pattern, Room (`@Upsert`, Flow, `exportSchema`); refs: `jetpack.md`, `room.md`, `di-hilt.md`
- `domains/jetpack-compose` — composables, state hoisting, `remember`/`derivedStateOf`, Modifier, `LazyColumn`/`LazyRow`, navegação Compose, Material3, performance; refs: `state.md`, `performance.md`
- `domains/flutter` — widget tree, StatelessWidget/StatefulWidget, state management (Provider/Riverpod/BLoC — resumo + referência), GoRouter, layout widgets, FutureBuilder/StreamBuilder; refs: `state-management.md`, `widgets.md`

#### Skills de linguagem mobile
- `languages/kotlin` — null safety, data/sealed classes, extension functions, scope functions, coroutines (visão geral), coleções, anti-patterns; refs: `coroutines-flow.md`, `idioms.md`
- `languages/gradle` — Kotlin DSL vs Groovy, `build.gradle.kts`, version catalog (`libs.versions.toml`), build types, product flavors, signing config, multi-módulo; refs: `build-config.md`, `dependencies.md`
- `languages/dart` — null safety, sound type system, async/await, Futures, Streams, classes/mixins/extensions, coleções, anti-patterns; refs: `async.md`, `language-tour.md`

#### Projeto
- `plugin.json` — versão `0.3.0`; description atualizada para incluir mobile
- `CLAUDE.md` — tabela de agentes atualizada (mobile-dev + magenta); organização de skills atualizada (3 novos domínios, 3 novas linguagens, mobile-base); assimetrias intencionais do conjunto mobile; gatilhos de split futuro (`room`, `flutter-state`)

## [0.2.1] - 2026-06-11

Rodada de otimização de consumo de tokens: redução do vetor de dados externos, carregamento mínimo de skills e aplicação de progressive disclosure nos `SKILL.md` (corpos enxutos + conteúdo detalhado movido para `references/` por tópico, sem perda de informação).

Segunda rodada de otimização de tokens: aplicação integral da regra de código inline (máx. 1 bloco curto por seção), eliminação de duplicações entre skills carregadas juntas e consolidação de fontes autoritativas únicas — preservando a precedência GLPI > Languages > Domains. Economia estimada de ~3.000+ palavras nos corpos carregados em runtime, sem perda de informação (conteúdo movido para `references/`).

### Alterado

#### Agentes
- `devops-cicd` — removida a ferramenta `WebSearch` (elimina o vetor de dados externos do agente); reforço de que as skills de domínio são mutuamente exclusivas por tarefa
- `spec-dev` — `WebSearch` mantido, mas com guardrail: usar apenas quando o usuário pedir explicitamente verificação de versão/documentação online, sem buscas especulativas
- `spec-dev`, `backend-dev`, `frontend-dev`, `devops-cicd` — adicionada diretriz de **carregamento mínimo** (carregar só a base + a skill da stack detectada; `references/` sob demanda)

#### Skills — progressive disclosure (corpos reduzidos)
- `domains/security` (2.683→~950 palavras) — OWASP Top 10 detalhado movido para `references/owasp-top10.md`; defesas web (XSS, CSRF, upload, CORS, secrets, supply chain) para `references/web-defenses.md`
- `domains/user-experience` (2.447→~1.355) — seções 6–12 movidas para `references/mobile-responsive.md`, `motion-darkmode-a11y.md`, `ux-writing-flows.md`; seção de formulários colapsada para ponteiro a `forms`
- `domains/api-rest` (2.385→~1.555) — `references/status-codes.md`, `error-handling.md` (RFC 9457), `advanced-endpoints.md` e `pagination.md`; tabelas de headers movidas para `http-patterns.md`
- `domains/database` (1.943→~1.640) — `references/migrations.md` e `sql-vs-nosql.md`; blocos SQL/Python inline duplicados removidos
- `domains/forms` (1.698→~1.350) — `references/brazilian-inputs.md`, `multi-step-and-upload.md` e `autocomplete.md`; seção de segurança colapsada para ponteiro a `security`
- `domains/glpi/vue` (1.726→~1.630) — modais e ciclo de vida movidos para `references/runtime-patterns.md`; bloco AJAX reduzido com ponteiro a `integration-patterns.md`
- `languages/twig` (1.663→~1.320) — catálogo de filters/functions reduzido a resumo (duplicava `references/filters-functions.md`); regra `|raw`/HTMLPurifier deduplicada
- `languages/html` (1.653→~1.520) — grid/breakpoints reduzidos a resumo (duplicava `references/bootstrap5-layout.md`)

#### Skills GLPI (precedência preservada)
- `glpi/ajax-handlers` — blocos de inicialização, validação, CRUD/`op`, respostas JSON, delegação e try-catch movidos para `references/patterns.md` (novas seções: Validação de Parâmetros, Operações Múltiplas via `op`, Estruturas de Resposta JSON); mantidos no corpo: sessão expirada em AJAX, nota RFC 9457 (sobrepõe `api-rest` deliberadamente), tabela de códigos HTTP e checklist de segurança
- `glpi/form-templates` — estrutura base e catálogo de macros movidos para `references/layouts.md`; §9 (Regras de UX) agora aponta para `domains/forms` mantendo inline apenas os específicos GLPI (asterisco `<span class="required">`, botão à direita, verbos de ação)
- `glpi` — árvore de estrutura condensada (completa em `plugin-creation`); tabela de Nomenclatura unificada (removida da sub-skill); repetições das Restrições Absolutas removidas das seções do próprio arquivo; bloco CommonDBTM reduzido
- `glpi/vue` — §8 (Compatibilidade) removida por repetir a introdução; bridge de dropdowns reduzido a 1 bloco + ponteiro para `references/integration-patterns.md`

#### Skills de linguagem (sintaxe básica condensada em tabelas)
- `languages/javascript` — exemplos de var/arrow/destructuring/template literals/classes/async reduzidos; classes ES6 movidas para `references/es6-features.md`; `references/modules.md` agora referenciado
- `languages/vue` — exemplos completos delegados a `references/` (composition-api, state-management, performance); tabelas mantidas
- `languages/python` — Boas Práticas Essenciais viraram tabela; estrutura de projeto e tratamento de erros condensados
- `languages/php` — blocos de PSR/tipos/8.3/erros encurtados; Boas Práticas viraram tabela
- `languages/twig` — tags de controle reduzidas a `for/else` + notas (`verbatim`, `apply`, `cycle`)
- `languages/html` — checklist WCAG restrito a markup puro (contraste/foco/teclado → `ui-components`); tabela de Input Types condensada (completa em `references/forms.md`); padronizado WCAG 2.2 (era 2.1)

#### Skills DevOps (criados os primeiros `references/` do conjunto)
- `domains/ci-cd` — YAMLs GitHub Actions/GitLab CI movidos para `references/pipeline-examples.md`; Segurança do Pipeline reduzida a ponteiro para `devsecops`
- `domains/containers` — Dockerfile multi-stage e Deployment movidos para `references/examples.md`
- `domains/azure-devops` — pipeline de ~43 linhas movido para `references/azure-pipelines-openshift.md`
- `domains/openshift` — Route YAML movido para `references/examples.md`
- `domains/iac` — bloco Terraform movido para `references/terraform-examples.md`
- `base/devops-base` — dupla listagem de skills removida das Referências; seção DevSecOps reduzida a ponteiro

#### Deduplicação entre pares carregados juntos
- `base/backend-base` — tabela "Adaptação por Framework" substituída por frase de roteamento (a tabela vive em `domains/glpi`, que prevalece)
- `base/spec-base` ↔ `domains/spec-review` — SCOPE em spec-base reduzido a definições conceituais; checklist operacional só em spec-review
- `base/frontend-base` — seções Segurança e Performance viraram ponteiros (`domains/security`, `ui-components`/`languages/vue`)
- `domains/ui-components` — §8 Performance aponta para `languages/vue`, mantendo só itens específicos de componente; `references/component-api.ts` e `composables.ts` agora referenciados
- `domains/api-rest` — JWT alinhado com `security` (15 min); `Idempotency-Key` consolidado; Caching fundido em 1 bloco; Rate Limiting restrito ao contrato HTTP + ponteiro
- `domains/user-experience` e `domains/database` — ajustes menores de duplicação e ponteiros

#### Agentes e Commands
- `backend-dev` — restrições GLPI substituídas por ponteiro às Restrições Absolutas de `domains/glpi`; alinhado `Session::checkRight()` como padrão em entry points
- `devops-cicd` — restrição security/devsecops encurtada
- `/fullstack-development:new-feature` — reafirmações da condicional DevOps removidas das Fases 4–5

#### Skills — descriptions e versões
- `domains/security`, `api-rest`, `database`, `forms` — adicionadas *trigger phrases* literais à `description` para melhorar a ativação
- `domains/glpi/vue` — `version` da skill alinhada para `0.2.0`

#### Projeto
- `plugin.json` — versão `0.2.1`; `version:` de todos os 29 `SKILL.md` alinhados a `0.2.1`
- `CLAUDE.md` — nova subseção "Política de progressive disclosure nos SKILL.md" (alvo de corpo ~1.500–2.000 palavras, máx. 1 bloco de código curto por seção, fonte autoritativa única por tópico transversal)
- Descriptions com trigger phrases adicionadas: `ui-components`, `spec-base`, `ci-cd`, `containers`, `iac`, `observability`

### Removido
- `domains/forms/references/rhf-zod-example.tsx` (React Hook Form — fora da stack do plugin)
- `domains/ui-components/references/storybook-example.ts` e `testing-examples.ts` (incoerentes com a nota "testes via PHPUnit, sem runner JS")

## [0.2.0] - 2026-06-10

### Adicionado

#### Agentes
- `devops-cicd` — DevOps, CI/CD, containerização, infraestrutura como código e observabilidade (color yellow)

#### Skills base
- `base/devops-base` — fundamentos de DevOps: cultura, princípios transversais, DevSecOps, métricas DORA e navegação entre os domínios

#### Skills de domínio
- `domains/ci-cd` — pipelines, estágios, gates de qualidade e estratégias de deploy (exemplos GitHub Actions/GitLab CI)
- `domains/containers` — Docker e Kubernetes (imagens multi-stage, probes, limites, scan e registries)
- `domains/openshift` — especificidades do OpenShift sobre Kubernetes (Route, SCC `restricted-v2`, BuildConfig/ImageStream, S2I, `oc`, OpenShift GitOps)
- `domains/azure-devops` — Azure Pipelines (stages/jobs/steps, service connections, variable groups/Key Vault, environments com approvals, deployment strategies)
- `domains/iac` — infraestrutura como código e GitOps (Terraform/Pulumi, state, drift, ArgoCD/Flux, secrets)
- `domains/observability` — três pilares (métricas/logs/traces), OpenTelemetry, golden signals, SLI/SLO/error budget e alerting acionável
- `domains/devsecops` — segurança no pipeline e na infraestrutura (SAST/SCA/DAST, IaC/image scanning, SBOM/cosign, OIDC, supply chain)

### Alterado

#### Commands
- `/fullstack-development:new-feature` — orquestração condicional do `devops-cicd`: quando a demanda tem solicitações explícitas de DevOps, o `spec-dev` gera uma seção DevOps na spec e o `devops-cicd` revisa apenas essa seção, restrito ao seu escopo

#### Skills de domínio
- `domains/security` — adicionada seção `## Referências` com cross-links (incl. `devsecops`); escopo reafirmado como segurança de aplicação web/API, complementar ao `devsecops` (pipeline/infra)

#### Projeto
- `plugin.json` — versão `0.2.0` e `description` atualizada para incluir o eixo DevOps/CI-CD
- `CLAUDE.md` — documentação do conjunto devops, das assimetrias intencionais (`ci-cd` inline vs `azure-devops`; `security` vs `devsecops` por audiência) e dos gatilhos de split futuro
- Precedência de carregamento: skills de plataforma (`openshift`/`azure-devops`) complementam as genéricas; `security` (app) e `devsecops` (pipeline/infra) separadas por audiência

## [0.1.0] - 2026-05-28

### Adicionado

#### Agentes
- `spec-dev` — revisão e validação de especificações de features para desenvolvimento com IA
- `backend-dev` — desenvolvimento backend com boas práticas por linguagem e domínio
- `frontend-dev` — desenvolvimento frontend com foco em componentes, formulários e UX

#### Skills base
- `base/spec-base` — fundamentos de especificação para IA
- `base/backend-base` — arquitetura e padrões backend
- `base/frontend-base` — arquitetura e padrões frontend

#### Skills de domínio
- `domains/spec-review` — critérios de revisão de especificações
- `domains/api-rest` — padrões REST, OpenAPI e respostas HTTP
- `domains/database` — modelagem, queries, transações e controle de acesso
- `domains/security` — OWASP, autenticação, CSRF, CORS e upload seguro
- `domains/forms` — formulários, validação e integração com APIs externas
- `domains/ui-components` — componentes UI, acessibilidade e design tokens
- `domains/user-experience` — UX, fluxos de usuário e boas práticas de interface
- `domains/glpi` — desenvolvimento de plugins GLPI 10.x com sub-skills especializadas:
  - `glpi/ajax-handlers` — padrões de endpoints AJAX no GLPI
  - `glpi/form-templates` — templates de formulários e dropdowns GLPI
  - `glpi/plugin-creation` — estrutura e ciclo de criação de plugins
  - `glpi/vue` — integração Vue.js em plugins GLPI via Twig

#### Skills de linguagem
- `languages/python` — Python moderno, type hints, async e testes
- `languages/php` — PHP 8.3, tipos, padrões e segurança
- `languages/javascript` — ES6+, async, módulos e DOM
- `languages/vue` — Vue.js, Composition API, estado e roteamento
- `languages/twig` — herança de templates, macros e performance
- `languages/html` — semântica, acessibilidade e Bootstrap 5

#### Commands
- `/fullstack-development:review-spec` — revisão completa de especificação de feature
- `/fullstack-development:new-feature` — iniciar desenvolvimento de nova feature
- `/fullstack-development:code-review` — revisão de código fullstack

#### Projeto
- Manifesto do plugin (`plugin.json`) com nome `fullstack-development` v0.1.0
- Documentação do projeto (`CLAUDE.md`) com estrutura, agentes e decisões de design
- Precedência de carregamento de skills: GLPI > Languages > Domains

[0.6.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.6.0
[0.5.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.5.0
[0.4.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.4.0
[0.3.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.3.0
[0.2.1]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.2.1
[0.2.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.2.0
[0.1.0]: https://github.com/RatadoColab/gaten-claude-plugin/releases/tag/v0.1.0
