# gaten-claude-plugin

Marketplace local de plugins Claude Code mantido pela equipe **Equipe GATEN**.

## O que é isso?

Este repositório centraliza plugins reutilizáveis para o [Claude Code](https://claude.ai/code), organizados para uso compartilhado pela equipe. Cada plugin é um diretório autocontido com agentes, skills e commands prontos para carregar em qualquer projeto.

## Plugins disponíveis

| Plugin | Versão | Descrição |
|--------|--------|-----------|
| [`fullstack-development`](./fullstack-development/) | 0.2.0 | Desenvolvimento fullstack com agentes especializados em spec, backend, frontend e DevOps/CI-CD |

## Como usar

### Carregando um plugin no Claude Code

```bash
# Apontar o Claude Code para este diretório de plugins
cc --plugin-dir /caminho/para/gaten-claude-plugin
```

### Verificar o que foi carregado

```bash
# Dentro de uma sessão Claude Code
/agents       # lista agentes disponíveis
/skills       # lista skills carregadas
```

## Plugin: fullstack-development

Plugin modular para desenvolvimento fullstack com agentes especializados por área de atuação.

### Agentes

| Agente | Cor | Gatilhos típicos |
|--------|-----|-----------------|
| `spec-dev` | blue | "revise esta spec", "valide a especificação" |
| `backend-dev` | green | "desenvolva o backend", "implemente a API", "crie o endpoint" |
| `frontend-dev` | cyan | "desenvolva o frontend", "crie o componente", "implemente o formulário" |
| `devops-cicd` | yellow | "crie o pipeline", "configure o CI/CD", "configure o Azure DevOps", "escreva o Dockerfile", "faça deploy no OpenShift", "provisione a infraestrutura" |

### Slash commands

```
/fullstack-development:review-spec    — revisão completa de especificação de feature
/fullstack-development:new-feature    — iniciar desenvolvimento de nova feature
/fullstack-development:code-review    — revisão de código fullstack
```

### Skills incluídas

**Base** (carregadas automaticamente por cada agente):
- `spec-base`, `backend-base`, `frontend-base`, `devops-base`

**Domínios:**
- `spec-review`, `api-rest`, `database`, `security`, `forms`, `ui-components`, `user-experience`
- DevOps/CI-CD: `ci-cd`, `containers`, `openshift`, `azure-devops`, `iac`, `observability`, `devsecops`
- `glpi` — com sub-skills: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue`

**Linguagens:**
- `python`, `php`, `javascript`, `vue`, `twig`, `html`

**Precedência de carregamento:** GLPI > Languages > Domains

## Estrutura do repositório

```
gaten-claude-plugin/
├── .claude-plugin/
│   └── marketplace.json          ← registro de plugins do marketplace
├── fullstack-development/        ← plugin fullstack
│   ├── .claude-plugin/
│   │   └── plugin.json           ← manifesto do plugin
│   ├── agents/                   ← spec-dev, backend-dev, frontend-dev, devops-cicd
│   ├── commands/                 ← review-spec, new-feature, code-review
│   ├── skills/
│   │   ├── base/                 ← skills base por agente
│   │   ├── domains/              ← skills de domínio (inclui glpi/)
│   │   └── languages/            ← skills por linguagem
│   ├── CLAUDE.md
│   └── CHANGELOG.md
└── README.md
```

## Adicionando um novo plugin

1. Crie um diretório com o nome do plugin na raiz deste repositório.
2. Adicione o manifesto `.claude-plugin/plugin.json` com `name`, `version`, `description` e `authors`.
3. Registre o plugin em `.claude-plugin/marketplace.json`:

```json
{
  "name": "gaten-marketplace",
  "owner": { "name": "Equipe GATEN" },
  "plugins": [
    {
      "name": "nome-do-plugin",
      "source": "./nome-do-plugin",
      "description": "Descrição breve do plugin"
    }
  ]
}
```

## Autores

- André Proto — <andre.proto@gmail.com>
- Aparecido Hermogenes Leite — <soulrunna@gmail.com>
