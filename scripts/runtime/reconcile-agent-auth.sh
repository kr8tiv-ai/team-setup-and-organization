#!/usr/bin/env bash
set -euo pipefail

# Reconcile Mission Control -> Gateway auth/session drift.
# Default mode is safe: rotate tokens only when agent API probes return 401.

MC_URL="${MC_URL:-http://localhost:8100}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-kr8tiv-mission-control-backend-1}"
FORCE_ROTATE="${FORCE_ROTATE:-false}"
TARGET_REGEX="${TARGET_REGEX:-openclaw-(friday|arsenal|jocasta|edith)|openclaw-ydy8-openclaw-1}"
LOG_PREFIX="[kr8tiv-agent-reconcile]"

log() {
  printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"
}

resolve_local_auth_token() {
  if [[ -n "${LOCAL_AUTH_TOKEN:-}" ]]; then
    printf '%s' "$LOCAL_AUTH_TOKEN"
    return 0
  fi

  if command -v docker >/dev/null 2>&1; then
    docker inspect "$BACKEND_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
      | awk -F= '/^LOCAL_AUTH_TOKEN=/{print substr($0, index($0,$2)); exit}'
    return 0
  fi

  return 1
}

resolve_agent_token() {
  local container="$1"
  local token=""

  token="$(
    docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
      | awk -F= '/^AUTH_TOKEN=/{print substr($0, index($0,$2)); exit}'
  )"
  if [[ -n "${token}" ]]; then
    printf '%s' "${token}"
    return 0
  fi

  token="$(
    docker exec "$container" sh -lc "awk -F= '/AUTH_TOKEN=/{print \$2; exit}' /data/.openclaw/workspace/TOOLS.md 2>/dev/null" 2>/dev/null || true
  )"
  printf '%s' "${token}"
}

probe_agent_auth() {
  local token="$1"
  curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Agent-Token: ${token}" \
    "${MC_URL}/api/v1/agent/boards"
}

should_rotate_tokens() {
  local need_rotate="false"
  local containers
  mapfile -t containers < <(docker ps --format '{{.Names}}' | grep -E "${TARGET_REGEX}" || true)

  if [[ "${#containers[@]}" -eq 0 ]]; then
    log "status=no_target_containers force_rotate=${FORCE_ROTATE}"
    [[ "${FORCE_ROTATE}" == "true" ]] && return 0
    return 1
  fi

  for container in "${containers[@]}"; do
    local token
    token="$(resolve_agent_token "$container")"
    if [[ -z "${token}" ]]; then
      log "container=${container} probe=skipped reason=missing_token"
      continue
    fi
    local code
    code="$(probe_agent_auth "$token" || true)"
    if [[ "${code}" == "401" ]]; then
      log "container=${container} probe=401 action=rotate"
      need_rotate="true"
      break
    fi
    log "container=${container} probe=${code}"
  done

  if [[ "${FORCE_ROTATE}" == "true" ]]; then
    return 0
  fi
  [[ "${need_rotate}" == "true" ]]
}

main() {
  log "start force_rotate=${FORCE_ROTATE}"

  if ! command -v curl >/dev/null 2>&1; then
    log "error=missing_curl"
    exit 2
  fi

  LOCAL_AUTH_TOKEN="$(resolve_local_auth_token)"
  if [[ -z "${LOCAL_AUTH_TOKEN:-}" ]]; then
    log "error=missing_local_auth_token"
    exit 3
  fi

  curl -fsS "${MC_URL}/healthz" >/dev/null

  if ! should_rotate_tokens; then
    log "status=healthy action=skip_rotation"
    exit 0
  fi

  GW_ID="$(
    curl -fsS "${MC_URL}/api/v1/gateways" \
      -H "Authorization: Bearer ${LOCAL_AUTH_TOKEN}" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); items=d.get("items", d); print(items[0]["id"] if items else "")'
  )"

  if [[ -z "${GW_ID}" ]]; then
    log "error=gateway_not_found"
    exit 4
  fi

  curl -fsS -X POST \
    "${MC_URL}/api/v1/gateways/${GW_ID}/templates/sync?rotate_tokens=true&reset_sessions=true&include_main=true&overwrite=true" \
    -H "Authorization: Bearer ${LOCAL_AUTH_TOKEN}" \
    -H "Content-Type: application/json" \
    >/dev/null

  log "ok action=rotated gateway_id=${GW_ID}"
}

main "$@"
