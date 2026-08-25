# Go — Tratamento de Erros

Wrapping, sentinel errors, tipos de erro e mapeamento para a borda do sistema.

---

## Wrapping com `%w`

```go
func loadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("ler config %s: %w", path, err)
    }
    var cfg Config
    if err := json.Unmarshal(data, &cfg); err != nil {
        return nil, fmt.Errorf("parsear config %s: %w", path, err)
    }
    return &cfg, nil
}
```

`%w` preserva o erro original na cadeia, permitindo que o chamador inspecione com `errors.Is`/`errors.As` sem conhecer a mensagem textual — usar `%v` apenas quando deliberadamente **não** se quer expor o erro original na cadeia (ex.: fronteira de segurança).

## Sentinel × Tipo de Erro

```go
var ErrNotFound = errors.New("recurso não encontrado")   // sentinel — comparação por identidade

type ValidationError struct {                             // tipo — carrega dado estruturado
    Field string
    Msg   string
}
func (e *ValidationError) Error() string { return fmt.Sprintf("%s: %s", e.Field, e.Msg) }
```

```go
if errors.Is(err, ErrNotFound) { ... }        // sentinel: existe/não existe
var verr *ValidationError
if errors.As(err, &verr) { fmt.Println(verr.Field) }   // tipo: extrai dado do erro
```

Sentinel para "essa condição específica ocorreu ou não" (comparável, exportável, estável); tipo estruturado quando o chamador precisa de dado adicional do erro (qual campo, qual valor esperado). Evitar comparar erro por *string* (`err.Error() == "..."`)  — frágil a mudança de mensagem.

## `errors.Join`

```go
var errs []error
for _, field := range fields {
    if err := validate(field); err != nil {
        errs = append(errs, err)
    }
}
if len(errs) > 0 {
    return errors.Join(errs...)
}
```

Agrega múltiplos erros independentes (ex.: validação de vários campos de um formulário) em um único erro que ainda responde a `errors.Is`/`errors.As` para qualquer um dos erros agregados — evita retornar só o primeiro erro encontrado quando todos são relevantes ao chamador.

## Onde Tratar o Erro (Boundary)

Não logar **e** retornar o mesmo erro — decidir explicitamente em que camada ele é definitivamente tratado:

```go
// camada de domínio: apenas propaga com contexto
func (s *Service) CreateUser(ctx context.Context, in Input) (*User, error) {
    if err := s.repo.Save(ctx, in); err != nil {
        return nil, fmt.Errorf("salvar usuário: %w", err)
    }
    return &User{...}, nil
}

// camada HTTP: boundary — decide log e resposta ao cliente
func (h *Handler) handleCreate(w http.ResponseWriter, r *http.Request) {
    user, err := h.svc.CreateUser(r.Context(), input)
    if err != nil {
        slog.ErrorContext(r.Context(), "criar usuário falhou", "error", err)
        http.Error(w, "não foi possível criar o usuário", http.StatusInternalServerError)
        return
    }
    ...
}
```

Logar em toda camada intermediária polui o log com o mesmo evento repetido; a decisão de "isso é um erro que o operador precisa ver" pertence ao boundary que também decide a resposta ao cliente.

## Mapeamento Erro → HTTP

```go
func statusFor(err error) int {
    switch {
    case errors.Is(err, ErrNotFound):
        return http.StatusNotFound
    case errors.As(err, new(*ValidationError)):
        return http.StatusBadRequest
    default:
        return http.StatusInternalServerError
    }
}
```

Centralizar esse mapeamento em uma função única evita `if`/`switch` de status duplicado em cada handler — ver `domains/api-rest/SKILL.md` para o formato de corpo de resposta de erro (RFC 9457/Problem Details).

## Segurança da Mensagem Exposta

Nunca retornar `err.Error()` diretamente no corpo da resposta HTTP — pode vazar caminho de arquivo, query SQL, versão de biblioteca ou detalhe de infraestrutura interna. A mensagem de log (interna, completa) e a mensagem exposta ao cliente (genérica, sem detalhe sensível) são deliberadamente diferentes.

## `panic`/`recover`

```go
func (s *Server) middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if rec := recover(); rec != nil {
                slog.Error("panic recuperado", "recover", rec, "stack", string(debug.Stack()))
                http.Error(w, "erro interno", http.StatusInternalServerError)
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

`recover()` só no boundary do servidor (middleware), para não derrubar o processo inteiro por um handler com bug — nunca usado para controle de fluxo normal em código de domínio. `panic` reservado a invariante impossível de acontecer em operação correta (índice fora de faixa por bug interno), nunca para erro esperado do domínio (não encontrado, validação, timeout de rede).
