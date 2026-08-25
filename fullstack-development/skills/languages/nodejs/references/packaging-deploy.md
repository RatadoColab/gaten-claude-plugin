# Node.js — Empacotamento e Deploy

`package.json`, workspaces, executável único e containerização.

---

## `package.json` de Referência

```json
{
  "name": "meu-servico",
  "version": "1.4.0",
  "type": "module",
  "engines": { "node": ">=24" },
  "packageManager": "pnpm@10.12.0",
  "scripts": {
    "start": "node --env-file=.env src/index.js",
    "dev": "node --watch --env-file=.env src/index.js",
    "test": "node --test",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": { "fastify": "^5.0.0" },
  "devDependencies": { "typescript": "^5.9.0" }
}
```

`packageManager` fixado + `corepack enable` garante que todo desenvolvedor e o CI usem exatamente a mesma versão do gerenciador, sem depender de instalação global divergente.

## pnpm Workspaces

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// apps/api/package.json
{ "dependencies": { "@meuescopo/shared": "workspace:*" } }
```

`workspace:*` resolve para o pacote local do monorepo em desenvolvimento e é substituído pela versão publicada real no momento do `pnpm publish` — evita link manual (`npm link`) e drift entre versão local e publicada.

## SEA — Single Executable Application

Empacota o runtime Node + o código da aplicação em um único binário nativo, sem exigir Node instalado no host de destino:

```bash
node --experimental-sea-config sea-config.json
node -e "require('fs').copyFileSync(process.execPath, 'meu-app')"
npx postject meu-app NODE_SEA_BLOB sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2
```

Útil para distribuir CLI ou ferramenta interna sem exigir `npm install` no ambiente alvo — ainda experimental, validar compatibilidade com dependências nativas (addons) antes de adotar em produção.

## Dockerfile Multi-Stage

Estrutura multi-stage (build com toolchain completo → runtime mínimo, usuário non-root) segue o padrão geral em **`domains/containers/references/examples.md`** — essa skill é a fonte autoritativa da imagem OCI. Delta específico de Node.js:

- Com pnpm, `corepack enable && pnpm install --frozen-lockfile` no stage de build (todas as dependências, incluindo dev) e `--frozen-lockfile --prod` no stage final, em vez do `npm ci` do exemplo genérico.
- `gcr.io/distroless/nodejs24` é alternativa ainda mais enxuta ao alpine para quem não precisa de shell no container final (troca depurabilidade por superfície de ataque menor).
- `CMD ["node", "--permission", "--allow-fs-read=./dist", "--allow-net", "dist/index.js"]` aplica o sandboxing do runtime já na definição da imagem, não apenas como configuração externa — ver **`references/security-supply-chain.md`** (§Permission Model) para a lista completa de flags e suas limitações.

## Sinais e PID 1

Em container, o processo Node normalmente roda como PID 1 — PID 1 não recebe o comportamento padrão de sinal (`SIGTERM` não mata automaticamente se não houver handler registrado, `SIGCHLD` de processo zumbi não é colhido). Usar `tini`/`dumb-init` como entrypoint, ou `docker run --init`, garante repasse correto de sinal e colheita de zumbi sem reescrever a aplicação.

```dockerfile
ENTRYPOINT ["tini", "--"]
CMD ["node", "dist/index.js"]
```

Detalhamento completo do permission model (flags, limitações, granularidade) em **`references/security-supply-chain.md`** (§Permission Model).
