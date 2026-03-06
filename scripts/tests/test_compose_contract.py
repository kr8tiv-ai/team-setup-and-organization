from pathlib import Path


def test_agent_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "image: ghcr.io/openclaw/openclaw:2026.3.2" in content
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content


def test_agent_template_bootstraps_cli_tools_into_persistent_path() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "entrypoint:" in content
    assert "NPM_CONFIG_PREFIX=/data/.tooling/npm-global" in content
    assert "/data/.tooling/npm-global/bin" in content
    assert "npm -g install @anthropic-ai/claude-code" in content
    assert "npm -g install @openai/codex" in content
    assert "npm -g install @google/gemini-cli" in content


def test_agent_template_accepts_cli_auth_seed_env() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "CLAUDE_CREDENTIALS_JSON_B64" in content
    assert "CODEX_AUTH_JSON_B64" in content


def test_agent_template_uses_secret_files_for_all_supported_llm_runtimes() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "ANTHROPIC_API_KEY_FILE: /run/secrets/anthropic_api_key" in content
    assert "OPENAI_API_KEY_FILE: /run/secrets/openai_api_key" in content
    assert "GOOGLE_API_KEY_FILE: /run/secrets/google_api_key" in content
    assert "NVIDIA_API_KEY_FILE: /run/secrets/nvidia_api_key" in content


def test_mission_control_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/mission-control.yml").read_text(encoding="utf-8")
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content


def test_setup_script_installs_reconcile_timer() -> None:
    content = Path("scripts/setup-infrastructure.sh").read_text(encoding="utf-8")
    assert "reconcile-agent-auth.sh" in content
    assert "kr8tiv-agent-reconcile.service" in content
    assert "kr8tiv-agent-reconcile.timer" in content


def test_reconcile_script_and_units_exist() -> None:
    assert Path("scripts/runtime/reconcile-agent-auth.sh").exists()
    assert Path("deploy/systemd/kr8tiv-agent-reconcile.service").exists()
    assert Path("deploy/systemd/kr8tiv-agent-reconcile.timer").exists()


def test_cli_bootstrap_script_and_units_exist() -> None:
    assert Path("scripts/runtime/bootstrap-openclaw-cli-auth.sh").exists()
    assert Path("deploy/systemd/kr8tiv-cli-bootstrap.service").exists()
    assert Path("deploy/systemd/kr8tiv-cli-bootstrap.timer").exists()


def test_cli_bootstrap_script_uses_persistent_tooling_prefix() -> None:
    content = Path("scripts/runtime/bootstrap-openclaw-cli-auth.sh").read_text(
        encoding="utf-8"
    )
    assert "NPM_CONFIG_PREFIX=/data/.tooling/npm-global" in content
    assert "/data/.tooling/npm-global/bin" in content


def test_cli_bootstrap_script_writes_persistent_cli_auth_stores() -> None:
    content = Path("scripts/runtime/bootstrap-openclaw-cli-auth.sh").read_text(
        encoding="utf-8"
    )
    assert "CLAUDE_CREDENTIALS_JSON_B64" in content
    assert "CODEX_AUTH_JSON_B64" in content
    assert 'runtime_home = Path(os.getenv("HOME") or "/tmp")' in content
    assert 'str(runtime_home / ".claude" / ".credentials.json")' in content
    assert 'str(runtime_home / ".codex" / "auth.json")' in content
    assert "/data/.tooling/auth" in content


def test_setup_script_installs_cli_bootstrap_timer() -> None:
    content = Path("scripts/setup-infrastructure.sh").read_text(encoding="utf-8")
    assert "bootstrap-openclaw-cli-auth.sh" in content
    assert "kr8tiv-cli-bootstrap.service" in content
    assert "kr8tiv-cli-bootstrap.timer" in content
