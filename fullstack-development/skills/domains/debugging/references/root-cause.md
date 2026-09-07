# Causa Raiz — Protocolo Detalhado

Detalhamento do método de diagnóstico. Resumo e ponteiros ficam no `SKILL.md`.

## Protocolo passo a passo

1. **Congelar o defeito.** Registrar por escrito, antes de investigar: sintoma exato (mensagem
   literal, código de status, valor incorreto), passos de reprodução, esperado × observado,
   ambiente e versão. Esse registro é a linha de base contra a qual toda hipótese é testada.
2. **Reproduzir localmente.** Recriar a falha no ambiente de trabalho. Se só reproduz em
   produção, tornar o ambiente local mais parecido (mesmos dados, mesma config, mesma versão de
   runtime) até reproduzir — ou instrumentar produção com log/trace suficiente para observar o
   estado no instante da falha.
3. **Minimizar o caso.** Remover partes do input, do fluxo e da config até que qualquer remoção
   adicional faça a falha sumir. O que resta é a superfície mínima.
4. **Mapear o caminho de execução.** Do ponto de entrada até o ponto onde o sintoma aparece,
   listar as funções/camadas atravessadas. As hipóteses vivem nesse caminho.
5. **Enumerar hipóteses.** Para cada ponto do caminho, "o que aqui poderia produzir esse
   sintoma?". Incluir hipóteses sobre dados (input inesperado), estado (valor residual, cache),
   ambiente (versão, permissão) e concorrência.
6. **Ordenar e refutar.** Testar primeiro a hipótese que mais reduz o espaço de busca. Para cada
   uma, produzir evidência que a confirma ou derruba: `print`/log de um valor, teste unitário
   pontual, `git blame`, execução com um fator alterado.
7. **Explicar o mecanismo.** Ao restar uma hipótese, articular a cadeia causal completa: "o campo
   X chega `null` porque o parser Y ignora a chave Z quando o payload usa o formato W; três
   camadas adiante, `a.b()` estoura porque assume X preenchido". Se não é possível narrar a
   cadeia, a causa raiz ainda não foi encontrada.
8. **Verificar amplitude.** `grep` pelo mesmo padrão em todo o código: a condição que causou o
   defeito quase nunca existe num único lugar.

## Checklist — bug que não reproduz

Quando a falha é relatada mas não dispara sob demanda:

- [ ] **Dados.** O caso real usa dados que o teste não tem? Registro específico, volume, valores
      nulos/extremos, encoding, tamanho. Obter uma cópia (anonimizada) do dado que falha.
- [ ] **Timing / ordem.** Só falha sob carga, em horário específico, ou depois de outra operação?
      Aponta para race, cache, expiração de sessão/token, job agendado.
- [ ] **Estado acumulado.** Falha só na segunda execução, ou após N operações? Estado global,
      conexão não liberada, pool exaurido, memória, arquivo temporário.
- [ ] **Ambiente.** Versão de runtime, SO, locale, timezone, variáveis de ambiente, feature flag,
      config por ambiente. Comparar o ambiente que falha com o que não falha, item a item.
- [ ] **Concorrência.** Reproduz ao rodar a operação em paralelo (2+ requisições simultâneas no
      mesmo recurso)? Ferramentas de stress local ajudam a forçar a janela.
- [ ] **Permissão / contexto de usuário.** Falha só para um perfil, tenant ou nível de acesso?
- [ ] **Rede.** Latência, timeout, DNS, proxy, TLS, serviço externo intermitente. Simular
      latência e falha de rede localmente.
- [ ] **Observabilidade.** Se nada acima reproduz, subir o nível de log no caminho suspeito e
      aguardar a próxima ocorrência com o estado capturado — ver `domains/observability`.

## `git bisect`

Localiza o commit que introduziu uma regressão por busca binária no histórico.

```bash
git bisect start
git bisect bad                 # HEAD (ou um commit) tem o defeito
git bisect good v1.4.0         # este commit/tag comprovadamente não tem
# git marca um commit no meio — testar e classificar:
git bisect good                # ou: git bisect bad
# repetir até o git apontar "<sha> is the first bad commit"
git bisect reset               # volta ao estado original
```

Automatizado — o script deve sair com `0` para "good" e `1–124` (exceto 125) para "bad":

```bash
git bisect start HEAD v1.4.0
git bisect run ./scripts/repro-bug.sh
```

Boas práticas:

- O script de `bisect run` deve ser determinístico e rápido; se um commit não compila, sair com
  `125` para que o `git` o pule
- Reduzir o intervalo antes de começar: quanto mais próximo o "good" conhecido, menos passos
- Em repositório com merges, `git bisect` já lida com o grafo — não é preciso linearizar

## Erros de diagnóstico a evitar

Os antipadrões de método (parar na primeira hipótese plausível, corrigir onde o erro estoura em
vez de onde nasce, mexer em vários fatores de uma vez, aceitar "sumiu" sem explicar a causa,
confundir a mensagem de erro com a causa) estão nos **Princípios Fundamentais** e na **Fase 4** do
`SKILL.md`. Específicos deste protocolo:

- **Ignorar a amplitude** — corrigir uma ocorrência e deixar as outras que o `grep` do passo 8
  encontraria
- **Encerrar sem o passo 7** — parar quando o sintoma some, sem conseguir narrar a cadeia causal
  completa do início ao fim
