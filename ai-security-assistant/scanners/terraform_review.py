from pathlib import Path
import re

RULES = [
    {
        "id": "TF001",
        "pattern": r"roles/owner",
        "message": "Owner role found in Terraform; use least-privilege roles instead.",
        "remediation": "Replace wide owner assignments with scoped role definitions."
    },
    {
        "id": "TF002",
        "pattern": r"0\.0\.0\.0/0",
        "message": "Open network access detected in Terraform; tighten CIDR ranges for public and admin access.",
        "remediation": "Replace wildcard CIDRs with approved IP ranges or managed access controls."
    },
    {
        "id": "TF003",
        "pattern": r"enable_logging\s*=\s*false",
        "message": "Logging is disabled in Terraform configuration.",
        "remediation": "Enable resource logging and monitoring for audit visibility."
    },
    {
        "id": "TF004",
        "pattern": r"google_project_iam_member[\s\S]*?roles/iam\.serviceAccountUser",
        "message": "Service account user binding found; review whether the service account needs this permission.",
        "remediation": "Audit service account roles and reduce to only required permissions."
    }
]


def scan_terraform(path: Path):
    if path.is_dir():
        files = list(path.rglob("*.tf"))
    else:
        files = [path]

    findings = []
    for tf_file in files:
        content = tf_file.read_text(encoding="utf-8")
        for rule in RULES:
            if re.search(rule["pattern"], content, re.IGNORECASE | re.MULTILINE):
                findings.append(f"{rule['id']}: {rule['message']} ({tf_file})")
    return sorted(set(findings))
