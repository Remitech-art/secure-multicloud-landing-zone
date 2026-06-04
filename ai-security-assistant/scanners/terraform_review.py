from pathlib import Path

KEYWORDS = ["admin", "*", "roles/owner", "allow", "disable"]


def scan_terraform(path: Path):
    if path.is_dir():
        files = list(path.rglob("*.tf"))
    else:
        files = [path]

    findings = []
    for tf_file in files:
        content = tf_file.read_text(encoding="utf-8")
        if "roles/owner" in content:
            findings.append(f"Owner role found in {tf_file}")
        if "google_project_iam_member" in content and "roles/iam.serviceAccountUser" in content:
            findings.append(f"Service account user binding detected in {tf_file}")
        if "enable_logging" in content and "false" in content:
            findings.append(f"Logging may be disabled in {tf_file}")
    return findings
