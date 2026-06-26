#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="sdd-ai-agents"
MANAGED_MARKER="Managed by sdd-ai-agents"
CONFIG_BLOCK_PREFIX="sdd-ai-agents"

DRY_RUN=0
INSTALL_MODE="link"
WITH_MCP=0

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [--dry-run] [--link|--copy] [--with-mcp|--without-mcp] [--help]

Installs the project-local Codex agents, skills, and power state for the current user.

Options:
  --dry-run       Print actions without changing files
  --link          Install symlinks (default)
  --copy          Install copied files and directories
  --with-mcp      Merge project MCP fragments into ~/.codex/config.toml
  --without-mcp   Skip MCP config changes (default)
  --help          Show this help
USAGE
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    printf 'DRY RUN'
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return 0
  fi

  "$@"
}

ensure_dir() {
  local path="$1"
  if [[ -d "${path}" ]]; then
    return 0
  fi
  run_cmd mkdir -p -- "${path}"
}

ensure_repo_root() {
  [[ -d "${repo_root}/agents" ]] || die "Run this from the repository root."
  [[ -d "${repo_root}/skills" ]] || die "Run this from the repository root."
  [[ -d "${repo_root}/powers" ]] || die "Run this from the repository root."
  [[ -d "${repo_root}/.codex" ]] || die "Run this from the repository root."
  [[ -f "${repo_root}/README.md" ]] || die "Run this from the repository root."
}

checksum_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "${path}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "${path}" | awk '{print $1}'
  else
    printf '%s' "-"
  fi
}

record_manifest() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    return 0
  fi

  local kind="$1"
  local path="$2"
  local source="${3:-}"
  local mode="${4:-}"
  local backup="${5:-}"
  local checksum="${6:-}"

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "${kind}" "${path}" "${source}" "${mode}" "${backup}" "${checksum}" >> "${manifest}"
}

