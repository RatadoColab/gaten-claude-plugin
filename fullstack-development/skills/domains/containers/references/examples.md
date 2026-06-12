# Containers — Exemplos

## Dockerfile multi-stage (Node.js)

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

## Deployment Kubernetes com probes e limites

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  template:
    spec:
      securityContext:
        runAsNonRoot: true          # reforça não-root
      containers:
        - name: api
          image: registry.example.com/api:1.4.2   # tag imutável
          ports:
            - containerPort: 3000
          resources:
            requests: { cpu: "100m", memory: "128Mi" }
            limits:   { cpu: "500m", memory: "256Mi" }
          readinessProbe:
            httpGet: { path: /health/ready, port: 3000 }
            initialDelaySeconds: 5
          livenessProbe:
            httpGet: { path: /health, port: 3000 }
            initialDelaySeconds: 15
```
