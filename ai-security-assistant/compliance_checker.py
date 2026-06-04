from pathlib import Path
import re

COMPLIANCE_RULES = [
    "no-public-s3",
    "no-wide-iam-permissions",
    "logging-enabled",
    "secret-manager-enabled",
    "network-deny-by-default",
]


def scan_compliance(path: Path):
    findings = []
    if path.is_dir():
        files = list(path.rglob("*.tf")) + list(path.rglob("*.yaml")) + list(path.rglob("*.yml"))
    else:
        files = [path]

    for file in files:
        text = file.read_text(encoding="utf-8")
        if re.search(r"0\.0\.0\.0/0", text):
            findings.append(f"C001: Open network access detected in {file}")
        if re.search(r"roles/(owner|editor)", text, re.IGNORECASE):
            findings.append(f"C002: Overly broad IAM role definition detected in {file}")
        if re.search(r"enable_logging\s*=\s*false", text, re.IGNORECASE):
            findings.append(f"C003: Logging appears disabled in {file}")
        if re.search(r"resource \"google_storage_bucket\"[\s\S]*?acl\s*=\s*\"public-read\"", text, re.IGNORECASE):
            findings.append(f"C004: Public storage ACL found in {file}")
    return sorted(set(findings))
