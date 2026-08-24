# Node.js — Segurança e Supply Chain

Permission model do runtime e hardening da cadeia de dependências npm.

---

## Permission Model

```bash
node --permission \
  --allow-fs-read=./data \
  --allow-fs-write=./tmp \
  --allow-net=api.example.com \
  --allow-child-process \
  server.js
```

Restringe o que o processo pode fazer no nível do runtime — leitura/escrita de arquivo, acesso à rede, criação de subprocesso, uso de addon nativo (`--allow-addons`) e de worker (`--allow-worker`). Qualquer operação fora do permitido lança `ERR_ACCESS_DENIED` com o recurso específico negado.

**Limitações importantes:**
- É uma camada de defesa em profundidade, **não substitui** revisão de dependências — uma dependência maliciosa ainda pode operar dentro do escopo permitido para a aplicação funcionar.
- Granularidade é por processo, não por módulo — não isola uma dependência específica das outras.
- Precisa de teste completo em staging: a lista de permissões deve cobrir todo I/O legítimo (incluindo caminhos abertos por dependências transitivas), ou a aplicação falha em runtime de forma pouco óbvia.

## `--ignore-scripts`

```bash
npm ci --ignore-scripts
```

Impede execução de scripts `preinstall`/`install`/`postinstall` de qualquer pacote durante a instalação — o vetor mais comum de comprometimento de supply chain (script arbitrário rodando com as permissões do usuário que instalou). Usar como padrão em CI; reabilitar seletivamente (`npm rebuild <pacote>`) apenas para os pacotes que legitimamente precisam de build nativo (ex.: `better-sqlite3`).

## Lockfile e `npm ci`

`npm ci` (nunca `npm install` em CI/build de produção):
- Instala exatamente o que está no lockfile, falha se `package.json` e lockfile divergirem.
- Remove `node_modules` antes de instalar — build determinístico, sem resíduo de instalação anterior.
- Não modifica o lockfile — qualquer drift é um erro explícito, não uma correção silenciosa.

Lockfile (`package-lock.json`/`pnpm-lock.yaml`) grava hash de integridade de cada pacote resolvido — toda instalação subsequente verifica esse hash contra o conteúdo baixado, detectando substituição do pacote no registry após a resolução original.

## `npm audit signatures`

```bash
npm audit signatures
```

Verifica a assinatura criptográfica de cada pacote instalado contra a chave pública do registry npm — detecta pacote servido sem assinatura válida (indício de registry comprometido ou pacote adulterado em trânsito). Complementar ao `npm audit` tradicional (que verifica vulnerabilidade conhecida, não integridade).

## Trusted Publishing e Provenance

Publicar sem token de longa duração armazenado em CI: o provedor de CI (GitHub Actions, GitLab CI) autentica via OIDC diretamente com o registry, que valida que a publicação vem exatamente do workflow/repositório autorizado — elimina o risco de vazamento de token npm de longa duração.

```yaml
# exemplo GitHub Actions com OIDC trusted publishing
permissions:
  id-token: write
steps:
  - run: npm publish --provenance
```

Provenance attestation gera um registro criptográfico público ligando o pacote publicado a um commit e workflow específicos, verificável por qualquer consumidor. **Limitação:** o npm não impõe a checagem de provenance no `npm install` — nada impede instalar uma versão publicada sem provenance; a garantia é de auditabilidade, não de bloqueio automático.

## Camadas de Defesa (Nenhuma É Suficiente Sozinha)

| Camada | Protege contra |
|---|---|
| Lockfile + `npm ci` | Drift de versão não intencional, pacote alterado após resolução |
| `--ignore-scripts` | Código arbitrário executado na instalação |
| `npm audit` / `govulncheck`-equivalente | Vulnerabilidade conhecida (CVE) em dependência |
| `npm audit signatures` | Pacote sem assinatura válida do registry |
| Provenance + trusted publishing | Publicação forjada ou token vazado |
| Cooldown de versão (aguardar N dias antes de atualizar) | Pacote comprometido detectado e removido rapidamente pela comunidade |
| SBOM (`npm sbom` ou CycloneDX) | Falta de visibilidade sobre a árvore completa de dependências transitivas |

Nenhuma camada isolada previne todo ataque de supply chain — a prática recomendada combina todas, com auditoria periódica em vez de checagem pontual única.
