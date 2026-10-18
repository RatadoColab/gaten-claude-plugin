#!/usr/bin/env bash
# UserPromptSubmit hook: matches Portuguese keywords in the prompt and emits a short,
# factual list of possibly applicable skills. Each skill is reported once per session
# (state kept per session_id). Silent when nothing matches or nothing is new.

input=$(cat)

# Extracts prompt and session id; jq is used when available, sed otherwise
if command -v jq >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
  session=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
else
  prompt=$(printf '%s' "$input" | sed -E 's/"(cwd|transcript_path)":"[^"]*"//g')
  session=$(printf '%s' "$input" | sed -n 's/.*"session_id":"\([^"]*\)".*/\1/p')
fi
[ -n "$prompt" ] || exit 0

plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
state_dir="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/fullstack-development}"
session="${session//[^A-Za-z0-9_-]/}"
state_file="$state_dir/seen-${session:-nosession}"

# Lowercases the prompt for case-insensitive matching
text=$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')

# Keyword rules: extended regex <TAB> space-separated skills (relative to skills/)
rules=$(cat <<'EOF'
(bug|erro |falha|quebr|exce[cç][aã]o|exception|stack ?trace|crash|n[aã]o funciona|regress)	domains/debugging
(endpoint|api |apis |rest|rota |status http|pagina[cç][aã]o)	domains/api-rest
(migration|banco de dados|query|[ií]ndice|sql|schema|tabela)	domains/database
(seguran[cç]a|vulnerab|csrf|xss|owasp|autentica|senha|sess[aã]o)	domains/security
(formul[aá]rio|valida[cç][aã]o de campo|campos? de entrada)	domains/forms
(componente|acessibilidade|a11y|design token)	domains/ui-components
(fluxo de tela|usabilidade|estado vazio|ux |loading)	domains/user-experience
(pipeline|ci/cd|github actions|gitlab ci|estrat[eé]gia de deploy)	domains/ci-cd base/devops-base
(dockerfile|containerfile|imagem de container|containeriz)	domains/containers
(kubernetes|k8s|helm|kustomize)	domains/kubernetes
(openshift)	domains/kubernetes domains/openshift
(podman|quadlet)	domains/podman
(terraform|gitops|infraestrutura como c[oó]digo)	domains/iac
(observabilidade|m[eé]tricas|tracing|alertas|slo)	domains/observability
(devsecops|sast|sbom|scan de)	domains/devsecops
(azure devops|azure pipelines)	domains/ci-cd domains/azure-devops
(especifica[cç][aã]o|crit[eé]rio de aceite|(^|[^a-z])spec([^a-z]|$))	base/spec-base domains/spec-review
(^|[^a-z])vue([^a-z]|$)	languages/vue
(^|[^a-z])php([^a-z]|$)	languages/php
(^|[^a-z])python([^a-z]|$)	languages/python
(golang|(^|[^a-z])go([^a-z]|$))	languages/golang
(node\.?js|(^|[^a-z])node([^a-z]|$))	languages/javascript languages/nodejs
(flutter|(^|[^a-z])dart([^a-z]|$))	domains/flutter languages/dart base/mobile-base
(jetpack|compose|viewmodel|kotlin)	domains/jetpack-compose languages/kotlin base/mobile-base
(gradle)	languages/gradle
(twig)	languages/twig
EOF
)

# Collects matched skills in rule order, without duplicates
matched=""
while IFS=$'\t' read -r re list; do
  [ -n "$re" ] || continue
  if printf '%s' "$text" | grep -qE "$re"; then
    for s in $list; do
      case " $matched " in
        *" $s "*) ;;
        *) matched="${matched:+$matched }$s" ;;
      esac
    done
  fi
done <<<"$rules"

# GLPI is version-sensitive: the router resolves it, so only a pointer is added
glpi_note=""
if printf '%s' "$text" | grep -qE 'glpi'; then
  glpi_note=" Pedido menciona GLPI (versão a confirmar; ver fullstack-router/SKILL.md)."
fi

# Keeps only skills not yet reported in this session, capped at five
mkdir -p "$state_dir" 2>/dev/null
fresh=""
count=0
for s in $matched; do
  [ "$count" -lt 5 ] || break
  if ! grep -qxF "$s" "$state_file" 2>/dev/null; then
    fresh="${fresh:+$fresh, }$s"
    printf '%s\n' "$s" >>"$state_file" 2>/dev/null
    count=$((count + 1))
  fi
done

[ -n "$fresh" ] || [ -n "$glpi_note" ] || exit 0

msg="fullstack-development:"
[ -n "$fresh" ] && msg="$msg skills possivelmente aplicáveis a este pedido (relativas a $plugin_root/skills/): $fresh."
msg="$msg$glpi_note"

# Escapes the message for JSON
msg="${msg//\\/\\\\}"
msg="${msg//\"/\\\"}"
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$msg"
exit 0
