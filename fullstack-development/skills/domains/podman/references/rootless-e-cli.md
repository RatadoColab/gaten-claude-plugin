# Podman Rootless — CLI, Setup e Erros Comuns

## Paridade de comandos com Docker

| Docker | Podman | Observação |
|--------|--------|------------|
| `docker build` | `podman build` | Mesma sintaxe; aceita `Dockerfile` ou `Containerfile` |
| `docker run` | `podman run` | Flags praticamente idênticas |
| `docker ps` | `podman ps` | — |
| `docker exec` | `podman exec` | — |
| `docker logs` | `podman logs` | — |
| `docker-compose up` | `podman compose up` (plugin) ou `podman-compose up` | Útil para portar projetos existentes; produção usa Quadlet |
| `docker system prune` | `podman system prune` | — |
| N/A (sem daemon) | `podman machine start/stop` | Só necessário em macOS/Windows |
| `docker generate` (n/a) | `podman generate kube` / `podman generate systemd` (deprecado) | Ver skill principal — `generate systemd` foi substituído por Quadlet |

Alias direto para transição gradual: `alias docker=podman` funciona para a maioria dos fluxos de
desenvolvimento, mas não deve ser assumido em scripts de CI sem validar as diferenças de flags
avançadas (ex.: BuildKit-specific flags não existem no Podman).

## Setup de subuid/subgid

Necessário para que um usuário comum consiga mapear múltiplos UIDs/GIDs dentro dos containers
rootless que ele roda:

```bash
# Verificar se o usuário já tem faixa alocada
grep "^$(whoami):" /etc/subuid /etc/subgid

# Se vazio, alocar uma faixa (exemplo: 65536 UIDs a partir de 100000)
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"

# Aplicar sem reiniciar a sessão
podman system migrate
```

Sem essa faixa alocada, `podman run` pode falhar com erro de mapeamento de namespace ou cair
silenciosamente para um único UID mapeado (sem suporte real a multi-usuário dentro do container).

## Portas privilegiadas (<1024)

Processos rootless não conseguem abrir portas abaixo de 1024 por padrão. Duas opções:

1. **Publicar em porta ≥1024** e colocar um proxy reverso (nginx, HAProxy, ou o próprio balanceador
   do cluster) fazendo a ponte para a porta privilegiada externa — abordagem recomendada
2. **Reduzir o limite do kernel** (exige root no host, avaliar impacto de segurança):
   ```bash
   sudo sysctl net.ipv4.ip_unprivileged_port_start=80
   ```

## Rótulos SELinux e ownership de volumes

| Flag | Efeito |
|------|--------|
| `:Z` | Aplica rótulo SELinux privado ao volume (só este container acessa) |
| `:z` (minúsculo) | Rótulo compartilhado entre múltiplos containers |
| `:U` | Ajusta recursivamente o ownership do volume para o UID/GID do container antes de montar |
| `--userns=keep-id` | Mapeia o UID do usuário do host para o mesmo UID dentro do container — evita que arquivos criados no bind mount fiquem com ownership estranho |

## `podman machine` (macOS/Windows)

```bash
podman machine init
podman machine start
podman machine ssh   # entrar na VM Linux subjacente, se necessário
```

Cada `podman machine` roda uma VM Linux leve — o comportamento rootless dentro dela é o mesmo do
Linux nativo.

## Erros comuns

| Sintoma | Causa provável | Correção |
|---------|-----------------|----------|
| `permission denied` ao publicar porta 80/443 | Porta privilegiada em modo rootless | Publicar em porta ≥1024 + proxy, ou ajustar `ip_unprivileged_port_start` |
| Arquivos criados no volume aparecem com UID estranho no host | Falta `:U` ou `--userns=keep-id` | Adicionar a flag adequada ao volume/run |
| `potentially insufficient UIDs or GIDs` | `/etc/subuid`/`/etc/subgid` sem faixa alocada | Rodar `usermod --add-subuids/--add-subgids` + `podman system migrate` |
| Container não resolve nome de outro container | Rede rootless (`pasta`/`slirp4netns`) sem DNS entre containers configurado | Usar rede nomeada dedicada (`.network` no Quadlet) em vez da rede padrão |
| `systemctl --user` não sobrevive ao logout | Linger não habilitado | `loginctl enable-linger <user>` |
