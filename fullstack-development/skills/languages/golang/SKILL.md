---
name: golang
description: This skill should be used when writing, reviewing, or refactoring Go code. Covers Go 1.27.x toolchain and module management, idiomatic naming and package layout (cmd/internal/pkg), error wrapping with errors.Is/As/Join, concurrency patterns (goroutines, channels, context, errgroup), structured logging with log/slog, table-driven testing, and stdlib-first HTTP services. Use when the user asks to "write Go code", "review Go", "create a Go package", "implement a goroutine", "handle errors in Go", "write a Go HTTP handler", "write table-driven tests", "use log/slog", or "set up go.mod".
---

# Go — Convenções e Boas Práticas (1.27.x)

Diretrizes para escrita de Go idiomático com base na stdlib e no toolchain 1.27.x.

---

## Toolchain e Versões

Go segue política de suporte **N-2**: cada versão major é suportada até haver duas mais novas. Em ago/2026, 1.27/1.26/1.25 recebem correções; 1.24 e anteriores, não.

```
module example.com/meuservico

go 1.27
```

`GOTOOLCHAIN=auto` (padrão) baixa automaticamente a toolchain declarada em `go.mod` se a instalada for mais antiga. `go work` cria um workspace multi-módulo local (`go.work`) sem editar `replace` em cada `go.mod` — útil ao desenvolver módulo e consumidor lado a lado.

---

## Nomenclatura e Organização

| Elemento | Convenção | Exemplo |
|---|---|---|
| Pacote | Curto, lowercase, sem underscore | `httputil`, não `http_util` |
| Tipo exportado / função exportada | `MixedCaps` (PascalCase) | `UserService`, `NewClient` |
| Não exportado | `mixedCaps` (camelCase) | `parseConfig`, `defaultTimeout` |
| Interface de um método | Nome do método + `-er` | `Reader`, `Closer`, `Validator` |
| Receiver | Curto, consistente entre métodos do tipo | `func (s *Server) Start()` — não `this`/`self` |
| Evitar stutter | Não repetir o nome do pacote no tipo | `user.Service`, não `user.UserService` |

Layout recomendado: `cmd/<binário>/main.go` para cada executável; `internal/` para código privado ao módulo (não importável externamente); `pkg/` **só** quando houver consumidor externo real — do contrário, manter em `internal/` ou na raiz. Hierarquia rasa — evitar `internal/services/user/handlers/http/v1/`. Detalhes de camadas e `go:embed` em **`references/project-layout.md`**.

---

## Tipos, Structs e Interfaces

Aceitar interfaces, retornar structs concretas — a interface é definida por quem **consome**, não por quem produz (o oposto de Java). Interfaces pequenas (1-3 métodos) são mais reutilizáveis que grandes. Preferir zero value útil (`var buf bytes.Buffer` já funciona, sem construtor).

```go
type UserRepository interface {   // definida no pacote consumidor
    FindByID(ctx context.Context, id string) (*User, error)
}

func Sum[T int | float64](vals []T) T { ... }        // generics — tipo explícito
func (r *Rand) N[Int int | int32 | int64](n Int) Int // método genérico (1.27+)
```

Usar `any` em vez de `interface{}` em código novo. Métodos genéricos (novidade 1.27) permitem parâmetro de tipo por método, sem generalizar o tipo inteiro.

---

## Erros

Encadear com `%w` para permitir `errors.Is`/`errors.As` na chamada; `errors.Join` agrega múltiplos erros independentes (ex.: validação de vários campos). Nunca logar o erro **e** retorná-lo — decidir em qual camada ele é tratado, para não duplicar o log. Nunca expor mensagem de erro interna (stack, query SQL) diretamente ao cliente HTTP.

```go
if err != nil {
    return fmt.Errorf("buscar usuário %s: %w", id, err)
}
// no chamador:
if errors.Is(err, sql.ErrNoRows) { ... }
```

`panic`/`recover` só para condição verdadeiramente irrecuperável (invariante quebrada) ou no boundary de um servidor para não derrubar o processo inteiro por um handler — nunca como controle de fluxo normal. Hierarquia de erro de domínio, mapeamento para HTTP e segurança da mensagem exposta em **`references/errors.md`**.

---

## Concorrência

Toda goroutine tem um dono claro que garante seu término — nunca disparar `go func()` sem saber quem espera por ela ou quem a cancela. `context.Context` é sempre o primeiro parâmetro de função que faz I/O ou pode ser cancelada; nunca guardado em struct.

