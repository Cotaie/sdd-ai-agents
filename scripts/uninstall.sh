#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="sdd-ai-agents"
MANAGED_MARKER="Managed by sdd-ai-agents"

usage() {
  cat <<'USAGE'
Usage: scripts/uninstall.sh [--dry-run] [--help]

Removes local Codex updates installed by this project.

The uninstaller removes only project-owned files:
- entries recorded in the install manifest
- symlinks pointing back to this repository
- copied files containing the "Managed by sdd-ai-agents" marker

Options:
  --dry-run   Print actions without changing files
  --help      Show this help
USAGE
}

DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
codex_home="${CODEX_HOME:-${HOME}/.codex}"
agents_home="${AGENTS_HOME:-${HOME}/.agents}"
state_dir="${codex_home}/${PROJECT_NAME}"
manifest="${state_dir}/install-manifest.tsv"

removed=0
skipped=0
restored=0

log() {
  printf '%s\n' "$*"
}

run_rm_file() {
  local path="$1"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN remove file: ${path}"
  else
    rm -f -- "${path}"
  fi
  removed=$((removed + 1))
}

run_rm_dir() {
  local path="$1"
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN remove directory: ${path}"
  else
    rm -rf -- "${path}"
  fi
  removed=$((removed + 1))
}

run_restore_backup() {
  local backup="$1"
  local path="$2"
  if [[ ! -f "${backup}" ]]; then
    log "SKIP missing backup: ${backup}"
    skipped=$((skipped + 1))
    return
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN restore backup: ${backup} -> ${path}"
  else
    mkdir -p -- "$(dirname -- "${path}")"
    cp -- "${backup}" "${path}"
  fi
  restored=$((restored + 1))
}

is_repo_symlink() {
  local path="$1"
  [[ -L "${path}" ]] || return 1

  local target
  target="$(readlink -- "${path}")"
  if [[ "${target}" != /* ]]; then
    target="$(cd -- "$(dirname -- "${path}")" && cd -- "$(dirname -- "${target}")" && pwd)/$(basename -- "${target}")"
  fi

  [[ "${target}" == "${repo_root}"/* ]]
}

has_managed_marker() {
  local path="$1"
  [[ -f "${path}" ]] || return 1
  head -n 5 -- "${path}" 2>/dev/null | grep -Fq "${MANAGED_MARKER}"
}

safe_remove_path() {
  local kind="$1"
  local path="$2"
  local source="${3:-}"
  local backup="${4:-}"

  if [[ -z "${path}" ]]; then
    return
  fi

  if [[ ! -e "${path}" && ! -L "${path}" ]]; then
    log "SKIP missing: ${path}"
    skipped=$((skipped + 1))
    return
  fi

  case "${kind}" in
    config-edit)
      if [[ "${backup}" == marker:* ]]; then
        local marker="${backup#marker:}"
        remove_config_block "${path}" "${marker}"
      elif [[ -n "${backup}" ]]; then
        run_restore_backup "${backup}" "${path}"
      else
        log "SKIP config edit without backup: ${path}"
        skipped=$((skipped + 1))
      fi
      ;;
    symlink)
      if is_repo_symlink "${path}"; then
        run_rm_file "${path}"
      else
        log "SKIP symlink not owned by this repo: ${path}"
        skipped=$((skipped + 1))
      fi
      ;;
    file)
      if is_repo_symlink "${path}" || has_managed_marker "${path}"; then
        run_rm_file "${path}"
      else
        log "SKIP file without project ownership marker: ${path}"
        skipped=$((skipped + 1))
      fi
      ;;
    directory)
      if is_repo_symlink "${path}"; then
        run_rm_file "${path}"
      elif [[ -d "${path}" && -f "${path}/.sdd-ai-agents-managed" ]]; then
        run_rm_dir "${path}"
      else
        log "SKIP directory without project ownership marker: ${path}"
        skipped=$((skipped + 1))
      fi
      ;;
    backup)
      if [[ "${path}" == "${state_dir}"/* ]]; then
        run_rm_file "${path}"
      else
        log "SKIP backup outside project state: ${path}"
        skipped=$((skipped + 1))
      fi
      ;;
    *)
      log "SKIP unknown manifest kind '${kind}': ${path}"
      skipped=$((skipped + 1))
      ;;
  esac
}

remove_config_block() {
  local path="$1"
  local marker="$2"
  local begin="# BEGIN ${marker}"
  local end="# END ${marker}"

  if [[ ! -f "${path}" ]]; then
    log "SKIP missing config file: ${path}"
    skipped=$((skipped + 1))
    return
  fi

  if ! grep -Fq "${begin}" "${path}"; then
    log "SKIP missing config block: ${marker}"
    skipped=$((skipped + 1))
    return
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN remove config block: ${marker} from ${path}"
    return
  fi

  local tmp
  tmp="$(mktemp)"
  awk -v begin="${begin}" -v end="${end}" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "${path}" > "${tmp}"
  mv -- "${tmp}" "${path}"

  if ! grep -Eq '^[[:space:]]*[^#[:space:]]' -- "${path}"; then
    rm -f -- "${path}"
  fi
}

uninstall_from_manifest() {
  log "Using install manifest: ${manifest}"

  while IFS=$'\t' read -r kind path source mode backup checksum; do
    case "${kind:-}" in
      ""|"# "*) continue ;;
    esac
    safe_remove_path "${kind}" "${path}" "${source:-}" "${backup:-}"
  done < "${manifest}"
}

fallback_uninstall() {
  log "No install manifest found. Using conservative fallback checks."

  local candidate

  for candidate in "${codex_home}/agents"/*.toml; do
    [[ -e "${candidate}" || -L "${candidate}" ]] || continue
    safe_remove_path "file" "${candidate}"
  done

  for candidate in "${agents_home}/skills"/*; do
    [[ -e "${candidate}" || -L "${candidate}" ]] || continue
    safe_remove_path "directory" "${candidate}"
  done

  candidate="${codex_home}/${PROJECT_NAME}/powers"
  if [[ -e "${candidate}" || -L "${candidate}" ]]; then
    safe_remove_path "directory" "${candidate}"
  fi

  candidate="${codex_home}/${PROJECT_NAME}/secrets"
  if [[ -e "${candidate}" || -L "${candidate}" ]]; then
    safe_remove_path "file" "${candidate}"
  fi
}

remove_empty_state_dir() {
  if [[ ! -d "${state_dir}" ]]; then
    return
  fi

  if find "${state_dir}" -mindepth 1 -print -quit | grep -q .; then
    log "SKIP non-empty state directory: ${state_dir}"
    return
  fi

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN remove empty state directory: ${state_dir}"
  else
    rmdir -- "${state_dir}"
  fi
}

main() {
  log "Uninstalling ${PROJECT_NAME} local Codex configuration"
  log "Repository root: ${repo_root}"
  log "CODEX_HOME: ${codex_home}"
  log "AGENTS_HOME: ${agents_home}"

  if [[ -f "${manifest}" ]]; then
    uninstall_from_manifest
  else
    fallback_uninstall
  fi

  remove_empty_state_dir

  log ""
  log "Summary:"
  log "- removed: ${removed}"
  log "- restored: ${restored}"
  log "- skipped: ${skipped}"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "Dry run only. No files were changed."
  fi
}

main