is_repo_symlink() {
  local path="$1"
  [[ -L "${path}" ]] || return 1
  local target
  target="$(readlink -- "${path}")"
  case "${target}" in
    /*) ;;
    *)
      target="$(cd -- "$(dirname -- "${path}")" && cd -- "$(dirname -- "${target}")" && pwd)/$(basename -- "${target}")"
      ;;
  esac
  [[ "${target}" == "${repo_root}"/* ]]
}

has_managed_marker() {
  local path="$1"
  [[ -f "${path}" ]] || return 1
  head -n 5 -- "${path}" 2>/dev/null | grep -Fq "${MANAGED_MARKER}"
}

has_managed_dir_marker() {
  local path="$1"
  [[ -d "${path}" ]] || return 1
  [[ -f "${path}/.sdd-ai-agents-managed" ]]
}

managed_file_header() {
  local path="$1"
  case "${path}" in
    *.md|*.markdown)
      printf '<!-- %s -->\n' "${MANAGED_MARKER}"
      ;;
    *)
      printf '# %s\n' "${MANAGED_MARKER}"
      ;;
  esac
}

prepare_destination() {
  local dest="$1"
  local source="$2"

  if [[ -L "${dest}" ]]; then
    local current
    current="$(readlink -- "${dest}")"
    if [[ "${current}" == "${source}" ]]; then
      return 1
    fi
    if is_repo_symlink "${dest}"; then
      run_cmd rm -f -- "${dest}"
      return 0
    fi
    die "Refusing to overwrite unrelated symlink: ${dest}"
  fi

  if [[ -e "${dest}" ]]; then
    if [[ -d "${dest}" ]]; then
      if has_managed_dir_marker "${dest}"; then
        run_cmd rm -rf -- "${dest}"
        return 0
      fi
      die "Refusing to overwrite unrelated directory: ${dest}"
    fi

    if has_managed_marker "${dest}"; then
      run_cmd rm -f -- "${dest}"
      return 0
    fi

    die "Refusing to overwrite unrelated file: ${dest}"
  fi

  return 0
}

install_symlink_file() {
  local source="$1"
  local dest="$2"

  if prepare_destination "${dest}" "${source}"; then
    :
  else
    log "SKIP existing managed symlink: ${dest}"
    return 0
  fi

  run_cmd ln -s -- "${source}" "${dest}"
}

install_copy_file() {
  local source="$1"
  local dest="$2"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN copy file: ${source} -> ${dest}"
    return 0
  fi

  if prepare_destination "${dest}" "${source}"; then
    :
  else
    log "SKIP existing managed file: ${dest}"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  {
    managed_file_header "${dest}"
    cat -- "${source}"
  } > "${tmp}"
  run_cmd mkdir -p -- "$(dirname -- "${dest}")"
  run_cmd mv -- "${tmp}" "${dest}"
}

install_symlink_dir() {
  local source="$1"
  local dest="$2"

  if prepare_destination "${dest}" "${source}"; then
    :
  else
    log "SKIP existing managed directory symlink: ${dest}"
    return 0
  fi

  run_cmd ln -s -- "${source}" "${dest}"
}

install_copy_dir() {
  local source="$1"
  local dest="$2"

  if prepare_destination "${dest}" "${source}"; then
    :
  else
    log "SKIP existing managed directory: ${dest}"
    return 0
  fi

  run_cmd mkdir -p -- "$(dirname -- "${dest}")"
  run_cmd cp -a -- "${source}" "${dest}"
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    : > "${dest}/.sdd-ai-agents-managed"
  fi
}

append_unique_block() {
  local dest="$1"
  local marker="$2"
  local fragment="$3"

  if [[ -f "${dest}" ]] && grep -Fq "# BEGIN ${marker}" "${dest}"; then
    log "SKIP existing MCP block: ${marker}"
    return 1
  fi

  ensure_dir "$(dirname -- "${dest}")"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "DRY RUN append MCP block: ${marker} -> ${dest}"
    return 0
  fi

  if [[ ! -f "${dest}" ]]; then
    {
      printf '# %s\n' "${MANAGED_MARKER}"
      printf '# Project MCP configuration for %s\n' "${PROJECT_NAME}"
      printf '\n'
      printf '# BEGIN %s\n' "${marker}"
      cat -- "${fragment}"
      printf '\n# END %s\n' "${marker}"
      printf '\n'
    } > "${dest}"
  else
    {
      printf '\n# BEGIN %s\n' "${marker}"
      cat -- "${fragment}"
      printf '\n# END %s\n' "${marker}"
      printf '\n'
    } >> "${dest}"
  fi
}

install_secrets_file() {
  local template
  local marker

  ensure_dir "${state_dir}"

  if [[ -f "${secrets_file}" ]]; then
    if ! grep -Fq "${MANAGED_MARKER}" "${secrets_file}"; then
      die "Refusing to overwrite unrelated secrets file: ${secrets_file}"
    fi
  else
    if [[ "${DRY_RUN}" -eq 1 ]]; then
      log "DRY RUN create secrets file: ${secrets_file}"
    else
      {
        printf '# %s\n' "${MANAGED_MARKER}"
        printf '# Project secrets for %s\n' "${PROJECT_NAME}"
        printf '\n'
      } > "${secrets_file}"
    fi
  fi

  for template in "${repo_root}/powers"/*/secrets.template; do
    [[ -f "${template}" ]] || continue
    marker="$(basename -- "$(dirname -- "${template}")")"
    if grep -Fq "# BEGIN ${marker}" "${secrets_file}" 2>/dev/null; then
      continue
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
      log "DRY RUN append secrets block: ${marker}"
      continue
    fi

    {
      printf '# BEGIN %s\n' "${marker}"
      cat -- "${template}"
      printf '# END %s\n\n' "${marker}"
    } >> "${secrets_file}"
  done

  if [[ "${DRY_RUN}" -eq 0 ]]; then
    chmod 600 -- "${secrets_file}"
  fi
}

install_mcp_fragment() {
  local fragment="$1"
  local marker="$2"
  local config_file="$3"

  append_unique_block "${config_file}" "${marker}" "${fragment}" || return 0
  record_manifest "config-edit" "${config_file}" "${fragment}" "append" "marker:${marker}" ""
}

