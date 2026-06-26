#!/usr/bin/env bash
# Source this file before starting Codex when you need project-local MCP credentials.
#
# Usage:
#   source .codex/load-project-env.sh
#   codex

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This script must be sourced, not executed:" >&2
  echo "  source .codex/load-project-env.sh" >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${repo_root}/.codex/.env.local"

if [[ ! -f "${env_file}" ]]; then
  echo "Missing ${env_file}" >&2
  echo "Create it from .codex/.env.example and fill in your Jira values." >&2
  return 1
fi

set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

echo "Loaded project environment from ${env_file}"

