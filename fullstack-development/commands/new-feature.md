---
description: Inicia o desenvolvimento de uma nova feature fullstack, identificando a stack em uso e acionando os agentes backend-dev, frontend-dev (web) e/ou mobile-dev (Android/Flutter) — e, somente quando a demanda incluir solicitações explícitas de DevOps/infra, também o devops-cicd — com as skills relevantes para cada contexto.
argument-hint: <nome-da-feature>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-feature

Guiar o desenvolvimento de uma nova feature com fluxo spec-first: gera especificação estruturada, submete à revisão paralela de domínio e consolida um plano final para aprovação antes de qualquer implementação.

## Processo

### Detecção de escopo Mobile (gatilho por stack ou pedido explícito)

Avaliar a demanda do usuário e o projeto em busca de sinais mobile. Considerar a trilha Mobile **acionada** quando:

- o projeto contiver `pubspec.yaml`, `AndroidManifest.xml`, arquivos `.kt` ou `.dart`
- o código usar `@Composable`, imports Jetpack (`androidx.*`), ou `flutter/material.dart`
- o usuário solicitar explicitamente app/tela/componente mobile, Android, Compose, Flutter ou Dart

**Quando acionado:** gerar seção **Mobile** na spec. A trilha Mobile e a trilha Frontend web são **independentes e podem coexistir** (projeto só-mobile → apenas Mobile; fullstack com app → Backend + Mobile; fullstack com web + app → Backend + Frontend + Mobile). Em projetos sem qualquer frontend web, a trilha Mobile assume o papel de cliente único.

**Quando não acionado:** seguir o fluxo backend/frontend inalterado. Projetos web sem sinal mobile **não** criam seção Mobile.

---

### Detecção de escopo DevOps (gatilho condicional)

Avaliar a demanda do usuário em busca de **solicitações explícitas** de DevOps. Considerar a trilha DevOps **acionada** quando a demanda mencionar qualquer um destes sinais:

- pipeline / CI-CD / build automatizado
- Dockerfile / containerização / imagem
- deploy / OpenShift / Kubernetes / manifests / Route
- infraestrutura / Terraform / IaC / provisionamento / GitOps
- observabilidade / monitoramento / métricas / logs / alertas / SLO
- segurança de pipeline / DevSecOps / scans / secrets no pipeline

**Regra "se, e apenas se":** se nenhum sinal explícito estiver presente, **não** criar seção DevOps e **não** acionar o `devops-cicd` — seguir o fluxo backend/frontend inalterado. Implicações indiretas de infra (sem pedido explícito) **não** acionam a trilha.

### Fase 1 — Identificação de stack

1. Identificar a stack do projeto (linguagens, frameworks, estrutura de diretórios) e aplicar as detecções de escopo Mobile e DevOps
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/backend-base/SKILL.md`
3. **Se trilha Mobile acionada:**
   - Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/mobile-base/SKILL.md`
   - **Android nativo:** carregar `${CLAUDE_PLUGIN_ROOT}/skills/languages/kotlin/SKILL.md`, `${CLAUDE_PLUGIN_ROOT}/skills/domains/android-architecture/SKILL.md` e, quando houver UI Compose, `${CLAUDE_PLUGIN_ROOT}/skills/domains/jetpack-compose/SKILL.md`; carregar `${CLAUDE_PLUGIN_ROOT}/skills/languages/gradle/SKILL.md` se tocar build/dependências — **Compose e Flutter são mutuamente exclusivos: nunca carregar ambos**
   - **Flutter:** carregar `${CLAUDE_PLUGIN_ROOT}/skills/languages/dart/SKILL.md` e `${CLAUDE_PLUGIN_ROOT}/skills/domains/flutter/SKILL.md`; carregar `${CLAUDE_PLUGIN_ROOT}/skills/languages/gradle/SKILL.md` se tocar build Android nativo do projeto Flutter
4. **Se trilha Frontend web acionada** (presença de `.vue`/`.html`/`.twig`, componentes web, páginas, CSS, ou pedido explícito de UI web):
   - Ler `${CLAUDE_PLUGIN_ROOT}/skills/base/frontend-base/SKILL.md`
5. Com base na stack identificada, carregar skills de linguagem pertinentes adicionais (ex.: `php`, `python`, `javascript`, `vue`)

### Fase 2 — Especificação da feature (spec-dev)

