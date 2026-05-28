// Referência: domains/forms/SKILL.md — Seção Inputs com Formatos Brasileiros
// Quando usar: busca automática de endereço por CEP via API ViaCEP

// Auto-fill address from postal code (ViaCEP)
async function fetchAddress(cep: string) {
  const clean = cep.replace(/\D/g, '');
  if (clean.length !== 8) return;
  const res = await fetch(`https://viacep.com.br/ws/${clean}/json/`);
  const data = await res.json();
  if (!data.erro) {
    setValue('street', data.logradouro);
    setValue('city', data.localidade);
    setValue('state', data.uf);
  }
}
