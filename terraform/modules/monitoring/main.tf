resource "google_logging_project_sink" "module_audit_sink" {
  name        = "module-audit-sink"
  destination = "storage.googleapis.com/${var.bucket_name}"
  project     = var.project_id
  filter      = "logName:\"projects/${var.project_id}/logs/cloudaudit.googleapis.com%2Factivity\""
  unique_writer_identity = true
}

resource "google_monitoring_alert_policy" "security_alert" {
  display_name = "Module Security Alert Policy"
  combiner     = "OR"
  conditions {
    display_name = "Unauthorized access attempt"
    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND metric.type = \"logging/user/latency\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  enabled = true
}
