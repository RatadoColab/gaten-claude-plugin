# Manifests Completos — Workload, Confiabilidade e Segurança

## Namespace com Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## Deployment — probes, securityContext restricted, resources

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: app-prod
  labels:
    app.kubernetes.io/name: app
    app.kubernetes.io/instance: app-prod
    app.kubernetes.io/version: "1.4.0"
    app.kubernetes.io/part-of: platform
    app.kubernetes.io/managed-by: kubectl
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      serviceAccountName: app
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: app
      containers:
        - name: app
          image: registry.example.com/app@sha256:abc123def456...
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              memory: 256Mi
          securityContext:
            runAsNonRoot: true
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
          startupProbe:
            httpGet:
              path: /health/startup
              port: 8080
            failureThreshold: 30
            periodSeconds: 2
          readinessProbe:
            httpGet:
              path: /health/ready
              port: 8080
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            periodSeconds: 10
            failureThreshold: 3
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 5"]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      volumes:
        - name: tmp
          emptyDir: {}
```

## Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app
  namespace: app-prod
spec:
  selector:
    app: app
  ports:
    - port: 8080
      targetPort: 8080
```

## HorizontalPodAutoscaler com `behavior`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app
  namespace: app-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
    scaleDown:
      stabilizationWindowSeconds: 300
```

## PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app
  namespace: app-prod
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: app
```

## NetworkPolicy — default-deny + allow explícito

Um default-deny de Egress sem uma policy liberando DNS quebra a resolução de nomes de todos os
pods do namespace — o `allow-dns-egress` abaixo é obrigatório sempre que `Egress` entrar em
`policyTypes`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: app-prod
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: app-prod
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-ingress
  namespace: app-prod
spec:
  podSelector:
    matchLabels:
      app: app
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: app-gateway
      ports:
        - port: 8080
```

## ServiceAccount + RBAC de menor privilégio

```yaml
# Aplicável apenas quando o pod realmente fala com a API do cluster — nesse caso, remover
# automountServiceAccountToken: false do Deployment para o token ficar disponível
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app
  namespace: app-prod
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-configmap-reader
  namespace: app-prod
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-configmap-reader
  namespace: app-prod
subjects:
  - kind: ServiceAccount
    name: app
    namespace: app-prod
roleRef:
  kind: Role
  name: app-configmap-reader
  apiGroup: rbac.authorization.k8s.io
```

## PersistentVolumeClaim e `volumeClaimTemplates`

`PersistentVolumeClaim` avulso — para uma carga com um único volume compartilhado:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: app-prod
spec:
  storageClassName: fast-ssd
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 10Gi
```

`volumeClaimTemplates` de um StatefulSet — um PVC por réplica, criado a partir do template e
preservado entre restarts (não é removido junto com o StatefulSet):

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
  namespace: app-prod
spec:
  serviceName: db
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
        - name: db
          image: registry.example.com/db@sha256:def789abc012...
          volumeMounts:
            - name: data
              mountPath: /var/lib/db
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        storageClassName: fast-ssd
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 20Gi
```

## Diagnóstico

| Sintoma | Causa provável | Comando |
|---|---|---|
| `CrashLoopBackOff` | Processo principal encerra logo após iniciar (erro de config, falha de conexão na inicialização) | `kubectl logs <pod> --previous` |
| `ImagePullBackOff` / `ErrImagePull` | Tag/digest inexistente, registry sem credencial ou sem rede até o registry | `kubectl describe pod <pod>` (seção Events) |
| `OOMKilled` | Container excedeu `resources.limits.memory` | `kubectl describe pod <pod>` (`Last State: Terminated, Reason: OOMKilled`) |
| `Pending` | Sem nó com recurso/label/toleration suficiente para o scheduler alocar o pod | `kubectl describe pod <pod>` (seção Events) ou `kubectl get events -n app-prod --sort-by=.lastTimestamp` |
| Pod roda mas não recebe tráfego | `readinessProbe` falhando, ou `Service`/`selector` não bate com os labels do pod | `kubectl get endpoints <service>` |
| Shell interativo para investigar sem alterar a imagem | — | `kubectl debug -it <pod> --image=busybox --target=<container>` |
