---
name: forms
description: This skill should be used when implementing forms, input validation, or form-related UX. Typical triggers include "build this form", "validate this input", "how should I show form errors?", "make this form accessible", "create a multi-step wizard", "add CPF/CNPJ/CEP validation", "handle file upload in this form". Covers validation strategies, error feedback patterns, accessibility requirements (WCAG 2.2), security, multi-step forms, file uploads, autocomplete, and user experience best practices for forms.
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

Use o atributo `autocomplete` com valores padronizados (`given-name`, `family-name`, `email`, `tel`, `address-line1`, `postal-code`, `current-password`, `new-password`, `one-time-code`) para acelerar o preenchimento e ajudar usuários com deficiências cognitivas ou motoras.

**Regras:**
- Use `autocomplete="new-password"` em formulários de cadastro para evitar que o browser sugira senhas antigas
- Nunca use `autocomplete="off"` em campos de login — navegadores modernos ignoram essa instrução e o comportamento é inconsistente
- Certifique-se de que campos de dados pessoais estejam dentro de um `<form>` para que o autofill do Chrome funcione corretamente

> Tabela completa de valores por contexto (com markup) em [`references/autocomplete.md`](references/autocomplete.md).

---

## 8. Multi-step e Upload de Arquivos

Padrões detalhados (wizard, estado multi-step, acessibilidade, upload acessível) em [`references/multi-step-and-upload.md`](references/multi-step-and-upload.md):

- **Multi-step:** usar acima de 8 campos ou grupos logicamente distintos; indicador de progresso; navegação para trás sem perder dados; persistência em `localStorage`
- **Upload:** validar tipo/tamanho no cliente **e** no servidor; progresso e cancelamento; drag-and-drop com equivalente por teclado/botão

---

## 9. Segurança

Aplicar no contexto de formulário (segurança de aplicação completa em `domains/security/SKILL.md` — fonte autoritativa):

- **CSRF:** token em todo formulário de escrita, via mecanismo do framework (ex.: `_glpi_csrf_token` em plugins GLPI)
- **XSS:** sanitizar input do usuário via biblioteca do framework antes de persistir/renderizar (ex.: `Sanitizer::sanitize()` no GLPI 10 — família depreciada no GLPI 11 em favor de `htmlescape()`/sanitização explícita no save, ver `domains/glpi-11/references/architecture.md`); CSP no servidor
- **Server-side:** revalidar/normalizar todo dado recebido; allowlist em campos enumerados; nunca expor erros internos do banco

---

## 10. Checklist de Implementação

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

## 11. Inputs com Formatos Brasileiros

Padrões para CPF/CNPJ, CEP (busca ViaCEP) e telefone (E.164) em [`references/brazilian-inputs.md`](references/brazilian-inputs.md):

- **CPF/CNPJ:** entrada livre, validar dígitos no cliente, normalizar no servidor, exibir máscara só em readonly
- **CEP:** busca automática na ViaCEP ao `blur`, preencher logradouro editável, tratar erro inline
- **Telefone:** `type="tel"` + `inputmode="tel"`, normalizar para E.164 no servidor
