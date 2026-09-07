---
name: debugging
description: This skill should be used when diagnosing a defect in existing code — reproducing a failure, isolating its root cause, or writing a regression test. Typical triggers include "fix this bug", "why does this crash?", "this worked before and now it doesn't", "track down the root cause", "this test is flaky", "find what commit broke this", "write a regression test for this fix". Covers deterministic reproduction, hypothesis-and-refutation, bisection and delta debugging, reading stack traces and logs, recurring defect classes, minimal vs. structural fixes, and the fail-before/pass-after regression test.
---

# Debugging — Diagnóstico de Causa Raiz

## Visão Geral

Método para corrigir um defeito em código que **já existe**: o comportamento está errado e o
trabalho é descobrir **por quê** antes de escrever qualquer linha de correção. O eixo é invertido
em relação a desenvolver uma feature — não se parte de uma especificação, parte-se de uma falha
observável e recua-se até a causa. A correção só é válida quando acompanhada de um teste de
regressão que **falha antes** dela e **passa depois**.

Antipadrão central a evitar: tratar o sintoma sem identificar a causa. Uma correção que faz o erro
"sumir" sem explicar o mecanismo tende a reaparecer, mudar de lugar ou mascarar um problema maior.

---

## Princípios Fundamentais

- **Reprodução antes de hipótese:** sem um caso que dispara a falha de forma repetível (ou uma
  cadeia de evidência no código que a prove), qualquer diagnóstico é especulação
- **Refutação, não confirmação:** buscar ativamente a evidência que **derruba** cada hipótese;
  a causa raiz é a única que sobrevive à tentativa de refutação
- **Uma variável por vez:** ao testar uma hipótese, alterar um único fator e observar o efeito
- **Evidência sobre plausibilidade:** "isso costuma causar esse erro" não é diagnóstico — é ponto
  de partida para procurar a prova no caso concreto
- **Correlação não é causa:** dois eventos coincidentes podem ter uma terceira origem comum

---

## Fase 1 — Reprodução Determinística

Reduzir a falha ao menor caso que a dispara de forma consistente.

- **Fixar as entradas:** dados de teste, relógio, semente aleatória, locale, timezone, variáveis
  de ambiente, versão de dependências
- **Isolar não-determinismo:** concorrência (ordem de threads/coroutines), ordem de execução de
  testes, estado compartilhado entre casos, cache, I/O de rede, dados de produção mutáveis
- **Minimizar:** remover partes do caso até que retirar qualquer outra faça a falha desaparecer —
  o que resta é a superfície mínima do defeito
- **Registrar a taxa:** falha 1 em 1 ou 1 em 100? Intermitência aponta para corrida, ordem ou
  recurso externo

> Quando a falha **não** reproduz: protocolo passo a passo, checklist de coleta de evidência e
> técnicas para bug intermitente em [`references/root-cause.md`](references/root-cause.md).

---

## Fase 2 — Hipótese e Refutação

1. **Enumerar candidatas:** listar as causas possíveis a partir do sintoma, do stack trace e da
   topologia do código no caminho da falha
2. **Ordenar por probabilidade × custo de teste:** começar pela hipótese que, se verdadeira ou
   falsa, elimina o maior número de outras com o menor esforço
3. **Refutar cada uma com evidência concreta:** trecho de código, saída de execução, valor logado,
   resultado de um teste pontual, `git blame` da linha suspeita
4. **A que sobra é a causa raiz** — e deve ser possível **explicar o mecanismo**: por que essa
   condição produz exatamente esse sintoma

Não passar para a correção enquanto houver mais de uma hipótese viva ou enquanto o mecanismo não
estiver explicado.

---

## Fase 3 — Isolamento

Técnicas para estreitar a região onde o defeito vive:

- **Bissecção temporal (`git bisect`):** quando há uma regressão datada (funcionava no build X,
  falha no Y), `git bisect` localiza o commit introdutor em `log₂(n)` passos. Automatizável com
  `git bisect run <script>`
- **Delta debugging na entrada:** dado um input grande que falha e um pequeno que passa, reduzir
  o grande pela metade repetidamente mantendo a falha — converge no fragmento responsável
- **Busca binária no fluxo:** inserir verificações de estado em pontos intermediários do caminho de
  execução; a falha está entre a última verificação sã e a primeira insana
- **Diferencial de ambiente:** se falha num ambiente e não noutro, comparar versões, config,
  dados e permissões — a diferença relevante costuma ser uma só

> Roteiro de `git bisect` (incluindo `bisect run`) em
> [`references/root-cause.md`](references/root-cause.md).

---

## Fase 4 — Leitura de Evidência

- **Stack trace de fora para dentro:** o topo é onde estourou, não necessariamente onde está o
  bug. Percorrer os frames até o último ponto sob controle do próprio código; o frame anterior
  costuma conter a premissa violada
- **Erro de origem × erro propagado:** um `NullPointerException` três camadas acima do ponto em
  que o valor deveria ter sido preenchido — rastrear até a origem do valor inválido, não remendar
  onde ele explode
