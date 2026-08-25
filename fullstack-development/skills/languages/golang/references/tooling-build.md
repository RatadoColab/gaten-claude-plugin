# Go — Ferramentas e Build

`golangci-lint` v2, `govulncheck`, cross-compile e imagem de container mínima.

---

## `golangci-lint` v2

```yaml
# .golangci.yml
version: "2"
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gofumpt
    - bodyclose
    - noctx
    - errorlint
run:
  timeout: 5m
```

```bash
golangci-lint run ./...
```

Meta-linter que roda dezenas de analisadores em paralelo com cache — padrão de facto do ecossistema Go. `errorlint` pega uso de `errors.Is`/`As` incorreto e comparação de erro por `==`; `bodyclose` pega `resp.Body` de `http.Response` não fechado; `noctx` pega chamada HTTP sem `context`. Configurar no CI como gate obrigatório, não como sugestão opcional.

## `govulncheck`

```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

Verifica as dependências do módulo contra o banco de dados de vulnerabilidades do Go, mas — diferente de scanners genéricos — analisa se o código do projeto realmente **chama** a função vulnerável (call graph), reduzindo drasticamente falso positivo de "dependência tem CVE mas a função afetada nunca é usada".

## `go mod tidy` e `go mod verify`

```bash
go mod tidy      # remove dependência não usada, adiciona a que falta, sincroniza go.sum
go mod verify    # confere hash de cada módulo baixado contra go.sum
```

Rodar `go mod tidy` antes de commitar mudança de import; `go mod verify` em CI detecta módulo baixado que não bate com o hash registrado (indício de cache corrompido ou tentativa de adulteração). A partir do Go 1.27, `go mod tidy` também mescla blocos `require` duplicados automaticamente para módulos com `go 1.27+` no `go.mod`.

## Cobertura e Race em CI

```bash
go test -race -cover -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

`-race` sempre em CI (custo de performance aceitável para a execução de teste, não para produção). `-coverprofile` gera relatório navegável (`go tool cover -html=coverage.out`) para identificar caminho não coberto.

## Cross-Compile

```bash
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o bin/servico-linux-amd64 ./cmd/api
GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -o bin/servico-darwin-arm64 ./cmd/api
```

Go compila nativamente para outra plataforma sem toolchain adicional — `CGO_ENABLED=0` desabilita dependência de biblioteca C do sistema, produzindo binário estático verdadeiramente portável (pré-requisito para rodar em imagem `scratch`).

## Build Tags

```go
//go:build linux && amd64

package platform
```

Compila o arquivo condicionalmente por plataforma/feature flag em tempo de build — usado para código específico de SO, variante experimental (`//go:build experimental`) ou implementação alternativa selecionável por flag de build.

## `ldflags` — Binário de Produção

```bash
go build -ldflags="-s -w -X main.version=1.4.0" -o bin/servico ./cmd/api
```

`-s -w` remove tabela de símbolo e informação de debug DWARF — reduz o tamanho do binário final (não afeta comportamento em runtime, só dificulta debug com `gdb`/`delve` direto no binário de produção). `-X main.version=...` injeta valor de variável em tempo de build (versão, commit hash) sem hardcode no código-fonte.

## Dockerfile Multi-Stage — Distroless/Scratch

```dockerfile
FROM golang:1.27-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/servico ./cmd/api

FROM gcr.io/distroless/static-debian12:nonroot AS production
COPY --from=builder /bin/servico /bin/servico
USER nonroot:nonroot
ENTRYPOINT ["/bin/servico"]
```

| Base final | Quando usar |
|---|---|
| `gcr.io/distroless/static` | Padrão recomendado — sem shell, sem package manager, usuário non-root pronto (`:nonroot`), poucos MB adicionais sobre `scratch` |
| `scratch` | Absoluto mínimo (poucos KB) — só quando não há necessidade alguma de certificado TLS/timezone embutido no runtime da imagem |
| `alpine` | Apenas quando é necessário shell para debug direto no container em produção — aumenta superfície de ataque |

Binário Go estático (sem CGO) é o caso ideal para imagem final de poucos MB — todo o runtime necessário já está compilado dentro do binário, sem exigir interpretador nem biblioteca dinâmica do SO base.
