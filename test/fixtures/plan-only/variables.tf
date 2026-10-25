variable "project_id" {
  description = "GCP project ID (mock_provider ignores this in plan-only)"
  type        = string
  default     = "test-project"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "prefix" {
  description = "Resource prefix for isolation"
  type        = string
  default     = "planmock"
}
