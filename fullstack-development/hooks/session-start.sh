#!/usr/bin/env bash
# SessionStart hook: detects the project stack from marker files and emits a short,
# factual context line listing the applicable skills. Pure bash (no jq/python) so it
# runs unchanged on Linux, macOS and Git Bash on Windows. Silent when nothing is detected.

root="${CLAUDE_PROJECT_DIR:-$PWD}"
plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Skip the filesystem root and the home directory to avoid scanning unrelated trees
[ -d "$root" ] || exit 0
if [ "$root" = "/" ] || [ "$root" = "${HOME:-}" ]; then
  exit 0
fi

# Single bounded scan of marker files and directories, ignoring dependency/build folders
files=$(find "$root" -maxdepth 3 \
  \( -name node_modules -o -name vendor -o -name .git -o -name dist -o -name build \
     -o -name .gradle -o -name .dart_tool -o -name target \) -prune \
  -o -print 2>/dev/null)
[ -n "$files" ] || exit 0

stacks=""
skills=""

# Checks whether any scanned path matches an extended regex
has() {
  grep -qE "$1" <<<"$files"
}

# Prints the first scanned path matching an extended regex
first() {
  grep -E "$1" <<<"$files" | head -n 1
}

# Appends a stack label once
add_stack() {
  case ", $stacks," in
    *", $1,"*) ;;
    *) stacks="${stacks:+$stacks, }$1" ;;
  esac
}

# Appends a skill path (relative to skills/) once
add_skill() {
  case " $skills " in
    *" $1 "*) ;;
    *) skills="${skills:+$skills }$1" ;;
  esac
}

# Escapes a string for use inside a JSON string literal
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# PHP and GLPI plugin detection
composer=$(first '/composer\.json$')
setup=$(first '/setup\.php$')
if [ -n "$setup" ] && ! grep -qs 'plugin_init_' "$setup"; then
  setup=""
fi

if [ -n "$composer" ] || [ -n "$setup" ]; then
  php_ver=""
  if [ -n "$composer" ]; then
    php_ver=$(grep -oE '"php"[[:space:]]*:[[:space:]]*"[^"]*"' "$composer" 2>/dev/null \
      | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
  fi
  if [ -n "$php_ver" ]; then
    add_stack "PHP $php_ver (composer.json)"
  else
    add_stack "PHP (versão não determinada)"
  fi
  add_skill base/backend-base
  add_skill languages/php
fi

if [ -n "$setup" ]; then
  glpi_ver=$(tr '\n' ' ' <"$setup" 2>/dev/null \
    | grep -oE "['\"]glpi['\"][[:space:]]*=>[[:space:]]*\[[^]]*['\"]min['\"][[:space:]]*=>[[:space:]]*['\"][0-9]+" \
    | grep -oE '[0-9]+$' | head -n 1)
  if [ -z "$glpi_ver" ] && grep -qs 'csrf_compliant' "$setup"; then
    glpi_ver=10
  fi
  case "$glpi_ver" in
    10|11|12)
      add_stack "plugin GLPI $glpi_ver (setup.php)"
      add_skill "domains/glpi-$glpi_ver"
      ;;
    *)
      add_stack "plugin GLPI (versão não determinada)"
      ;;
  esac
fi

if has '/[^/]+\.twig$'; then
  add_stack "Twig"
  add_skill languages/twig
fi

# JavaScript / Vue / Node detection
pkg=$(first '/package\.json$')
if [ -n "$pkg" ]; then
  if grep -qE '"vue"[[:space:]]*:' "$pkg" 2>/dev/null; then
    add_stack "Vue (package.json)"
    add_skill base/frontend-base
    add_skill languages/vue
    add_skill languages/javascript
  else
    add_stack "Node.js (package.json)"
    add_skill base/backend-base
    add_skill languages/javascript
    add_skill languages/nodejs
  fi
fi

# Go and Python detection
if has '/go\.mod$'; then
  add_stack "Go (go.mod)"
  add_skill base/backend-base
  add_skill languages/golang
fi
if has '/(pyproject\.toml|requirements\.txt)$'; then
  add_stack "Python"
  add_skill base/backend-base
  add_skill languages/python
fi

# Mobile detection: Flutter takes precedence because it embeds an Android project
if has '/pubspec\.yaml$'; then
  add_stack "Flutter (pubspec.yaml)"
  add_skill base/mobile-base
  add_skill languages/dart
  add_skill domains/flutter
elif has '/(AndroidManifest\.xml|build\.gradle(\.kts)?)$'; then
  add_stack "Android (Gradle)"
  add_skill base/mobile-base
  add_skill languages/kotlin
  add_skill languages/gradle
  add_skill domains/android-architecture
  gradle_files=$(grep -E '/build\.gradle(\.kts)?$' <<<"$files")
  while IFS= read -r gradle_file; do
    [ -n "$gradle_file" ] || continue
    if grep -qs 'androidx.compose' "$gradle_file" 2>/dev/null; then
      add_skill domains/jetpack-compose
      break
    fi
  done <<<"$gradle_files"
fi

# DevOps detection
devops=""
if has '/(Dockerfile|Containerfile)[^/]*$'; then
  devops="${devops:+$devops, }Dockerfile/Containerfile"
  add_skill domains/containers
fi
if has '/\.github/workflows$|/\.gitlab-ci\.yml$'; then
  devops="${devops:+$devops, }pipeline CI"
  add_skill domains/ci-cd
fi
if has '/azure-pipelines\.yml$'; then
  devops="${devops:+$devops, }Azure Pipelines"
  add_skill domains/ci-cd
  add_skill domains/azure-devops
fi
if has '/[^/]+\.tf$'; then
  devops="${devops:+$devops, }Terraform"
  add_skill domains/iac
fi
if has '/(Chart\.yaml|kustomization\.yaml)$'; then
  devops="${devops:+$devops, }Kubernetes"
  add_skill domains/kubernetes
fi
if [ -n "$devops" ]; then
  add_stack "$devops"
  add_skill base/devops-base
fi

# Nothing detected: stay silent
[ -n "$stacks" ] || exit 0

# Keeps the injected context small: past 10 skills only the router pointer is emitted
count=$(wc -w <<<"$skills" | tr -d ' ')
if [ "$count" -le 10 ]; then
  skill_list="${skills// /, }"
  msg="fullstack-development: stack detectada — $stacks. Skills aplicáveis (relativas a $plugin_root/skills/): $skill_list. Índice completo: fullstack-router/SKILL.md."
else
  msg="fullstack-development: stack detectada — $stacks. Índice de skills: $plugin_root/skills/fullstack-router/SKILL.md."
fi

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$(json_escape "$msg")"
exit 0
