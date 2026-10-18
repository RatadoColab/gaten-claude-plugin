---
description: Inicia o desenvolvimento de uma nova feature fullstack com fluxo spec-first, conduzido na conversa principal — identifica a stack, especifica a feature (Backend, Frontend web, Mobile e/ou DevOps/Infraestrutura), oferece uma revisão independente opcional pelo spec-dev, consolida o plano para aprovação e só então implementa.
argument-hint: <nome-da-feature>
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---

# new-feature

Guiar o desenvolvimento de uma nova feature com fluxo spec-first: especifica a feature, oferece revisão independente opcional e consolida um plano final para aprovação antes de qualquer implementação. Todas as fases rodam na conversa principal, com as skills carregadas uma única vez.

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
- Dockerfile/Containerfile / containerização / imagem
- Podman / Quadlet / rootless / systemd
- deploy / OpenShift / Kubernetes / manifests / Route / Gateway API / Helm / Kustomize
- infraestrutura / Terraform / IaC / provisionamento / GitOps
- observabilidade / monitoramento / métricas / logs / alertas / SLO
- segurança de pipeline / DevSecOps / scans / secrets no pipeline

**Regra "se, e apenas se":** se nenhum sinal explícito estiver presente, **não** criar seção DevOps e **não** carregar skills DevOps — seguir o fluxo backend/frontend inalterado. Implicações indiretas de infra (sem pedido explícito) **não** acionam a trilha.

### Fase 1 — Identificação de stack

1. Identificar a stack do projeto (linguagens, frameworks, estrutura de diretórios) e aplicar as detecções de escopo Mobile e DevOps. Se o contexto da sessão já trouxer a linha de stack detectada, usá-la como ponto de partida
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/fullstack-router/SKILL.md` — índice com a tabela de skills e caminhos, as regras de detecção de stack/versão e a precedência de carregamento
3. Carregar, pelos caminhos do índice, a skill base de cada trilha ativa: `backend-base` (sempre), `mobile-base` (se trilha Mobile acionada), `frontend-base` (se trilha Frontend web acionada — presença de `.vue`/`.html`/`.twig`, componentes web, páginas, CSS, ou pedido explícito de UI web) e `devops-base` (se trilha DevOps acionada)
4. **Se trilha Mobile acionada:** carregar as skills da stack (Android nativo ou Flutter) e `gradle` se tocar build, conforme o índice — **Compose e Flutter são mutuamente exclusivos: nunca carregar ambos**
5. **Se trilha DevOps acionada:** carregar as skills de domínio DevOps conforme os sinais detectados (`ci-cd`, `containers`, `podman` **ou** `kubernetes` — mutuamente exclusivos —, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`)
6. Com base na stack identificada, carregar as skills de linguagem e de domínio pertinentes adicionais, conforme o índice. Em plugin GLPI, determinar a versão-alvo e carregar **apenas uma** das três árvores; sem indício em nenhuma direção, **perguntar** ao usuário antes de gerar código — nunca assumir um default

### Fase 2 — Especificação da feature

7. Especificar a feature a partir da demanda:
   - Se o usuário já tiver uma spec, validá-la e melhorá-la em vez de criar do zero
   - Sempre incluir seção **Backend**
   - **Se trilha Mobile acionada:** incluir seção **Mobile** (em vez de, ou além de, **Frontend** web) cobrindo: arquitetura de telas e navegação, gerenciamento de estado, integração com o backend (endpoints, DTOs, tratamento de erros/timeouts), estados de borda (loading/erro/vazio/sucesso) e arquivos/módulos esperados
   - **Se trilha Frontend web acionada:** incluir seção **Frontend**
   - **Somente se** a Detecção de escopo DevOps for positiva, adicionar também uma seção **DevOps/Infraestrutura** cobrindo: estratégia de pipeline/CI-CD, containerização e alvo de deploy, infraestrutura/IaC necessária, observabilidade e requisitos de segurança de pipeline
   - Incluir em todas as seções: objetivo, critérios de aceite, restrições, fluxo de dados e arquivos esperados
   - Salvar a spec em `.claude/specs/<nome-da-feature>.md`

### Fase 3 — Revisão independente (opcional)

8. Sugerir ao usuário uma revisão independente pelo agente `spec-dev` (somente leitura, contexto limpo) quando a spec tiver 3 ou mais trilhas, envolver autenticação/autorização, pagamento, dados sensíveis ou migração de dados, ou quando o usuário pedir. Em specs pequenas, seguir direto para a Fase 4. A revisão nunca é obrigatória
9. Se o usuário aceitar, acionar **um único** `spec-dev` com um prompt contendo:
   - **Stack detectada** (linha do contexto da sessão ou resultado da Fase 1)
   - **Caminhos exatos das skills** de cada trilha ativa, para o agente não redetectar a stack
   - **Escopo:** trilhas ativas e caminho da spec em `.claude/specs/<nome>.md`
   - **Formato de saída:** gaps por trilha (do mais crítico ao menos crítico), riscos com mitigação e lista de alterações propostas (o quê, onde, por quê), sem repetir a spec — nenhum achado omitido por tamanho
10. Avaliar o relatório, aplicar as alterações aceitas na spec e gravá-la novamente

### Fase 4 — Plano final e aprovação

11. Consolidar a spec e, quando houver, o relatório da revisão em um **Plano Final** contendo:
    - Spec unificada (todas as seções ativas: Backend, Frontend, Mobile e/ou DevOps/Infraestrutura)
    - Lista de arquivos a criar/modificar separados por escopo (backend / frontend / mobile / devops)
    - Pontos de atenção levantados pela revisão, se houve
    - Estimativa de impacto em arquivos existentes
12. Apresentar o Plano Final ao usuário e **aguardar aprovação explícita** antes de continuar. Quando o plano for grande (várias trilhas ou muitos arquivos), oferecer a escolha entre **implementar na conversa** ou **delegar ao agente da trilha** (`backend-dev`, `frontend-dev`, `mobile-dev` ou `devops-cicd`), informando que a delegação custa mais tokens e que a implementação na conversa aumenta o contexto e pode levar à compactação

### Fase 5 — Implementação (somente após aprovação)

13. Implementar o Plano Final aprovado na conversa principal, com as skills já carregadas na Fase 1. Se o usuário escolher delegar, usar um prompt com stack detectada, caminhos exatos das skills, escopo (trilha e seção da spec) e formato de saída (resumo e lista de arquivos alterados)
14. Ao final, listar arquivos criados/modificados e pontos de atenção para testes

## Dicas de Uso

```
/fullstack-development:new-feature autenticacao-usuario
/fullstack-development:new-feature modulo-relatorios
/fullstack-development:new-feature tela-listagem-produtos      # trilha Mobile se projeto Android/Flutter
/fullstack-development:new-feature sincronizacao-offline-app   # fullstack: trilhas Backend + Mobile
```
