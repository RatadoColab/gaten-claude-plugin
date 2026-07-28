---
name: podman
description: This skill should be used when the user asks to "use Podman instead of Docker", "run the container rootless", "run this image with podman", "create the Quadlet unit", "run the container as a systemd service", "configure systemd for the container", "auto-update the container image", "migrate from docker-compose to Podman", "build the image with Buildah", "podman kube play", or mentions Buildah, Skopeo, or rootless containers. Covers Podman as a daemonless/rootless OCI runtime for both local development and production deployment via Quadlet + systemd.
---

# Podman — Runtime de Containers Daemonless e Rootless

## Visão Geral

Podman é um runtime de containers compatível com OCI, daemonless e rootless por padrão. Serve tanto
como substituto direto do Docker no dia a dia de desenvolvimento quanto como base de produção,
integrando-se ao systemd via Quadlet para rodar containers como serviços gerenciados nativamente
pelo Linux — sem depender de um orquestrador completo.

---

## Princípios Fundamentais

- **Daemonless:** cada container é um processo filho direto do usuário (fork/exec via `conmon`),
  sem daemon root sempre ativo — elimina um alvo de escalonamento de privilégio e um ponto único
  de falha
- **Rootless por padrão:** o UID 0 dentro do container é mapeado para um UID sem privilégios no
  host via user namespaces — um escape de container vira um processo comum, não root
- **Compatível com OCI:** mesma imagem, mesmo `Containerfile`/`Dockerfile`, mesmo registry — troca
  de runtime não exige reescrever nada
- **Pods como primitiva nativa:** Podman agrupa containers em pods (como no Kubernetes) mesmo fora
  de um cluster, compartilhando rede e namespace
- **systemd como supervisor:** em produção, o ciclo de vida do container é delegado ao systemd
  (restart policy, dependências, logs via journald) em vez de reimplementar isso na CLI

---

## Desenvolvimento

- CLI é compatível em quase tudo com o Docker — `podman build`, `podman run`, `podman ps`,
  `podman logs` aceitam os mesmos argumentos na maioria dos casos
- `podman machine` provê a VM Linux necessária em macOS/Windows (equivalente ao Docker Desktop)
- `podman compose` (plugin) ou `podman-compose` executam arquivos `compose.yaml` existentes sem
  reescrita — útil para portar projetos, mas não é o alvo de produção
- `podman secret create` gerencia segredos locais sem variável de ambiente em texto puro
- Volumes montados de bind mount podem exigir rótulo SELinux (`:Z` privado, `:U` ajusta ownership) —
  ver §Rootless para o mapeamento de UID/GID entre host e container

Tabela de comandos e flags equivalentes ao Docker em **`references/rootless-e-cli.md`**.

---

## Produção — Quadlet e systemd

Quadlet é o padrão atual para rodar containers como serviços systemd de forma declarativa —
substitui o fluxo antigo baseado em `podman generate systemd`, que está **deprecado** desde a
5.0. Um arquivo declarativo (`.container`, `.pod`, `.volume`, `.network`, `.build`, `.image` ou
`.kube`) é convertido automaticamente em uma unit systemd pelo gerador do Quadlet.

| Tipo de arquivo | Gera |
|------------------|------|
| `.container`     | Um container único como serviço |
| `.pod`           | Um pod compartilhando rede entre containers |
| `.volume`        | Volume nomeado gerenciado pelo systemd |
| `.network`       | Rede dedicada |
| `.build`         | Build de imagem a partir de um Containerfile, como dependência de outra unit |
| `.image`         | Pull declarativo de uma imagem antes do container subir |
| `.kube`          | Deploy a partir de um YAML no estilo Kubernetes (`podman kube play`) |

Requisitos: Podman ≥ 4.4 (Quadlet foi introduzido nessa versão e virou o padrão de produção na
5.0, quando `podman generate systemd` foi deprecado), kernel com cgroup v2 e user namespaces.
Unidades rootless vão em `~/.config/containers/systemd/`; unidades root em
`/etc/containers/systemd/`. Após criar ou alterar um arquivo, rodar `systemctl daemon-reload` (ou
`systemctl --user daemon-reload` no modo rootless) para o Quadlet gerar a unit. Para o serviço
rootless sobreviver ao logout, habilitar linger: `loginctl enable-linger <user>`.

```ini
# app.container
[Container]
Image=registry.example.com/app@sha256:abc123...
PublishPort=8080:8080

[Install]
WantedBy=default.target
```

