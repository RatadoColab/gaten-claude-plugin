# HTML5 — Formulários, Validação e Acessibilidade

Referência completa de formulários: input types, validação nativa, Constraint Validation API, Bootstrap 5 e acessibilidade.

---

## Input Types HTML5

| Type | Uso | Atributos específicos | Teclado virtual (mobile) |
|---|---|---|---|
| `text` | Texto livre de linha única | `minlength`, `maxlength`, `pattern`, `list` | Padrão |
| `email` | Endereço de e-mail | `multiple` (aceita lista) | Com `@` e `.com` |
| `tel` | Número de telefone | `pattern` (formato varia por país) | Numérico |
| `url` | URL completa (com esquema) | — | Com `/` e `.com` |
| `number` | Valor numérico com spinners | `min`, `max`, `step` | Numérico |
| `date` | Data no formato YYYY-MM-DD | `min`, `max`, `step` | Date picker |
| `datetime-local` | Data e hora sem fuso horário | `min`, `max`, `step` | Date+time picker |
| `time` | Horário HH:MM | `min`, `max`, `step` | Time picker |
| `range` | Controle deslizante | `min`, `max`, `step`, `list` | — |
| `color` | Seletor de cor (hex) | — | Color picker |
| `file` | Upload de arquivo | `accept`, `multiple` | — |
| `search` | Campo de busca (estilo nativo) | `list` (datalist) | Com chave "Pesquisar" |
| `password` | Texto mascarado | `minlength`, `maxlength`, `autocomplete` | Padrão |
| `checkbox` | Seleção booleana ou múltipla | `checked`, `value` | — |
| `radio` | Seleção exclusiva em grupo | `checked`, `value` | — |
| `hidden` | Dado não exibido ao usuário | `value` | — |

```html
<!-- email com validação nativa -->
<label for="email">E-mail</label>
<input type="email" id="email" name="email"
       placeholder="usuario@dominio.com.br"
       autocomplete="email" required>

<!-- telefone com pattern brasileiro -->
<label for="telefone">Telefone</label>
<input type="tel" id="telefone" name="telefone"
       pattern="\(\d{2}\)\s?\d{4,5}-\d{4}"
       placeholder="(21) 99999-0000"
       autocomplete="tel">

<!-- number com limites -->
<label for="quantidade">Quantidade</label>
<input type="number" id="quantidade" name="quantidade"
       min="1" max="999" step="1" value="1">

<!-- date com intervalo -->
<label for="data-inicio">Data de início</label>
<input type="date" id="data-inicio" name="dataInicio"
       min="2024-01-01" max="2024-12-31">

<!-- file com tipos aceitos -->
<label for="documento">Documento (PDF ou imagem)</label>
<input type="file" id="documento" name="documento"
       accept=".pdf,image/png,image/jpeg" multiple>

<!-- datalist: sugestões para text/search -->
<label for="municipio">Município</label>
<input type="search" id="municipio" name="municipio" list="municipios-list">
<datalist id="municipios-list">
  <option value="Rio de Janeiro">
  <option value="São Paulo">
  <option value="Belo Horizonte">
</datalist>
```

---

## Atributos de Validação Nativa

| Atributo | Tipos compatíveis | Descrição | Exemplo |
|---|---|---|---|
| `required` | Todos exceto `hidden` | Campo obrigatório | `<input required>` |
| `pattern` | text, email, tel, url, search, password | Expressão regular (sem barras) | `pattern="[A-Z]{3}\d{4}"` |
| `min` | number, date, datetime-local, time, range, week, month | Valor mínimo | `min="0"` |
| `max` | number, date, datetime-local, time, range, week, month | Valor máximo | `max="100"` |
| `step` | number, date, time, range | Incremento válido | `step="0.01"` |
| `minlength` | text, email, tel, url, search, password, textarea | Número mínimo de caracteres | `minlength="8"` |
| `maxlength` | text, email, tel, url, search, password, textarea | Número máximo de caracteres | `maxlength="128"` |
| `multiple` | email, file | Aceita múltiplos valores | `<input type="file" multiple>` |

```html
<!-- CEP com pattern -->
<label for="cep">CEP</label>
<input type="text" id="cep" name="cep"
       pattern="\d{5}-?\d{3}"
       minlength="8" maxlength="9"
       placeholder="00000-000"
       autocomplete="postal-code"
       required>

<!-- senha com regras de comprimento -->
<label for="senha">Senha</label>
<input type="password" id="senha" name="senha"
       minlength="8" maxlength="128"
       autocomplete="new-password"
       aria-describedby="senha-requisitos"
       required>
<div id="senha-requisitos" class="form-text">
  Mínimo de 8 caracteres.
</div>
```

---

## Constraint Validation API

