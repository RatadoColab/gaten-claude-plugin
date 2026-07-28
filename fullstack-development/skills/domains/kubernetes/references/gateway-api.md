# Gateway API — Exemplos e Migração desde Ingress

## GatewayClass — papel de infraestrutura (provido pelo controller)

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: default-gateway-class
spec:
  controllerName: example.com/gateway-controller
```

## Gateway — ponto de entrada e TLS

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: app-gateway
spec:
  gatewayClassName: default-gateway-class
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "app.example.com"
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: app-tls
      allowedRoutes:
        namespaces:
          from: Selector
          selector:
            matchLabels:
              kubernetes.io/metadata.name: app-prod
```

`app-tls` é tipicamente gerenciado pelo cert-manager via `Certificate`/`Issuer`, não criado
manualmente.

## HTTPRoute — regras de roteamento por aplicação

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app
  namespace: app-prod
spec:
  parentRefs:
    - name: prod-gateway
      namespace: app-gateway
  hostnames:
    - "app.example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: app
          port: 8080
```

## Roteamento canário por peso

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-canary
  namespace: app-prod
spec:
  parentRefs:
    - name: prod-gateway
      namespace: app-gateway
  hostnames:
    - "app.example.com"
  rules:
    - backendRefs:
        - name: app-stable
          port: 8080
          weight: 90
        - name: app-canary
          port: 8080
          weight: 10
```

## Separação de papéis

| Recurso | Dono típico | Escopo |
|---------|-------------|--------|
| `GatewayClass` | Plataforma/infra | Cluster inteiro |
| `Gateway` | Plataforma/infra | Namespace de infra, referenciado por rotas |
| `HTTPRoute` | Time de aplicação | Namespace da aplicação |

Essa separação é o principal ganho do Gateway API sobre o `Ingress` — cada annotation
proprietária de controller vira campo tipado, e o time de aplicação não precisa tocar em recursos
de infraestrutura para expor um serviço.

## Migração desde Ingress

- `kubernetes/ingress-nginx` atingiu fim de vida em 24/03/2026 — repositório read-only, sem novos
  patches de CVE
- A API `Ingress` do core do Kubernetes **continua existindo** e válida; o que foi descontinuado é
  o controller `ingress-nginx` especificamente
- `ingress2gateway` (ferramenta oficial, versão 1.0) converte recursos `Ingress` existentes —
  incluindo boa parte das annotations mais comuns — em `Gateway`/`HTTPRoute` equivalentes
- Alternativas ao migrar: adotar Gateway API com um controller compatível, ou trocar para outro
  controller de Ingress mantido (Traefik, HAProxy, F5 NGINX, Envoy) caso a migração completa não
  seja viável no curto prazo

## Mapeamento rápido Ingress → Gateway API

| Ingress | Gateway API |
|---------|-------------|
| `Ingress` (regras de host/path) | `HTTPRoute` |
| `IngressClass` | `GatewayClass` |
| TLS no `Ingress.spec.tls` | TLS no `Gateway.spec.listeners[].tls` |
| Annotations proprietárias do controller (rewrite, canário, etc.) | Campos tipados em `HTTPRoute` (filters, `backendRefs[].weight`) |
