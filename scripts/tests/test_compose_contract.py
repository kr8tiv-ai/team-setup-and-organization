from pathlib import Path


def test_agent_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/agent-template.yml").read_text(encoding="utf-8")
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content


def test_mission_control_template_has_restart_healthcheck_and_watchdog_label() -> None:
    content = Path("docker-templates/mission-control.yml").read_text(encoding="utf-8")
    assert "restart: unless-stopped" in content
    assert "healthcheck:" in content
    assert "com.kr8tiv.watchdog" in content
