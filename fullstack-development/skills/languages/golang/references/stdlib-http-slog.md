# Go — `net/http` e `log/slog` Completos

Servidor e cliente HTTP idiomáticos, middleware e logging estruturado.

---

## Servidor Completo

```go
func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
    slog.SetDefault(logger)

    mux := http.NewServeMux()
    mux.HandleFunc("GET /users/{id}", handleGetUser)
    mux.HandleFunc("POST /users", handleCreateUser)

    srv := &http.Server{
        Addr:              ":8080",
        Handler:           withMiddleware(mux),
        ReadHeaderTimeout: 5 * time.Second,
        ReadTimeout:       10 * time.Second,
        WriteTimeout:      10 * time.Second,
        IdleTimeout:       120 * time.Second,
    }

    go func() {
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            slog.Error("servidor encerrou com erro", "error", err)
            os.Exit(1)
        }
    }()

    stop := make(chan os.Signal, 1)
    signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)
    <-stop

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
        slog.Error("shutdown forçado", "error", err)
    }
}
```

`ReadHeaderTimeout` no mínimo é obrigatório — sem ele, uma conexão que envia cabeçalho lentamente (deliberado ou não) pode prender um file descriptor indefinidamente (Slowloris). `srv.Shutdown(ctx)` para de aceitar novas conexões e espera as em andamento terminarem dentro do timeout do contexto — depois disso, force-close o que sobrar.

## `ServeMux` — Padrões de Rota (1.22+)

```go
mux.HandleFunc("GET /users/{id}", handleGetUser)          // método + wildcard de path
mux.HandleFunc("GET /users/{id}/orders/{orderID}", ...)   // múltiplos wildcards
mux.HandleFunc("GET /files/{path...}", handleServeFile)   // wildcard "resto do caminho"

func handleGetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")   // extrai o wildcard nomeado
    ...
}
```

Cobre roteamento por método e path parametrizado nativamente, sem framework — suficiente para a maioria dos serviços que não precisam de middleware chain sofisticado.

## Middleware

```go
type Middleware func(http.Handler) http.Handler

func chain(h http.Handler, mws ...Middleware) http.Handler {
    for i := len(mws) - 1; i >= 0; i-- {
        h = mws[i](h)
    }
    return h
}

func requestLogger(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        slog.InfoContext(r.Context(), "requisição concluída",
            "method", r.Method, "path", r.URL.Path, "duration_ms", time.Since(start).Milliseconds())
    })
}
```

Middleware como `func(http.Handler) http.Handler` é o padrão idiomático — compõe sem framework, e qualquer router de terceiro (`chi`) que aceite `http.Handler` continua compatível.

## Cliente HTTP

```go
client := &http.Client{Timeout: 5 * time.Second}

req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
if err != nil {
    return fmt.Errorf("criar requisição: %w", err)
}
req.Header.Set("Accept", "application/json")

resp, err := client.Do(req)
if err != nil {
    return fmt.Errorf("chamar %s: %w", url, err)
}
defer resp.Body.Close()

if resp.StatusCode != http.StatusOK {
    return fmt.Errorf("status inesperado %d de %s", resp.StatusCode, url)
}
```

Sempre `NewRequestWithContext` (nunca `http.Get` puro em código de produção) — propaga cancelamento/timeout da chamada original. `client.Timeout` no `http.Client` cobre a requisição inteira; contexto cobre cancelamento vindo de fora (ex.: cliente HTTP upstream desconectou).

## Handler `slog` Customizado

```go
type contextHandler struct {
    slog.Handler
}

func (h contextHandler) Handle(ctx context.Context, r slog.Record) error {
    if reqID, ok := ctx.Value(requestIDKey{}).(string); ok {
        r.AddAttrs(slog.String("request_id", reqID))
    }
    return h.Handler.Handle(ctx, r)
}
```

```go
base := slog.NewJSONHandler(os.Stdout, nil)
slog.SetDefault(slog.New(contextHandler{base}))
```

Injeta atributo derivado do `context` (request ID, trace span) automaticamente em toda chamada `slog.InfoContext`/`ErrorContext` sem precisar passar o campo manualmente em cada linha de log — centraliza a extração em um único lugar.

## `slog.Group` e Campos Padrão

```go
slog.Info("pedido processado",
    slog.Group("pedido", "id", orderID, "total", total),
    "service", "orders-api",
    "env", "production",
)
```

`slog.Group` evita colisão de nome de campo entre subsistemas (`pedido.id` vs `usuario.id` no mesmo log) e mantém o JSON de saída organizado hierarquicamente. Campos como `service`/`env` fixos no handler default (via `slog.With`) evitam repetir em cada chamada de log espalhada pelo código.
