---
name: iac
description: This skill should be used when provisioning infrastructure as code or implementing GitOps. Typical triggers include "write the Terraform config", "provision the infrastructure", "set up ArgoCD/Flux", "manage Terraform state". Covers IaC tools (Terraform, Pulumi, CloudFormation), GitOps with ArgoCD/Flux, Git as source of truth, state management, drift detection, secrets management (Vault, sealed secrets), and zero-trust principles.
---

# IaC — Infraestrutura como Código e GitOps

## Visão Geral

Diretrizes para definir, provisionar e operar infraestrutura de forma declarativa e versionada.
Infraestrutura como Código (IaC) trata servidores, redes e serviços como artefatos de software:
definidos em arquivos, revisados em PRs e aplicados de forma reproduzível. GitOps estende esse
modelo usando o Git como fonte única da verdade para o estado desejado.

---

## Princípios Fundamentais

- **Declarativo sobre imperativo:** descrever o estado desejado, não os passos — a ferramenta
  converge a infraestrutura para esse estado
- **Git como fonte da verdade:** todo estado desejado vive em repositório versionado e revisado
- **Idempotência:** aplicar a mesma definição várias vezes resulta no mesmo estado
- **Imutabilidade:** recriar recursos a partir da definição em vez de alterá-los in-place
- **Modularidade:** componentizar infraestrutura em módulos reutilizáveis e parametrizados

---

## Ferramentas de IaC

| Ferramenta         | Escopo                                          | Observação                          |
|--------------------|-------------------------------------------------|-------------------------------------|
| **Terraform**      | Multi-cloud, declarativo (HCL)                  | Padrão de mercado, grande ecossistema |
| **Pulumi**         | Multi-cloud, linguagens de programação reais    | Útil quando se quer lógica/tipagem  |
| **CloudFormation** | AWS nativo                                       | Integração profunda com AWS         |
| **Ansible**        | Configuração e provisionamento procedural       | Bom para config management          |

---

## GitOps

GitOps é a prática de manter o estado desejado da infraestrutura/aplicações no Git e usar um agente
que sincroniza continuamente o ambiente real com esse estado.

- Definir infraestrutura/manifests em IaC e armazenar no Git
- Usar **ArgoCD** ou **Flux** para sincronizar automaticamente o cluster com o repositório
- Mudanças em produção acontecem via PR no Git — nunca por alteração manual no ambiente
- O agente detecta **drift** (diferença entre desejado e real) e reconcilia ou alerta

**Benefícios:** auditoria completa via histórico Git, rollback por `git revert`, e ambiente sempre
reproduzível a partir do repositório.

---

## Gestão de Estado (Terraform)

- Armazenar o state em backend remoto compartilhado (S3 + DynamoDB lock, Terraform Cloud)
- **Nunca** versionar o arquivo de state no Git — pode conter secrets
- Habilitar **locking** para evitar aplicações concorrentes conflitantes
- Isolar state por ambiente (workspaces ou diretórios separados)
- Revisar o `plan` antes de todo `apply` — idealmente como gate no pipeline

Exemplo de backend remoto (S3 + DynamoDB lock) e recurso parametrizado em **`references/terraform-examples.md`**.

---

## Detecção de Drift

- Rodar `terraform plan` / reconciliação do ArgoCD periodicamente para detectar divergências
- Alertar a equipe sobre mudanças não autorizadas (feitas fora do Git)
- Tratar drift como incidente: corrigir reaplicando o estado desejado, não acomodando a mudança

---

## Gestão de Secrets

- **Nunca** commitar secrets em texto puro no repositório
- Usar cofre dedicado: **HashiCorp Vault**, AWS Secrets Manager, GCP Secret Manager
- Em GitOps, usar **Sealed Secrets** ou **SOPS** para criptografar secrets antes do commit
- Injetar secrets em runtime; rotacioná-los regularmente
- Aplicar menor privilégio: cada serviço acessa apenas os secrets que precisa

---

## Zero-Trust e Segurança de IaC

- Escanear definições de IaC por misconfiguração antes de aplicar (Checkov, tfsec, Terrascan)
- Aplicar políticas como código (OPA/Conftest) para enforçar padrões de segurança no pipeline
- Princípio de menor privilégio em todas as roles e políticas provisionadas
- Não confiar implicitamente em rede; autenticar e autorizar cada acesso

> Ver `domains/devsecops/SKILL.md` para o catálogo de IaC scanning (Checkov/tfsec/Terrascan/OPA) e gestão de secrets/credenciais no pipeline.

---

## Referências

- Ver `domains/containers/SKILL.md` para as imagens consumidas pelos manifests
- Ver `domains/kubernetes/SKILL.md` para os manifests aplicados via GitOps (Kustomize/Helm)
- Ver `domains/ci-cd/SKILL.md` para gates de `plan`/scan no pipeline
- Ver `domains/observability/SKILL.md` para monitorar o estado da infraestrutura
- Ver `domains/devsecops/SKILL.md` para IaC scanning, gestão de credenciais e secrets no pipeline
- [Terraform — Best Practices](https://developer.hashicorp.com/terraform/language)
- [OpenGitOps — Principles](https://opengitops.dev/)