```go
g, ctx := errgroup.WithContext(ctx)
for _, id := range ids {
    g.Go(func() error { return process(ctx, id) })
}
if err := g.Wait(); err != nil { return err }
```

`errgroup` propaga o primeiro erro e cancela o grupo; canais para comunicação entre goroutines, mutex para proteger estado compartilhado simples — não misturar os dois padrões para o mesmo dado. `sync.WaitGroup.Go` (1.25) simplifica o `go func() { defer wg.Done(); ... }()` repetitivo. `testing/synctest` testa código concorrente com tempo virtual, sem `time.Sleep` real. Detecção de vazamento de goroutine via profile `goroutineleak` (estável na 1.27). Rodar testes sempre com `-race` em CI. Padrões completos em **`references/concurrency.md`**.

---

## HTTP com a Stdlib

`net/http` desde 1.22 roteia por método e path wildcard nativamente — cobre a maioria dos casos sem framework:

```go
mux := http.NewServeMux()
mux.HandleFunc("GET /users/{id}", handleGetUser)
srv := &http.Server{Addr: ":8080", Handler: mux, ReadHeaderTimeout: 5 * time.Second}
```

Sempre configurar timeouts explícitos no `http.Server` (`ReadHeaderTimeout` no mínimo) — sem isso, uma conexão lenta pode esgotar file descriptors. Graceful shutdown com `srv.Shutdown(ctx)` tratando `SIGTERM`.

| Opção | Quando usar |
|---|---|
| `net/http` puro | Serviço pequeno/médio, zero dependência externa |
| `chi` | Roteamento composable com middleware idiomático, mantém `net/http.Handler` |
| `Echo` | Microsserviço de baixa latência, ecossistema de middleware pronto |
| `Gin` | Alta familiaridade de equipe com API estilo Express, benchmarks agressivos |

Contrato de API, versionamento e formato de erro em `domains/api-rest/SKILL.md`. Servidor e cliente `net/http` completos, middleware e graceful shutdown em **`references/stdlib-http-slog.md`**.

---

## Logging Estruturado

`log/slog` (stdlib desde 1.21) é o padrão — evita depender de biblioteca externa de logging e o ecossistema convergiu para ele como frontend comum.

```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
slog.SetDefault(logger)
slog.Info("requisição processada", "request_id", reqID, "status", 200, "duration_ms", 42)
```

Campos consistentes entre serviços (`request_id`, `service`, `status`) facilitam correlação em observabilidade centralizada; `slog.Group` agrupa campos relacionados. Nunca logar segredo ou dado sensível como campo estruturado. Handlers customizados e propagação de atributos por `context` em **`references/stdlib-http-slog.md`**; pipeline de métricas/traces em `domains/observability/SKILL.md`.

---

## Testes

Table-driven é o padrão idiomático — um `[]struct` de casos, um `t.Run` por caso:

```go
func TestParse(t *testing.T) {
    cases := []struct{ name, in string; want int; wantErr bool }{
        {"válido", "42", 42, false},
        {"inválido", "abc", 0, true},
    }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            got, err := Parse(tc.in)
            if (err != nil) != tc.wantErr { t.Fatalf("err = %v", err) }
            if got != tc.want { t.Errorf("got %d, want %d", got, tc.want) }
        })
    }
}
```

`t.Parallel()` para casos independentes; `t.Cleanup()` em vez de `defer` para teardown que deve rodar mesmo com subteste; `t.Context()` fornece um `context.Context` já ligado ao ciclo de vida do teste. Benchmarks com `b.Loop()` (substituindo o padrão manual `for i := 0; i < b.N; i++`). Fuzzing nativo (`go test -fuzz`) para funções que parseiam entrada não confiável. Padrões de mock via interface, `httptest` e golden files em **`references/testing.md`**.

---

## Novidades 1.25 → 1.27

| Recurso | Desde | Resumo |
|---|---|---|
| `encoding/json/v2` | 1.25 (experimental) → 1.27 (GA) | Rejeita UTF-8 inválido e chaves duplicadas por padrão; unmarshal bem mais rápido |
| Métodos genéricos | 1.27 | Parâmetro de tipo por método, sem generalizar o tipo inteiro |
| `new(expr)` | 1.27 | `new` aceita expressão, não só tipo, como valor inicial |
| `go fix` com modernizers | 1.27 | Reescreve automaticamente para idiomas mais novos da stdlib |
| Profile `goroutineleak` | 1.26 (experimental) → 1.27 (estável) | Detecta goroutine permanentemente bloqueada via análise do GC |
| GOMAXPROCS container-aware | 1.25 | Respeita cgroup quota automaticamente, sem `GOMAXPROCS` manual |
| Alocação de memória | 1.27 | Rotinas especializadas por tamanho reduzem custo de alocação pequena em até 30% |
| `crypto/mldsa`, `crypto/hpke` | 1.27 | Criptografia pós-quântica (FIPS 204) e HPKE (RFC 9180) na stdlib |

