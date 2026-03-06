#!/usr/bin/env bash
set -euo pipefail

# Ensure CLI model backends (claude/codex/gemini) and auth profiles stay boot-safe.
# Run from host via systemd timer; script is idempotent.

LOG_PREFIX="[kr8tiv-cli-bootstrap]"
TARGET_REGEX="${TARGET_REGEX:-openclaw-(friday|arsenal|jocasta|edith)|openclaw-ydy8-openclaw-1}"

log() {
  printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$LOG_PREFIX" "$*"
}

if ! command -v docker >/dev/null 2>&1; then
  log "error=docker_not_found"
  exit 2
fi

mapfile -t TARGET_CONTAINERS < <(
  docker ps --format '{{.Names}}' | grep -E "${TARGET_REGEX}" || true
)

if [ "${#TARGET_CONTAINERS[@]}" -eq 0 ]; then
  log "status=no_target_containers"
  exit 0
fi

bootstrap_container() {
  local container="$1"
  log "container=${container} phase=start"

docker exec -i "${container}" sh <<'EOS'
set -eu
export NPM_CONFIG_PREFIX=/data/.tooling/npm-global
export PATH="/data/.tooling/npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
mkdir -p /data/.tooling/npm-global /data/.tooling

python3 - <<'PY'
from __future__ import annotations

import base64
import os
from pathlib import Path


def read_secret(name: str) -> str:
    direct = str(os.getenv(name, "")).strip()
    if direct:
        return direct
    from_file = str(os.getenv(f"{name}_FILE", "")).strip()
    if from_file:
        try:
            return Path(from_file).read_text(encoding="utf-8").strip()
        except OSError:
            return ""
    return ""


def write_json_seed(name: str, targets: list[str]) -> None:
    encoded = read_secret(name)
    if not encoded:
        return
    try:
        payload = base64.b64decode(encoded).decode("utf-8")
    except Exception:
        return
    for target in targets:
        path = Path(target)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(payload, encoding="utf-8")
        os.chmod(path, 0o600)


runtime_home = Path(os.getenv("HOME") or "/tmp")
write_json_seed(
    "CLAUDE_CREDENTIALS_JSON_B64",
    [
        "/data/.tooling/auth/claude.credentials.json",
        str(runtime_home / ".claude" / ".credentials.json"),
    ],
)
write_json_seed(
    "CODEX_AUTH_JSON_B64",
    [
        "/data/.tooling/auth/codex-auth.json",
        str(runtime_home / ".codex" / "auth.json"),
    ],
)
PY

if command -v npm >/dev/null 2>&1; then
  command -v claude >/dev/null 2>&1 || npm -g install @anthropic-ai/claude-code >>/data/.tooling/cli-bootstrap.log 2>&1 || true
  command -v codex >/dev/null 2>&1 || npm -g install @openai/codex >>/data/.tooling/cli-bootstrap.log 2>&1 || true
  command -v gemini >/dev/null 2>&1 || npm -g install @google/gemini-cli >>/data/.tooling/cli-bootstrap.log 2>&1 || true
fi

for bin in claude codex gemini; do
  p="$(command -v "$bin" 2>/dev/null || true)"
  if [ -n "$p" ]; then
    chmod 755 "$p" 2>/dev/null || true
  fi
done

codex_bin="$(command -v codex 2>/dev/null || true)"
if [ -n "${codex_bin}" ]; then
  codex_real="$(dirname "${codex_bin}")/codex-real"
  if [ ! -x "${codex_real}" ]; then
    mv "${codex_bin}" "${codex_real}"
    cat >"${codex_bin}" <<'SH'
#!/usr/bin/env bash
set -eu
real_bin="$(dirname "$0")/codex-real"
args=()
for arg in "$@"; do
  case "$arg" in
    --color|--color=*)
      continue
      ;;
  esac
  args+=("$arg")
done
exec "${real_bin}" "${args[@]}"
SH
    chmod 755 "${codex_bin}" 2>/dev/null || true
  fi
fi

python3 - <<'PY'
from __future__ import annotations

import json
import os
from pathlib import Path

TARGETS = [
    Path("/data/.openclaw/agents/main/agent/auth-profiles.json"),
    Path("/data/.openclaw/agents/default/agent/auth-profiles.json"),
    Path("/data/.openclaw/auth-profiles.json"),
]


def read_secret(name: str) -> str:
    direct = str(os.getenv(name, "")).strip()
    if direct:
        return direct
    from_file = str(os.getenv(f"{name}_FILE", "")).strip()
    if from_file:
        try:
            return Path(from_file).read_text(encoding="utf-8").strip()
        except OSError:
            return ""
    return ""


def load_existing() -> dict[str, dict[str, str]]:
    merged: dict[str, dict[str, str]] = {}
    for path in TARGETS:
        if not path.exists():
            continue
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(raw, dict):
            continue
        for provider, payload in raw.items():
            if not isinstance(payload, dict):
                continue
            key = str(payload.get("apiKey") or "").strip()
            if key:
                merged[str(provider)] = {"apiKey": key}
    return merged


profiles = load_existing()
provider_env = {
    "anthropic": "ANTHROPIC_API_KEY",
    "openai": "OPENAI_API_KEY",
    "google": "GOOGLE_API_KEY",
    "nvidia": "NVIDIA_API_KEY",
}

