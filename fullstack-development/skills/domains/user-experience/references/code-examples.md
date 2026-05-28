# Code Examples — User Experience

> Exemplos de código para `domains/user-experience/SKILL.md`.

## Estado de Carregamento — Skeleton vs Spinner

**Quando usar:** componentes de loading state baseados no tempo de resposta esperado.

```jsx
// Skeleton — preferido para listas e cards
<SkeletonCard lines={3} avatarSize="md" />

// Spinner — aceitável para ações pontuais
<Button loading={isSubmitting}>Salvar</Button>
```

---

## Estado Vazio — Ruim vs Bom

**Quando usar:** qualquer tela que possa não ter dados — primeira vez, filtro sem resultado ou restrição de permissão.

```
// Ruim
[lista vazia sem mensagem]

// Bom
🗂️ Nenhum relatório encontrado
Ajuste os filtros ou crie um novo relatório para começar.
[Criar relatório]
```

---

## Estado de Erro — Estrutura de Mensagem

**Quando usar:** toda mensagem de erro exibida ao usuário — validações de formulário, erros de rede ou falhas de operação.

```
// Ruim
"Erro 500. Algo deu errado."

// Bom
"Não conseguimos salvar as alterações.
 Verifique sua conexão com a internet e tente novamente.
 [Tentar novamente]  [Descartar]"
```

---

## Feedback Visual — Botão com Estados

**Quando usar:** botões interativos que precisam de feedback de hover, active e disabled via CSS.

```css
/* Button with state feedback */
.btn {
  transition: background-color 150ms ease-out, transform 100ms ease-out;
}
.btn:active {
  transform: scale(0.97);
}
.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
```

---

## Dark Mode — Design Tokens CSS

**Quando usar:** implementação de tema escuro via variáveis CSS e atributo data-theme.

```css
/* Design tokens for dark mode */
:root {
  --color-surface: #ffffff;
  --color-text-primary: #1a1a1a;
}
[data-theme="dark"] {
  --color-surface: #121212;
  --color-text-primary: #e8e8e8;
}
```

---

## Motion Design — prefers-reduced-motion

**Quando usar:** respeitar preferência do usuário por menos movimento/animação.

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```
