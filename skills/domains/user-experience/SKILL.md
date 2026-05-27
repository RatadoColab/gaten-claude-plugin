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

```jsx
// Skeleton — preferido para listas e cards
<SkeletonCard lines={3} avatarSize="md" />

// Spinner — aceitável para ações pontuais
<Button loading={isSubmitting}>Salvar</Button>
```

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

## 5. Formulários

### 5.1 Layout e Ordem

- Ordenar campos na sequência que o usuário pensa (nome → email → senha, não email → nome → senha)
- Formulários simples (≤ 5 campos): coluna única; formulários complexos: agrupar por contexto com títulos de seção
- Alinhar labels acima dos campos (não ao lado) — melhora leitura e funciona melhor em mobile

### 5.2 Validação

- Validar no `blur` do campo (quando o usuário sai), nunca ao digitar (keystroke-level) — evita frustração prematura
- Exibir erros inline, abaixo do campo, em fonte ≥ 12px
- Mensagens específicas: "Informe um e-mail válido (ex: usuario@dominio.com)" em vez de "E-mail inválido"
- Indicar campos obrigatórios claramente (asterisco + legenda); não marcar campos opcionais com "(opcional)" em formulários predominantemente obrigatórios — faça o oposto

### 5.3 Campos Especializados

**Data e hora:**
- `type="date"` tem renderização inconsistente entre browsers — avaliar uso de componente customizado para formulários críticos
- Sempre exibir o formato esperado como placeholder ou hint: `DD/MM/AAAA`
- Para intervalos de data, preferir dois campos separados (início / fim) a um date range picker complexo

**Upload de arquivo:**
- Sempre oferecer botão de clique como alternativa ao drag-and-drop (acessibilidade de teclado)
- Exibir progresso de upload com `aria-live="polite"` para leitores de tela
- Mostrar preview antes do envio quando o formato permitir (imagens)
- Limites de tamanho e tipos aceitos devem estar visíveis antes do upload, não apenas em mensagem de erro

**Autocompletar:**
- Usar atributo `autocomplete` com valores padronizados HTML (ex: `given-name`, `family-name`, `email`)
- Nunca usar `autocomplete="off"` em campos de login — browsers modernos ignoram e prejudica gerenciadores de senha
- Para busca com sugestões, implementar `aria-autocomplete`, `aria-expanded` e `aria-activedescendant` corretamente

### 5.4 CTAs de Formulário

- Usar verbos que descrevem a ação: "Criar conta", "Salvar alterações", "Enviar pedido" em vez de "Confirmar" ou "OK"
- Botão primário à direita; botão secundário ou cancelar à esquerda (padrão ocidental de leitura)
- Não desabilitar o botão de submit antes da tentativa — exibir erros após a tentativa inicial

---

## 6. Mobile-First e Responsividade

### 6.1 Estratégia

- Projetar para a menor tela primeiro; adicionar complexidade progressivamente para telas maiores
- O tráfego mobile representa a maioria do tráfego web global — projete sempre mobile-first e trate desktop como progressive enhancement.

### 6.2 Alvos de Toque

- Elementos interativos: mínimo **44×44px** (Apple HIG) ou **48×48px** (Material Design / WCAG 2.5.5)
- Espaçamento mínimo de 8px entre elementos tocáveis para evitar toques acidentais

### 6.3 Breakpoints de Referência (2025)

| Nome       | Largura        | Uso típico              |
|------------|----------------|-------------------------|
| Mobile S   | < 360px        | Dispositivos compactos  |
| Mobile     | 360px – 767px  | Smartphones             |
| Tablet     | 768px – 1023px | Tablets em retrato      |
| Desktop S  | 1024px – 1279px| Laptops                 |
| Desktop    | 1280px – 1439px| Monitores               |
| Desktop L / Ultrawide | ≥ 1440px | Monitores 27"+, layouts de múltiplas colunas |

- Preferir breakpoints baseados no conteúdo ("quebrar quando o layout precisar") em vez de fixos por dispositivo

### 6.4 Gestos

- Usar gestos reconhecíveis (swipe, pinch, scroll) — evitar gestos customizados sem feedback visual de descoberta
- Fornecer alternativa por toque para todo gesto (ex: botão de exclusão além de swipe-to-delete)

---

## 7. Dark Mode

- Implementar como **preferência do usuário**, respeitando `prefers-color-scheme` do sistema por padrão, com toggle explícito para sobrescrever
- Usar cinza escuro (`#121212` ou similar) em vez de preto puro — reduz fadiga visual
- Nunca inverter imagens ou ícones coloridos — usar variantes específicas para dark mode
- Manter contraste mínimo WCAG AA (ver seção de Acessibilidade para valores exatos)
- Evitar sombras escuras em dark mode — substituir por bordas sutis ou elevação via cor

> Ver exemplo completo em [`references/code-examples.md`](references/code-examples.md).

---

## 8. Motion Design e Animação

### 8.1 Princípios

- Animação deve **comunicar** (transição de estado, hierarquia, causalidade) — não decorar
- Duração recomendada: 100–150ms para microinterações, 200–400ms para transições de tela
- Easing padrão: `ease-out` para entradas (elementos que chegam), `ease-in` para saídas (elementos que partem)

