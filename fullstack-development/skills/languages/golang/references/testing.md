# Go — Testes

Table-driven, mocks via interface, `httptest`, fuzzing e benchmarks.

---

## Table-Driven com Subtests

```go
func TestValidateEmail(t *testing.T) {
    cases := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"válido simples", "user@example.com", false},
        {"sem arroba", "userexample.com", true},
        {"vazio", "", true},
    }

    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()
            err := ValidateEmail(tc.input)
            if (err != nil) != tc.wantErr {
                t.Errorf("ValidateEmail(%q) err = %v, wantErr %v", tc.input, err, tc.wantErr)
            }
        })
    }
}
```

`t.Run` isola cada caso — falha em um não impede a execução dos demais, e o nome do subteste aparece na saída (`TestValidateEmail/sem_arroba`), facilitando localizar exatamente qual caso quebrou. `t.Parallel()` dentro do loop paraleliza os subtests entre si — usar quando os casos não compartilham estado mutável.

## `t.Cleanup` vs `defer`

```go
func setupDB(t *testing.T) *sql.DB {
    db, err := sql.Open("postgres", testDSN)
    if err != nil {
        t.Fatalf("abrir conexão de teste: %v", err)
    }
    t.Cleanup(func() { db.Close() })
    return db
}
```

`t.Cleanup` registra a limpeza no framework de teste em vez de `defer` local — roda mesmo se o teste falhar via `t.Fatal` (que aborta a goroutine do teste antes de alcançar um `defer` posterior no fluxo), e helpers como este podem registrar sua própria limpeza sem o chamador precisar lembrar.

## `t.Context()`

```go
func TestFetch(t *testing.T) {
    ctx := t.Context()   // cancelado automaticamente ao fim do teste
    result, err := Fetch(ctx, "https://api.example.com")
    ...
}
```

Fornece um `context.Context` já ligado ao ciclo de vida do teste — cancelado automaticamente quando o teste termina (ou timeout do runner é atingido), sem precisar criar e cancelar manualmente.

## Mocks via Interface

```go
type stubRepository struct {
    users map[string]*User
}

func (s *stubRepository) FindByID(_ context.Context, id string) (*User, error) {
    u, ok := s.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return u, nil
}

func TestService_FindUser(t *testing.T) {
    repo := &stubRepository{users: map[string]*User{"1": {ID: "1", Name: "Ana"}}}
    svc := NewService(repo, slog.Default())

    user, err := svc.FindUser(t.Context(), "1")
    if err != nil {
        t.Fatalf("erro inesperado: %v", err)
    }
    if user.Name != "Ana" {
        t.Errorf("Name = %q, want Ana", user.Name)
    }
}
```

Porque a interface é definida no pacote consumidor (ver `SKILL.md` §Tipos), criar um stub para teste é trivial — não requer biblioteca de mocking nem geração de código na maioria dos casos. Para interface grande ou gerada a partir de contrato externo, `gomock`/`mockery` continuam válidos.

## `httptest`

```go
func TestHandleGetUser(t *testing.T) {
    handler := NewHandler(stubService{})
    req := httptest.NewRequest(http.MethodGet, "/users/1", nil)
    rec := httptest.NewRecorder()

    handler.ServeHTTP(rec, req)

    if rec.Code != http.StatusOK {
        t.Fatalf("status = %d, want 200", rec.Code)
    }
}
```

`httptest.NewServer` sobe um servidor HTTP real em porta efêmera quando o teste precisa exercitar o cliente HTTP completo (timeouts, TLS) em vez de só o handler isolado.

## Fuzzing

```go
func FuzzParseCSV(f *testing.F) {
    f.Add("nome,idade\nAna,30")   // seed corpus
    f.Fuzz(func(t *testing.T, input string) {
        _, err := ParseCSV(input)
        if err != nil {
            return   // erro é aceitável — o que não pode é panicar
        }
    })
}
```

```bash
go test -fuzz FuzzParseCSV -fuzztime 30s
```

Nativo desde 1.18 — essencial para qualquer função que parseia entrada não confiável (parser, deserializador, validador de formato). O fuzzer gera entradas automaticamente buscando panic/crash; casos que quebram são salvos em `testdata/fuzz/` para virarem regressão determinística.

## Benchmarks com `b.Loop()`

```go
func BenchmarkParseCSV(b *testing.B) {
    input := generateSampleCSV(1000)
    for b.Loop() {
        _, _ = ParseCSV(input)
    }
}
```

`b.Loop()` (substituindo o padrão manual `for i := 0; i < b.N; i++`) reseta o timer automaticamente e evita que o compilador elimine a chamada por dead-code elimination — mais seguro que o padrão antigo, que exigia `b.ResetTimer()` manual após qualquer setup custoso dentro da função de benchmark.

## Golden Files

```go
func TestRenderReport(t *testing.T) {
    got := RenderReport(sampleData)
    golden := filepath.Join("testdata", "report.golden")

    if *update {
        os.WriteFile(golden, got, 0o644)
    }
    want, _ := os.ReadFile(golden)
    if !bytes.Equal(got, want) {
        t.Errorf("saída difere do golden file — rode com -update para regravar")
    }
}
```

Padrão comum para saída grande/estruturada (relatório, template renderizado) — compara contra um arquivo de referência versionado em vez de embutir a saída esperada inline no código do teste; flag `-update` (custom, definida no próprio pacote de teste) regrava o golden file quando a mudança é intencional.
