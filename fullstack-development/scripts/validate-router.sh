#!/usr/bin/env bash
# Validates that the router table matches the SKILL.md files on disk.
# Usage: bash scripts/validate-router.sh   (run from any directory)

set -u

# Byte-order sorting keeps sort and comm consistent across locales
export LC_ALL=C

plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="$plugin_root/skills"
router="$skills_dir/fullstack-router/SKILL.md"

[ -f "$router" ] || { echo "ERRO: router não encontrado em $router"; exit 1; }

# Paths listed in the router table, with <v> expanded to each GLPI version
listed=$(grep -oE '\| [a-z]+/[a-zA-Z0-9<>/_-]+/SKILL\.md \|?$' "$router" \
  | grep -oE '[a-z]+/[a-zA-Z0-9<>/_-]+/SKILL\.md' \
  | while read -r p; do
      case "$p" in
        *'<v>'*) for v in 10 11 12; do echo "${p//<v>/$v}"; done ;;
        *) echo "$p" ;;
      esac
    done | sort -u)

# SKILL.md files on disk, excluding the router itself
actual=$(cd "$skills_dir" && find . -name SKILL.md -not -path './fullstack-router/*' \
  | sed 's|^\./||' | sort -u)

missing_on_disk=$(comm -23 <(echo "$listed") <(echo "$actual"))
missing_in_table=$(comm -13 <(echo "$listed") <(echo "$actual"))

status=0
if [ -n "$missing_on_disk" ]; then
  echo "Na tabela, mas sem arquivo:"; echo "$missing_on_disk"; status=1
fi
if [ -n "$missing_in_table" ]; then
  echo "Em disco, mas fora da tabela:"; echo "$missing_in_table"; status=1
fi

if [ "$status" -eq 0 ]; then
  echo "OK: $(echo "$actual" | wc -l | tr -d ' ') skills em disco = tabela do router"
fi
exit "$status"
