resource "google_service_account" "security_scanner" {
  account_id   = "secure-multicloud-security"
  display_name = "Secure Multicloud Security Service Account"
  project      = var.project_id
}

resource "google_project_iam_member" "logging_role" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.security_scanner.email}"
}

resource "google_project_iam_member" "monitoring_role" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.security_scanner.email}"
}

resource "google_project_iam_member" "scc_admin" {
  count   = var.enable_security_center && length(trimspace(var.org_id)) > 0 ? 1 : 0
  project = var.project_id
  role    = "roles/securitycenter.admin"
  member  = "serviceAccount:${google_service_account.security_scanner.email}"
}

resource "google_security_center_organization_settings" "scc_settings" {
  count                 = var.enable_security_center && length(trimspace(var.org_id)) > 0 ? 1 : 0
  org_id                = var.org_id
  enable_asset_discovery = true
}
