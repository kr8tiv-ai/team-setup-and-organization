# Agent Resilience Runbook

This runbook defines persistence and deterministic recovery for FRIDAY, ARSENAL, JOCASTA, and EDITH.

## Objectives

- Agents auto-restart on host reboot or process crash.
- Exactly one recovery owner acts when a peer is down.
- Secret values stay out of repo files and are injected at runtime only.
- Model routes remain pinned unless explicitly changed through Mission Control policy.

## Runtime Model Policy

- FRIDAY: `anthropic/claude-opus-4-6` (API path)
- ARSENAL: `anthropic/claude-opus-4-6` (API path)
- JOCASTA: `anthropic/claude-opus-4-6` (API path)
- EDITH: `anthropic/claude-opus-4-6` (API path)

Do not let agents self-edit model routes at runtime.

## Recovery Delegation

Recovery order:
1. FRIDAY
2. ARSENAL
3. JOCASTA
4. EDITH

Rules:
- Down agent cannot self-assign recovery.
- Non-owner agents do not run competing restart attempts.
- Recovery attempts are logged with UTC timestamps.

## Required Host Automation

Installed by `scripts/setup-infrastructure.sh`:

- `/root/backup-containers.sh` (daily 2 AM)
- `/root/agent-recovery-orchestrator.sh` (every 2 minutes)

## Compose Policy Contracts

- Every production service must set `restart: unless-stopped`.
- Every production service must define a `healthcheck`.
- Every service participating in runtime remediation must include `com.kr8tiv.watchdog: "enabled"`.
- Agent templates should include `com.kr8tiv.recovery-window-seconds: "120"` to align with the watchdog SLO.

## Verification Commands

```bash
docker ps --format '{{.Names}}|{{.Status}}'
crontab -l | grep -E 'backup-containers|agent-recovery-orchestrator'
tail -n 100 /var/log/agent-recovery.log
tail -n 100 /var/log/container-backup.log
```

## Cross-Repo Smoke Verification

After template changes are deployed, run the resilience smoke protocol from
`kr8tiv-team-execution-resilience`:

```bash
bash scripts/smoke_verify_recovery.sh --dry-run
```

Expected checks:

- `CHECK telegram_ingress`
- `CHECK agent_health_matrix`
- `CHECK gsd_stage_guards`
- `CHECK recovery_under_120s`

## Secret Hygiene

- Keep `docker-templates/*.yml` public-safe.
- Use `*_FILE` env patterns and mounted secret files.
- Do not commit `.env` values, key files, token files, or OAuth caches.
