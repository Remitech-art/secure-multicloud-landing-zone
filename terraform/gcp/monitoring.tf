resource "google_logging_project_sink" "audit_sink" {
  name        = "secure-multicloud-audit-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.artifacts.name}"
  project     = var.project_id
  filter      = "logName=\"projects/${var.project_id}/logs/cloudaudit.googleapis.com%2Factivity\""
  unique_writer_identity = true
}

resource "google_monitoring_alert_policy" "high_severity" {
  display_name = "High Severity Security Events"
  combiner     = "OR"
  conditions {
    display_name = "Audit log error or security finding"
    condition_threshold {
      filter = "resource.type = \"gce_instance\" AND metric.type = \"logging/user/latency\""
      comparison = "COMPARISON_GT"
      threshold_value = 0
      duration = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  notification_channels = []
  enabled = true
}