- **O que um log ausente prova:** se a linha "entrou no método X" não aparece, o fluxo não chegou
  lá — a falha é a montante. Ausência de evidência é evidência
- **Mensagem × realidade:** mensagens de erro genéricas ("algo deu errado") ou herdadas de
  `catch` amplo podem apontar para o lugar errado; confirmar com o estado real (valores, tipos)

---

## Classes Recorrentes de Defeito

Checklist de padrões que respondem pela maioria dos bugs — verificar contra o caso:

| Classe | Sinais típicos |
|---|---|
| **Off-by-one / limites** | erro só no primeiro/último item, coleção vazia, paginação |
| **Estado compartilhado mutável** | falha só quando há concorrência ou em execução repetida |
| **Race condition** | intermitente, sensível a carga/timing, some com log adicionado |
| **N+1 / performance** | lento proporcional ao volume; muitas queries idênticas |
| **Coerção e comparação de tipo** | `"0" == 0`, `null` vs `undefined`, inteiro vs decimal, truthiness |
| **Timezone / encoding** | erro de 1 dia, horário deslocado, caractere corrompido, `UTF-8` vs `latin1` |
| **Cache obsoleto** | comportamento correto após limpar cache/reiniciar; TTL ou chave errada |
| **Tratamento de erro que engole** | `catch` vazio ou amplo demais, exceção suprimida, retorno de erro ignorado |
| **Precisão de ponto flutuante** | `0.1 + 0.2`, arredondamento monetário, acúmulo de erro |
| **Contrato quebrado entre camadas** | DTO/serialização divergente, campo renomeado só de um lado |

Vulnerabilidade também é uma classe de defeito, mas o diagnóstico e a mitigação seguem
`domains/security` (OWASP Top 10:2025) — esta skill não o reescreve.

---

## Fase 5 — Correção: Mínima × Estrutural

Depois da causa raiz identificada, escolher a amplitude da correção:

- **Mínima:** altera o menor número de linhas para eliminar a causa. Preferir quando o defeito é
  localizado, o risco de regressão precisa ser baixo, ou a correção é urgente
- **Estrutural:** remove a **condição** que tornou o defeito possível (um invariante mal
  modelado, uma responsabilidade no lugar errado). Preferir quando o mesmo padrão já apareceu
  em mais de um ponto, ou quando a correção mínima seria um remendo sobre um design frágil
- **Registrar o que ficou de fora:** se a correção estrutural for maior que o escopo do bugfix,
  aplicar a mínima **e** registrar a dívida em `PENDENCIAS.md` (data, contexto, dono ou "sem
  dono", critério de pronto) ou como `// TODO(dono): motivo` no código

Apresentar o trade-off explicitamente e recomendar uma opção — a escolha final é do responsável.

---

## Fase 6 — Teste de Regressão

Toda correção de bug produz um teste. Sem exceção.

- **Fail-before / pass-after:** escrever o teste **primeiro**, rodar e confirmar que ele **falha**
  reproduzindo o defeito. Sem essa confirmação, o teste pode estar verde por não exercer nada
- **Aplicar a correção** e confirmar que o teste passa e que a suíte existente não regride
- **Nível certo na pirâmide:** teste unitário quando a causa é uma função pura ou um ramo lógico;
  teste de integração quando o defeito estava na fronteira entre componentes (query, serialização,
  contrato de API); só subir para E2E quando o mecanismo realmente atravessa o sistema
- **Nomear pelo defeito:** o nome do teste descreve a condição que falhava, não o método testado
  (ex.: `test_desconto_nao_arredonda_para_baixo_em_centavos`)

> Método detalhado do teste que falha-antes/passa-depois, e a ponte para o runner de cada
> linguagem, em [`references/regression-tests.md`](references/regression-tests.md).

---

## Fronteiras com Outras Skills

- **Instrumentação, logs estruturados, traces e métricas:** fonte autoritativa é
  `domains/observability` — esta skill apenas **usa** os sinais, não ensina a produzi-los
- **Sintaxe e runner de teste por linguagem:** `languages/python/references/testing.md`,
  `languages/php/references/testing.md`, `languages/golang/references/testing.md`,
  `languages/nodejs/references/testing.md` — esta skill cobre *o que* testar e em que nível, não
  *como* escrever o teste na linguagem
- **Vulnerabilidade como defeito:** `domains/security` — diagnóstico e mitigação de classes OWASP
- **Precedência de carregamento:** skill de domínio genérico — abaixo de GLPI e de Languages na
  regra `GLPI > Languages > Domains` do plugin

---

## Referências

- [`references/root-cause.md`](references/root-cause.md) — protocolo de causa raiz, checklist de bug não reproduzível, `git bisect`
- [`references/regression-tests.md`](references/regression-tests.md) — teste fail-before/pass-after e ponte para o runner de cada linguagem
- Skills correlatas (`observability`, `security`, `languages/*/references/testing.md`): ver §"Fronteiras com Outras Skills" acima
