from pathlib import Path


def scan_cloud_config(path: Path):
    if path.is_dir():
        files = list(path.rglob("*.yaml")) + list(path.rglob("*.yml")) + list(path.rglob("*.json"))
    else:
        files = [path]

    findings = []
    for cfg in files:
        text = cfg.read_text(encoding="utf-8")
        if "public" in text and "access" in text:
            findings.append(f"Potential public access configuration found in {cfg}")
        if "security_center" in text and "enabled: false" in text:
            findings.append(f"Security Command Center appears disabled in {cfg}")
    return findings