Detalhamento e exemplos completos em **`references/go127-features.md`**.

---

## Ferramentas

| Ferramenta | Uso |
|---|---|
| `gofmt` / `gofumpt` | Formatação — rodar sempre, sem exceção; `gofumpt` é um superset mais estrito |
| `go vet` | Análise estática embutida — parte do `go test` desde sempre |
| `golangci-lint` (v2) | Meta-linter com dezenas de linters, cache e execução paralela — padrão de facto do ecossistema |
| `go fix` | Reescreve código para APIs mais novas (modernizers) |
| `govulncheck` | Verifica dependências contra o banco de vulnerabilidades do Go |
| `go mod tidy` / `go mod verify` | Sincroniza `go.mod`/`go.sum`; verifica integridade contra adulteração |
| `go test -cover -race` | Cobertura + detecção de data race sempre em CI |

Build de produção: `CGO_ENABLED=0 go build -ldflags="-s -w"` gera binário estático sem símbolo de debug, ideal para imagem `scratch`/distroless. Configuração de `golangci-lint` v2, cross-compile e Dockerfile multi-stage em **`references/tooling-build.md`**.

---

## Anti-Patterns

| Anti-Pattern | Problema | Correção |
|---|---|---|
| `interface{}` em código novo | Menos legível, sem type safety | `any`, ou generics quando o tipo importa |
| Interface definida no pacote produtor | Acopla consumidores a uma abstração que talvez nem usem toda | Definir a interface no pacote **consumidor** |
| `panic` para erro esperado (não encontrado, validação) | Trata fluxo normal como exceção | Retornar `error` |
| Ignorar `err` retornado (`_ = err` sem justificativa) | Falha silenciosa | Tratar ou propagar explicitamente |
| `context.Background()` dentro de um handler HTTP | Perde cancelamento e deadline da requisição original | Usar `r.Context()` |
| `context.Context` como campo de struct | Vaza escopo de vida incorreto | Sempre como primeiro parâmetro de função |
| Goroutine disparada sem dono nem cancelamento | Vazamento — nunca termina | `errgroup`/`context` com dono claro |
| `time.Sleep` para sincronizar teste concorrente | Flaky e lento | `testing/synctest` |
| `pkg/` para código sem consumidor externo | Sinaliza API pública que não existe | Manter em `internal/` |
| Getter com prefixo `Get` (`GetName()`) | Não é idiomático em Go | `Name()` |
| `init()` com efeito colateral (I/O, registro global) | Ordem de execução implícita, difícil de testar | Inicialização explícita em `main()` ou construtor |
| Mensagem de erro com maiúscula inicial ou pontuação final | Quebra convenção de encadeamento (`fmt.Errorf("...: %w")`) | `"falha ao processar: %w"`, minúsculo, sem ponto final |

---

## Referências Detalhadas

Consultar conforme necessário — carregados sob demanda:

| Arquivo | Conteúdo |
|---|---|
| **`references/errors.md`** | Wrapping, sentinel × tipo, `errors.Join`, mapeamento erro→HTTP |
| **`references/concurrency.md`** | Goroutines, canais, `select`, `context`, `errgroup`, worker pool, `synctest` |
| **`references/project-layout.md`** | `cmd`/`internal`/`pkg`, camadas, DI manual, `go.work`, `go:embed` |
| **`references/testing.md`** | Table-driven, mocks via interface, `httptest`, fuzz, benchmarks com `b.Loop` |
| **`references/stdlib-http-slog.md`** | `net/http` server/client completos, middleware, `slog` customizado |
| **`references/go127-features.md`** | Novidades 1.25→1.27 com exemplos completos |
| **`references/tooling-build.md`** | `golangci-lint` v2, `govulncheck`, cross-compile, Dockerfile distroless/scratch |

---

## Também consultar

- `domains/api-rest/SKILL.md` — contrato de API REST, versionamento, tratamento de erro HTTP
- `domains/database/SKILL.md` — acesso a banco de dados (`database/sql`, drivers, migrações)
- `domains/security/SKILL.md` — segurança de aplicação (validação de input, autenticação, exposição de erro)
- `domains/observability/SKILL.md` — métricas, logs, traces e SLI/SLO
- `domains/containers/SKILL.md` — Containerfile/Dockerfile para empacotar o binário Go
