# Mobile-First e Responsividade

Detalhamento da estratégia mobile-first, alvos de toque, breakpoints e gestos.
Resumo no `SKILL.md`.

## Estratégia

- Projetar para a menor tela primeiro; adicionar complexidade progressivamente para telas maiores
- O tráfego mobile representa a maioria do tráfego web global — projete sempre mobile-first e trate desktop como progressive enhancement.

## Alvos de Toque

- Elementos interativos: mínimo **44×44px** (Apple HIG) ou **48×48px** (Material Design / WCAG 2.5.5)
- Espaçamento mínimo de 8px entre elementos tocáveis para evitar toques acidentais

## Breakpoints de Referência (2025)

| Nome       | Largura        | Uso típico              |
|------------|----------------|-------------------------|
| Mobile S   | < 360px        | Dispositivos compactos  |
| Mobile     | 360px – 767px  | Smartphones             |
| Tablet     | 768px – 1023px | Tablets em retrato      |
| Desktop S  | 1024px – 1279px| Laptops                 |
| Desktop    | 1280px – 1439px| Monitores               |
| Desktop L / Ultrawide | ≥ 1440px | Monitores 27"+, layouts de múltiplas colunas |

- Preferir breakpoints baseados no conteúdo ("quebrar quando o layout precisar") em vez de fixos por dispositivo

## Gestos

- Usar gestos reconhecíveis (swipe, pinch, scroll) — evitar gestos customizados sem feedback visual de descoberta
- Fornecer alternativa por toque para todo gesto (ex: botão de exclusão além de swipe-to-delete)
