---
name: containers
description: This skill should be used when writing Dockerfiles or working with containers and Kubernetes. Typical triggers include "write the Dockerfile", "containerize this app", "create the Kubernetes manifest", "configure probes and resource limits". Covers image best practices (multi-stage, non-root, minimal base, pinned versions), image scanning, registries, immutable infrastructure, and Kubernetes fundamentals (probes, resource limits, namespaces, secrets).
---

# Containers — Docker e Kubernetes

## Visão Geral

Diretrizes para empacotar aplicações em imagens de container seguras e enxutas e para operá-las em
orquestradores como Kubernetes. Containers são a unidade de entrega imutável: a mesma imagem roda
identicamente em qualquer ambiente.

---

## Princípios Fundamentais

- **Imutabilidade:** ambientes são reconstruídos a partir da imagem, nunca alterados in-place —
  elimina drift e backdoors persistentes
- **Imagem mínima:** menos camadas e pacotes = menor superfície de ataque e download mais rápido
- **Reprodutibilidade:** build determinístico a partir do Dockerfile + lockfiles versionados
- **Um processo por container:** cada container tem uma única responsabilidade
- **Configuração externa:** config via variáveis de ambiente/volumes, nunca embutida na imagem

---

## Boas Práticas de Dockerfile

- **Multi-stage build:** separar a etapa de build (com toolchain) da imagem final (só runtime)
- **Base mínima:** preferir imagens `slim`, `alpine` ou `distroless`
- **Usuário não-root:** criar e usar um usuário sem privilégios (`USER app`)
- **Pin de versões:** fixar versões de base e dependências; evitar `latest`
- **Ordem de camadas:** copiar manifests e instalar dependências antes do código-fonte para
  aproveitar cache
- **`.dockerignore`:** excluir `.git`, `node_modules` locais, secrets e artefatos desnecessários
- **Sem secrets na imagem:** nunca `COPY` de chaves; usar build secrets ou injeção em runtime
- **HEALTHCHECK:** declarar verificação de saúde quando aplicável

Dockerfile multi-stage completo (Node.js) em **`references/examples.md`**.

---

## Scan e Registry

- Escanear imagens em busca de CVEs no pipeline (Trivy, Grype, Snyk) antes de publicar
- Bloquear publicação de imagens com vulnerabilidades críticas
- Publicar em registry privado com controle de acesso e tags imutáveis
- Assinar imagens (cosign/Sigstore) e verificar a assinatura no deploy
- Gerar SBOM da imagem para rastrear a cadeia de suprimentos

> Ver `domains/devsecops/SKILL.md` para o catálogo de image scanning, SBOM/assinatura e supply chain no pipeline.

---

## Fundamentos de Kubernetes

| Recurso/Conceito        | Boa prática                                                       |
|-------------------------|------------------------------------------------------------------|
| **Liveness probe**      | Reinicia o container travado                                      |
| **Readiness probe**     | Só recebe tráfego quando pronto                                   |
| **Requests/Limits**     | Definir CPU/memória para evitar contenção e OOM                   |
| **Namespaces**          | Isolar ambientes/equipes e aplicar quotas                        |
| **Secrets/ConfigMaps**  | Separar configuração e segredos da imagem                        |
| **Liveness ≠ Readiness**| Não confundir; probes mal configuradas causam falsos restarts    |

Deployment completo com probes, `securityContext` e requests/limits em **`references/examples.md`**.

---

## Segurança de Containers

- Rodar como não-root e com `readOnlyRootFilesystem` quando possível
- Aplicar menor privilégio: descartar capabilities desnecessárias
- Não montar o socket do Docker dentro de containers
- Usar Network Policies para restringir tráfego pod-a-pod
- Manter imagens base atualizadas — rebuildar regularmente para incorporar patches

---

## Referências

- Ver `domains/ci-cd/SKILL.md` para construir e publicar imagens no pipeline
- Ver `domains/iac/SKILL.md` para provisionar clusters e aplicar manifests via GitOps
- Ver `domains/observability/SKILL.md` para monitorar workloads em Kubernetes
- Ver `domains/devsecops/SKILL.md` para scan de imagens, SBOM/assinatura e hardening do pipeline
- [Docker — Best practices for building images](https://docs.docker.com/build/building/best-practices/)
- [Kubernetes — Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
