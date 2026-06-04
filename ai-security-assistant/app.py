import argparse
from pathlib import Path

from scanners.terraform_review import scan_terraform
from scanners.iam_analysis import scan_iam
from scanners.cloud_config import scan_cloud_config

OUTPUT_REPORT = Path(__file__).resolve().parent / "reports" / "summary_report.md"


def build_report(results):
    sections = [
        "# AI Security Assistant Report\n",
        "## Terraform Review\n",
        "- " + "\n- ".join(results["terraform"]) if results["terraform"] else "No issues found.",
        "\n## IAM Analysis\n",
        "- " + "\n- ".join(results["iam"]) if results["iam"] else "No issues found.",
        "\n## Cloud Configuration Analysis\n",
        "- " + "\n- ".join(results["cloud"]) if results["cloud"] else "No issues found.",
        "\n## Risk Scoring\n",
        f"- Overall risk score: {results['risk_score']}/10\n",
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
    args = parser.parse_args()

    terraform_results = scan_terraform(args.terraform) if args.terraform else []
    iam_results = scan_iam(args.iam) if args.iam else []
    cloud_results = scan_cloud_config(args.cloud) if args.cloud else []

    risk_score = min(10, len(terraform_results) + len(iam_results) + len(cloud_results))
    recommendations = []
    if terraform_results:
        recommendations.append("Review Terraform findings and apply least-privilege IAM and network segmentation.")
    if iam_results:
        recommendations.append("Refine IAM policies to remove broad roles and unused permissions.")
    if cloud_results:
        recommendations.append("Harden cloud configuration and enable continuous monitoring for security events.")
    if not recommendations:
        recommendations.append("Maintain current secure configuration and validate periodically.")

    report = build_report({
        "terraform": terraform_results,
        "iam": iam_results,
        "cloud": cloud_results,
        "risk_score": risk_score,
        "recommendations": recommendations,
    })

    if args.report:
        OUTPUT_REPORT.write_text(report)
        print(f"Report generated at {OUTPUT_REPORT}")
    else:
        print(report)


if __name__ == "__main__":
    main()
