# Go — Estrutura de Projeto

`cmd`/`internal`/`pkg`, camadas, injeção de dependência manual e workspaces.

---

## Layout Padrão

```
meuservico/
├── go.mod
├── go.sum
├── cmd/
│   ├── api/
│   │   └── main.go              # ponto de entrada do servidor HTTP
│   └── worker/
│       └── main.go              # ponto de entrada do processador assíncrono
├── internal/
│   ├── user/
│   │   ├── service.go           # regra de negócio
│   │   ├── repository.go        # interface consumida pelo domínio
│   │   └── postgres/
│   │       └── repository.go    # implementação concreta
│   └── httpapi/
│       └── handlers.go
└── migrations/
```

- **`cmd/<binário>/main.go`**: um diretório por executável, nome do diretório = nome do binário gerado. `main.go` deve ser fino — monta dependências (config, DB, logger) e chama `Run()`; a lógica real vive em `internal/`.
- **`internal/`**: qualquer pacote sob `internal/` só é importável por código dentro da mesma árvore acima do `internal/` — o compilador Go aplica essa regra, não é convenção informal. Padrão correto para tudo que é específico deste módulo.
- **`pkg/`**: usar **apenas** quando existe consumidor externo real e comprovado (outro módulo, outro repositório). Sem isso, `pkg/` é ruído — manter em `internal/` ou na raiz do módulo.

Evitar aninhamento profundo (`internal/services/user/handlers/http/v1/`) — Go favorece hierarquia rasa; a estrutura deve emergir do domínio real, não ser imposta antecipadamente por analogia com outra linguagem.

## Camadas e Injeção de Dependência Manual

Go não tem um framework de DI padrão — a prática idiomática é injeção manual via construtor, com a interface definida no pacote consumidor:

```go
// internal/user/service.go
type Repository interface {           // definida onde é consumida
    FindByID(ctx context.Context, id string) (*User, error)
}

type Service struct {
    repo Repository
    log  *slog.Logger
}

func NewService(repo Repository, log *slog.Logger) *Service {
    return &Service{repo: repo, log: log}
}
```

```go
// cmd/api/main.go
func main() {
    db := mustConnectDB()
    repo := postgres.NewUserRepository(db)
    svc := user.NewService(repo, slog.Default())
    ...
}
```

Sem container de DI mágico — a árvore de dependências é explícita e visível em `main.go`, o que facilita rastrear o que cada componente realmente usa.

## `go.work` — Multi-Módulo Local

```
# go.work
go 1.27

use (
    ./meuservico
    ./meuservico-shared
)
```

Permite desenvolver um módulo e seu consumidor lado a lado, com o `go build`/`go test` do consumidor resolvendo o outro módulo pelo caminho local em vez da versão publicada — sem editar `replace` dentro de cada `go.mod` (que precisaria ser revertido antes de commitar). `go.work` fica fora do controle de versão do módulo publicado (é conveniência local de desenvolvimento).

## Versionamento `/v2`+

Go embute a versão major no import path a partir da v2 — mudança incompatível exige um novo diretório/módulo lógico:

```
module example.com/meuservico/v2
```

```go
import "example.com/meuservico/v2/user"
```

Consumidores podem importar `v1` e `v2` simultaneamente sem conflito, porque o import path é literalmente diferente — mecanismo deliberado para permitir migração gradual em vez de big-bang.

## `go:embed`

```go
//go:embed templates/*.html
var templatesFS embed.FS

//go:embed schema.sql
var schemaSQL string
```

Embute arquivo estático (template, migração SQL, asset) diretamente no binário compilado — elimina dependência de arquivo externo no filesystem em produção, o que simplifica deploy de binário único (especialmente relevante para imagem de container `scratch`/distroless sem esses arquivos copiados separadamente).
