# Containers — Exemplos

## Dockerfile/Containerfile multi-stage (Node.js)

```dockerfile
# Estágio de build com toolchain completo
FROM node:20-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci                          # instalação reproduzível
COPY . .
RUN npm run build

# Imagem final mínima, somente runtime
FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN useradd --system --create-home app   # usuário não-root
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
USER app
EXPOSE 3000
HEALTHCHECK CMD node healthcheck.js || exit 1
CMD ["node", "dist/server.js"]
```

---

## Variante com pin por digest e labels OCI

Mesmo Dockerfile acima, trocando a base por tag pela mesma imagem fixada por digest e adicionando
rastreabilidade até o commit de origem:

```dockerfile
# Digest imutável em vez de tag — a tag "20-slim" pode ser sobrescrita no registry
FROM node:20-slim@sha256:1a2b3c4d5e6f... AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim@sha256:1a2b3c4d5e6f... AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN useradd --system --create-home app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
USER app
EXPOSE 3000

# Rastreabilidade: liga a imagem publicada ao commit/versão que a gerou
LABEL org.opencontainers.image.source="https://github.com/org/app" \
      org.opencontainers.image.revision="$GIT_SHA" \
      org.opencontainers.image.version="1.4.2"

CMD ["node", "dist/server.js"]
```
