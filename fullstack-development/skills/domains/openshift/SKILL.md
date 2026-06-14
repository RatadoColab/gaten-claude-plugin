---
name: openshift
description: This skill should be used when deploying to or working with Red Hat OpenShift (OKD). Covers the differences from vanilla Kubernetes (Route vs Ingress, Project vs Namespace, DeploymentConfig, BuildConfig/ImageStream), Security Context Constraints (SCC), restricted-v2 defaults and their Dockerfile implications, Source-to-Image (S2I), the internal registry, the `oc` CLI, and OpenShift GitOps (ArgoCD).
---

# OpenShift — Kubernetes Enterprise da Red Hat

## Visão Geral

Diretrizes específicas para empacotar e operar aplicações no OpenShift (e seu upstream OKD). O
OpenShift é uma distribuição enterprise de Kubernetes: tudo que vale para Kubernetes continua
valendo, mas a plataforma acrescenta recursos próprios (Routes, BuildConfig, ImageStreams) e adota
defaults de segurança mais restritivos. Carregar esta skill junto de `containers` — aqui ficam
apenas as diferenças em relação ao Kubernetes vanilla.

---

## Princípios Fundamentais

- **Seguro por padrão:** SCC `restricted-v2` é aplicada por padrão; o pod roda com UID aleatório
  não-root e sem privilégios — projetar a imagem para tolerar isso, não relaxar a SCC
- **Recursos nativos primeiro:** preferir `Route` e `BuildConfig`/`ImageStream` aos equivalentes
  genéricos quando o ganho for real (TLS gerenciado, rebuild automático por trigger)
- **`oc` é superset de `kubectl`:** todo manifest Kubernetes funciona; `oc` adiciona comandos para
  os recursos próprios da plataforma
- **Imutabilidade e tags por digest:** promover imagens por digest via ImageStream, nunca
  sobrescrever tags publicadas

---

## OpenShift vs Kubernetes vanilla

| Conceito Kubernetes      | Equivalente/recurso OpenShift           | Observação                                  |
|--------------------------|-----------------------------------------|---------------------------------------------|
| `Ingress`                | `Route`                                 | Route gerencia TLS (edge/passthrough/reencrypt) |
| `Namespace`              | `Project`                               | Project = Namespace + anotações + RBAC      |
| `Deployment`             | `Deployment` (preferir) ou `DeploymentConfig` | DeploymentConfig é legado; usar Deployment |
| Build externo + push     | `BuildConfig` + `ImageStream`           | Build dentro do cluster, trigger automático |
| `PodSecurity` admission  | `SecurityContextConstraints` (SCC)      | SCC é anterior e mais granular              |
| `kubectl`                | `oc`                                    | `oc` é superset; `oc new-app`, `oc rollout` |
| Registry externo         | Internal registry (`image-registry...`) | Integrado a ImageStreams                    |

---

## Segurança — Security Context Constraints (SCC)

A SCC `restricted-v2` (default) impõe restrições que quebram imagens mal projetadas:

- **UID aleatório:** o container roda com um UID arbitrário (não o `USER` do Dockerfile) pertencente
  ao grupo `root` (GID `0`) — **não** fixar `USER 1000`; garantir que arquivos e diretórios graváveis
  tenham permissão de grupo (`chgrp 0 && chmod g=u`)
- **Não-root obrigatório:** processos não podem rodar como root nem escalar privilégios
- **Portas ≥ 1024:** sem `NET_BIND_SERVICE`, expor portas não privilegiadas (ex.: `8080`, não `80`)
- **Filesystem:** preferir `readOnlyRootFilesystem` e montar volumes graváveis explícitos
- **Evitar `anyuid`:** conceder a SCC `anyuid` apenas em último caso e com justificativa — quebra o
  modelo de segurança da plataforma

### Implicações no Dockerfile

```dockerfile
FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production PORT=8080
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
# Permitir UID aleatório do OpenShift: tornar o app gravável pelo grupo root (GID 0)
RUN chgrp -R 0 /app && chmod -R g=u /app
EXPOSE 8080                          # porta não privilegiada
# Sem USER numérico fixo — a SCC injeta o UID em runtime
CMD ["node", "dist/server.js"]
```

---

## Build na Plataforma — S2I, BuildConfig e ImageStream

- **Source-to-Image (S2I):** monta a imagem a partir do código-fonte + uma builder image, sem
  Dockerfile — útil para padronizar stacks; usar quando a equipe não quer manter Dockerfile
- **Dockerfile strategy:** o `BuildConfig` também aceita build por Dockerfile quando há necessidade
  de controle fino
- **ImageStream:** abstrai tags de imagem e dispara rebuild/redeploy automático via triggers quando
  a imagem de base muda
- **Internal registry:** publicar no registry interno integrado aos ImageStreams ou em registry
  externo conforme a política da empresa

---

## Exposição — Route com TLS

Manifest completo de `Route` (host automático vs fixo, `insecureEdgeTerminationPolicy: Redirect`) em **`references/examples.md`**.

| Terminação      | Onde o TLS termina                        | Quando usar                          |
|-----------------|-------------------------------------------|--------------------------------------|
| **edge**        | No router; tráfego interno em HTTP         | Padrão; certificado gerenciado no router |
| **passthrough** | No pod (o app serve TLS)                    | mTLS ou requisito de criptografia ponta a ponta |
| **reencrypt**   | Reencripta do router até o pod              | TLS interno obrigatório com cert do router externo |

---

## Deploy e Rollback com `oc`

Reusar probes, requests/limits e `securityContext` da skill `containers`. Operação via `oc`:

```bash
oc new-app --image=image-registry.../api:1.4.2   # cria Deployment + Service
oc expose service/api                            # cria Route
oc rollout status deployment/api                 # acompanha o rollout
oc rollout undo deployment/api                   # rollback para a revisão anterior
oc logs -f deployment/api                         # logs em streaming
```

---

## GitOps no OpenShift

- **OpenShift GitOps** empacota o ArgoCD como operador — Git é a fonte de verdade dos manifests
  (Deployment, Route, BuildConfig), com reconciliação automática e detecção de drift
- Versionar os recursos OpenShift no repositório e deixar o ArgoCD aplicar — ver `domains/iac/SKILL.md`

---

## Referências

- Ver `domains/containers/SKILL.md` para fundamentos de imagem, probes e Kubernetes (base desta skill)
- Ver `domains/azure-devops/SKILL.md` para o pipeline que builda e faz deploy no OpenShift
- Ver `domains/ci-cd/SKILL.md` para estágios, gates e estratégias de deploy
- Ver `domains/iac/SKILL.md` para GitOps (OpenShift GitOps/ArgoCD)
- Ver `domains/devsecops/SKILL.md` para scan de imagens, SBOM/assinatura e hardening do pipeline
- [OpenShift — Managing security context constraints](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html)
- [OpenShift — Creating routes](https://docs.openshift.com/container-platform/latest/networking/routes/route-configuration.html)
