variable "falcon_cloud" {
  description = "CrowdStrike Falcon Cloud Region (us-1, us-2, or eu-1)"
  type        = string
  default     = "us-1"
}

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

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN"
  type        = string
  default     = null
}

variable "linux_sensor_version" {
  description = "Specific Linux sensor version to deploy (leave empty for latest)"
  type        = string
  default     = ""
}

variable "windows_sensor_version" {
  description = "Specific Windows sensor version to deploy (leave empty for latest)"
  type        = string
  default     = ""
}
