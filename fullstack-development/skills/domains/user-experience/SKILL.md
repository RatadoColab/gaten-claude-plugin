---
name: user-experience
description: >
  This skill should be used when a user asks how to design or improve a user interface,
  user flow, or interaction — including questions about loading states, empty states,
  error messages, forms and validation, accessibility (a11y), microcopy, dark mode,
  mobile-first design, motion/animation, or usability testing. Typical triggers:
  "how should I handle this empty state?", "review the UX of this flow",
  "what's the best way to show a loading indicator?", "is this error message good?",
  "how do I make this accessible?", "write microcopy for this button",
  "design a toast notification pattern", "should I use a modal or inline here?".
version: 0.2.0
---

# User Experience — UX e Fluxos de Usuário

## Visão Geral

Diretrizes para criar interfaces que oferecem experiência clara, previsível e satisfatória ao usuário, cobrindo desde princípios fundamentais até padrões específicos de estado, formulários, acessibilidade e microcopy.

---

## 1. Princípios Fundamentais (Heurísticas de Nielsen)

Toda interface deve respeitar as dez heurísticas de usabilidade de Nielsen como base mínima:

1. **Visibilidade do status do sistema** — o usuário sabe o que está acontecendo a todo momento (ex: barra de progresso, indicador de carregamento, breadcrumb ativo)
2. **Correspondência com o mundo real** — usar a linguagem do usuário, não jargão técnico; ordenar informações de forma natural
3. **Controle e liberdade** — oferecer "desfazer" e saídas claras; nunca prender o usuário em um fluxo sem saída
4. **Consistência e padrões** — ações iguais produzem resultados iguais; seguir convenções da plataforma
5. **Prevenção de erros** — preferir prevenir erros a apenas reportá-los; usar validação progressiva em formulários
6. **Reconhecimento em vez de memória** — tornar opções e ações visíveis; não exigir que o usuário lembre de informações entre telas
7. **Flexibilidade e eficiência** — oferecer atalhos para usuários avançados sem comprometer iniciantes
8. **Design estético e minimalista** — cada elemento sem valor direto compete com os que têm; remover o que não serve ao usuário
9. **Recuperação de erros** — mensagens de erro em linguagem clara, descrevendo o problema e sugerindo solução
10. **Ajuda e documentação** — quando necessário, fornecer ajuda contextual, breve e orientada à tarefa

---

## 2. Carga Cognitiva

Reduzir a carga cognitiva é o principal meio de diminuir fricção. Aplicar:

- **Divulgação progressiva (progressive disclosure):** mostrar apenas o que é essencial agora; revelar opções avançadas sob demanda
  ```
  // Exemplo: formulário de endereço
  // Exibir apenas CEP, rua e número inicialmente
  // Revelar "Complemento" e "Referência" via toggle "Adicionar detalhes"
  ```
- **Chunking:** agrupar informações relacionadas em blocos visuais distintos (max 5–7 itens por grupo)
- **Defaults inteligentes:** pré-preencher campos com o valor mais provável para o contexto do usuário
- **Persistir estado entre navegações:** filtros aplicados, posição de scroll e seleções devem sobreviver à navegação e ao recarregamento quando fizer sentido
- **Labels persistentes:** nunca substituir labels por placeholders — o usuário perde a referência ao começar a digitar

---

## 3. Estados da Interface

Todo componente ou tela que depende de dados externos deve tratar **explicitamente** os quatro estados abaixo. A ausência de qualquer um é um bug de UX.

### 3.1 Estado de Carregamento

**Prefira skeleton screens a spinners:**
- Skeleton screens reduzem em ~30% o tempo de carregamento *percebido* e evitam layout shift quando o conteúdo real chega
- Spinners são aceitáveis apenas para ações pontuais e curtas (< 1 segundo), como submissão de formulário
- Adicionar animação sutil de pulso ao skeleton para indicar atividade

> Ver exemplo (SkeletonCard + Button loading) em [`references/code-examples.md`](references/code-examples.md).

**Regras de tempo:**
- < 100ms: nenhuma indicação necessária
- 100ms – 1s: spinner ou skeleton
- > 1s: skeleton com estimativa de progresso quando possível
- > 10s: barra de progresso com possibilidade de cancelamento

### 3.2 Estado Vazio

O estado vazio determina se o usuário continua ou abandona o produto. Um estado vazio eficaz deve:

1. Explicar **por que** a tela está vazia ("Você ainda não criou nenhum projeto")
2. Dizer **o que fazer a seguir** (botão CTA claro: "Criar primeiro projeto")
3. Definir **expectativas** sobre o que aparecerá após a ação

> Ver exemplo completo em [`references/code-examples.md`](references/code-examples.md).

Diferenciar estados vazios por origem:
- **Primeira vez:** mensagem de boas-vindas + CTA de onboarding
- **Filtro sem resultado:** sugerir limpar filtros ou alterar busca
- **Sem permissão:** explicar a restrição e a quem recorrer

### 3.3 Estado de Erro

Erros são o momento mais crítico da jornada — o usuário já encontrou um problema.

**Estrutura de mensagem de erro:**
1. O que aconteceu (sem jargão técnico)
2. Por que aconteceu (quando o usuário tem controle)
3. O que fazer agora (ação concreta)

