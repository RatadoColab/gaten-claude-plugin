# CI/CD — Exemplos de Pipeline

## GitHub Actions

```yaml
name: ci
on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  build-test:
    runs-on: ubuntu-latest
    permissions:
      contents: read            # menor privilégio
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci              # instalação reproduzível
      - run: npm run lint        # gate de estilo
      - run: npm test -- --coverage
      - run: npm audit --audit-level=high   # SCA
```

---

## GitLab CI

```yaml
stages: [build, test, deploy]

build:
  stage: build
  script:
    - docker build -t "$IMAGE:$CI_COMMIT_SHORT_SHA" .   # tag imutável por commit

test:
  stage: test
  script:
    - npm ci
    - npm test

deploy_prod:
  stage: deploy
  when: manual                  # gate de aprovação para produção
  environment: production
  script:
    - ./scripts/deploy.sh "$IMAGE:$CI_COMMIT_SHORT_SHA"
```
