from pathlib import Path


def scan_iam(path: Path):
    if path.is_dir():
        files = list(path.rglob("*.json")) + list(path.rglob("*.yaml")) + list(path.rglob("*.yml"))
    else:
        files = [path]

    findings = []
    for iam_file in files:
        text = iam_file.read_text(encoding="utf-8")
        if "roles/owner" in text or "roles/editor" in text:
            findings.append(f"High privilege role found in {iam_file}")
        if "*" in text and "roles" in text:
            findings.append(f"Wildcard role assignment detected in {iam_file}")
    return findings
