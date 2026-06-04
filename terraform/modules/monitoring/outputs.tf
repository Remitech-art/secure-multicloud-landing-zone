output "logging_sink_name" {
  description = "The name of the created logging sink." 
  value       = google_logging_project_sink.module_audit_sink.name
}

output "alert_policy_name" {
  description = "The name of the alert policy created for monitoring."
  value       = google_monitoring_alert_policy.security_alert.name
}
