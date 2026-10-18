---
description: Revisão pré-release, executada uma vez por release sobre tudo o que será lançado (ou o código todo, se o intervalo não puder ser detectado) — avalia conformidade com as skills do plugin, coerência entre camadas e prontidão de release, e encerra sugerindo a auditoria do agente security-reviewer. Para bugs pontuais, usar o /code-review nativo.
argument-hint: [intervalo-git | ref | caminho]
allowed-tools: [Read, Grep, Glob, Bash(git log:*), Bash(git rev-list:*), Bash(git diff:*), Bash(git describe:*), Bash(git tag:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git branch:*), Bash(git status:*)]
---

# release-review

Revisar, **uma vez por release**, o conjunto de mudanças que será lançado. Não é um comando para cada feature implantada: o foco é o que o `/code-review` nativo não conhece — conformidade com as skills do plugin, coerência entre camadas e prontidão de release. Bugs pontuais de lógica ficam com o `/code-review` nativo; a auditoria de segurança fica com o agente `security-reviewer`.

## Processo

### Fase 1 — Escopo da release

Definir o escopo pela primeira regra que se aplicar:

1. **Argumento com intervalo ou ref** (`v0.7.2..HEAD`, `v0.7.2`): usar o argumento. **Argumento com caminho:** código todo desse caminho
2. **Última tag alcançável** (`git describe --tags --abbrev=0`): intervalo `<tag>..HEAD`
3. **Sem tags, em branch diferente de `main`/`master`:** obter a base com `git merge-base <principal> HEAD` e usar o intervalo `<sha>..HEAD`, em duas chamadas separadas (sem substituição de comando)
4. **Sem repositório git ou intervalo vazio:** código todo, ignorando `vendor/`, `node_modules/`, diretórios de build e artefatos gerados

Em qualquer caso, antes de revisar, apresentar ao usuário e **pedir confirmação**: o intervalo, o número de commits (`git rev-list --count <intervalo>`), as mensagens de commit resumidas e os arquivos agrupados por trilha. Em releases grandes (acima de ~80 arquivos), propor uma ordem de revisão por trilha e criticidade.

### Fase 2 — Trilhas e skills

1. Detectar as trilhas pelos arquivos do escopo:
   - **Backend:** PHP, Python, JS/Node.js, Go, SQL, controllers, services, repositories
   - **Frontend web:** Vue, HTML, Twig, CSS, componentes, páginas
   - **Mobile Android:** Kotlin, `.kt`, `@Composable`, imports `androidx.*`, `AndroidManifest.xml`
   - **Mobile Flutter:** Dart, `.dart`, `pubspec.yaml`, `flutter/material.dart`
   - **DevOps/Infra:** `Dockerfile`/`Containerfile`; unidades Quadlet (`*.container`/`*.pod`/`*.volume`/`*.network`); YAML com `apiVersion:`+`kind:` (manifests Kubernetes/OpenShift); `Chart.yaml`/`kustomization.yaml`; `.gitlab-ci.yml`/`.github/workflows/`/`azure-pipelines.yml`; `*.tf`
2. Ler `${CLAUDE_PLUGIN_ROOT}/skills/fullstack-router/SKILL.md` e carregar, por caminho, a skill base da trilha (`<tipo>-base`; mobile: `mobile-base`; DevOps/Infra: `devops-base`) e as skills de domínio e de linguagem que a tabela indicar para a stack detectada
3. Respeitar as exclusões do router: Compose e Flutter são mutuamente exclusivos; `podman` e `kubernetes` são mutuamente exclusivos; em Node, carregar `javascript` + `nodejs` juntas; em GLPI, apenas a árvore da versão detectada (sem indício, perguntar a versão)

### Fase 3 — Dimensões de revisão

Revisar o escopo, lendo fora do diff o contexto necessário (chamadores, consumidores, contratos):

- **Conformidade com as skills:** padrões da linguagem e do domínio (incluindo KDoc/DartDoc para mobile) e restrições absolutas da árvore GLPI detectada
- **Coerência fullstack:** contratos de API alterados versus consumidores (web e mobile), tipos e DTOs consistentes entre camadas, tratamento de erros, timeouts e cancelamento de coroutines/futures
- **Prontidão de release:**
  - migrações de banco reversíveis e na ordem correta
  - novas variáveis de ambiente e configurações documentadas
  - dependências novas ou atualizadas
  - restos de depuração (`var_dump`, `dd(`, `console.log`, `print(`)
  - `TODO` sem dono
  - features da release ausentes no `CHANGELOG.md` do projeto, se existir
  - artefatos de DevOps coerentes com a mudança
- **Segurança:** apenas sinalizar o que for evidente durante a leitura; a auditoria é do `security-reviewer`

### Fase 4 — Relatório

1. Sumário: intervalo revisado, trilhas e veredito (**pronta**, **pronta com ressalvas** ou **bloqueada**)
2. Achados por severidade (crítico, aviso, sugestão), cada um com trilha, `arquivo:linha` e o que corrigir. Nenhum achado pode ser omitido por limite de tamanho
3. Registrar o que ficou fora da revisão, se houver

### Encerramento (obrigatório)

Sempre terminar o relatório com a mensagem abaixo, preenchendo o intervalo, as trilhas ativas e os caminhos das skills já resolvidos na Fase 2 (para o agente não redetectar a stack):

> Para concluir a preparação da release, recomendo a auditoria de segurança com contexto limpo. Copie e execute:
>
> `Use o agente security-reviewer para auditar a release <intervalo>. Trilhas: <trilhas>. Skills: <caminhos das skills>.`
>
> Para bugs pontuais de lógica nas mudanças, use também o `/code-review` nativo.

## Dicas de Uso

```
/fullstack-development:release-review
/fullstack-development:release-review v0.7.2..HEAD
/fullstack-development:release-review src/
```
