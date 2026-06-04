from pathlib import Path

RISK_WEIGHTS = {
    "terraform": 3,
    "iam": 2,
    "cloud": 2,
    "compliance": 3,
}


def score_findings(findings):
    score = 0
    for category, items in findings.items():
        weight = RISK_WEIGHTS.get(category, 1)
        score += min(len(items), 5) * weight
    return max(0, min(10, 10 - score // 3))


def build_summary(findings):
    score = score_findings(findings)
    summary = {
        "score": score,
        "status": "Pass" if score >= 7 else "Review Required",
        "highlights": [],
    }

    if findings.get("terraform"):
        summary["highlights"].append("Terraform security issues detected.")
    if findings.get("iam"):
        summary["highlights"].append("IAM risk conditions require review.")
    if findings.get("cloud"):
        summary["highlights"].append("Cloud configuration hardening needed.")
    if findings.get("compliance"):
        summary["highlights"].append("Non-compliant controls were detected.")

    if not summary["highlights"]:
        summary["highlights"].append("No critical risks detected.")

    return summary
