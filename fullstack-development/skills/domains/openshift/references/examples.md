# OpenShift — Exemplos

## Route com TLS

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: api
spec:
  # host omitido = o cluster gera um hostname automático; defina host: para domínio fixo
  to:
    kind: Service
    name: api
  port:
    targetPort: 8080
  tls:
    termination: edge                 # edge | passthrough | reencrypt
    insecureEdgeTerminationPolicy: Redirect
```