> Ver exemplo completo em [`references/code-examples.md`](references/code-examples.md).

**Regras adicionais:**
- Nunca usar vermelho como único indicador de erro — adicionar ícone e texto para acessibilidade
- Erros de formulário: exibir inline após blur — ver seção Formulários.
- Ações destrutivas irreversíveis sempre pedem confirmação modal com descrição clara da consequência
- Preservar o conteúdo do formulário após erro; nunca limpar o que o usuário preencheu

### 3.4 Estado Offline / Sem Conexão

- Detectar via `navigator.onLine` e o evento `offline`
- Exibir banner persistente não-intrusivo informando a ausência de conexão
- Permitir navegação em conteúdo já carregado (cache local)
- Encapsular ações que requerem rede (formulários, submissões) com feedback de "salvará quando reconectar"
- Retentar automaticamente requests pendentes quando a conexão for restaurada (evento `online`)
- Distinguir offline de erro de servidor — mensagens e iconografia diferentes

```javascript
// Detect connection state changes
window.addEventListener('offline', () => showOfflineBanner());
window.addEventListener('online', () => { hideOfflineBanner(); retryPendingRequests(); });
```

### 3.5 Estado de Sucesso

- Confirmar visualmente o que foi realizado com linguagem específica: "Relatório salvo" em vez de "Sucesso"
- Toasts para confirmações não bloqueantes; duração padrão de 3–5 segundos, com opção de fechar manualmente
- Após ações de criação, redirecionar para o item criado ou exibir atualização inline sem recarregar a página

---

## 4. Feedback Visual e Micro-interações

Micro-interações comunicam estado, guiam atenção e tornam a interface responsiva ao toque.

- **Hover/foco:** indicar interatividade com mudança sutil de cor ou sombra (não apenas cursor)
- **Active state:** compressão visual leve em botões ao clicar (scale 0.97)
- **Transição de estado:** animar mudanças de estado em 150–300ms com easing `ease-out`; evitar mudanças abruptas
- **Ações assíncronas:** desabilitar o botão durante o envio para evitar submissões duplas; restaurar ao concluir

> Ver exemplo completo em [`references/code-examples.md`](references/code-examples.md).

**Notificações e alertas:**
- **Toast (não bloqueante):** confirmações de ação bem-sucedida, avisos de baixa urgência
- **Banner inline:** erros ou avisos que afetam o contexto atual e precisam de atenção contínua
- **Modal/dialog:** confirmação de ação destrutiva ou decisão importante que requer resposta imediata
- **Tooltip:** informação suplementar ao hover — nunca usar para informação essencial à tarefa

---

## 5. Formulários (ângulo UX)

Princípios de UX para formulários — implementação completa (validação, erros, acessibilidade, multi-step, upload, inputs BR) em `../forms/SKILL.md`, a fonte autoritativa:

- **Ordem e layout:** seguir a sequência que o usuário pensa; labels acima dos campos; coluna única até 5 campos
- **Validação:** no `blur`, nunca a cada tecla; erros inline e específicos ("Informe um e-mail válido (ex: usuario@dominio.com)")
- **CTAs:** verbo da ação ("Criar conta", "Salvar alterações"), não "OK"/"Confirmar"; primário à direita
- **Campos:** exibir formato esperado como hint (`DD/MM/AAAA`); `autocomplete` padronizado; nunca `autocomplete="off"` em login

---

## 6. Tópicos Avançados (carregar sob demanda)

Os tópicos abaixo foram movidos para references por tema — carregar apenas quando a tarefa exigir:

- **Mobile-first, alvos de toque, breakpoints e gestos:** [`references/mobile-responsive.md`](references/mobile-responsive.md)
- **Dark mode, motion design e acessibilidade (a11y):** [`references/motion-darkmode-a11y.md`](references/motion-darkmode-a11y.md)
- **UX writing/microcopy, onboarding progressivo, fluxos de usuário e testes de usabilidade:** [`references/ux-writing-flows.md`](references/ux-writing-flows.md)

Pontos a não esquecer mesmo sem abrir os references:
- **Acessibilidade:** WCAG 2.2 AA é o mínimo; contraste 4.5:1 (texto normal); teclado + `focus-visible`; HTML semântico antes de ARIA. Fonte autoritativa de a11y: `../ui-components/SKILL.md`.
- **Mobile:** alvo de toque mínimo 44×44px; projetar mobile-first.
- **Motion:** respeitar `prefers-reduced-motion`.

---

## Referências

- [Nielsen Norman Group — Skeleton Screens](https://www.nngroup.com/articles/skeleton-screens/)
- [Nielsen Norman Group — Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)
- [WCAG 2.2 — Web Content Accessibility Guidelines](https://www.w3.org/TR/WCAG22/)
- [Carbon Design System — Loading Pattern](https://carbondesignsystem.com/patterns/loading-pattern/)
- [Smashing Magazine — Inclusive Dark Mode](https://www.smashingmagazine.com/2025/04/inclusive-dark-mode-designing-accessible-dark-themes/)
- [Bunnyfoot — Form Error Best Practices](https://www.bunnyfoot.com/2024/01/13-best-practices-to-design-error-friendly-forms/)
- [UXPin — Progressive Disclosure](https://www.uxpin.com/studio/blog/what-is-progressive-disclosure/)
