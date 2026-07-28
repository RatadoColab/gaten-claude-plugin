# Empacotamento — Kustomize e Helm

## Layout recomendado do Kustomize

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patch-replicas.yaml
    ├── stg/
    │   └── kustomization.yaml
    └── prod/
        ├── kustomization.yaml
        └── patch-resources.yaml
```

## `base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - hpa.yaml
```

## `overlays/prod/kustomization.yaml` — patches, generators e imagens

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: app-prod
resources:
  - ../../base
patches:
  - path: patch-resources.yaml
    target:
      kind: Deployment
      name: app
configMapGenerator:
  - name: app-config
    literals:
      - LOG_LEVEL=info
images:
  - name: registry.example.com/app
    newTag: v1.4.2
replicas:
  - name: app
    count: 5
```

`configMapGenerator` gera automaticamente um hash no nome do `ConfigMap` a cada mudança de
conteúdo, e referências ao recurso são atualizadas — isso força o rollout do `Deployment` sem
precisar de annotation manual.

## `overlays/prod/patch-resources.yaml` — patch estratégico

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
        - name: app
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              memory: 512Mi
```

## Comandos

```bash
kubectl kustomize overlays/prod              # renderiza sem aplicar
kubectl apply -k overlays/prod               # renderiza e aplica
kubectl diff -k overlays/prod                # revisa mudanças antes de aplicar
```

## Esqueleto de chart Helm

```
app-chart/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml
    └── _helpers.tpl
```

`Chart.yaml`:

```yaml
apiVersion: v2
name: app-chart
version: 1.4.2
appVersion: "1.4.2"
```

`values.yaml` traz os defaults; `values-prod.yaml` sobrepõe apenas o que muda em produção:

```bash
helm upgrade --install app ./app-chart -f values.yaml -f values-prod.yaml -n app-prod
helm diff upgrade app ./app-chart -f values.yaml -f values-prod.yaml -n app-prod   # plugin helm-diff
```

## Combinando Helm + Kustomize sem fork do chart

Quando um chart de terceiro (ex.: Prometheus) precisa de um recurso complementar específico do
ambiente (uma `NetworkPolicy`, por exemplo) sem fork do chart original:

```
monitoring/
├── kustomization.yaml     # helmCharts + resources complementares
└── extra-networkpolicy.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
helmCharts:
  - name: kube-prometheus-stack
    repo: https://prometheus-community.github.io/helm-charts
    version: 60.0.0
    releaseName: monitoring
    valuesFile: values-prod.yaml
resources:
  - extra-networkpolicy.yaml
```

## Validação antes de aplicar

```bash
kubeconform -strict -summary <(kubectl kustomize overlays/prod)
kube-linter lint overlays/prod
```

Rodar essas checagens no pipeline de CI antes do deploy — ver `domains/devsecops/SKILL.md` para o
catálogo completo de scanners de IaC/manifests.
