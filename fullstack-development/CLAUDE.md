# fullstack-development Plugin — Contexto Local

Plugin Claude Code modular para desenvolvimento fullstack. Construído em maio/2026.

## Instalação e Teste

```bash
# Instalar localmente para testar
cc --plugin-dir /home/andre/projetos/IBGE/gaten-claude-plugin

# Verificar agentes carregados
/agents

# Testar commands disponíveis
/fullstack-development:review-spec
/fullstack-development:new-feature
/fullstack-development:code-review
```

## Estrutura do Plugin

```
.claude-plugin/plugin.json     ← manifesto (nome: fullstack-development)
agents/                        ← 3 agentes: spec-dev, backend-dev, frontend-dev
skills/
  base/                        ← 1 skill base por agente
  domains/                     ← 8 skills de domínio (glpi tem 4 sub-skills)
  languages/                   ← 6 skills de linguagem
commands/                      ← 3 slash commands
```

## Agentes e Gatilhos

| Agente | Gatilhos típicos | Color |
|--------|-----------------|-------|
| `spec-dev` | "revise esta spec", "valide a especificação" | blue |
| `backend-dev` | "desenvolva o backend", "implemente a API", "crie o endpoint" | green |
| `frontend-dev` | "desenvolva o frontend", "crie o componente", "implemente o formulário" | cyan |

## Organização das Skills

- **Base** (`skills/base/`): carregadas automaticamente por cada agente ao iniciar
- **Domínio** (`skills/domains/`): `spec-review`, `api-rest`, `database`, `security`, `forms`, `glpi`, `ui-components`, `user-experience`
  - `glpi` tem sub-skills aninhadas em `skills/domains/glpi/`: `ajax-handlers`, `form-templates`, `plugin-creation`, `vue`
- **Linguagem** (`skills/languages/`): `python`, `php`, `javascript`, `vue`, `twig`, `html`

## Padrão de Carregamento de Skills pelos Agentes

Cada agente instrui explicitamente quais skills carregar via `${CLAUDE_PLUGIN_ROOT}`:

```
${CLAUDE_PLUGIN_ROOT}/skills/base/<agente>-base/SKILL.md        ← sempre
${CLAUDE_PLUGIN_ROOT}/skills/domains/<dominio>/SKILL.md          ← conforme contexto
${CLAUDE_PLUGIN_ROOT}/skills/languages/<linguagem>/SKILL.md      ← conforme stack
```

## Precedência de Carregamento de Skills

Quando múltiplas skills são candidatas, a ordem de prioridade é: **GLPI > Languages > Domains**. Skills de domínio GLPI têm precedência sobre skills de linguagem, que têm precedência sobre domínios genéricos.

## Decisões de Design

- Skills organizadas em subdirs (`base/`, `domains/`, `languages/`) para separação clara por responsabilidade
- Commands em `commands/` (formato legado, mas intencional para slash commands diretos)
- Skills com conteúdo mínimo — intencionalmente para expansão posterior
- JavaScript cobre backend (Node.js) e frontend no mesmo arquivo de skill
- `authors` no plugin.json (array) em vez de `author` (objeto único)

## Autores

- André Proto <andre.proto@gmail.com>
- Aparecido Hermogenes Leite <soulrunna@gmail.com>

## Próximos Passos Sugeridos

- Expandir o conteúdo de cada `SKILL.md` com `references/` detalhados
- Adicionar `examples/` às skills de linguagem com snippets prontos
- Considerar hooks para validação automática de specs antes de commits
- Testar gatilhos dos agentes em cenários reais de desenvolvimento
