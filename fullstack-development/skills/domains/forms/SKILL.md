---
name: forms
description: This skill should be used when implementing forms, input validation, or form-related UX. Covers validation strategies, error feedback patterns, accessibility requirements (WCAG 2.2), security, multi-step forms, file uploads, autocomplete, and user experience best practices for forms.
version: 0.2.0
---

# Forms — Formulários Frontend

## Visão Geral

Diretrizes para implementação de formulários acessíveis, seguros e com boa experiência de usuário. Cobre validação, feedback, acessibilidade WCAG 2.2, segurança, uploads e formulários de múltiplas etapas.

---

## 1. Princípios Fundamentais

- Nunca confie em validação apenas no cliente — sempre revalide no servidor
- Erros devem descrever o problema **e** como corrigi-lo ("Mínimo 8 caracteres" em vez de "Campo inválido")
- Cada campo deve ter um `<label>` explícito e programaticamente associado — placeholder não substitui label
- Desabilite o botão de submit durante o envio para evitar submissões duplicadas
- Preserve os dados preenchidos em caso de erro no envio

---

## 2. Estrutura HTML Semântica

> Ver exemplo completo em [`references/html-structure.html`](references/html-structure.html).

**Regras:**
- Use `novalidate` no `<form>` para controlar totalmente o feedback de erros via JavaScript
- Associe dicas de formato via `aria-describedby` apontando para um `<span>` de hint
- Use `aria-required="true"` junto com o atributo `required` do HTML
- Indique campos obrigatórios com asterisco e legenda visível no topo do formulário ("* campos obrigatórios")

---

## 3. Validação: Estratégia e Timing

### 3.1 Client-side

A validação no cliente melhora UX mas **nunca** substitui a validação no servidor.

| Evento      | Quando usar                                      | Debounce recomendado |
|-------------|--------------------------------------------------|----------------------|
| `blur`      | Regras de formato e campos obrigatórios          | Nenhum               |
| `input`     | Feedback em tempo real (ex.: força de senha)     | 300–500 ms           |
| `submit`    | Resumo de todos os erros pendentes               | Nenhum               |
| Assíncrono  | Verificação de disponibilidade (ex.: username)   | 400–700 ms           |

**Regra importante:** não aplique debounce ao corrigir um erro já exibido — mostre a correção imediatamente.

Para validações assíncronas, cancele a requisição anterior para evitar condições de corrida:

> Ver exemplo completo em [`references/validation-patterns.js`](references/validation-patterns.js).

### 3.2 Server-side

- Revalide **todos** os campos recebidos, independente do que veio do cliente
- Retorne erros estruturados por campo para exibição inline:

```json
{
  "errors": {
    "email": "Este e-mail já está cadastrado",
    "cpf": "CPF inválido"
  }
}
```

- Normalize e sanitize dados antes de persistir (trim, lowercase em e-mails, formatação de CPF/CNPJ)

---

## 4. Exibição de Erros

### 4.1 Erros de campo (inline)

- Exiba imediatamente abaixo do campo correspondente
- Associe via `aria-describedby` para leitores de tela
- Use `role="alert"` para anúncio imediato ou `aria-live="polite"` para verificações assíncronas
- Marque o input com `aria-invalid="true"` enquanto houver erro

> Ver exemplo completo em [`references/error-handling.js`](references/error-handling.js).

### 4.2 Resumo de erros (formulários longos)

Em formulários com mais de 5 campos ou de múltiplas seções, exiba um resumo no topo ao submeter (ver markup e lógica de foco em [`references/error-handling.js`](references/error-handling.js)):

- Links no resumo devem focar o campo correspondente ao clicar
- Mova o foco para o resumo ao exibi-lo: `errorSummary.focus()`

---

## 5. Estados do Formulário

| Estado          | Comportamento esperado                                                  |
|-----------------|-------------------------------------------------------------------------|
| Inicial         | Campos vazios, sem erros visíveis                                       |
| Interagindo     | Validação ativa ao sair do foco (blur)                                  |
| Submetendo      | Botão desabilitado, inputs desabilitados, indicador de loading visível  |
| Erro de campo   | Mensagens inline com `aria-invalid`, foco retorna ao primeiro erro      |
| Erro de servidor| Mensagem global + erros de campo quando o backend os retornar           |
| Sucesso         | Feedback claro (toast/banner), redirect ou limpeza do formulário        |

