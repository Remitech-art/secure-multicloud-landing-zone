terraform {
  backend "gcs" {
    bucket = "secure-multicloud-terraform-state"
    prefix = "gcp/landing-zone/terraform/state"
  }
}
