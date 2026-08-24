# Go — Novidades 1.25 → 1.27

Exemplos completos dos recursos introduzidos entre as três últimas versões suportadas.

---

## `encoding/json/v2` (experimental na 1.25, GA na 1.27)

```go
import "encoding/json/v2"

data, err := json.Marshal(user)                 // API compatível na superfície
err = json.Unmarshal(data, &user)

// comportamento mais estrito por padrão:
// - rejeita UTF-8 inválido (v1 substituía silenciosamente)
// - rejeita nome de campo duplicado no JSON de entrada (v1 aceitava o último)
```

Performance de `Marshal` fica em paridade com v1; `Unmarshal` é significativamente mais rápido. Opção de desligar globalmente durante migração: `GOEXPERIMENT=nojsonv2` na 1.25/1.26 (não aplicável após virar padrão na 1.27). Migrar gradualmente testando contra os dois comportamentos antes de fixar `v2` como import definitivo em código que já depende do comportamento permissivo do v1.

## Métodos Genéricos (1.27)

```go
type Container[T any] struct{ items []T }

func (c *Container[T]) Map(fn func(T) T) *Container[T] {   // método comum, tipo já genérico
    ...
}

// novidade 1.27: o MÉTODO declara seu próprio parâmetro de tipo
func (r *Rand) N[Int int | int32 | int64](n Int) Int {
    ...
}
```

Antes da 1.27, um método só podia usar o(s) parâmetro(s) de tipo já declarado(s) no tipo receptor — não podia introduzir um novo parâmetro de tipo próprio. Isso permitia apenas função solta genérica (`func Sum[T ...](...)`), nunca um método genérico independente do tipo genérico do receptor. Limitação: métodos de **interface** continuam não podendo declarar parâmetro de tipo próprio — a restrição vale só para métodos concretos.

## `new(expr)` (1.27)

```go
// antes: variável intermediária só para tirar o endereço
count := 5
p := &count

// 1.27: new aceita expressão, não só tipo
p := new(5)          // equivalente ao idiom acima, sem variável nomeada
timeout := new(30 * time.Second)
```

Elimina o idiom comum de declarar uma variável só para poder tirar seu endereço (frequente ao popular ponteiro de campo opcional em struct de configuração).

## `go fix` com Modernizers (1.27)

```bash
go fix ./...
```

Reescrito sobre o framework de análise do Go, com dezenas de "modernizers" — analisadores que sugerem/aplicam reescrita segura para idioma mais novo da stdlib. Exemplos de categoria: `atomictypes` (migra uso manual de `sync/atomic` funções para os tipos `atomic.Int64` etc.), `embedlit` (substitui slice/array literal grande por `//go:embed` quando os dados vêm de arquivo estático), `slicesbackward` (substitui loop reverso manual por `slices.Backward` em `range`), `unsafefuncs` (moderniza uso de `unsafe`). Rodar como parte de manutenção periódica, revisando o diff antes de commitar — é reescrita automática, não apenas sugestão passiva.

## Profile `goroutineleak` (experimental 1.26 → estável 1.27)

```bash
go test -run TestServiceLifecycle -leak
```

Usa análise de alcançabilidade do garbage collector para identificar goroutine que está permanentemente bloqueada em canal, mutex ou `WaitGroup` sem nenhuma possibilidade de progresso futuro — diferente de um simples contador de goroutines ativas, que não distingue "ainda trabalhando" de "vazada para sempre". Ver `references/concurrency.md` para uso em conjunto com `testing/synctest`.

## GOMAXPROCS Container-Aware (1.25)

Antes da 1.25, `GOMAXPROCS` (número de threads de SO usadas pelo scheduler) via por padrão a contagem de CPUs lógicas da máquina host, ignorando `cpu.cfs_quota_us`/limite de cgroup do container — em Kubernetes com `limits.cpu: "2"` rodando em nó de 32 cores, o runtime achava que tinha 32 cores disponíveis, gerando contenção e latência de scheduling. Desde 1.25, o runtime lê o limite de cgroup automaticamente e ajusta `GOMAXPROCS` — elimina a necessidade da correção manual histórica via `uber-go/automaxprocs` em novo código.

## Alocação de Memória Mais Rápida (1.27)

Rotinas de alocação especializadas por tamanho reduzem o custo de alocação pequena em até 30%, com ~1% de ganho geral em programas com muita alocação — o binário fica ~60 KB maior por causa das rotinas adicionais, troca aceitável na quase totalidade dos casos.

## `crypto/mldsa` e `crypto/hpke` (1.27)

```go
import "crypto/mldsa"   // ML-DSA — assinatura pós-quântica, FIPS 204
import "crypto/hpke"    // Hybrid Public Key Encryption, RFC 9180
```

Suporte pós-quântico chega também a `crypto/tls`/`crypto/x509` (assinatura ML-DSA em certificado, `MLKEM1024` em handshake TLS 1.3) — relevante para sistemas com requisito de compliance de longo prazo (dado cifrado hoje precisa resistir a ataque de computador quântico futuro).

## Outras Adições Notáveis

| Pacote | Adição | Versão |
|---|---|---|
| `strings`/`bytes` | `CutLast()` | 1.27 |
| `math/big` | `Int.Divide()` com modos de arredondamento | 1.27 |
| `net/url` | `URL.Clone()`, `Values.Clone()` | 1.27 |
| `hash/maphash` | Interface `Hasher`, tipo `ComparableHasher` | 1.27 |
| `uuid` | Novo pacote — geração e parsing de UUID na stdlib | 1.27 |
| `simd`/`simd/archsimd` (experimental) | Operações vetoriais portáveis e específicas de arquitetura | 1.25→1.27 |