> Ver função `handleSubmit` com todos os estados em [`references/error-handling.js`](references/error-handling.js).

---

## 6. Acessibilidade (WCAG 2.2 AA)

### 6.1 Requisitos mínimos

| Critério WCAG | Requisito                                                                 |
|---------------|---------------------------------------------------------------------------|
| 1.3.1         | Todo campo tem label programaticamente associado (`for`/`id` ou wrapping) |
| 1.3.5         | Campos de dados pessoais têm `autocomplete` correto                       |
| 3.3.1         | Erros são identificados por texto (não apenas cor)                        |
| 3.3.2         | Instruções de formato são fornecidas antes ou durante o preenchimento     |
| 3.3.3         | Sugestões de correção são fornecidas quando o erro é detectado            |
| 2.4.3         | Foco segue ordem lógica; ao exibir erros, o foco é movido adequadamente  |
| 2.5.3         | O label visível do campo corresponde ao seu accessible name              |

### 6.2 Navegação por teclado

- Todos os campos, botões e controles devem ser acessíveis via Tab
- Modais e painéis de múltiplas etapas devem implementar **focus trap** enquanto abertos
- Use `tabindex="0"` apenas em elementos interativos customizados; nunca use `tabindex` positivo

### 6.3 Indicação de campos obrigatórios

```html
<!-- At the top of the form -->
<p>Campos marcados com <span aria-hidden="true">*</span><span class="sr-only">asterisco</span> são obrigatórios.</p>
```

---

## 7. Autocomplete e Autofill

Use o atributo `autocomplete` com valores padronizados para acelerar o preenchimento e ajudar usuários com deficiências cognitivas ou motoras.

```html
<!-- Personal data -->
<input type="text"     autocomplete="given-name"      name="first_name" />
<input type="text"     autocomplete="family-name"     name="last_name" />
<input type="email"    autocomplete="email"           name="email" />
<input type="tel"      autocomplete="tel"             name="phone" />

<!-- Address -->
<input type="text"     autocomplete="address-line1"   name="address" />
<input type="text"     autocomplete="postal-code"     name="cep" />

<!-- Authentication -->
<input type="password" autocomplete="current-password" name="password" />
<input type="password" autocomplete="new-password"     name="new_password" />

<!-- OTP -->
<input type="text"     autocomplete="one-time-code"   name="otp" inputmode="numeric" />
```

**Regras:**
- Use `autocomplete="new-password"` em formulários de cadastro para evitar que o browser sugira senhas antigas
- Nunca use `autocomplete="off"` em campos de login — navegadores modernos ignoram essa instrução e o comportamento é inconsistente
- Certifique-se de que campos de dados pessoais estejam dentro de um `<form>` para que o autofill do Chrome funcione corretamente

---

## 8. Formulários de Múltiplas Etapas (Multi-step / Wizard)

**Quando usar:** formulários com mais de 8 campos, grupos de dados logicamente distintos (dados pessoais → endereço → confirmação), ou quando etapas anteriores condicionam etapas posteriores.

**Quando evitar:** formulários simples com 5 campos ou menos — a fricção adicional da navegação entre etapas supera o benefício para o usuário.

### 8.1 Estrutura

- Divida o formulário em grupos lógicos — cada etapa com um único objetivo
- Exiba um **indicador de progresso** claro (ex.: "Etapa 2 de 4")
- Permita navegar para etapas anteriores sem perder dados já preenchidos
- Implemente salvamento automático em `localStorage` para formulários críticos

### 8.2 Gerenciamento de estado multi-step

> Ver exemplo completo em [`references/multi-step-store.ts`](references/multi-step-store.ts).

### 8.3 Acessibilidade em wizards

- Atualize o `<title>` da página ou um `aria-live` ao mudar de etapa
- O foco deve ir para o heading da nova etapa ao avançar
- Não desabilite o botão "Voltar" — sempre permita revisão

---

## 10. Upload de Arquivos

### 10.1 Estrutura básica acessível

> Ver exemplo completo em [`references/file-upload.html`](references/file-upload.html).

