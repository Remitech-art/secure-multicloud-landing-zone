resource "google_project_iam_member" "platform_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.platform.email}"
}

resource "google_project_iam_member" "platform_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.platform.email}"
}

resource "google_project_iam_member" "platform_security_admin" {
  project = var.project_id
  role    = "roles/securitycenter.admin"
  member  = "serviceAccount:${google_service_account.platform.email}"
}

resource "google_project_iam_member" "platform_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.platform.email}"
}

resource "google_security_center_organization_settings" "scc_settings" {
  count           = var.enable_security_center && length(trimspace(var.org_id)) > 0 ? 1 : 0
  org_id          = var.org_id
  enable_asset_discovery = true
  finding_export_config {
    destination = "projects/${var.project_id}"
  }
}

resource "google_project_iam_member" "scc_ingest" {
  count   = var.enable_security_center && length(trimspace(var.org_id)) > 0 ? 1 : 0
  project = var.project_id
  role    = "roles/securitycenter.findingsEditor"
  member  = "serviceAccount:${google_service_account.platform.email}"
}
