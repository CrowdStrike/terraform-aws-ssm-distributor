# Advanced CrowdStrike Falcon Sensor Deployment Example

module "crowdstrike_distributor" {
  source = "../../"

  # Multi-region deployment
  regions = ["us-east-1", "us-west-2", "eu-west-1"]

  # CrowdStrike API credentials
  falcon_cloud         = var.falcon_cloud
  falcon_client_id     = var.falcon_client_id
  falcon_client_secret = var.falcon_client_secret

  # Action: Install the sensor
  action = "Install"

  # Use Secrets Manager for production security
  secret_storage_method       = "SecretsManager"
  secrets_manager_secret_name = "production/crowdstrike/falcon"

  # Enable customer-managed KMS encryption
  create_kms_key = true
  kms_key_alias  = "crowdstrike-falcon-prod"

  # IAM configuration
  iam_role_name        = "CrowdStrikeFalconAutomation"
  permissions_boundary = var.permissions_boundary_arn

  # Association configuration
  association_name_prefix     = "production"
  cron_schedule_expression    = "cron(0 2 ? * * *)" # Daily at 2 AM UTC
  association_max_concurrency = "25%"
  association_max_errors      = "5"

  # Package versions (optional)
  linux_package_version   = var.linux_sensor_version
  windows_package_version = var.windows_sensor_version

  # Installer parameters for sensor tagging
  linux_installer_params   = "--tags=Environment:Production,ManagedBy:Terraform"
  windows_installer_params = "/tags=Environment:Production,ManagedBy:Terraform"

  # Optional: target only specific EC2 instances.
  # Note: CrowdStrike-FalconSensorDeploy is an Automation document — only one tag key is
  # supported. To AND multiple tags, use an AWS Resource Group.
  #
  # Target by single tag:
  # association_targets = { key = "tag:Environment", values = ["production"] }
  #
  # Target by AWS Resource Group (supports multi-tag AND filtering):
  # association_targets = { key = "ResourceGroup", values = ["my-crowdstrike-targets"] }

  # Comprehensive tagging
  tags = {
    Environment = "production"
    Application = "crowdstrike-falcon"
    ManagedBy   = "terraform"
    CostCenter  = "security"
    Compliance  = "required"
    Team        = "security-operations"
  }
}
