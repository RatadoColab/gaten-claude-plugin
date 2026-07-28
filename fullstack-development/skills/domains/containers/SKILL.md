---
name: containers
description: This skill should be used when writing Dockerfiles or Containerfiles, or building/scanning/publishing container images. Typical triggers include "write the Dockerfile", "write the Containerfile", "containerize this app", "build the image", "scan the image for vulnerabilities". Covers image best practices (multi-stage, non-root, minimal base, digest pinning), OCI labels, image scanning, registries, and image immutability (digest pinning, immutable tags) — runtime-agnostic (Docker, Podman, Buildah).
---

# Containers — Imagens OCI (Docker e Podman)

## Visão Geral

Diretrizes para empacotar aplicações em imagens de container seguras e enxutas, no formato aberto
OCI — independente de qual runtime a executa depois (Docker, Podman, containerd). Containers são a
unidade de entrega imutável: a mesma imagem roda identicamente em qualquer ambiente.

> Esta skill cobre apenas a camada de **imagem**. Para rodar containers em um único host via
> systemd, ver `domains/podman/SKILL.md`; para orquestração em cluster, ver
> `domains/kubernetes/SKILL.md`.

---

## Princípios Fundamentais

- **Imutabilidade:** ambientes são reconstruídos a partir da imagem, nunca alterados in-place —
  elimina drift e backdoors persistentes
- **Imagem mínima:** menos camadas e pacotes = menor superfície de ataque e download mais rápido
- **Reprodutibilidade:** build determinístico a partir do Dockerfile + lockfiles versionados
- **Um processo por container:** cada container tem uma única responsabilidade
- **Configuração externa:** config via variáveis de ambiente/volumes, nunca embutida na imagem

---

## Boas Práticas de Dockerfile/Containerfile

`Containerfile` é o nome runtime-agnóstico do mesmo formato do `Dockerfile` — Podman, Buildah e
Docker leem ambos indistintamente; ferramentas de build (`docker build`, `podman build`,
`buildah bud`, BuildKit) aceitam o mesmo conteúdo.

- **Multi-stage build:** separar a etapa de build (com toolchain) da imagem final (só runtime)
- **Base mínima:** preferir imagens `slim`, `alpine`, `distroless` ou UBI-minimal (Red Hat)
- **Usuário não-root:** criar e usar um usuário sem privilégios (`USER app`)
- **Pin por digest:** fixar a imagem base por `@sha256:...`, não só por tag — uma tag pode ser
  sobrescrita no registry; o digest é imutável
- **Ordem de camadas:** copiar manifests e instalar dependências antes do código-fonte para
  aproveitar cache
- **`.containerignore`/`.dockerignore`:** excluir `.git`, `node_modules` locais, secrets e
  artefatos desnecessários (Podman lê `.containerignore`; na ausência, cai para `.dockerignore`)
- **Sem secrets na imagem:** nunca `COPY` de chaves; usar build secrets ou injeção em runtime
- **Labels OCI:** anotar com `org.opencontainers.image.*` (`source`, `revision`, `version`) para
  rastreabilidade da imagem até o commit que a gerou
- **HEALTHCHECK:** declarar verificação de saúde quando aplicável — vale para execução direta via
  Docker/Podman; em Kubernetes, `HEALTHCHECK` do Dockerfile é ignorado e as probes do pod
  (`domains/kubernetes/SKILL.md`) assumem esse papel

Dockerfile multi-stage completo (Node.js), com variante de pin por digest, em
**`references/examples.md`**.

---

## Scan e Registry

- Publicar em registry privado com controle de acesso e tags imutáveis
- Promover entre ambientes por digest explícito, nunca reetiquetando a mesma tag

> Ver `domains/devsecops/SKILL.md` para o catálogo de image scanning (Trivy/Grype/Snyk),
> SBOM/assinatura (cosign/Sigstore) e supply chain no pipeline.

---

## Segurança da Imagem

- Manter imagens base atualizadas — rebuildar regularmente para incorporar patches de CVE
- Nunca embutir secrets em camada, inclusive em camadas intermediárias descartadas — um `COPY`
  seguido de `RUN rm` ainda deixa o segredo no histórico de camadas da imagem

> Ver `domains/podman/SKILL.md` e `domains/kubernetes/SKILL.md` para hardening de execução
> (`readOnlyRootFilesystem`, descarte de capabilities, socket do runtime).

---

## Referências

- Ver `domains/podman/SKILL.md` para rodar a imagem em um host via Podman/Quadlet
- Ver `domains/kubernetes/SKILL.md` para orquestração — probes, requests/limits, NetworkPolicy, RBAC
- Ver `domains/ci-cd/SKILL.md` para construir e publicar imagens no pipeline
- Ver `domains/devsecops/SKILL.md` para scan de imagens, SBOM/assinatura e hardening do pipeline
- [Docker — Best practices for building images](https://docs.docker.com/build/building/best-practices/)
- [Open Container Initiative — Image Spec](https://github.com/opencontainers/image-spec)