Não usar `User=` na seção `[Service]` como substituto do posicionamento correto da unit rootless —
a localização do arquivo, não a diretiva, determina o contexto systemd. Credenciais vão via
`Secret=` (`podman secret`), nunca via `EnvironmentFile` em texto puro. Health check do container
integra com o restart do systemd via `HealthCmd=`/`HealthOnFailure=kill`. Versionar as units da
mesma forma que o código da aplicação (Git, revisão, pipeline de deploy). Exemplos completos de
`.container` (com `Secret=`, health check e dependência entre units), `.volume`, `.network`,
`.pod` e `.kube`, além do fluxo de troubleshooting com `quadlet -dryrun`, em
**`references/quadlet-units.md`**.

---

## Rootless — Restrições e Ajustes

- **Portas privilegiadas:** processos rootless não abrem portas `<1024` por padrão; publicar em
  porta `≥1024` e usar proxy reverso, ou ajustar `net.ipv4.ip_unprivileged_port_start` no host
- **Mapeamento de UID/GID:** requer entradas em `/etc/subuid` e `/etc/subgid` para o usuário —
  sem isso, `podman run` falha ou cai em um único UID mapeado
- **Rede:** modo rootless usa `pasta` (padrão atual) ou `slirp4netns`; modo root usa `netavark` +
  `aardvark-dns` para DNS entre containers
- **`--userns=keep-id`:** preserva o UID/GID do usuário do host dentro do container — essencial
  quando o container escreve em bind mounts do host

Setup completo de subuid/subgid e tabela de erros comuns em **`references/rootless-e-cli.md`**.

---

## Atualização de Imagens

- Em unit Quadlet, usar a chave `AutoUpdate=registry` (compara digest remoto) ou `=local` (compara
  contra uma imagem local atualizada por outro processo); fora do Quadlet, o rótulo equivalente é
  `io.containers.autoupdate=registry`/`=local`
- Habilitar `podman-auto-update.timer` para checar e atualizar periodicamente; o systemd faz
  rollback automático da unit se o novo container falhar ao iniciar
- **Regra de produção:** para serviços críticos ou stateful, fixar a imagem por tag/digest
  explícito e não usar auto-update — a atualização passa por um pipeline de promoção manual.
  Auto-update vale para serviços onde aplicar patches rapidamente pesa mais que controle estrito
  de versão

---

## Ecossistema

| Ferramenta | Papel |
|------------|-------|
| **Buildah**  | Build de imagens com controle granular por camada (`buildah bud`); não depende de daemon |
| **Skopeo**   | Copia, inspeciona e sincroniza imagens entre registries sem precisar dar pull local (`skopeo copy`, `skopeo inspect`) |
| **crun**     | Implementação da OCI Runtime Spec em C — alternativa mais leve ao `runc`, padrão do Podman |
| **netavark / aardvark-dns** | Stack de rede e DNS entre containers no modo root |

---

## Ponte para Kubernetes

- `podman generate kube` produz um YAML no estilo Kubernetes a partir de containers/pods já
  rodando; `podman kube play` aplica um YAML desse tipo localmente
- Suporta os tipos `Pod`, `Deployment`, `DaemonSet`, `Job`, `PersistentVolumeClaim`, `ConfigMap` e
  `Secret` — mas é um subconjunto simplificado, pensado para dev/teste local ou Quadlet `.kube`
- **Não é substituto de manifests de produção:** o YAML gerado não cobre HPA, PodDisruptionBudget,
  RBAC, NetworkPolicy nem os demais recursos de confiabilidade de um cluster real

> Ver `domains/kubernetes/SKILL.md` para workloads, probes, segurança e empacotamento de manifests
> destinados a um cluster Kubernetes/OpenShift real — **mutuamente exclusiva com esta skill**: um
> host único gerenciado por systemd ou um cluster orquestrado, nunca os dois na mesma tarefa.

---

## Segurança

- Rootless reduz o raio de impacto de um escape, mas **não é segurança por padrão** — ainda vale
  aplicar least privilege dentro do container
- Nunca usar `--privileged`; usar `--cap-drop=all` e adicionar apenas as capabilities necessárias
- Preferir `--read-only` com `--tmpfs` para diretórios que precisam de escrita
- Nunca expor o socket do Podman (equivalente ao `docker.sock`) dentro de outro container

> Ver `domains/devsecops/SKILL.md` para scan de imagens, SBOM/assinatura e hardening de supply
> chain no pipeline.

---

## Referências

- Ver `domains/containers/SKILL.md` para boas práticas de Containerfile/Dockerfile (camada de imagem, independente do runtime)
- Ver `domains/kubernetes/SKILL.md` para orquestração de produção além do escopo de um único host
- Ver `domains/devsecops/SKILL.md` para scan, SBOM e assinatura de imagens
- Ver `domains/ci-cd/SKILL.md` para build e publicação de imagens no pipeline
- [Podman — Documentação oficial](https://docs.podman.io/)
- [Quadlet — man page](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
