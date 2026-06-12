# Dark Mode, Motion Design e Acessibilidade

Detalhamento de dark mode, animação e acessibilidade na camada de UX. Resumo no `SKILL.md`.
Para acessibilidade aprofundada (WCAG, ARIA), `../ui-components/SKILL.md` é a fonte autoritativa.

## Dark Mode

- Implementar como **preferência do usuário**, respeitando `prefers-color-scheme` do sistema por padrão, com toggle explícito para sobrescrever
- Usar cinza escuro (`#121212` ou similar) em vez de preto puro — reduz fadiga visual
- Nunca inverter imagens ou ícones coloridos — usar variantes específicas para dark mode
- Manter contraste mínimo WCAG AA (ver Acessibilidade para valores exatos)
- Evitar sombras escuras em dark mode — substituir por bordas sutis ou elevação via cor

> Ver exemplo completo em [`code-examples.md`](code-examples.md).

## Motion Design e Animação

### Princípios

- Animação deve **comunicar** (transição de estado, hierarquia, causalidade) — não decorar
- Duração recomendada: 100–150ms para microinterações, 200–400ms para transições de tela
- Easing padrão: `ease-out` para entradas (elementos que chegam), `ease-in` para saídas (elementos que partem)

### Acessibilidade de Movimento

- Respeitar `prefers-reduced-motion: reduce` — desabilitar ou simplificar animações para usuários sensíveis
- Animações com flicker ou movimento rápido podem desencadear crises em usuários com epilepsia fotossensível

> Ver exemplo completo em [`code-examples.md`](code-examples.md).

## Acessibilidade (a11y)

- **WCAG 2.2 AA** é o padrão mínimo exigido; o WCAG 3.0 está em elaboração
- Contraste mínimo: **4.5:1** para texto normal, **3:1** para texto grande (≥ 18pt ou ≥ 14pt bold)
- Todo elemento interativo deve ser acessível via teclado e ter `focus-visible` visível
- Usar HTML semântico antes de atribuir `role` ARIA — `<button>` em vez de `<div role="button">`
- Imagens informativas precisam de `alt` descritivo; imagens decorativas devem ter `alt=""`
- Ordem de leitura do DOM deve coincidir com a ordem visual para usuários de screen reader