```html
<form id="form-cadastro" novalidate>
  <div class="mb-3">
    <label for="nome-completo" class="form-label">Nome completo</label>
    <input type="text" id="nome-completo" name="nomeCompleto"
           class="form-control" minlength="5" required>
    <div class="invalid-feedback" id="nome-completo-erro"></div>
  </div>

  <div class="mb-3">
    <label for="cpf-input" class="form-label">CPF</label>
    <input type="text" id="cpf-input" name="cpf"
           class="form-control" pattern="\d{3}\.\d{3}\.\d{3}-\d{2}"
           placeholder="000.000.000-00" required>
    <div class="invalid-feedback" id="cpf-erro"></div>
  </div>

  <button type="submit" class="btn btn-primary">Cadastrar</button>
</form>

<script>
  /**
   * Returns a human-readable validation message for the given input.
   * @param {HTMLInputElement} input
   * @returns {string}
   */
  function getMensagemErro(input) {
    const v = input.validity;

    // check each validity state in priority order
    if (v.valueMissing)   return 'Este campo é obrigatório.';
    if (v.tooShort)       return `Mínimo de ${input.minLength} caracteres.`;
    if (v.tooLong)        return `Máximo de ${input.maxLength} caracteres.`;
    if (v.patternMismatch) return input.dataset.patternMsg || 'Formato inválido.';
    if (v.typeMismatch)   return 'Valor incompatível com o tipo esperado.';
    if (v.rangeUnderflow) return `Valor mínimo: ${input.min}.`;
    if (v.rangeOverflow)  return `Valor máximo: ${input.max}.`;
    if (v.stepMismatch)   return `O valor deve ser múltiplo de ${input.step}.`;

    // fallback to browser default message
    return input.validationMessage;
  }

  /**
   * Validates a single form field and updates its visual state.
   * @param {HTMLInputElement} input
   */
  function validarCampo(input) {
    const isValid = input.checkValidity();
    const errorEl = document.getElementById(`${input.id}-erro`);

    input.classList.toggle('is-valid', isValid);
    input.classList.toggle('is-invalid', !isValid);
    input.setAttribute('aria-invalid', isValid ? 'false' : 'true');

    if (errorEl) {
      errorEl.textContent = isValid ? '' : getMensagemErro(input);
    }
  }

  // custom validity: validação além do HTML5 nativo
  const cpfInput = document.getElementById('cpf-input');

  cpfInput.addEventListener('input', () => {
    // reset custom validity before re-checking
    cpfInput.setCustomValidity('');

    if (cpfInput.value && !validarCPF(cpfInput.value)) {
      cpfInput.setCustomValidity('CPF inválido.');
    }

    validarCampo(cpfInput);
  });

  // validate on submit
  document.getElementById('form-cadastro').addEventListener('submit', (event) => {
    event.preventDefault();
    const campos = event.target.querySelectorAll('input, select, textarea');
    let primeiroInvalido = null;

    campos.forEach((campo) => {
      validarCampo(campo);
      if (!campo.validity.valid && !primeiroInvalido) {
        primeiroInvalido = campo;
      }
    });

    if (primeiroInvalido) {
      // move focus to first invalid field for accessibility
      primeiroInvalido.focus();
      return;
    }

    // form is valid — submit data
    console.log('Formulário válido, enviando...');
  });

  /**
   * Validates a CPF number (Brazilian individual taxpayer ID).
   * @param {string} cpf
   * @returns {boolean}
   */
  function validarCPF(cpf) {
    const d = cpf.replace(/\D/g, '');
    if (d.length !== 11 || /^(\d)\1+$/.test(d)) return false;
    const calc = (len) => {
      let s = 0;
      for (let i = 0; i < len; i++) s += parseInt(d[i]) * (len + 1 - i);
      const r = (s * 10) % 11;
      return (r === 10 || r === 11) ? 0 : r;
    };
    return calc(9) === parseInt(d[9]) && calc(10) === parseInt(d[10]);
  }
</script>
```

### Propriedades da `ValidityState`

`valueMissing` | `tooShort` | `tooLong` | `patternMismatch` | `typeMismatch` | `rangeUnderflow` | `rangeOverflow` | `stepMismatch` | `customError` | `valid`

Cada propriedade é `true` quando o campo viola a restrição correspondente. `valid` é `true` apenas quando nenhuma outra propriedade é `true`.

---

## Bootstrap 5 — Feedback Visual

```html
<!-- was-validated: ativa estilos :valid/:invalid no submit -->
<form class="was-validated" novalidate>

  <!-- campo válido -->
  <div class="mb-3">
    <label for="f-nome" class="form-label">Nome</label>
    <input type="text" id="f-nome" class="form-control is-valid"
           value="Maria Silva" required>
    <div class="valid-feedback">Parece bom!</div>
  </div>

  <!-- campo inválido -->
  <div class="mb-3">
    <label for="f-email" class="form-label">E-mail</label>
    <input type="email" id="f-email" class="form-control is-invalid"
           value="nao-e-email" required
           aria-describedby="f-email-feedback"
           aria-invalid="true">
    <div id="f-email-feedback" class="invalid-feedback">
      Informe um endereço de e-mail válido.
    </div>
  </div>

</form>
```