**Regras:**
- Exiba barra de progresso por arquivo em uploads múltiplos
- Permita cancelar o upload em andamento
- Valide tipo e tamanho no cliente antes do envio (para feedback imediato) **e** no servidor
- Mostre preview de imagens antes do envio quando possível
- Drag-and-drop deve ter equivalente via botão (acessibilidade)
- Suporte `keyboard` events no drop zone para usuários sem mouse: `Enter`/`Space` abre o file picker

---

## 11. Segurança

### 11.1 CSRF

- Use tokens CSRF em todos os formulários com ações de escrita — via mecanismo do framework (ex.: `_glpi_csrf_token` em plugins GLPI)

### 11.2 XSS

- Nunca renderize input do usuário diretamente como HTML sem sanitização
- Sanitize via biblioteca do framework (ex.: `Sanitizer::sanitize()` no GLPI) antes de persistir ou renderizar
- Configure Content Security Policy (CSP) no servidor para restringir origens de scripts

### 11.3 Validação e sanitização server-side

- Trate **todo** dado recebido do cliente como potencialmente malicioso
- Normalize antes de validar: trim em strings, lowercase em e-mails
- Use listas de permissão (allowlist) para campos de tipo enumerado (ex.: categorias, status)
- Nunca exponha mensagens de erro internas do banco ou stack traces ao cliente

---

## 12. Checklist de Implementação

Antes de considerar um formulário concluído, verifique:

**Funcionalidade**
- [ ] Validação client-side com mensagens claras e acionáveis
- [ ] Revalidação server-side em todos os campos
- [ ] Erros do servidor mapeados de volta para campos individuais
- [ ] Botão de submit desabilitado durante envio
- [ ] Dados preservados em caso de erro

**Acessibilidade**
- [ ] Todo campo tem `<label>` associado
- [ ] Campos obrigatórios têm `aria-required="true"` e indicação visual
- [ ] Erros associados via `aria-describedby` e `aria-invalid="true"`
- [ ] `role="alert"` ou `aria-live` em mensagens dinâmicas
- [ ] Navegação completa por teclado
- [ ] Foco gerenciado ao exibir erros (resumo ou primeiro campo)

**UX**
- [ ] Feedback imediato ao corrigir um erro
- [ ] Indicador de loading durante o envio
- [ ] Mensagem de sucesso clara após conclusão
- [ ] Hints de formato antes do preenchimento
- [ ] `autocomplete` adequado em campos de dados pessoais

**Segurança**
- [ ] Token CSRF em formulários de escrita
- [ ] Sanitização de HTML de input do usuário (via mecanismo do framework)
- [ ] Validação de tipo e tamanho em uploads (cliente e servidor)
- [ ] Nenhuma informação sensível exposta em mensagens de erro

**Multi-step (se aplicável)**
- [ ] Indicador de progresso visível
- [ ] Navegação para etapas anteriores sem perda de dados
- [ ] Persistência de dados (localStorage ou estado global)
- [ ] Foco movido para o heading da nova etapa ao avançar

---

## 13. Inputs com Formatos Brasileiros

### CPF / CNPJ
- Aceitar entrada livre (com ou sem máscara) e normalizar no servidor: remover pontos, traços e barras antes de persistir
- Validar os dígitos verificadores **no cliente** para feedback imediato — não apenas no servidor
- Exibir no formato `000.000.000-00` apenas em modo de exibição (readonly), não durante o preenchimento
- Atributos recomendados: `inputmode="numeric"`, `autocomplete="off"`

### CEP com Busca Automática
- Ao sair do campo de CEP (`blur`), disparar busca na API ViaCEP
- Preencher campos de logradouro automaticamente e mantê-los editáveis
- Indicar loading durante a busca (`aria-busy="true"`) e tratar erros (CEP não encontrado) com mensagem inline

> Ver exemplo completo em [`references/viacep-integration.ts`](references/viacep-integration.ts).

### Telefone
- Usar `type="tel"` com `autocomplete="tel"` e `inputmode="tel"`
- Aceitar DDD + número com ou sem formatação; normalizar no servidor para formato E.164 (`+5511999999999`)
- Validar com regex que aceite formatos variados: `(11) 99999-9999`, `11999999999`, `+5511999999999`
