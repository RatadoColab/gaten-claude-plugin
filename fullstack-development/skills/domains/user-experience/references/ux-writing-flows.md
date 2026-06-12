# UX Writing, Onboarding, Fluxos e Testes de Usabilidade

Detalhamento de microcopy, onboarding progressivo, fluxos de usuário e testes.
Resumo no `SKILL.md`.

## UX Writing e Microcopy

Microcopy são os pequenos textos da interface (labels, placeholders, mensagens de erro, tooltips, CTAs) que guiam o usuário sem que ele perceba.

### Princípios

- **Claro antes de criativo:** comunicar o essencial com a menor quantidade de palavras
- **Usar a voz do usuário:** escrever como o usuário pensa ("Esqueci minha senha" em vez de "Recuperação de credenciais")
- **Verbos de ação em CTAs:** "Baixar relatório", "Adicionar membro" em vez de "Download" ou "Adicionar"
- **Consistência terminológica:** usar o mesmo termo em toda a interface; documentar em glossário de produto

### Mensagens de Erro em Microcopy

```
// Técnico e frio
"Autenticação falhou."

// Humano e orientado à ação
"Senha incorreta. Tente novamente ou redefina sua senha."
```

### Onboarding e Tooltips

- Tooltips: máximo 1–2 frases; aparecer no hover/foco; não conter informação crítica que o usuário não verá no mobile
- Onboarding progressivo: apresentar funcionalidades conforme o usuário avança, não tudo de uma vez no primeiro acesso

## Onboarding Progressivo

- **Empty states como onboarding:** quando o estado vazio é o primeiro contato do usuário, transformá-lo em guia de primeiros passos com CTA claro
- **Product tours:** usar apenas para funcionalidades não-óbvias; máximo de 3-5 etapas; permitir pular a qualquer momento
- **Checklist de primeiros passos:** eficaz para produtos com setup inicial (ex: "Complete seu perfil", "Conecte sua conta") — exibir progresso e celebrar conclusão
- **Aha moment:** identificar o momento em que o usuário percebe o valor do produto e projetar o fluxo de onboarding para chegar lá o mais rápido possível
- **Tooltips contextuais:** disparar na primeira vez que o usuário encontra uma funcionalidade avançada, não na abertura da aplicação

## Fluxos de Usuário

- Definir o **caminho feliz (happy path)** primeiro e garantir que funcione sem fricção
- Mapear pontos de saída do fluxo e garantir que o usuário possa retornar (breadcrumb, botão voltar, estado preservado)
- Identificar e projetar explicitamente os **fluxos de exceção** (erro, permissão negada, sessão expirada, offline)
- Mínimo de cliques para ações frequentes — eliminar confirmações desnecessárias para ações reversíveis
- Redirecionar automaticamente ao destino original após login (não sempre para a home)

## Testes de Usabilidade

- **Teste com 5 usuários** identifica ~85% dos problemas de usabilidade (Nielsen, NN/G)
- Usar texto real desde os primeiros protótipos — nunca lorem ipsum
- Tipos de teste por fase:
  - **Exploratório (discovery):** entrevistas, card sorting, tree testing
  - **Formativo (protótipo):** teste de usabilidade moderado, think-aloud
  - **Somativo (produto):** A/B testing de microcopy e CTAs, métricas de funil
- Documentar achados com **prioridade de impacto** (crítico / moderado / cosmético) e associar a heurística violada
- Testar dark mode, tamanhos de fonte aumentados e navegação por teclado como parte do processo padrão
