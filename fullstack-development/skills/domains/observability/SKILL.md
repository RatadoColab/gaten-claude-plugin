---
name: observability
description: This skill should be used when instrumenting observability or implementing SRE practices. Typical triggers include "add metrics/logging/tracing", "set up Prometheus/Grafana", "define SLIs and SLOs", "configure alerts". Covers the three pillars (metrics, logs, traces), OpenTelemetry, Prometheus/Grafana/Loki/Jaeger, the four golden signals, SLI/SLO/error budgets, and actionable alerting.
---

# Observability — Observabilidade e SRE

## Visão Geral

Diretrizes para instrumentar sistemas de forma que seu estado interno possa ser compreendido a
partir de sinais externos. Observabilidade vai além do monitoramento tradicional: em ambientes com
pods efêmeros e serviços interconectados, permite investigar problemas não previstos. É também a
base para decisões de deploy (canary, rollback) e para a prática de SRE.

---

## Princípios Fundamentais

- **Instrumentar desde o início:** observabilidade é requisito, não complemento pós-incidente
- **Padrão aberto:** preferir **OpenTelemetry** (padrão CNCF) para instrumentar métricas, logs e
  traces, evitando lock-in de fornecedor
- **Correlação:** métricas, logs e traces devem se correlacionar (ex.: via trace ID) para
  acelerar a análise de causa raiz
- **Acionabilidade:** todo alerta deve exigir ação humana — alertas que não exigem ação geram
  fadiga e são ignorados

---

## Os Três Pilares

| Pilar       | O que é                                          | Ferramentas comuns          |
|-------------|--------------------------------------------------|-----------------------------|
| **Métricas**| Séries temporais numéricas agregadas             | Prometheus, Grafana         |
| **Logs**    | Registros de eventos discretos, contextualizados | Loki, Fluent Bit, ELK       |
| **Traces**  | Caminho de uma requisição entre serviços         | Jaeger, Tempo, OpenTelemetry|

- **Métricas:** baratas de armazenar, ótimas para alertas e tendências (latência, throughput)
- **Logs:** ricos em contexto; usar logs estruturados (JSON) com nível e correlação
- **Traces:** essenciais em arquiteturas distribuídas para localizar gargalos e dependências

---

## OpenTelemetry

- Padrão de fato (CNCF) para instrumentar telemetria de forma agnóstica a backend
- Instrumentar uma vez; exportar para qualquer backend (Prometheus, Jaeger, vendors)
- Propagar contexto de trace entre serviços para correlação ponta a ponta
- Ferramentas baseadas em **eBPF** complementam com visão a nível de kernel sem alterar o código

---

## Os Quatro Sinais de Ouro (Golden Signals)

Sinais essenciais para monitorar qualquer serviço (SRE):

| Sinal          | O que mede                                              |
|----------------|--------------------------------------------------------|
| **Latency**    | Tempo de resposta — separar sucesso de erro            |
| **Traffic**    | Demanda sobre o sistema (req/s, transações)            |
| **Errors**     | Taxa de requisições que falham                         |
| **Saturation** | Quão "cheio" está o recurso (CPU, memória, fila)       |

---

## SLI, SLO e Error Budget

- **SLI (Service Level Indicator):** métrica que quantifica a qualidade do serviço (ex.: % de
  requisições com latência < 300ms)
- **SLO (Service Level Objective):** meta para o SLI ao longo de uma janela (ex.: 99,9% no mês)
- **Error Budget:** o complemento do SLO (ex.: 0,1%) — o quanto de falha é tolerável. Quando o
  orçamento se esgota, prioriza-se confiabilidade sobre novas features

**Regras:**
- Definir SLOs a partir da experiência do usuário, não de métricas internas isoladas
- Usar o error budget para equilibrar velocidade de entrega e estabilidade
- Alertar com base na **queima do error budget**, não em limiares estáticos arbitrários

---

## Alerting Acionável

- Alertar sobre **sintomas** (usuário afetado) antes de causas (CPU alta)
- Cada alerta deve ter: severidade, dono, runbook e ação esperada
- Evitar ruído: agrupar alertas correlacionados, suprimir os derivados
- Diferenciar paging (acordar alguém) de tickets (resolver no horário comercial)

### Exemplo — regra de alerta Prometheus

```yaml
groups:
  - name: api-slo
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            / sum(rate(http_requests_total[5m])) > 0.01
        for: 10m
        labels:
          severity: page
        annotations:
          summary: "Taxa de erro acima de 1% por 10min"
          runbook: "https://runbooks.example.com/high-error-rate"
```

---

## Práticas de SRE

- **Postmortems sem culpa** após incidentes, com ações de melhoria rastreadas
- **Health checks** padronizados: `/health` (liveness) e `/health/ready` (readiness)
- Verificação pós-deploy automatizada (smoke tests + métricas) para promover ou reverter releases
- Reduzir **toil**: automatizar tarefas operacionais repetitivas

---

## Referências

- Ver `domains/ci-cd/SKILL.md` para verificação pós-deploy e decisão de canary/rollback
- Ver `domains/containers/SKILL.md` para probes de liveness/readiness em Kubernetes
- Ver `domains/iac/SKILL.md` para monitorar o estado da infraestrutura
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Google SRE — Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/)
- [Prometheus — Alerting Best Practices](https://prometheus.io/docs/practices/alerting/)
