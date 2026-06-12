# Azure Pipelines — Exemplo completo (build → scan → deploy no OpenShift)

```yaml
trigger:
  branches: { include: [main, develop] }
pr:
  branches: { include: [main] }

variables:
  - group: prod-secrets                  # secrets via Key Vault
  - name: imageTag
    value: $(Build.SourceVersion)

stages:
  - stage: Build
    jobs:
      - job: build_test
        pool: { vmImage: 'ubuntu-latest' }
        steps:
          - script: npm ci
          - script: npm run lint
          - script: npm test -- --coverage
          - script: npm audit --audit-level=high      # SCA
          - task: Docker@2                              # build + push imutável
            inputs:
              command: buildAndPush
              repository: api
              tags: $(imageTag)
              containerRegistry: acr-connection         # service connection

  - stage: DeployProd
    dependsOn: Build
    jobs:
      - deployment: deploy
        environment: production                         # exige approval configurado
        strategy:
          runOnce:
            deploy:
              steps:
                - task: oc-setup@2                       # requer a extensão "Red Hat OpenShift" na org
                  inputs: { openshiftService: 'ocp-connection' }
                - script: |
                    oc set image deployment/api \
                      api=image-registry.../api:$(imageTag)   # tag imutável
                    oc rollout status deployment/api
```
