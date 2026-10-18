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

---

## Aumentar o disparo do `fullstack-router` na conversa principal

- **Registrado em:** 2026-10-17
- **Dono:** sem dono
- **Contexto:** Medido com `claude plugin eval` (pasta `fullstack-development/evals/`, 10 prompts
  positivos em português e 2 negativos, projeto vazio, 3 execuções por caso): a skill roteadora foi
  invocada em ~50–65% das execuções positivas; nenhum falso positivo nos negativos. Casos que mais
  falham: revisão de componente Vue, revisão de segurança, correção de bug Flutter, criação de
  pipeline (o modelo responde direto, sem consultar o router). Em projeto real com stack detectada
  (teste manual em projeto GLPI de exemplo) o router foi invocado e escolheu a árvore `glpi-11`
  corretamente. Variante de descrição mais ampla ("Consultar ANTES de…") não trouxe ganho claro.
  O hook `UserPromptSubmit` (`hooks/prompt-skills.sh`, palavras-chave em português, deduplicação por
  sessão) foi implementado e dispara, mas **não aumentou** as leituras de skills nos mesmos casos;
  por isso não está registrado em `hooks/hooks.json`. Opção ainda não testada: modelo híbrido, com
  2–3 skills de maior uso registradas individualmente (exige mover pastas para o nível único e
  alterar os caminhos dos agentes — fora do escopo da sessão).
- **Nova medição (2026-10-18):** `claude plugin eval . --runs 3 -j 4 --ablation none --no-publish
  --trust-plugin` após a revisão dos arquivos modificados (formato único da `spec-review`, ajustes
  na descrição e na detecção do router). 12 casos, 3 execuções cada, resultado idêntico nas 3 execuções
  de cada caso. O router foi invocado em 9 dos 10 casos positivos (só `router-review-vue` ficou
  em 0); nenhum falso positivo nos 2 negativos. Casos com nota máxima: 6 positivos
  (`android-screen`, `bug-flutter`, `dockerfile`, `endpoint-go`, `migration`, `php-feature`).
  Nota 0,50 (router chamado, mas nenhum `Read` de skill depois): `form-glpi`, `pipeline`,
  `security`. Nota 0,00: `review-vue`. O gargalo passou a ser a leitura das skills após a
  consulta ao router, não só o disparo; vale checar se `max_turns: 6` e as ferramentas permitidas
  no eval limitam a leitura (rodar com `--keep-temp` e inspecionar o `trace.jsonl`). O bug Flutter
  deixou a lista de falhas da medição anterior.
- **Diagnóstico dos casos parciais (2026-10-18):** rodados `router-pipeline`, `router-security`,
  `router-form-glpi` e `router-review-vue` com `--keep-temp` (1 execução cada, traces lidos como
  dados). Em todos o projeto do eval está vazio e o modelo agiu corretamente: nos três primeiros
  chamou o router, procurou arquivos com `Glob` e perguntou stack, caminho do código ou versão do
  GLPI em vez de ler skills (no GLPI, conforme o contrato de não assumir versão); no `review-vue`
  buscou `**/*.vue`, não achou componente nem código no prompt e pediu o código, sem chamar o
  router. Conclusão: a nota baixa vem do desenho dos casos, não do router, e o disparo real está
  subestimado nesses quatro. Próximo passo: tornar os prompts autossuficientes (colar um trecho de
  código no próprio prompt: componente Vue, módulo de login, etc.) ou usar fixtures por caso
  (formato de "scaffold scripts" do `claude plugin eval` ainda não verificado) e repetir a medição.
  Relatório local em
  `fullstack-development/evals/results/2026-10-18T20-28-39-210Z/report.html` (ignorado pelo git).
- **Ação:** reavaliar com o uso real do GATEN (taxa de disparo percebida). Se continuar baixa,
  testar (a) texto do hook em forma mais diretiva, avaliando o risco de ser tratado como prompt
  injection, e (b) o modelo híbrido.
- **Critério de pronto:** disparo ≥ 80% nos casos positivos de `evals/`, sem falso positivo nos
  negativos — ou decisão registrada de aceitar a taxa atual.

---

## Revisar o fluxo de permissões de leitura das skills em outros ambientes

- **Registrado em:** 2026-10-17
- **Dono:** sem dono
- **Contexto:** No modo de permissão padrão (testado com `claude -p --plugin-dir`), o `Read` de
  `SKILL.md` do plugin foi negado por estar fora do projeto. Foi adicionado o hook `PreToolUse`
  (`hooks/allow-skill-read.sh`) que aprova apenas leituras `.md` dentro de `skills/` do plugin; com
  ele as leituras passaram. Não foi testado com o plugin instalado pelo marketplace (caminho do
  cache) nem no macOS/Windows. O hook cobre só `Read`: comandos `Bash` (ex.: `ls` em `references/`)
  fora do projeto continuam pedindo permissão.
- **Ação:** validar com um colega do GATEN (plugin instalado via marketplace) e, se necessário,
  documentar no README uma regra `Read(...)` de permissão.
- **Critério de pronto:** leitura de skills sem prompt de permissão confirmada em instalação via
  marketplace em Linux e em macOS ou Windows (Git Bash).

---

## Gap: `frontend-dev` não referencia sub-skills GLPI

- **Registrado em:** 2026-10-17 (migrado do `CLAUDE.md` do plugin, onde estava em "Próximos Passos Sugeridos")
- **Dono:** sem dono
- **Contexto:** `agents/frontend-dev.md` não referencia nenhuma sub-skill GLPI; `form-templates` e `vue`
  das três árvores (`glpi-10`, `glpi-11`, `glpi-12`) não estão ligadas a agente algum. Gap pré-existente,
  anterior à criação das árvores. Na conversa principal e nos comandos essas skills já são alcançáveis
  pelo `fullstack-router`.
- **Ação:** decidir se o `frontend-dev` deve carregar `form-templates` e `vue` da árvore GLPI detectada.
- **Critério de pronto:** `frontend-dev` aponta (ou decisão registrada de não apontar) as sub-skills GLPI.

---

## Avaliar hooks de validação automática de specs antes de commits

- **Registrado em:** 2026-10-17 (migrado do `CLAUDE.md` do plugin)
- **Dono:** sem dono
- **Contexto:** Ideia antiga de usar hooks para validar specs (`.claude/specs/*.md`) antes de commits.
  A infraestrutura de hooks do plugin passou a existir com o router (`hooks/hooks.json`).
- **Ação:** definir o que seria validado e em qual evento.
- **Critério de pronto:** hook implementado ou ideia descartada com justificativa.
