---
description: Inicia a correção de um bug com fluxo diagnóstico-first — reproduz a falha, isola a causa raiz com evidência antes de propor qualquer código, usa o agente spec-dev para estruturar o laudo e consolidar o plano final, submete-o à revisão paralela dos agentes de domínio pertinentes (backend-dev, frontend-dev, mobile-dev e — somente quando a falha for de pipeline/build/deploy/infra — devops-cicd) e só implementa após aprovação explícita, sempre com teste de regressão.
argument-hint: <identificador-do-bug ou descrição do sintoma>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-bugfix

Guiar a correção de um bug com fluxo diagnóstico-first: reproduz a falha, isola a causa raiz com evidência antes de qualquer código, submete o laudo à revisão paralela de domínio e consolida um Plano de Correção para aprovação — encerrando sempre com um teste de regressão que falha antes e passa depois.

## Processo

### Detecção de escopo (antes da Fase 1)

Aplicar os mesmos sinais já usados em `new-feature` e `code-review` — não criar heurística nova:

- **Mobile:** `pubspec.yaml`, `AndroidManifest.xml`, arquivos `.kt`/`.dart`, `@Composable`, imports `androidx.*`, `flutter/material.dart` — Compose e Flutter são **mutuamente exclusivos: nunca ambos**
- **Frontend web:** `.vue`/`.html`/`.twig`, componentes, páginas, CSS
- **Backend:** PHP, Python, JS/Node.js, Go, SQL, controllers, services, repositories
- **DevOps/Infra — regra "se, e apenas se":** acionar a trilha DevOps **somente** quando a própria falha for de pipeline/CI-CD, build, imagem OCI, deploy, IaC, orquestração ou observabilidade. Um bug de aplicação que apenas **roda** em container **não** aciona a trilha. `podman` e `kubernetes` são mutuamente exclusivos.

**Identificador (`<id>`):** se o argumento já for um identificador curto (issue, ticket, slug), usá-lo. Se for uma descrição do sintoma em texto livre, derivar um slug em minúsculas com hífens, ~4–6 palavras (ex.: `"lista de produtos duplica itens ao rolar"` → `lista-produtos-duplica-ao-rolar`) e compor `.claude/specs/bugfix-<id>.md` com ele.

### Fase 1 — Reprodução e delimitação

1. Ler `${CLAUDE_PLUGIN_ROOT}/skills/domains/debugging/SKILL.md` (**sempre**)
2. Coletar e registrar os fatos do defeito:
   - Sintoma observado (mensagem de erro, comportamento incorreto, stack trace)
   - Passos de reprodução determinísticos
   - Comportamento esperado × comportamento observado
   - Ambiente, versão da aplicação e stack
   - Primeira ocorrência conhecida (build, commit, data) — se houver
3. **Portão duro:** se a falha não for reproduzível nem determinável por leitura de código **com evidência**, **não avançar** — solicitar ao usuário os dados faltantes (log completo, stack trace, payload, versão, passos exatos). Nunca propor correção especulativa.

### Fase 2 — Diagnóstico de causa raiz

4. Identificar a stack e carregar as skills de linguagem/domínio pertinentes:
   - `${CLAUDE_PLUGIN_ROOT}/skills/base/backend-base/SKILL.md` e/ou `${CLAUDE_PLUGIN_ROOT}/skills/base/frontend-base/SKILL.md` / `${CLAUDE_PLUGIN_ROOT}/skills/base/mobile-base/SKILL.md` / `${CLAUDE_PLUGIN_ROOT}/skills/base/devops-base/SKILL.md`, conforme as trilhas ativas
   - Skills de linguagem conforme a stack (`php`, `python`, `javascript`+`nodejs`, `golang`, `vue`, `kotlin`+`gradle`, `dart`)
   - Se for plugin GLPI, determinar a versão-alvo (indícios de GLPI 10, 11 ou 12) e carregar **apenas uma** das três árvores; sem indício em nenhuma direção, **perguntar** ao usuário antes de gerar código — nunca assumir um default
5. Formular hipóteses de causa ordenadas por probabilidade e **refutar cada uma com evidência** — trecho de código, saída de execução, log ou teste —, nunca por plausibilidade. Distinguir correlação de causa
6. Quando houver regressão datada, usar `git log`/`git bisect` para localizar a mudança que a introduziu
7. **Não escrever correção antes de a causa raiz estar identificada e evidenciada.** Tratar o sintoma sem a causa é exatamente o antipadrão que este comando existe para impedir

### Fase 3 — Estruturação do laudo (spec-dev)

8. Usar o agente `spec-dev` para estruturar o laudo a partir da reprodução (Fase 1) e do diagnóstico (Fase 2):
   - Instrução: **"Estruture o laudo do bug `<id>` em `.claude/specs/bugfix-<id>.md` a partir da reprodução e do diagnóstico fornecidos, aplicando o template abaixo. Aplique ao laudo apenas as dimensões de completude, ambiguidade e critério de verificação do protocolo de `spec-review` (as demais, específicas de spec de feature, não se aplicam): aponte reprodução ambígua, causa raiz sem evidência e critério de verificação ausente. NÃO escreva código de correção."**
   - Se o usuário já tiver um relatório de bug, **validá-lo e melhorá-lo** em vez de criar do zero
   - Salvar em `.claude/specs/bugfix-<id>.md` com o template:
   ```markdown
   # Bugfix — <id>

   ## Sintoma
   ## Reprodução
   ## Esperado × observado
   ## Ambiente e versões
   ## Causa raiz
   ### Hipóteses avaliadas e refutadas
   ## Escopo do impacto
   ## Correção proposta
   ## Teste de regressão
   ## Ocorrências correlatas
   ## Fora de escopo
   ```
   - Quando mais de uma trilha estiver ativa, subdividir **Causa raiz**, **Escopo do impacto** e **Correção proposta** por camada (`### Backend`, `### Frontend`, `### Mobile`, `### DevOps/Infraestrutura`) para dar a cada revisor da Fase 4 um recorte explícito

