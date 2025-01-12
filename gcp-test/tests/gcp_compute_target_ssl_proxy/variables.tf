
variable "resource_name" {
  type        = string
  default     = "turbot-test-20200125-create-update"
  description = "Name of the resource used throughout the test."
}

variable "gcp_project" {
  type        = string
  default     = "niteowl-aaa"
  description = "GCP project used for the test."
}

variable "gcp_region" {
  type        = string
  default     = "us-east1"
  description = "GCP region used for the test."
}

variable "gcp_zone" {
  type    = string
  default = "us-east1-b"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

data "google_client_config" "current" {}

data "null_data_source" "resource" {
  inputs = {
    scope = "gcp://cloudresourcemanager.googleapis.com/projects/${data.google_client_config.current.project}"
  }
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "self_signed_certificate" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "${var.resource_name}.com"
    organization = "Turbot"
  }

  validity_period_hours = 2

  allowed_uses = [
    "any_extended",
    "cert_signing",
    "client_auth",
    "code_signing",
    "content_commitment",
    "crl_signing",
    "data_encipherment",
    "decipher_only",
    "digital_signature",
    "email_protection",
    "encipher_only",
    "ipsec_end_system",
    "ipsec_tunnel",
    "ipsec_user",
    "key_agreement",
    "key_encipherment",
    "microsoft_server_gated_crypto",
    "netscape_server_gated_crypto",
    "ocsp_signing",
    "server_auth",
    "timestamping"
  ]
}

resource "google_compute_target_ssl_proxy" "named_test_resource" {
  name             = var.resource_name
  description      = "Test target ssl proxy to validate the table outcome."
  backend_service  = google_compute_backend_service.named_test_resource.id
  ssl_certificates = [google_compute_ssl_certificate.named_test_resource.id]
}

resource "google_compute_ssl_certificate" "named_test_resource" {
  name        = var.resource_name
  private_key = tls_private_key.private_key.private_key_pem
  certificate = tls_self_signed_cert.self_signed_certificate.cert_pem
}

resource "google_compute_backend_service" "named_test_resource" {
  name          = var.resource_name
  protocol      = "SSL"
  health_checks = [google_compute_health_check.named_test_resource.id]
}

resource "google_compute_health_check" "named_test_resource" {
  name               = var.resource_name
  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "443"
  }
}

output "resource_aka" {
  value = "gcp://compute.googleapis.com/${google_compute_target_ssl_proxy.named_test_resource.id}"
}

output "resource_name" {
  value = var.resource_name
}

output "proxy_id" {
  value = google_compute_target_ssl_proxy.named_test_resource.proxy_id
}

output "resource_id" {
  value = google_compute_target_ssl_proxy.named_test_resource.id
}

output "self_link" {
  value = google_compute_target_ssl_proxy.named_test_resource.self_link
}

output "certificate_id" {
  value = google_compute_ssl_certificate.named_test_resource.self_link
}

output "backend_service" {
  value = google_compute_backend_service.named_test_resource.self_link
}

output "project_id" {
  value = var.gcp_project
}
