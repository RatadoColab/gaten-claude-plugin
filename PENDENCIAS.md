# Pendências

Tarefas e dívida técnica em aberto. Cada entrada: data de registro, contexto suficiente
para retomada sem reinvestigação, dono e critério de "pronto".

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
     GLPI 11.0.8 e 12.0.0 GA (3.5.43) empacotam Vue **3.5.x** (`window._vue`), e o GLPI 10 não traz Vue no
     core (o plugin embarca o próprio, com piso 3.5 recomendado nas skills). Nenhum herda Vapor
     hoje — revisitar apenas quando algum core GLPI passar a empacotar Vue 3.6.
- **Critério de pronto:** `languages/vue` sem a ressalva "RC / não usar em produção" e com o
  Vapor Mode documentado como recurso normal, versão-alvo.