6. Usar o agente `spec-dev` para criar a especificação a partir da demanda:
   - Se o usuário já tiver uma spec, validá-la e melhorá-la em vez de criar do zero
   - Sempre incluir seção **Backend**
   - **Se trilha Mobile acionada:** incluir seção **Mobile** (em vez de, ou além de, **Frontend** web) cobrindo: arquitetura de telas e navegação, gerenciamento de estado, integração com o backend (endpoints, DTOs, tratamento de erros/timeouts), estados de borda (loading/erro/vazio/sucesso) e arquivos/módulos esperados
   - **Se trilha Frontend web acionada:** incluir seção **Frontend**
   - **Somente se** a Detecção de escopo DevOps for positiva, adicionar também uma seção **DevOps/Infraestrutura** cobrindo: estratégia de pipeline/CI-CD, containerização e alvo de deploy, infraestrutura/IaC necessária, observabilidade e requisitos de segurança de pipeline
   - Incluir em todas as seções: objetivo, critérios de aceite, restrições, fluxo de dados e arquivos esperados
   - Salvar a spec em `.claude/specs/<nome-da-feature>.md`

### Fase 3 — Revisão paralela de domínio

7. Acionar **em paralelo** os agentes de domínio das trilhas ativas, cada um revisando apenas sua seção:
   - `backend-dev` — instrução: **"Revise apenas a seção Backend da spec em `.claude/specs/<nome>.md`. Aponte lacunas, riscos técnicos e ajustes necessários. NÃO escreva código — retorne somente o relatório de revisão e a seção Backend corrigida."**
   - `frontend-dev` **(quando trilha Frontend web ativa)** — instrução: **"Revise apenas a seção Frontend da spec em `.claude/specs/<nome>.md`. Aponte lacunas, riscos de UX/integração e ajustes necessários. NÃO escreva código — retorne somente o relatório de revisão e a seção Frontend corrigida."**
   - `mobile-dev` **(quando trilha Mobile ativa)** — instrução: **"Revise apenas a seção Mobile da spec em `.claude/specs/<nome>.md`. Aponte lacunas de arquitetura (MVVM/MVI, camadas data/domain/ui), gerenciamento de estado, consumo do backend (DTOs, erros, timeouts) e estados de borda (loading/erro/vazio). NÃO escreva código — retorne somente o relatório de revisão e a seção Mobile corrigida."**
   - `devops-cicd` **(apenas quando a seção DevOps/Infraestrutura existir)** — instrução: **"Revise apenas a seção DevOps/Infraestrutura da spec em `.claude/specs/<nome>.md`, limitando-se a CI/CD, containers, infraestrutura/IaC, deploy/rollback, observabilidade e segurança de pipeline. NÃO opine sobre regra de negócio do backend, modelagem de dados de aplicação nem UI/UX. NÃO escreva código — retorne somente o relatório de revisão e a seção DevOps corrigida."**
   - Cada agente deve carregar suas skills de domínio conforme a stack identificada na Fase 1:
     - `devops-cicd` carrega `devops-base` sempre e `ci-cd`/`containers`/`openshift`/`azure-devops`/`iac`/`observability`/`devsecops` conforme os sinais detectados
     - `mobile-dev` carrega `mobile-base` sempre e as skills pertinentes à stack (Android ou Flutter) identificada na Fase 1

   Formato esperado de cada relatório de revisão:
   ```markdown
   ## Revisão [Backend|Frontend|Mobile|DevOps/Infraestrutura] — <nome-da-feature>

   ### Gaps identificados
   - [gap]: descrição

   ### Riscos
   - [risco]: descrição e mitigação sugerida

   ### Seção [Backend|Frontend|Mobile|DevOps/Infraestrutura] corrigida
   [texto revisado da seção]
   ```

### Fase 4 — Plano final e aprovação

8. Consolidar spec original + feedbacks dos agentes acionados em um **Plano Final** contendo:
   - Spec revisada unificada (todas as seções existentes: Backend, Frontend, Mobile e/ou DevOps/Infraestrutura conforme ativas)
   - Lista de arquivos a criar/modificar separados por escopo (backend / frontend / mobile / devops)
   - Pontos de atenção levantados pelos agentes
   - Estimativa de impacto em arquivos existentes
9. Apresentar o Plano Final ao usuário e **aguardar aprovação explícita** antes de continuar

### Fase 5 — Implementação (somente após aprovação)

10. Para cada parte aprovada:
    - Carregar skills de domínio conforme o contexto da feature
    - Implementar seguindo o Plano Final aprovado
11. Ao final, listar arquivos criados/modificados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-feature autenticacao-usuario
/fullstack-development:new-feature modulo-relatorios
/fullstack-development:new-feature tela-listagem-produtos      # aciona mobile-dev se projeto Android/Flutter
/fullstack-development:new-feature sincronizacao-offline-app   # fullstack: backend + mobile-dev
```
