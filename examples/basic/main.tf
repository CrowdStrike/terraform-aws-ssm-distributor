# Basic CrowdStrike Falcon Sensor Deployment Example

module "crowdstrike_distributor" {
  source = "../../"

  # Deploy to multiple regions
  regions = ["us-east-1", "us-west-2"]

  # CrowdStrike API credentials
  falcon_cloud         = "us-1"
  falcon_client_id     = var.falcon_client_id
  falcon_client_secret = var.falcon_client_secret

  # Optional: Customize deployment
  cron_schedule_expression = "cron(0 2 ? * * *)" # Daily at 2 AM UTC

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
