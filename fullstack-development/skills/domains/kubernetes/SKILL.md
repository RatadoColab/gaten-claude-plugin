---
name: kubernetes
description: This skill should be used when the user asks to "create the Kubernetes manifest", "write the Deployment", "create the StatefulSet", "configure the PVC/persistent volume", "create the CronJob", "configure probes and resource limits", "create the HPA", "configure Gateway API/Ingress", "create the Kustomize overlays", "write the Helm chart", "apply a NetworkPolicy", "configure RBAC", or mentions Kubernetes workloads, Pod Security Standards, PodDisruptionBudget, or topology spread constraints. Covers application workloads, reliability, workload security, networking/exposure, storage, and manifest packaging for a Kubernetes cluster.
---

# Kubernetes — Orquestração de Workloads

## Visão Geral

Diretrizes para modelar, proteger e operar workloads de aplicação em um cluster Kubernetes.
Cobre o que roda **dentro** do cluster — Deployments, probes, segurança de pod, rede, empacotamento
de manifests.

> Provisionamento do cluster em si e GitOps de infraestrutura ficam em `domains/iac/SKILL.md`; a
> camada de imagem (Containerfile/Dockerfile) fica em `domains/containers/SKILL.md`;
> particularidades do OpenShift complementam esta skill em `domains/openshift/SKILL.md`.

---

## Princípios Fundamentais

- **Declarativo sobre imperativo:** manifests descrevem o estado desejado e são aplicados via
  `kubectl apply`; nunca editar recursos em produção com `kubectl edit` — a mudança se perde no
  próximo `apply` e não fica versionada
- **Reconciliação contínua:** controllers comparam estado desejado × estado real continuamente e
  corrigem divergências — não assumir que um recurso aplicado uma vez permanece correto para sempre
- **Manifests versionados:** todo YAML vive em Git, revisado como código; nunca aplicar manifest
  ad-hoc que não existe no repositório
- **Namespace como fronteira:** isolar times/ambientes por namespace, com quotas e RBAC por
  namespace — não misturar workloads de ambientes diferentes no mesmo namespace
- **Nunca copiar manifests entre ambientes:** usar overlays/values parametrizados (Kustomize/Helm)
  em vez de duplicar YAML com pequenas edições manuais

---

## Workloads

| Tipo | Uso |
|------|-----|
| **Deployment**  | Aplicações stateless, escaláveis horizontalmente, sem identidade fixa entre réplicas |
| **StatefulSet** | Cargas com identidade estável (hostname, volume por réplica) — bancos, filas |
| **DaemonSet**   | Um pod por nó — agentes de log, monitoramento, CNI |
| **Job**         | Tarefa que roda até completar e termina |
| **CronJob**     | `Job` agendado periodicamente |

---

## As Três Probes

| Probe | Propósito | Erro comum |
|-------|-----------|------------|
| **`startupProbe`**   | Cobre boot lento — bloqueia liveness/readiness até a aplicação inicializar | Omitir e compensar afrouxando o `livenessProbe`, mascarando travamentos reais |
| **`readinessProbe`** | Decide se o pod recebe tráfego agora | Confundir com liveness — pod não pronto não deveria reiniciar, só sair do endpoint |
| **`livenessProbe`**  | Decide se o pod precisa ser reiniciado | Depender de um serviço externo (banco, API terceira) — indisponibilidade externa não deveria derrubar o pod em loop de restart |

Deployment completo com as três probes configuradas em **`references/manifests.md`**.

---

## Recursos e QoS

- Classes de qualidade de serviço: **Guaranteed** (requests = limits em CPU e memória),
  **Burstable** (requests < limits) e **BestEffort** (sem requests/limits — evitar em produção)
- Sempre definir `requests` — é a base do scheduling e do cálculo de QoS
- Definir `limits` de memória (estoura OOM de forma previsível); `limits` de CPU exige cautela —
  throttling agressivo pode degradar latência mesmo com CPU ociosa no nó
- `LimitRange` define requests/limits padrão por namespace; `ResourceQuota` limita o consumo
  agregado do namespace

---

## Confiabilidade

