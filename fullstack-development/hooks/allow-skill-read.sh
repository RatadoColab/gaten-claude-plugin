#!/usr/bin/env bash
# PreToolUse hook (matcher: Read): auto-approves reads of SKILL.md and reference files
# that live inside this plugin's own skills/ directory. Any other path is left to the
# regular permission flow (no output, no decision).

input=$(cat)
plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
skills_prefix="$plugin_root/skills/"

# Extracts the requested path; jq is used when available, sed otherwise
if command -v jq >/dev/null 2>&1; then
  path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  path=$(printf '%s' "$input" | sed -n 's/.*"file_path":"\([^"]*\)".*/\1/p')
fi

# Only absolute paths under skills/, without parent-directory traversal, markdown files only
case "$path" in
  "$skills_prefix"*.md) ;;
  *) exit 0 ;;
esac
case "$path" in
  *..*) exit 0 ;;
esac

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Leitura de skill do plugin fullstack-development"}}\n'
exit 0
