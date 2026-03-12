terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

variable "falcon_client_id" {
  type        = string
  sensitive   = true
  description = "Falcon API Client ID"
}

variable "falcon_client_secret" {
  type        = string
  sensitive   = true
  description = "Falcon API Client Secret"
}

locals {
  regions                     = ["us-east-1", "us-west-2"]
  falcon_cloud                = "us-1"
  action                      = "Install" # or "Uninstall"
  secret_storage_method       = "ParameterStore"
  cron_schedule_expression    = "cron(0 2 ? * * *)"
  apply_only_at_cron_interval = false
  linux_package_version       = ""
  windows_package_version     = ""
  create_kms_key              = false
}

provider "aws" {
  region = "us-east-1"
}

module "crowdstrike_distributor" {
  source = "CrowdStrike/ssm-distributor/aws"

  # Multi-region deployment
  regions = local.regions

  # CrowdStrike credentials
  falcon_cloud         = local.falcon_cloud
  falcon_client_id     = var.falcon_client_id
  falcon_client_secret = var.falcon_client_secret

  # Action: Install or Uninstall
  action = local.action

  # Credential storage
  secret_storage_method = local.secret_storage_method

  # Deployment schedule
  cron_schedule_expression    = local.cron_schedule_expression
  apply_only_at_cron_interval = local.apply_only_at_cron_interval

  # Package versions (optional - leave empty for latest)
  linux_package_version   = local.linux_package_version
  windows_package_version = local.windows_package_version

  # Encryption (optional)
  create_kms_key = local.create_kms_key

  # Tags
  tags = {
    Environment = "production"
    Team        = "security"
  }
}