- **`PodDisruptionBudget`:** protege disponibilidade durante disrupções voluntárias (drain de nó,
  upgrade, autoscaling do cluster) — define `minAvailable`/`maxUnavailable`
- **`topologySpreadConstraints`:** distribui réplicas entre nós/zonas para evitar que uma falha de
  nó ou zona derrube todas as réplicas ao mesmo tempo
- **HPA:** escala por métricas de recurso ou customizadas; usar `behavior` com janelas de
  estabilização para evitar oscilação (scale up rápido, scale down cauteloso)
- **Conflito HPA × VPA:** rodar os dois na mesma métrica de recurso cria um loop de controle — VPA
  ajusta o request, o que muda a métrica que o HPA usa para decidir réplicas. Quando ambos atuam
  sobre o mesmo workload, manter o VPA em modo `Off` ou `Initial`
- **Encerramento gracioso:** `terminationGracePeriodSeconds` + hook `preStop` dão tempo para a
  aplicação drenar conexões antes do `SIGKILL`
- **`strategy` do Deployment:** `RollingUpdate` com `maxSurge`/`maxUnavailable` controla velocidade
  e folga do rollout; `Recreate` para cargas que não toleram duas versões simultâneas (ex.: migração
  de schema incompatível)
- **Agendamento:** `nodeSelector`/`affinity`/`podAntiAffinity` direcionam ou afastam pods entre nós;
  `tolerations` permitem rodar em nós com taint (ex.: nós dedicados a uma carga). `initContainers`
  rodam antes dos containers principais — incluindo o sidecar nativo (`restartPolicy: Always`,
  GA desde a 1.29), que fica ativo durante todo o ciclo de vida do pod

HPA com `behavior`, PDB e `topologySpreadConstraints` completos em **`references/manifests.md`**.

---

## Segurança do Workload

- **Pod Security Standards, nível `restricted`:** alvo de produção — aplicar via label no
  namespace: `pod-security.kubernetes.io/enforce=restricted`
