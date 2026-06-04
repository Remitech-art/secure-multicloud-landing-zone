import argparse
from pathlib import Path

from scanners.terraform_review import scan_terraform
from scanners.iam_analysis import scan_iam
from scanners.cloud_config import scan_cloud_config
from compliance_checker import scan_compliance

OUTPUT_REPORT = Path(__file__).resolve().parent / "reports" / "summary_report.md"


def build_report(results):
    sections = [
        "# AI Security Assistant Report\n",
        "## Terraform Review\n",
        "- " + "\n- ".join(results["terraform"]) if results["terraform"] else "No issues found.",
        "\n## Compliance Findings\n",
        "- " + "\n- ".join(results.get("compliance", [])) if results.get("compliance") else "No compliance issues found.",
        "\n## IAM Analysis\n",
        "- " + "\n- ".join(results["iam"]) if results["iam"] else "No issues found.",
        "\n## Cloud Configuration Analysis\n",
        "- " + "\n- ".join(results["cloud"]) if results["cloud"] else "No issues found.",
        "\n## Risk Scoring\n",
        f"- Overall risk score: {results['risk_score']}/10\n",
        f"- Risk level: {results['risk_level']}\n",
        "## Remediation Recommendations\n",
        "- " + "\n- ".join(results["recommendations"]) if results["recommendations"] else "No recommendations available."
    ]
    return "\n".join(sections)


def main():
    parser = argparse.ArgumentParser(description="AI Security Assistant starter tool")
    parser.add_argument("--terraform", type=Path, help="Path to Terraform files or directory")
    parser.add_argument("--iam", type=Path, help="Path to IAM policy files or directory")
    parser.add_argument("--cloud", type=Path, help="Path to cloud configuration files")
    parser.add_argument("--report", action="store_true", help="Generate markdown report")
    parser.add_argument("--json-output", type=Path, help="Write structured JSON output to file")
    args = parser.parse_args()

    terraform_results = scan_terraform(args.terraform) if args.terraform else []
    iam_results = scan_iam(args.iam) if args.iam else []
    cloud_results = scan_cloud_config(args.cloud) if args.cloud else []
    compliance_results = []
    if args.terraform:
        compliance_results = scan_compliance(args.terraform)

    risk_score = min(10, len(terraform_results) + len(iam_results) + len(cloud_results) + len(compliance_results))
    risk_level = "Low"
    if risk_score >= 7:
        risk_level = "High"
    elif risk_score >= 4:
        risk_level = "Medium"

    recommendations = []
    if terraform_results:
        recommendations.append("Review Terraform findings and apply least-privilege IAM and network segmentation.")
    if compliance_results:
        recommendations.append("Resolve compliance findings by restricting public access and removing broad role assignments.")
    if iam_results:
        recommendations.append("Refine IAM policies to remove broad roles and unused permissions.")
    if cloud_results:
        recommendations.append("Harden cloud configuration and enable continuous monitoring for security events.")
    if not recommendations:
        recommendations.append("Maintain current secure configuration and validate periodically.")

    report = build_report({
        "terraform": terraform_results,
        "compliance": compliance_results,
        "iam": iam_results,
        "cloud": cloud_results,
        "risk_score": risk_score,
        "risk_level": risk_level,
        "recommendations": recommendations,
    })

    # ensure reports directory exists
    reports_dir = OUTPUT_REPORT.parent
    reports_dir.mkdir(parents=True, exist_ok=True)

    if args.json_output:
        import json
        output = {
            "terraform_findings": terraform_results,
            "compliance_findings": compliance_results,
            "iam_findings": iam_results,
            "cloud_findings": cloud_results,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "recommendations": recommendations,
        }
        args.json_output.write_text(json.dumps(output, indent=2))
        print(f"JSON report written to {args.json_output}")

    if args.report:
        OUTPUT_REPORT.write_text(report)
        print(f"Report generated at {OUTPUT_REPORT}")
    else:
        print(report)


if __name__ == "__main__":
    main()