---

## Formulário Completo — Bootstrap 5 + Acessibilidade

```html
<form id="form-contato" novalidate aria-label="Formulário de contato">
  <fieldset>
    <legend class="fs-5 fw-semibold mb-3">Dados de contato</legend>

    <!-- nome: required + minlength + aria -->
    <div class="mb-3">
      <label for="fc-nome" class="form-label">Nome <span aria-hidden="true" class="text-danger">*</span></label>
      <input type="text" id="fc-nome" name="nome" class="form-control"
             autocomplete="name" required minlength="5"
             aria-required="true" aria-describedby="fc-nome-erro">
      <div id="fc-nome-erro" class="invalid-feedback"></div>
    </div>

    <!-- e-mail: type=email valida formato nativo -->
    <div class="mb-3">
      <label for="fc-email" class="form-label">E-mail <span aria-hidden="true" class="text-danger">*</span></label>
      <input type="email" id="fc-email" name="email" class="form-control"
             autocomplete="email" required
             aria-required="true" aria-describedby="fc-email-erro">
      <div id="fc-email-erro" class="invalid-feedback"></div>
    </div>

    <!-- telefone: opcional + hint de formato -->
    <div class="mb-3">
      <label for="fc-tel" class="form-label">Telefone</label>
      <input type="tel" id="fc-tel" name="telefone" class="form-control"
             autocomplete="tel" pattern="\(\d{2}\)\s?\d{4,5}-\d{4}"
             placeholder="(21) 99999-0000"
             aria-describedby="fc-tel-hint fc-tel-erro">
      <div id="fc-tel-hint" class="form-text">Opcional. Formato: (21) 99999-0000</div>
      <div id="fc-tel-erro" class="invalid-feedback"></div>
    </div>
  </fieldset>

  <!-- select: primeiro option vazio e desabilitado como placeholder -->
  <div class="mb-3">
    <label for="fc-assunto" class="form-label">Assunto <span aria-hidden="true" class="text-danger">*</span></label>
    <select id="fc-assunto" name="assunto" class="form-select"
            required aria-required="true" aria-describedby="fc-assunto-erro">
      <option value="" disabled selected>Selecione...</option>
      <option value="duvida">Dúvida</option>
      <option value="sugestao">Sugestão</option>
    </select>
    <div id="fc-assunto-erro" class="invalid-feedback"></div>
  </div>

  <!-- textarea: contador de caracteres via aria-describedby -->
  <div class="mb-3">
    <label for="fc-mensagem" class="form-label">Mensagem <span aria-hidden="true" class="text-danger">*</span></label>
    <textarea id="fc-mensagem" name="mensagem" class="form-control"
              rows="5" required minlength="20" maxlength="2000"
              aria-required="true" aria-describedby="fc-mensagem-contador fc-mensagem-erro"></textarea>
    <div id="fc-mensagem-contador" class="form-text text-end" aria-live="polite">
      <span id="fc-chars">0</span>/2000
    </div>
    <div id="fc-mensagem-erro" class="invalid-feedback"></div>
  </div>

  <!-- checkbox: label envolve o link externo com aviso para leitores de tela -->
  <div class="mb-3 form-check">
    <input type="checkbox" id="fc-lgpd" name="aceiteLGPD" class="form-check-input"
           required aria-required="true" aria-describedby="fc-lgpd-erro">
    <label class="form-check-label" for="fc-lgpd">
      Li e aceito a <a href="/privacidade" target="_blank" rel="noopener">
        Política de Privacidade <span class="visually-hidden">(abre em nova aba)</span>
      </a>
    </label>
    <div id="fc-lgpd-erro" class="invalid-feedback"></div>
  </div>

  <p class="text-body-secondary mb-3">
    <span aria-hidden="true" class="text-danger">*</span> Campos obrigatórios
  </p>
  <button type="submit" class="btn btn-primary">Enviar mensagem</button>
</form>
```

### Acessibilidade em Formulários — Checklist

| Item | Como implementar |
|---|---|
| Label associado a todo campo | `<label for="id">` + `id` correspondente no campo |
| Campos obrigatórios indicados | `required` + `aria-required="true"` + indicador visual com `aria-hidden` |
| Erros em texto (não só cor) | Mensagem textual + `aria-invalid="true"` + `aria-describedby` |
| Grupos relacionados | `<fieldset>` + `<legend>` para radios, checkboxes e grupos temáticos |
| Instruções antes do campo | `aria-describedby` apontando para texto de ajuda |
| Autocomplete | Atributo `autocomplete` com valor semântico correto |
| Foco no primeiro erro | `elemento.focus()` ao submeter formulário inválido |
| Regiões de feedback dinâmico | `aria-live="polite"` para mensagens de erro injetadas via JS |