### Fase 4 — Revisão paralela de domínio

9. Acionar **em paralelo** os agentes de domínio das trilhas ativas, cada um revisando apenas sua camada e carregando as skills pertinentes conforme a stack da Fase 2:
   - `backend-dev` — instrução: **"Revise o laudo em `.claude/specs/bugfix-<id>.md` sob a ótica da camada Backend (a subseção `### Backend` quando o laudo estiver subdividido; os aspectos backend da causa raiz e da correção proposta caso contrário). Confirme ou refute a causa raiz apontada, com evidência. Aponte efeitos colaterais da correção proposta e ocorrências do mesmo padrão de defeito em outros pontos do backend. NÃO escreva código — retorne somente o relatório de revisão."**
   - `frontend-dev` **(quando trilha Frontend web ativa)** — instrução: **"Revise o laudo em `.claude/specs/bugfix-<id>.md` sob a ótica da camada Frontend. Confirme ou refute a causa raiz, com evidência. Aponte riscos de UX/integração da correção proposta e ocorrências do mesmo padrão em outros componentes. NÃO escreva código — retorne somente o relatório de revisão."**
   - `mobile-dev` **(quando trilha Mobile ativa)** — instrução: **"Revise o laudo em `.claude/specs/bugfix-<id>.md` sob a ótica da camada Mobile. Confirme ou refute a causa raiz, com evidência. Avalie impacto em arquitetura (camadas data/domain/ui), gerenciamento de estado, ciclo de vida e cancelamento de coroutines/futures. NÃO escreva código — retorne somente o relatório de revisão."**
   - `devops-cicd` **(apenas quando a trilha DevOps foi acionada)** — instrução: **"Revise o laudo em `.claude/specs/bugfix-<id>.md` sob a ótica da camada DevOps/Infraestrutura, limitando-se a CI/CD, containers, IaC, deploy/rollback e observabilidade; carregue `devsecops` se a falha envolver scan, secret ou supply chain do pipeline. Confirme ou refute a causa raiz, com evidência. NÃO opine sobre regra de negócio do backend nem sobre UI/UX. NÃO escreva código — retorne somente o relatório de revisão."**

   Formato esperado de cada relatório:
   ```markdown
   ## Revisão de laudo [Backend|Frontend|Mobile|DevOps/Infraestrutura] — <id>

   ### Causa raiz: confirmada | refutada | parcialmente confirmada
   [justificativa com evidência]

   ### Efeitos colaterais previstos
   - [efeito]: descrição

   ### Ocorrências correlatas
   - [arquivo:linha]: mesmo padrão de defeito

   ### Ajustes na correção proposta
   - [ajuste]: descrição
   ```

### Fase 5 — Plano de Correção e aprovação (spec-dev)

10. Acionar novamente o `spec-dev` para consolidar laudo + relatórios das revisões:
    - Instrução: **"Consolide o laudo `.claude/specs/bugfix-<id>.md` e os relatórios de revisão anexos num Plano de Correção único. Reconcilie divergências entre os revisores sobre a causa raiz e sinalize-as em vez de escolher silenciosamente. NÃO escreva código."**
    - O **Plano de Correção** deve conter:
      - Causa raiz consolidada
      - **Correção mínima × correção estrutural** — apresentar o trade-off explicitamente e recomendar uma
      - Arquivos a alterar, separados por escopo (backend / frontend / mobile / devops)
      - Risco de regressão: o que a correção pode quebrar
      - Teste de regressão a escrever: qual, onde e por que ele falha hoje
      - **Fora de escopo:** o que foi encontrado mas não será corrigido agora → registrar em `PENDENCIAS.md` (data, contexto, dono ou "sem dono", critério de pronto) ou como `// TODO(dono): motivo` no código
11. Apresentar o Plano de Correção ao usuário e **aguardar aprovação explícita** antes de continuar

### Fase 6 — Correção e verificação (somente após aprovação)

12. Delegar a correção ao agente de domínio da camada afetada (`backend-dev`, `frontend-dev`, `mobile-dev` ou `devops-cicd`), carregando as skills do seu contexto:
    - Escrever **primeiro** o teste de regressão e confirmar que ele **falha** no código atual
    - Quando o diagnóstico se deu apenas por evidência de código (sem um caso reproduzível na Fase 1), converter essa evidência num teste que exercite o defeito antes da correção; se for comprovadamente impossível escrever tal teste, registrar a exceção no laudo com justificativa em vez de pular a verificação
    - Aplicar a correção; confirmar que o teste passa e que a suíte existente não regride
    - Varrer com `Grep` as ocorrências do mesmo padrão de defeito e corrigir apenas as aprovadas
13. Atualizar o laudo com a correção efetivamente aplicada; listar arquivos alterados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-bugfix login-retorna-500
/fullstack-development:new-bugfix "lista de produtos duplica itens ao rolar"   # aciona mobile-dev se projeto Android/Flutter
/fullstack-development:new-bugfix pipeline-falha-no-push-da-imagem             # aciona devops-cicd (falha de pipeline)
/fullstack-development:new-bugfix calculo-de-desconto-arredonda-errado
```
