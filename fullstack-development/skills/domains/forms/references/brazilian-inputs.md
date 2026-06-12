# Inputs com Formatos Brasileiros

Detalhamento de CPF/CNPJ, CEP e telefone. Resumo no `SKILL.md`.

## CPF / CNPJ
- Aceitar entrada livre (com ou sem máscara) e normalizar no servidor: remover pontos, traços e barras antes de persistir
- Validar os dígitos verificadores **no cliente** para feedback imediato — não apenas no servidor
- Exibir no formato `000.000.000-00` apenas em modo de exibição (readonly), não durante o preenchimento
- Atributos recomendados: `inputmode="numeric"`, `autocomplete="off"`

## CEP com Busca Automática
- Ao sair do campo de CEP (`blur`), disparar busca na API ViaCEP
- Preencher campos de logradouro automaticamente e mantê-los editáveis
- Indicar loading durante a busca (`aria-busy="true"`) e tratar erros (CEP não encontrado) com mensagem inline

> Ver exemplo completo em [`viacep-integration.ts`](viacep-integration.ts).

## Telefone
- Usar `type="tel"` com `autocomplete="tel"` e `inputmode="tel"`
- Aceitar DDD + número com ou sem formatação; normalizar no servidor para formato E.164 (`+5511999999999`)
- Validar com regex que aceite formatos variados: `(11) 99999-9999`, `11999999999`, `+5511999999999`
