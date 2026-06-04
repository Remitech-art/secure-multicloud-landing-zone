output "security_service_account_email" {
  description = "Email of the security service account." 
  value       = google_service_account.security_scanner.email
}
