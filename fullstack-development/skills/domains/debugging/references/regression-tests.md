# Teste de Regressão — Método

Detalhamento do teste que acompanha toda correção de bug. Resumo e ponteiros ficam no `SKILL.md`.
A sintaxe e o runner de cada linguagem ficam nos `references/testing.md` das skills de linguagem —
este documento cobre apenas o **método**, comum a todas.

## Fail-before / pass-after

O teste de regressão só tem valor se demonstrar que exercita o defeito:

1. **Escrever o teste primeiro**, codificando o caso mínimo que reproduz a falha (Fase 1 do
   diagnóstico já produziu esse caso). Quando o diagnóstico se deu apenas por evidência de código,
   sem um caso reproduzível, converter essa evidência num teste que exercite o defeito; se for
   comprovadamente impossível, registrar a exceção no laudo com justificativa em vez de pular a
   verificação.
2. **Rodar o teste contra o código não corrigido** e confirmar que ele **falha** — e falha
   **pela razão certa** (a asserção sobre o comportamento incorreto), não por erro de setup,
   import ou fixture.
3. **Aplicar a correção.**
4. **Rodar de novo** e confirmar que o teste passa.
5. **Rodar a suíte completa** e confirmar que nada mais regrediu.

Pular o passo 2 é o erro mais comum: um teste que nunca foi visto falhar pode estar verde porque
não afirma nada de útil.

## Nível certo na pirâmide

Escolher o nível pelo lugar onde a causa raiz vive — não subir mais que o necessário:

| Causa raiz está em… | Nível do teste |
|---|---|
| Função pura, ramo lógico, cálculo, validação | **Unitário** |
| Fronteira entre componentes: query ao banco, serialização, mapeamento DTO, contrato de API, parsing | **Integração** |
| Fluxo que só quebra atravessando o sistema real (auth + navegação + estado + backend) | **E2E** (último recurso) |

Um bug de arredondamento monetário é unitário. Um bug de "campo some ao salvar" quase sempre é
integração (serialização ou camada de dados). Reservar E2E para quando o mecanismo genuinamente
depende da composição ponta a ponta — são lentos e frágeis.

## Nomear pelo defeito

O nome descreve a **condição que falhava**, não o método sob teste:

- `test_desconto_nao_arredonda_para_baixo_em_centavos`
- `test_lista_nao_duplica_itens_ao_paginar`
- `test_login_expira_sessao_apos_logout_em_outra_aba`
- `it("mantém a ordem original quando dois itens têm a mesma prioridade")`

Assim, quando o teste quebrar no futuro, o nome já diz qual regressão voltou.

## Casos de borda a incluir junto

Além do caso exato relatado, cobrir a vizinhança do defeito — é barato e previne a variação:

- Limites: coleção vazia, um elemento, primeiro/último, valor zero, negativo, máximo
- Nulos e ausência: campo `null`, chave faltante, string vazia vs. não fornecida
- Tipo: número como string, decimal onde se esperava inteiro, booleano coagido
- Concorrência: se a causa era race, um teste que dispara a operação em paralelo
- Idempotência: repetir a operação e verificar que o resultado não muda

## Ponte para o runner de cada linguagem

O *como* escrever, rodar e estruturar o teste na linguagem do projeto:

- **Python:** [`languages/python/references/testing.md`](../../../languages/python/references/testing.md) — `pytest`, fixtures, `parametrize`, mocks
- **PHP:** [`languages/php/references/testing.md`](../../../languages/php/references/testing.md) — PHPUnit, data providers, test doubles
- **Go:** [`languages/golang/references/testing.md`](../../../languages/golang/references/testing.md) — `testing`, table-driven tests, `-race`
- **Node.js:** [`languages/nodejs/references/testing.md`](../../../languages/nodejs/references/testing.md) — `node:test`, `assert`, mocks nativos

Para stacks sem `references/testing.md` dedicado (Kotlin, Dart, Vue), seguir o framework de teste
idiomático da plataforma (JUnit/Turbine, `flutter_test`, Vitest) e as skills de domínio
correspondentes (`android-architecture`, `flutter`, `vue`).

## Onde o teste mora

- Colocar o teste de regressão junto à suíte existente do módulo corrigido, não num diretório à
  parte de "bugs"
- Se o projeto não tem suíte para aquele módulo, criar a estrutura mínima seguindo a convenção do
  restante do repositório — e registrar em `PENDENCIAS.md` a lacuna de cobertura mais ampla, se
  ela exceder o escopo do bugfix
