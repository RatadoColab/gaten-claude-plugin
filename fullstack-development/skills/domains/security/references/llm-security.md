# Segurança de Aplicações com LLM — Detalhamento

Riscos e mitigações para aplicações que consomem modelos de linguagem: chatbots, copilots, RAG,
resumo/classificação de conteúdo e agentes com tool calling. Ancorado no **OWASP Top 10 for LLM
Applications** (OWASP GenAI Security Project). A edição 2026 reordenou a lista e substituiu "System
Prompt Leakage" por "Hidden Context Exposure"; a numeração abaixo segue a 2026, com o nome da 2025
entre parênteses quando mudou. Sempre conferir a lista corrente em <https://genai.owasp.org/llm-top-10/>.

## Princípio central

A **saída do modelo é input não confiável**. Todo texto gerado — resposta, chamada de ferramenta,
trecho de código, HTML — deve passar pelas mesmas defesas aplicadas a dados do usuário antes de ser
renderizado, executado em shell, interpolado em query ou usado para decisão de autorização.

## Categorias

### LLM01 — Prompt Injection

Instruções maliciosas embutidas na entrada do usuário ou em conteúdo recuperado (documento, página,
e-mail) que subvertem o comportamento pretendido.

- Separar instruções de sistema do conteúdo do usuário e dos documentos recuperados por canal
  estrutural, não por delimitador textual (que o atacante pode falsificar)
- Nunca conceder ao modelo, por padrão, autoridade para ações sensíveis só porque "foi instruído"
- Validar a saída contra o formato esperado (schema/allowlist) antes de agir sobre ela
- Marcar conteúdo de origem externa como não confiável ao montar o contexto

### LLM02 — Sensitive Information Disclosure

Vazamento de PII, secrets ou dados proprietários pela resposta do modelo.

- Filtrar/mascarar dados sensíveis antes de inseri-los no contexto e ao pós-processar a resposta
- Não colocar secrets, chaves ou credenciais no system prompt
- Aplicar autorização por linha/documento **antes** da recuperação em RAG — não confiar no modelo para filtrar

### LLM03 — Excessive Agency

O sistema recebe permissões, ferramentas ou autonomia além do necessário; uma saída manipulada vira ação real.

- Menor privilégio por ferramenta: escopo mínimo, sem credenciais amplas compartilhadas
- Human-in-the-loop obrigatório para ações destrutivas, irreversíveis ou com efeito financeiro
- Limitar o encadeamento de ações autônomas; exigir confirmação a cada salto de privilégio
- Registrar toda chamada de ferramenta com parâmetros para auditoria

### LLM04 — Supply Chain

Modelos, adapters (LoRA), datasets e plugins de terceiros comprometidos ou não verificados.

- Obter modelos e pesos de fontes confiáveis; verificar checksums e proveniência
- Versionar e fixar modelo, prompt e configuração; tratar troca de modelo como mudança de código
- Ver `domains/security/references/web-defenses.md` (§Supply Chain) para dependências da aplicação

### LLM05 — Data and Model Poisoning

Manipulação de dados de treino, fine-tuning ou de embeddings para inserir backdoors ou viés.

- Controlar a proveniência dos dados de treino/fine-tuning; revisar contribuições externas
- Isolar e validar conteúdo antes de indexá-lo em base vetorial usada por RAG
- Monitorar deriva de qualidade de resposta como sinal de contaminação

### LLM06 — Unbounded Consumption

Uso descontrolado de recursos — custo, tokens, chamadas — incluindo negação de serviço econômica.

- Teto de custo e quota de tokens por usuário e por sessão
- Rate limiting nas rotas que chamam o modelo; timeout e limite de tamanho de entrada/saída
- Limitar profundidade e número de iterações em loops de agente

### LLM07 — Misinformation

Conteúdo incorreto apresentado com aparência de confiança (alucinação), levando a decisão errada.

- Exibir fontes/citações verificáveis; não usar saída não verificada para decisão automática crítica
- Grounding via RAG com dados autoritativos; sinalizar baixa confiança
- Revisão humana onde o erro tem custo alto (jurídico, médico, financeiro)

### LLM08 — Hidden Context Exposure (2025: System Prompt Leakage)

Exposição de qualquer parte não visível do contexto: system prompt, documentos recuperados,
memória, dados do usuário, estado da aplicação, respostas de ferramentas.

- Não depender do sigilo do system prompt como controle de segurança — assumir que ele vaza
- Não colocar regra de autorização, secret ou lógica de negócio sensível no prompt
- Minimizar o que entra no contexto; remover PII e dados de outros tenants antes de montar o prompt

### LLM09 — Vector and Embedding Weaknesses

Falhas em geração, armazenamento e recuperação de embeddings em sistemas RAG.

- Isolamento multi-tenant rígido na base vetorial: filtro por tenant aplicado no retriever, não no modelo
- Controlar quem pode inserir documentos no índice (relaciona-se a LLM05)
- Validar que o conteúdo recuperado não carrega instruções injetadas (relaciona-se a LLM01)

### LLM10 — Improper Output Handling

Aceitar a saída do modelo sem validação/sanitização antes de repassá-la a outro componente.

- Escapar por contexto antes de renderizar (HTML/Markdown → XSS)
- Nunca passar saída do modelo direto para `eval`, shell, SQL dinâmico ou desserialização
- Validar contra schema estrito quando a saída alimenta uma API ou ferramenta

## Referências

- [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/)
- [OWASP GenAI Security Project](https://genai.owasp.org/)
- Ver `domains/security/SKILL.md` para as defesas web referenciadas (XSS, injeção, CSP)
- Ver `domains/api-rest/SKILL.md` para rate limiting e contrato de erro das rotas de inferência
