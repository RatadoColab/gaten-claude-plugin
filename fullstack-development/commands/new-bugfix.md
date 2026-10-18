---
description: Inicia a correção de um bug com fluxo diagnóstico-first, conduzido na conversa principal — reproduz a falha, isola a causa raiz com evidência antes de propor qualquer código, registra o laudo, oferece uma revisão independente opcional pelo spec-dev e só implementa após aprovação explícita, sempre com teste de regressão.
argument-hint: <identificador-do-bug ou descrição do sintoma>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-bugfix

Guiar a correção de um bug com fluxo diagnóstico-first: reproduz a falha, isola a causa raiz com evidência antes de qualquer código, registra o laudo e consolida um Plano de Correção para aprovação — encerrando sempre com um teste de regressão que falha antes e passa depois. Todas as fases rodam na conversa principal, com a skill `debugging` e as skills da stack carregadas uma única vez.

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

4. Identificar a stack (se o contexto da sessão já trouxer a linha de stack detectada, usá-la como ponto de partida) e carregar as skills de linguagem/domínio pertinentes, lendo primeiro `${CLAUDE_PLUGIN_ROOT}/skills/fullstack-router/SKILL.md` (índice com caminhos, detecção de stack/versão e precedência):
   - Skill base de cada trilha ativa (`backend-base`, `frontend-base`, `mobile-base`, `devops-base`), pelos caminhos do índice
   - Skills de linguagem e de domínio conforme a stack, pelos caminhos do índice
   - Se for plugin GLPI, determinar a versão-alvo (indícios de GLPI 10, 11 ou 12) e carregar **apenas uma** das três árvores; sem indício em nenhuma direção, **perguntar** ao usuário antes de gerar código — nunca assumir um default
5. Formular hipóteses de causa ordenadas por probabilidade e **refutar cada uma com evidência** — trecho de código, saída de execução, log ou teste —, nunca por plausibilidade. Distinguir correlação de causa
6. Quando houver regressão datada, usar `git log`/`git bisect` para localizar a mudança que a introduziu
7. **Não escrever correção antes de a causa raiz estar identificada e evidenciada.** Tratar o sintoma sem a causa é exatamente o antipadrão que este comando existe para impedir

### Fase 3 — Laudo do bug

8. Estruturar o laudo a partir da reprodução (Fase 1) e do diagnóstico (Fase 2) e salvá-lo em `.claude/specs/bugfix-<id>.md`:
   - Se o usuário já tiver um relatório de bug, **validá-lo e melhorá-lo** em vez de criar do zero
   - Aplicar ao laudo as dimensões de completude, ambiguidade e critério de verificação do protocolo de `spec-review` (as demais, específicas de spec de feature, não se aplicam): reprodução ambígua, causa raiz sem evidência e critério de verificação ausente são gaps a fechar
   - Template:
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
   - Quando mais de uma trilha estiver ativa, subdividir **Causa raiz**, **Escopo do impacto** e **Correção proposta** por camada (`### Backend`, `### Frontend`, `### Mobile`, `### DevOps/Infraestrutura`)

### Fase 4 — Revisão independente (opcional)

9. Sugerir ao usuário uma revisão independente do laudo pelo agente `spec-dev` (somente leitura, contexto limpo) quando a falha atravessar mais de uma camada, a causa raiz tiver pouca evidência, houver segurança envolvida ou for incidente de produção. Em bugs simples e bem evidenciados, seguir direto para a Fase 5. A revisão nunca é obrigatória
10. Se o usuário aceitar, acionar **um único** `spec-dev` com um prompt contendo:
    - **Stack detectada** (linha do contexto da sessão ou resultado da Fase 2)
    - **Caminhos exatos das skills** de cada camada ativa, para o agente não redetectar a stack
    - **Escopo:** camadas ativas e caminho do laudo em `.claude/specs/bugfix-<id>.md`
    - **Formato de saída:** por camada, causa raiz confirmada/refutada/parcial com evidência, efeitos colaterais previstos, ocorrências correlatas (`arquivo:linha`) e ajustes na correção proposta — sem repetir o laudo e sem omitir achados por tamanho
11. Avaliar o relatório, reconciliar divergências sobre a causa raiz sinalizando-as ao usuário e atualizar o laudo

### Fase 5 — Plano de Correção e aprovação

12. Consolidar o laudo e, quando houver, o relatório da revisão em um **Plano de Correção** contendo:
    - Causa raiz consolidada
    - **Correção mínima × correção estrutural** — apresentar o trade-off explicitamente e recomendar uma
    - Arquivos a alterar, separados por escopo (backend / frontend / mobile / devops)
    - Risco de regressão: o que a correção pode quebrar
    - Teste de regressão a escrever: qual, onde e por que ele falha hoje
    - **Fora de escopo:** o que foi encontrado mas não será corrigido agora → registrar em `PENDENCIAS.md` (data, contexto, dono ou "sem dono", critério de pronto) ou como `// TODO(dono): motivo` no código
13. Apresentar o Plano de Correção ao usuário e **aguardar aprovação explícita** antes de continuar. Quando o plano for grande (várias camadas ou muitos arquivos), oferecer a escolha entre **corrigir na conversa** ou **delegar ao agente da camada** (`backend-dev`, `frontend-dev`, `mobile-dev` ou `devops-cicd`), informando que a delegação custa mais tokens e que a correção na conversa aumenta o contexto e pode levar à compactação

### Fase 6 — Correção e verificação (somente após aprovação)

14. Corrigir na conversa principal, com a skill `debugging` e as skills da stack já carregadas. Se o usuário escolher delegar, usar um prompt com stack detectada, caminhos exatos das skills, escopo (camada e seção do laudo) e formato de saída (resumo e lista de arquivos alterados):
    - Escrever **primeiro** o teste de regressão e confirmar que ele **falha** no código atual
    - Quando o diagnóstico se deu apenas por evidência de código (sem um caso reproduzível na Fase 1), converter essa evidência num teste que exercite o defeito antes da correção; se for comprovadamente impossível escrever tal teste, registrar a exceção no laudo com justificativa em vez de pular a verificação
    - Aplicar a correção; confirmar que o teste passa e que a suíte existente não regride
    - Varrer com `Grep` as ocorrências do mesmo padrão de defeito e corrigir apenas as aprovadas
15. Atualizar o laudo com a correção efetivamente aplicada; listar arquivos alterados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-bugfix login-retorna-500
/fullstack-development:new-bugfix "lista de produtos duplica itens ao rolar"   # camada Mobile se projeto Android/Flutter
/fullstack-development:new-bugfix pipeline-falha-no-push-da-imagem             # camada DevOps (falha de pipeline)
/fullstack-development:new-bugfix calculo-de-desconto-arredonda-errado
```
