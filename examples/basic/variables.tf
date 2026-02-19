variable "falcon_client_id" {
  description = "CrowdStrike Falcon API Client ID"
  type        = string
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon API Client Secret"
  type        = string
  sensitive   = true
}
