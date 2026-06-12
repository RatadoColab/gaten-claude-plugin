# Autocomplete e Autofill

Valores padronizados de `autocomplete` por contexto. Resumo das regras no `SKILL.md`.

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
