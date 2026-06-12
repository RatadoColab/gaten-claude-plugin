# Formulários Multi-step e Upload de Arquivos

Detalhamento de wizards e upload. Resumo no `SKILL.md`.

## Formulários de Múltiplas Etapas (Multi-step / Wizard)

**Quando usar:** formulários com mais de 8 campos, grupos de dados logicamente distintos (dados pessoais → endereço → confirmação), ou quando etapas anteriores condicionam etapas posteriores.

**Quando evitar:** formulários simples com 5 campos ou menos — a fricção adicional da navegação entre etapas supera o benefício para o usuário.

### Estrutura

- Divida o formulário em grupos lógicos — cada etapa com um único objetivo
- Exiba um **indicador de progresso** claro (ex.: "Etapa 2 de 4")
- Permita navegar para etapas anteriores sem perder dados já preenchidos
- Implemente salvamento automático em `localStorage` para formulários críticos

### Gerenciamento de estado multi-step

> Ver exemplo completo em [`multi-step-store.ts`](multi-step-store.ts).

### Acessibilidade em wizards

- Atualize o `<title>` da página ou um `aria-live` ao mudar de etapa
- O foco deve ir para o heading da nova etapa ao avançar
- Não desabilite o botão "Voltar" — sempre permita revisão

## Upload de Arquivos

### Estrutura básica acessível

> Ver exemplo completo em [`file-upload.html`](file-upload.html).

**Regras:**
- Exiba barra de progresso por arquivo em uploads múltiplos
- Permita cancelar o upload em andamento
- Valide tipo e tamanho no cliente antes do envio (para feedback imediato) **e** no servidor
- Mostre preview de imagens antes do envio quando possível
- Drag-and-drop deve ter equivalente via botão (acessibilidade)
- Suporte `keyboard` events no drop zone para usuários sem mouse: `Enter`/`Space` abre o file picker