for provider, env_name in provider_env.items():
    secret = read_secret(env_name)
    if secret:
        profiles[provider] = {"apiKey": secret}

if profiles:
    payload = json.dumps(profiles, indent=2, sort_keys=True)
    for path in TARGETS:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(payload, encoding="utf-8")

model_id = str(os.getenv("MODEL") or os.getenv("MODEL_PRIMARY") or "").strip()
fallbacks_value = str(os.getenv("MODEL_FALLBACKS") or "").strip()
fallback_models = [part.strip() for part in fallbacks_value.split(",") if part.strip()]
container_tag = str(os.getenv("SUPERMEMORY_CONTAINER") or "").strip()
config_path = Path("/data/.openclaw/openclaw.json")
if config_path.exists() and (model_id or fallback_models or container_tag):
    try:
        data = json.loads(config_path.read_text(encoding="utf-8"))
    except Exception:
        data = None
    if isinstance(data, dict):
        changed = False
        for key in ("model", "defaultModel", "primaryModel"):
            if data.pop(key, None) is not None:
                changed = True

        agents = data.get("agents")
        if not isinstance(agents, dict):
            agents = {}
            data["agents"] = agents
            changed = True
        defaults = agents.get("defaults")
        if not isinstance(defaults, dict):
            defaults = {}
            agents["defaults"] = defaults
            changed = True
        model_obj = defaults.get("model")
        if not isinstance(model_obj, dict):
            model_obj = {}
            defaults["model"] = model_obj
            changed = True
        if model_obj.get("primary") != model_id:
            model_obj["primary"] = model_id
            changed = True
        if model_obj.get("fallbacks") != fallback_models:
            model_obj["fallbacks"] = fallback_models
            changed = True

        tools = data.get("tools")
        if not isinstance(tools, dict):
            tools = {}
            data["tools"] = tools
            changed = True
        if tools.get("profile") != "coding":
            tools["profile"] = "coding"
            changed = True

        if container_tag:
            memory = data.get("memory")
            if not isinstance(memory, dict):
                memory = {}
                data["memory"] = memory
                changed = True
            if memory.get("backend") != "supermemory":
                memory["backend"] = "supermemory"
                changed = True
            if memory.get("citations") != "auto":
                memory["citations"] = "auto"
                changed = True
            supermemory = memory.get("supermemory")
            if not isinstance(supermemory, dict):
                supermemory = {}
                memory["supermemory"] = supermemory
                changed = True
            if supermemory.get("containerTag") != container_tag:
                supermemory["containerTag"] = container_tag
                changed = True

        if changed:
            config_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
PY

chmod 600 /data/.openclaw/agents/main/agent/auth-profiles.json 2>/dev/null || true
chmod 600 /data/.openclaw/agents/default/agent/auth-profiles.json 2>/dev/null || true
chmod 600 /data/.openclaw/auth-profiles.json 2>/dev/null || true
EOS

  log "container=${container} phase=done"
}

preflight_container() {
  local container="$1"
  local required_cli="$2"
  local api_env="$3"
  local require_cli="${4:-false}"
  local mode="${5:-cli_or_api}"

  local output
  output="$(
    docker exec -i "${container}" sh -lc "
set -eu
cli_ok=0
if [ -n '${required_cli}' ] && command -v '${required_cli}' >/dev/null 2>&1; then
  cli_ok=1
fi
api_ok=0
api_val=\$(printenv '${api_env}' || true)
if [ -n \"\${api_val}\" ]; then
  api_ok=1
fi
api_file=\$(printenv '${api_env}_FILE' || true)
if [ -n \"\${api_file}\" ] && [ -r \"\${api_file}\" ] && [ -s \"\${api_file}\" ]; then
  api_ok=1
fi
if [ '${mode}' = 'api_only' ]; then
  [ \${api_ok} -eq 1 ] && echo ok || echo fail
else
  if [ '${require_cli}' = 'true' ]; then
    [ \${cli_ok} -eq 1 ] && echo ok || echo fail
  else
    [ \${cli_ok} -eq 1 ] || [ \${api_ok} -eq 1 ] && echo ok || echo fail
  fi
fi
" 2>/dev/null || echo "fail"
  )"

  if [ "${output}" = "ok" ]; then
    log "container=${container} preflight=ok cli=${required_cli:-none} api_env=${api_env} mode=${mode}"
    return 0
  fi

  log "container=${container} preflight=failed cli=${required_cli:-none} api_env=${api_env} mode=${mode}"
  return 1
}

for container in "${TARGET_CONTAINERS[@]}"; do
  if ! bootstrap_container "${container}"; then
    log "container=${container} phase=failed"
  fi

  case "${container}" in
    *friday* )
      preflight_container "${container}" "claude" "ANTHROPIC_API_KEY" "false" "cli_or_api" || true
      ;;
    *arsenal* )
      preflight_container "${container}" "codex" "OPENAI_API_KEY" "false" "cli_or_api" || true
      ;;
    *edith* )
      preflight_container "${container}" "gemini" "GOOGLE_API_KEY" "false" "cli_or_api" || true
      ;;
    *jocasta* )
      preflight_container "${container}" "" "NVIDIA_API_KEY" "false" "api_only" || true
      ;;
  esac
done

log "status=complete containers=${#TARGET_CONTAINERS[@]}"
