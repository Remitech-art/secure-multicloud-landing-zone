from pathlib import Path

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
        if "0.0.0.0/0" in text and "cidr" in text:
            findings.append("Potential open network access in {}".format(file))
        if "roles/owner" in text or "Owner" in text:
            findings.append("Potential overly broad IAM role use in {}".format(file))
        if "enable_logging" in text and "false" in text:
            findings.append("Logging appears disabled in {}".format(file))
    return findings
