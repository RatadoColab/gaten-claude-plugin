// Referência: domains/forms/SKILL.md — Seção Exibição de Erros e Estados
// Quando usar: gerenciamento de erros inline e resumo de erros acessível

function showError(input, message) {
  const errorEl = document.getElementById(`${input.id}-error`);
  errorEl.textContent = message;
  errorEl.hidden = false;
  input.setAttribute('aria-invalid', 'true');
  input.dataset.hasError = 'true';
}

function clearError(input) {
  const errorEl = document.getElementById(`${input.id}-error`);
  errorEl.hidden = true;
  input.removeAttribute('aria-invalid');
  input.dataset.hasError = 'false';
}

// Error summary markup (for forms with 5+ fields or multiple sections)
//
// <div role="alert" aria-live="assertive" id="error-summary" class="error-summary" hidden>
//   <h2>Corrija os erros abaixo antes de continuar:</h2>
//   <ul>
//     <li><a href="#email">E-mail: formato inválido</a></li>
//     <li><a href="#cpf">CPF: obrigatório</a></li>
//   </ul>
// </div>
//
// After showing the summary, move focus to it: errorSummary.focus()

async function handleSubmit(e) {
  e.preventDefault();
  if (!validateAll()) { focusFirstError(); return; }

  setSubmitting(true); // disables button and inputs
  try {
    await submitForm(getFormData());
    showSuccess();
  } catch (err) {
    applyServerErrors(err.errors);
  } finally {
    setSubmitting(false);
  }
}
