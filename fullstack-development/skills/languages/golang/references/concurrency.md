# Go — Concorrência

Goroutines, canais, context, errgroup e detecção de vazamento/race.

---

## Goroutine Tem Dono

Toda goroutine disparada precisa de um dono claro — algo que espera seu término (`sync.WaitGroup`, canal, `errgroup`) e algo que pode cancelá-la (`context`). Goroutine "solta", sem nenhum dos dois, é vazamento garantido se a condição de saída nunca ocorrer.

```go
// vazamento: se ninguém nunca envia em `done`, a goroutine nunca termina
go func() {
    <-done
    cleanup()
}()

// dono explícito: contexto cancelável + espera pelo término
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
var wg sync.WaitGroup
wg.Go(func() {                    // sync.WaitGroup.Go — Go 1.25+
    select {
    case <-ctx.Done():
        return
    case <-workDone:
        cleanup()
    }
})
wg.Wait()
```

## `context.Context`

Sempre primeiro parâmetro de qualquer função que faz I/O ou pode ser cancelada — nunca campo de struct (perde o vínculo correto com o escopo de vida da chamada específica).

```go
func (s *Service) Process(ctx context.Context, id string) error {
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()

    select {
    case <-ctx.Done():
        return ctx.Err()
    case result := <-s.doWork(ctx, id):
        return result
    }
}
```

`context.Background()` só na raiz (`main`, teste, worker sem requisição associada); handler HTTP sempre propaga `r.Context()` — cancelar quando o cliente desconecta.

## `errgroup`

```go
g, ctx := errgroup.WithContext(ctx)
for _, url := range urls {
    url := url   // Go < 1.22 exigia essa captura; desnecessário a partir do 1.22
    g.Go(func() error {
        return fetch(ctx, url)
    })
}
if err := g.Wait(); err != nil {
    return fmt.Errorf("buscar URLs: %w", err)
}
```

`errgroup.WithContext` cancela automaticamente o contexto compartilhado assim que a primeira goroutine retorna erro — as demais recebem `ctx.Done()` e podem abortar cedo, em vez de continuar trabalho que será descartado.

## Canais × Mutex

| Ferramenta | Quando usar |
|---|---|
| Canal | Comunicação/transferência de posse de dado entre goroutines; pipeline produtor-consumidor |
| `sync.Mutex`/`sync.RWMutex` | Proteger acesso concorrente a estado compartilhado simples (contador, mapa, cache) |
| `sync.WaitGroup` | Esperar N goroutines terminarem, sem trocar dado entre elas |
| `sync.Once` | Inicialização lazy garantida uma única vez |

Não misturar os dois padrões para proteger o **mesmo** dado — escolher um por dado protegido. Regra prática: "compartilhar memória comunicando", não "comunicar compartilhando memória" — preferir canal quando há transferência de posse; mutex quando é só acesso concorrente a estado local.

## Worker Pool

```go
func processAll(ctx context.Context, items []Item, workers int) error {
    g, ctx := errgroup.WithContext(ctx)
    itemCh := make(chan Item)

    g.Go(func() error {
        defer close(itemCh)
        for _, item := range items {
            select {
            case itemCh <- item:
            case <-ctx.Done():
                return ctx.Err()
            }
        }
        return nil
    })

    for i := 0; i < workers; i++ {
        g.Go(func() error {
            for item := range itemCh {
                if err := process(ctx, item); err != nil {
                    return err
                }
            }
            return nil
        })
    }
    return g.Wait()
}
```

Limita paralelismo a um número fixo de workers — importante quando o custo por item é alto (chamada de rede, I/O) e paralelismo ilimitado esgotaria conexões/memória.

## `testing/synctest`

```go
func TestTimeout(t *testing.T) {
    synctest.Run(func() {
        ctx, cancel := context.WithTimeout(context.Background(), time.Second)
        defer cancel()

        time.Sleep(2 * time.Second)   // tempo virtual — não espera de verdade
        if ctx.Err() == nil {
            t.Fatal("esperava contexto expirado")
        }
    })
}
```

`synctest.Run` executa o corpo em uma bolha de tempo virtual: `time.Sleep`, timers e `context` com deadline avançam instantaneamente e de forma determinística — elimina teste flaky por dependência de tempo real e acelera a suíte (sem `time.Sleep` real de segundos).

## Detecção de Vazamento e Race

```bash
go test -race ./...                                    # data race — sempre em CI
go test -run TestX -leak                                # goroutineleak profile (1.27+)
```

`-race` instrumenta acesso concorrente e detecta condição de corrida real durante a execução do teste — roda mais devagar, mas é obrigatório em CI, não opcional. O profile `goroutineleak` (experimental na 1.26, estável na 1.27) usa análise de alcançabilidade do GC para apontar goroutine permanentemente bloqueada em canal/mutex/`WaitGroup` sem possibilidade de progresso — pega vazamento que passaria despercebido em teste unitário isolado.