- **`securityContext` do pod/container:** `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
  `capabilities.drop: ["ALL"]`, `seccompProfile.type: RuntimeDefault`, `readOnlyRootFilesystem: true`
  quando a aplicação permitir
- **RBAC de menor privilégio:** `Role`/`RoleBinding` com escopo mínimo por namespace; evitar
  `ClusterRole` amplo salvo necessidade real; usar uma `ServiceAccount` dedicada por workload em
  vez da `default`
- **`automountServiceAccountToken: false`** quando o pod não precisa falar com a API do cluster
- **NetworkPolicy default-deny:** bloquear todo tráfego por padrão no namespace e liberar
  explicitamente apenas o necessário

> Ver `domains/devsecops/SKILL.md` para scan de manifests/IaC e políticas admissionais no pipeline.

Manifests completos (`securityContext` restricted, RBAC mínimo, NetworkPolicy default-deny +
allow) em **`references/manifests.md`**.

---

## Configuração e Secrets

- `Secret` do Kubernetes é **codificado em base64, não criptografado** — não tratar como
  cofre de segredos por si só; combinar com encryption at rest do cluster ou soluções como
  External Secrets Operator / Sealed Secrets
- Mudança em `ConfigMap`/`Secret` não reinicia pods automaticamente — forçar rollout com hash do
  conteúdo em uma annotation do pod template, ou usar `configMapGenerator` do Kustomize, que já
  gera esse hash

> Ver `domains/iac/SKILL.md` para gestão de secrets como infraestrutura (cofre, rotação, GitOps).

---

## Armazenamento

- `PersistentVolumeClaim` declara a necessidade de volume; a `StorageClass` referenciada decide o
  provisionador e a `reclaimPolicy` (`Delete` apaga o volume junto do PVC — usar `Retain` para
  dados críticos)
- `accessModes`: `ReadWriteOnce` (um nó por vez) é o suportado pela maioria dos block storages;
  `ReadWriteMany` exige storage de arquivo (NFS/CephFS)
- StatefulSet usa `volumeClaimTemplates` — um PVC por réplica, preservado entre restarts e
  **não removido** quando o StatefulSet é deletado

PVC avulso e `volumeClaimTemplates` completos em **`references/manifests.md`**.

---

## Rede e Exposição

- **Service:** `ClusterIP` (interno), `NodePort` (exposição direta por nó, uso limitado),
  `LoadBalancer` (integração com cloud), `headless` (`clusterIP: None`, descoberta direta de pods —
  usado por StatefulSets)
- **Gateway API — padrão atual para tráfego norte-sul:** modelo baseado em `GatewayClass`
  (infraestrutura), `Gateway` (ponto de entrada, TLS) e `HTTPRoute` (regras de roteamento por
  aplicação), com separação clara entre papel de plataforma e papel de aplicação; TLS tipicamente
  provisionado via cert-manager
- **Ingress — legado:** a API do core continua válida, mas o controller `ingress-nginx` está sem
  manutenção ativa; projetos novos devem nascer em Gateway API. Data de fim de vida, ferramenta de
  migração e mapeamento Ingress→Gateway em **`references/gateway-api.md`**

Exemplos completos de `GatewayClass`/`Gateway`/`HTTPRoute`, TLS e roteamento canário por peso em
**`references/gateway-api.md`**.

---

## Empacotamento

| Ferramenta | Quando usar |
|------------|-------------|
| **Kustomize** | Microserviços internos com variação simples entre ambientes (réplicas, limites, namespace); sem componente client-side adicional além do `kubectl` |
| **Helm**      | Distribuição de software (charts de terceiros como Prometheus/cert-manager) ou aplicações que precisam de templating complexo, versionamento de release e reuso entre múltiplos consumidores |

Layout recomendado para Kustomize: `base/` com os manifests genéricos + `overlays/{dev,stg,prod}/`
com patches específicos de cada ambiente. Nada impede combinar as duas ferramentas — Helm para o
chart base de uma dependência de terceiros, Kustomize por cima para ajustes específicos do
ambiente, sem fazer fork do chart original.

Estrutura completa de `base/`+`overlays/`, `kustomization.yaml` com patches/`configMapGenerator`, e
esqueleto de chart Helm em **`references/packaging.md`**.

---

## Operação com kubectl

- `kubectl apply --server-side` reduz conflitos de campo em ambientes com múltiplos autores
  (controllers + humanos) do mesmo recurso
- `kubectl diff -f manifest.yaml` antes de aplicar, para revisar o que vai mudar
- `kubectl rollout status deployment/app` acompanha um rollout; `kubectl rollout undo` reverte
- `kubectl apply --dry-run=server` valida contra a API do cluster sem persistir a mudança

---

## Validação de Manifests

- **kubeconform:** valida manifests contra o schema oficial do Kubernetes — roda no pipeline antes
  do deploy
- **kube-linter / Polaris:** checam boas práticas (probes ausentes, sem limits, containers
  privilegiados) e devem bloquear o pipeline em achados críticos
- **Kyverno / OPA-Gatekeeper:** aplicam política admissional dentro do próprio cluster — a última
  linha de defesa contra manifests fora de conformidade, mesmo os aplicados fora do pipeline

> Ver `domains/devsecops/SKILL.md` para o catálogo completo de scanners de IaC/manifests no pipeline.

---

## Referências

> Ver `domains/podman/SKILL.md` para runtime de container em um único host, fora de um cluster —
> **mutuamente exclusiva com esta skill**: um host único gerenciado por systemd ou um cluster
> orquestrado, nunca os dois na mesma tarefa.

- Ver `domains/containers/SKILL.md` para boas práticas de imagem (Containerfile/Dockerfile)
- Ver `domains/openshift/SKILL.md` para as particularidades da plataforma (SCC, Route, S2I)
- Ver `domains/iac/SKILL.md` para provisionamento de cluster, GitOps e gestão de secrets
- Ver `domains/observability/SKILL.md` para monitorar workloads em produção
- Ver `domains/devsecops/SKILL.md` para scan de imagens/manifests e políticas admissionais
- Ver `domains/ci-cd/SKILL.md` para a escolha de estratégia de deploy (blue-green, canary, feature flags)
- [Kubernetes — Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Kubernetes — Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Gateway API — Documentação oficial](https://gateway-api.sigs.k8s.io/)
