---
name: devsecops
description: This skill should be used when integrating security into CI/CD pipelines and infrastructure (shift-left security). Covers pipeline scans (SAST, SCA, DAST, secret scanning, IaC scanning, image scanning), security gates that fail the build, supply chain security (dependency/action pinning, SBOM, cosign/Sigstore signing, SLSA), secrets management in pipelines (vault injection, OIDC and short-lived credentials), and runner isolation. For application/API web security (OWASP Top 10, XSS, CSRF, JWT), use the security skill instead.
version: 0.1.0
---

# DevSecOps — Segurança no Pipeline e na Infraestrutura

## Visão Geral

Diretrizes para embutir segurança ao longo do pipeline de CI/CD e do provisionamento de
infraestrutura (*shift-left*): a segurança roda como etapa automatizada em cada commit, não como
auditoria final. Esta skill cobre a segurança do **caminho de entrega** (scans, supply chain,
secrets, credenciais do pipeline).

> Para segurança de **aplicação web/API** (OWASP Top 10, XSS, CSRF, JWT, validação de entrada,
> upload), carregar `../security/SKILL.md` — escopo distinto e complementar.

---

## Princípios Fundamentais

- **Shift-left:** detectar a vulnerabilidade o mais cedo possível — quanto mais tarde, mais caro
- **Fail the build:** achados de severidade alta/crítica bloqueiam a progressão do pipeline
- **Menor privilégio e zero-trust:** credenciais do pipeline com escopo mínimo e curta duração
- **Tudo como código auditável:** políticas de segurança versionadas e aplicadas automaticamente
- **Segurança é responsabilidade de todos:** integrada ao fluxo, não terceirizada a uma etapa final

---

## Scans no Pipeline

Cada classe de scan cobre uma superfície diferente; combinar todas para defesa em profundidade:

| Scan                | O que detecta                                         | Estágio típico        |
|---------------------|-------------------------------------------------------|-----------------------|
| **SAST**            | Vulnerabilidades no código-fonte (análise estática)   | Após build/lint       |
| **SCA**             | CVEs em dependências de terceiros                     | Após instalar deps    |
| **Secret scanning** | Secrets vazados no diff/histórico                     | Em todo push/PR       |
| **IaC scanning**    | Misconfigurações em Terraform/manifests/Dockerfile    | Antes do apply        |
| **Image scanning**  | CVEs e pacotes vulneráveis na imagem de container     | Após build da imagem  |
| **DAST**            | Vulnerabilidades em runtime (app implantado)          | Após deploy em staging |

> Ver `../ci-cd/SKILL.md` para a ordem dos estágios e os gates de qualidade que esses scans alimentam.

---

## Ferramentas por Domínio

| Domínio             | Ferramentas comuns                                    |
|---------------------|-------------------------------------------------------|
| **Imagem/container**| Trivy, Grype, Snyk                                    |
| **IaC**             | Checkov, tfsec, Terrascan, OPA/Conftest (policy as code) |
| **Dependências (SCA)** | `npm audit`, `pip-audit`, OWASP Dependency-Check, Snyk |
| **Secrets**         | Gitleaks, TruffleHog, detect-secrets                  |
| **SAST**            | Semgrep, CodeQL, SonarQube                             |

Bloquear a publicação/promoção quando houver achados de severidade alta/crítica — ver exemplo abaixo.

---

## Supply Chain

- **Pinning por hash:** fixar actions/imagens por digest (não por tag móvel) para evitar
  comprometimento da cadeia de suprimentos
- **SBOM:** gerar o Software Bill of Materials de cada artefato/imagem para rastreabilidade
- **Assinatura:** assinar imagens e artefatos com cosign/Sigstore e **verificar a assinatura no
  deploy** — só roda o que foi assinado pelo pipeline confiável
- **SLSA:** mirar níveis crescentes do framework SLSA para garantir a integridade da build

---

## Secrets e Credenciais do Pipeline

- **Nunca** secrets em texto puro no repositório ou no YAML — injetar em runtime via cofre (Vault,
  sealed secrets, secret managers da nuvem, Azure Key Vault)
- **OIDC e short-lived credentials:** preferir federação/OIDC a chaves longevas de longa duração
- **Isolamento de runners:** não executar código não confiável de PRs com credenciais de produção
- **Escopo mínimo:** a credencial do pipeline só pode fazer o que o deploy daquele ambiente exige

---

## Exemplo — Gate de scan bloqueando severidade alta/crítica

```yaml
security_scan:
  stage: test
  script:
    - npm audit --audit-level=high            # SCA: falha se houver CVE alta/crítica
    - trivy image --exit-code 1 \
        --severity HIGH,CRITICAL "$IMAGE:$SHA" # image scan: bloqueia o build
    - checkov -d infra/ --hard-fail-on HIGH    # IaC scanning
    - gitleaks detect --no-banner              # secret scanning no diff
```

---

## Referências

- Ver `../ci-cd/SKILL.md` para estágios do pipeline e gates de qualidade
- Ver `../containers/SKILL.md` para scan/assinatura de imagens e registry
- Ver `../iac/SKILL.md` para IaC scanning (Checkov/tfsec) e gestão de secrets na infra
- Ver `../openshift/SKILL.md` para SCC e hardening específicos da plataforma
- Ver `../security/SKILL.md` para segurança de aplicação web/API (OWASP Top 10)
- [OWASP CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- [SLSA — Supply-chain Levels for Software Artifacts](https://slsa.dev/)
