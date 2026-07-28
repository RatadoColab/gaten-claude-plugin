# Quadlet — Exemplos de Unidades

## `.container` — container único completo

```ini
# ~/.config/containers/systemd/app.container
[Unit]
Description=API da aplicação
After=network-online.target db.service
Wants=network-online.target
# Dependência de outra unit — o Quadlet gera db.service a partir de db.container
Requires=db.service

[Container]
Image=registry.example.com/app@sha256:abc123def456...
ContainerName=app
PublishPort=8080:8080
Environment=NODE_ENV=production
EnvironmentFile=/etc/app/app.env
# Credencial injetada pelo podman secret — não usar EnvironmentFile para segredos
Secret=app-db-pass,type=env,target=DB_PASSWORD
Volume=app-data.volume:/data
Network=app.network
UserNS=keep-id
AutoUpdate=registry
# Integra o health check ao restart do systemd
HealthCmd=curl -fsS http://localhost:8080/health
HealthInterval=30s
HealthOnFailure=kill
# Endurecimento — equivalente ao securityContext do Kubernetes
NoNewPrivileges=true
ReadOnly=true
Tmpfs=/tmp
DropCapability=all

[Service]
Restart=always
TimeoutStartSec=30

[Install]
WantedBy=default.target
```

Após criar/editar: `systemctl --user daemon-reload && systemctl --user start app.service`.
Verificar logs com `journalctl --user -u app.service -f`. Em unidades root (fora de
`~/.config/containers/systemd/`), trocar `WantedBy=default.target` por `WantedBy=multi-user.target`.

## `.volume` — volume nomeado

```ini
# ~/.config/containers/systemd/app-data.volume
[Volume]
# Sem opções adicionais, o Quadlet cria um volume padrão gerenciado pelo Podman
```

## `.network` — rede dedicada

```ini
# ~/.config/containers/systemd/app.network
[Network]
Subnet=10.89.1.0/24
```

## `.pod` — pod compartilhando rede entre containers

```ini
# ~/.config/containers/systemd/app.pod
[Pod]
PodName=app-pod
PublishPort=8080:8080
```

Containers que devem entrar nesse pod referenciam `Pod=app.pod` na respectiva seção `[Container]`.

## `.kube` — deploy a partir de YAML Kubernetes-like

```ini
# ~/.config/containers/systemd/app.kube
[Kube]
Yaml=app-pod.yaml

[Service]
Restart=always

[Install]
WantedBy=default.target
```

`app-pod.yaml` é o mesmo formato aceito por `podman kube play` — útil para reaproveitar um
manifest simplificado sem reescrever como `.container`.

## Timer de auto-update

O timer já vem empacotado com o Podman; apenas habilitar:

```bash
systemctl --user enable --now podman-auto-update.timer
# Testar sem esperar o timer:
podman auto-update --dry-run
```

## Comandos systemd úteis (contexto rootless)

```bash
systemctl --user daemon-reload           # gera as units a partir dos arquivos Quadlet
systemctl --user status app.service
systemctl --user restart app.service
loginctl enable-linger $(whoami)         # mantém o serviço rodando após logout
```

## Troubleshooting

- `/usr/libexec/podman/quadlet -dryrun` — valida a sintaxe dos arquivos `.container`/`.pod`/etc.
  sem aplicar, mostrando a unit systemd que seria gerada
- Se a unit não aparece após `daemon-reload`: confirmar que o arquivo está no diretório correto
  (`~/.config/containers/systemd/` para rootless, `/etc/containers/systemd/` para root) e que a
  extensão bate com o tipo (`.container`, não `.service`)
- Erros de permissão em porta: ver seção de portas privilegiadas em `rootless-e-cli.md`
- Erros de rede entre containers de units diferentes: confirmar que ambos referenciam o mesmo
  `.network`
