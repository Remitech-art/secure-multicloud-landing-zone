locals {
  service_account_id = "secure-multicloud-sa"
}

resource "google_project_service" "enabled_apis" {
  project = var.project_id
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
    "securitycenter.googleapis.com"
  ])
  service = each.key
}

resource "google_service_account" "platform" {
  account_id   = local.service_account_id
  display_name = "Secure Multicloud Platform Service Account"
  project      = var.project_id
}

module "networking" {
  source       = "../modules/networking"
  project_id   = var.project_id
  region       = var.region
  network_name = var.network_name
  subnets      = var.subnets
}

module "storage" {
  source      = "../modules/storage"
  project_id  = var.project_id
  bucket_name = var.bucket_name
  service_account_email = google_service_account.platform.email
}

module "security" {
  source      = "../modules/security"
  project_id  = var.project_id
  org_id      = var.org_id
  service_account_email = google_service_account.platform.email
  enable_security_center = var.enable_security_center
}

module "monitoring" {
  source      = "../modules/monitoring"
  project_id  = var.project_id
  bucket_name = module.storage.bucket_name
}