### 8.2 Acessibilidade de Movimento

- Respeitar `prefers-reduced-motion: reduce` — desabilitar ou simplificar animações para usuários sensíveis
- Animações com flicker ou movimento rápido podem desencadear crises em usuários com epilepsia fotossensível

> Ver exemplo completo em [`references/code-examples.md`](references/code-examples.md).

---

## 9. Acessibilidade (a11y)

- **WCAG 2.2 AA** é o padrão mínimo exigido; o WCAG 3.0 está em elaboração
- Contraste mínimo: **4.5:1** para texto normal, **3:1** para texto grande (≥ 18pt ou ≥ 14pt bold)
- Todo elemento interativo deve ser acessível via teclado e ter `focus-visible` visível
- Usar HTML semântico antes de atribuir `role` ARIA — `<button>` em vez de `<div role="button">`
- Imagens informativas precisam de `alt` descritivo; imagens decorativas devem ter `alt=""`
- Ordem de leitura do DOM deve coincidir com a ordem visual para usuários de screen reader

---

## 10. UX Writing e Microcopy

Microcopy são os pequenos textos da interface (labels, placeholders, mensagens de erro, tooltips, CTAs) que guiam o usuário sem que ele perceba.

### 10.1 Princípios

- **Claro antes de criativo:** comunicar o essencial com a menor quantidade de palavras
- **Usar a voz do usuário:** escrever como o usuário pensa ("Esqueci minha senha" em vez de "Recuperação de credenciais")
- **Verbos de ação em CTAs:** "Baixar relatório", "Adicionar membro" em vez de "Download" ou "Adicionar"
- **Consistência terminológica:** usar o mesmo termo em toda a interface; documentar em glossário de produto

### 10.2 Mensagens de Erro em Microcopy

```
// Técnico e frio
"Autenticação falhou."

// Humano e orientado à ação
"Senha incorreta. Tente novamente ou redefina sua senha."
```

### 10.3 Onboarding e Tooltips

- Tooltips: máximo 1–2 frases; aparecer no hover/foco; não conter informação crítica que o usuário não verá no mobile
- Onboarding progressivo: apresentar funcionalidades conforme o usuário avança, não tudo de uma vez no primeiro acesso

---

## Onboarding Progressivo

- **Empty states como onboarding:** quando o estado vazio é o primeiro contato do usuário, transformá-lo em guia de primeiros passos com CTA claro
- **Product tours:** usar apenas para funcionalidades não-óbvias; máximo de 3-5 etapas; permitir pular a qualquer momento
- **Checklist de primeiros passos:** eficaz para produtos com setup inicial (ex: "Complete seu perfil", "Conecte sua conta") — exibir progresso e celebrar conclusão
- **Aha moment:** identificar o momento em que o usuário percebe o valor do produto e projetar o fluxo de onboarding para chegar lá o mais rápido possível
- **Tooltips contextuais:** disparar na primeira vez que o usuário encontra uma funcionalidade avançada, não na abertura da aplicação

---

## 11. Fluxos de Usuário

- Definir o **caminho feliz (happy path)** primeiro e garantir que funcione sem fricção
- Mapear pontos de saída do fluxo e garantir que o usuário possa retornar (breadcrumb, botão voltar, estado preservado)
- Identificar e projetar explicitamente os **fluxos de exceção** (erro, permissão negada, sessão expirada, offline)
- Mínimo de cliques para ações frequentes — eliminar confirmações desnecessárias para ações reversíveis
- Redirecionar automaticamente ao destino original após login (não sempre para a home)

---

## 12. Testes de Usabilidade

- **Teste com 5 usuários** identifica ~85% dos problemas de usabilidade (Nielsen, NN/G)
- Usar texto real desde os primeiros protótipos — nunca lorem ipsum
- Tipos de teste por fase:
  - **Exploratório (discovery):** entrevistas, card sorting, tree testing
  - **Formativo (protótipo):** teste de usabilidade moderado, think-aloud
  - **Somativo (produto):** A/B testing de microcopy e CTAs, métricas de funil
- Documentar achados com **prioridade de impacto** (crítico / moderado / cosmético) e associar a heurística violada
- Testar dark mode, tamanhos de fonte aumentados e navegação por teclado como parte do processo padrão

---

## Referências

- [Nielsen Norman Group — Skeleton Screens](https://www.nngroup.com/articles/skeleton-screens/)
- [Nielsen Norman Group — Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)
- [WCAG 2.2 — Web Content Accessibility Guidelines](https://www.w3.org/TR/WCAG22/)
- [Carbon Design System — Loading Pattern](https://carbondesignsystem.com/patterns/loading-pattern/)
- [Smashing Magazine — Inclusive Dark Mode](https://www.smashingmagazine.com/2025/04/inclusive-dark-mode-designing-accessible-dark-themes/)
- [Bunnyfoot — Form Error Best Practices](https://www.bunnyfoot.com/2024/01/13-best-practices-to-design-error-friendly-forms/)
- [UXPin — Progressive Disclosure](https://www.uxpin.com/studio/blog/what-is-progressive-disclosure/)
