from pathlib import Path


def test_agent_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content


def test_agent_template_uses_anthropic_secret_file_only_for_llm_runtime() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "ANTHROPIC_API_KEY_FILE: /run/secrets/anthropic_api_key" in content
    assert "openai_api_key" not in content
    assert "gemini_api_key" not in content
    assert "nvidia_api_key" not in content


def test_mission_control_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/mission-control.yml").read_text(encoding="utf-8")
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content
