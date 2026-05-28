// Referência: domains/forms/SKILL.md — Seção Validação
// Quando usar: padrões de validação client-side com timing adequado

// Cancel previous request to avoid race conditions
let abortController: AbortController | null = null;

async function validateUsernameAvailability(value: string) {
  if (abortController) abortController.abort();
  abortController = new AbortController();

  try {
    const res = await fetch(`/api/check-username?value=${value}`, {
      signal: abortController.signal,
    });
    return res.ok ? true : 'Username already taken';
  } catch (err) {
    if ((err as Error).name !== 'AbortError') throw err;
  }
}

// Example: validate on blur, re-validate immediately on correction
input.addEventListener('blur', () => validate(input));
input.addEventListener('input', () => {
  if (input.dataset.hasError === 'true') validate(input); // instant feedback on fix
});