main() {
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "${arg}" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --link)
        INSTALL_MODE="link"
        shift
        ;;
      --copy)
        INSTALL_MODE="copy"
        shift
        ;;
      --with-mcp)
        WITH_MCP=1
        shift
        ;;
      --without-mcp)
        WITH_MCP=0
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: ${arg}"
        ;;
    esac
  done

  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd -- "${script_dir}/.." && pwd)"

  ensure_repo_root

  codex_home="${CODEX_HOME:-${HOME}/.codex}"
  agents_home="${AGENTS_HOME:-${HOME}/.agents}"
  state_dir="${codex_home}/${PROJECT_NAME}"
  manifest="${state_dir}/install-manifest.tsv"
  secrets_file="${state_dir}/secrets"
  config_file="${codex_home}/config.toml"

  agents_dest="${codex_home}/agents"
  skills_dest="${agents_home}/skills"
  powers_dest="${state_dir}/powers"

  log "Installing ${PROJECT_NAME}"
  log "Repository root: ${repo_root}"
  log "CODEX_HOME: ${codex_home}"
  log "AGENTS_HOME: ${agents_home}"
  log "Mode: ${INSTALL_MODE}"
  log "MCP merge: $([[ "${WITH_MCP}" -eq 1 ]] && printf 'enabled' || printf 'disabled')"

  ensure_dir "${codex_home}"
  ensure_dir "${agents_home}"
  ensure_dir "${state_dir}"
  ensure_dir "${agents_dest}"
  ensure_dir "${skills_dest}"
  ensure_dir "${powers_dest}"

  if [[ "${DRY_RUN}" -eq 0 ]]; then
    {
      printf '# install manifest for %s\n' "${PROJECT_NAME}"
      printf '# kind\tpath\tsource\tmode\tbackup\tchecksum\n'
    } > "${manifest}"
  else
    log "DRY RUN manifest: ${manifest}"
  fi

  local source dest checksum

  for source in "${repo_root}/agents"/*.toml; do
    [[ -f "${source}" ]] || continue
    dest="${agents_dest}/$(basename -- "${source}")"
    case "${INSTALL_MODE}" in
      link) install_symlink_file "${source}" "${dest}" ;;
      copy) install_copy_file "${source}" "${dest}" ;;
    esac
    checksum="$(checksum_file "${source}")"
    record_manifest "file" "${dest}" "${source}" "${INSTALL_MODE}" "" "${checksum}"
  done

  for source in "${repo_root}/skills"/*; do
    [[ -d "${source}" ]] || continue
    dest="${skills_dest}/$(basename -- "${source}")"
    case "${INSTALL_MODE}" in
      link) install_symlink_dir "${source}" "${dest}" ;;
      copy) install_copy_dir "${source}" "${dest}" ;;
    esac
    record_manifest "directory" "${dest}" "${source}" "${INSTALL_MODE}" "" ""
  done

  if [[ -e "${powers_dest}" || -L "${powers_dest}" ]]; then
    if [[ -L "${powers_dest}" ]] && is_repo_symlink "${powers_dest}"; then
      if [[ "${INSTALL_MODE}" == "copy" ]]; then
        run_cmd rm -f -- "${powers_dest}"
      fi
    elif [[ -d "${powers_dest}" ]] && has_managed_dir_marker "${powers_dest}"; then
      if [[ "${INSTALL_MODE}" == "link" ]]; then
        run_cmd rm -rf -- "${powers_dest}"
      fi
    elif [[ -e "${powers_dest}" || -L "${powers_dest}" ]]; then
      die "Refusing to overwrite unrelated powers directory: ${powers_dest}"
    fi
  fi

  case "${INSTALL_MODE}" in
    link)
      install_symlink_dir "${repo_root}/powers" "${powers_dest}"
      ;;
    copy)
      install_copy_dir "${repo_root}/powers" "${powers_dest}"
      ;;
  esac
  record_manifest "directory" "${powers_dest}" "${repo_root}/powers" "${INSTALL_MODE}" "" ""

  install_secrets_file
  record_manifest "file" "${secrets_file}" "powers/*/secrets.template" "generated" "" ""

  if [[ "${WITH_MCP}" -eq 1 ]]; then
    for source in "${repo_root}/powers"/*/mcp.toml; do
      [[ -f "${source}" ]] || continue
      marker="$(basename -- "$(dirname -- "${source}")")"
      install_mcp_fragment "${source}" "${CONFIG_BLOCK_PREFIX}_${marker}" "${config_file}"
    done
  fi

  log ""
  log "Installed agents into: ${agents_dest}"
  log "Installed skills into: ${skills_dest}"
  log "Installed powers into: ${powers_dest}"
  log "Secrets file: ${secrets_file}"
  if [[ "${WITH_MCP}" -eq 1 ]]; then
    log "MCP config updated: ${config_file}"
  fi
  log "Manifest: ${manifest}"
  log ""
  log "Reload Codex after installation if it is already running."
}

main "$@"
