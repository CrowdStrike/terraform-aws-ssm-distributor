# IAM Role Outputs
output "iam_role_arn" {
  description = "The ARN of the IAM role created for SSM automation"
  value       = aws_iam_role.ssm_assume_role.arn
}

output "iam_role_name" {
  description = "The name of the IAM role created for SSM automation"
  value       = aws_iam_role.ssm_assume_role.name
}

output "iam_role_id" {
  description = "The ID of the IAM role created for SSM automation"
  value       = aws_iam_role.ssm_assume_role.id
}

# Regional Deployment Information
output "deployed_regions" {
  description = "List of regions where the Falcon sensor deployment is configured"
  value       = var.regions
}

# SSM Association Outputs (per region)
output "ssm_association_ids" {
  description = "Map of region to SSM association ID for CrowdStrike Falcon sensor deployment"
  value       = { for k, v in aws_ssm_association.sensor_deploy : k => v.association_id }
}

output "ssm_association_names" {
  description = "Map of region to SSM association name"
  value       = { for k, v in aws_ssm_association.sensor_deploy : k => v.association_name }
}

output "ssm_document_names" {
  description = "Map of region to SSM document name used for sensor deployment"
  value       = { for k, v in data.aws_ssm_document.falcon_sensor_deploy : k => v.name }
}

output "ssm_document_versions" {
  description = "Map of region to SSM document version being used"
  value       = { for k, v in data.aws_ssm_document.falcon_sensor_deploy : k => v.document_version }
}

# KMS Outputs (per region)
output "kms_key_ids" {
  description = "Map of region to KMS key ID (if create_kms_key is true)"
  value       = var.create_kms_key ? { for k, v in aws_kms_key.distributor_key : k => v.id } : {}
}

output "kms_key_arns" {
  description = "Map of region to KMS key ARN (if create_kms_key is true)"
  value       = var.create_kms_key ? { for k, v in aws_kms_key.distributor_key : k => v.arn } : {}
}

output "kms_key_aliases" {
  description = "Map of region to KMS key alias (if create_kms_key is true)"
  value       = var.create_kms_key ? { for k, v in aws_kms_alias.distributor_key_alias : k => v.name } : {}
}

# Secrets Manager Outputs (per region, when using Secrets Manager)
output "secrets_manager_secret_arns" {
  description = "Map of region to Secrets Manager secret ARN (when using Secrets Manager for credential storage)"
  value       = local.secret_storage_method == "secretsmanager" ? { for k, v in aws_secretsmanager_secret.distributor_secret : k => v.arn } : {}
}

output "secrets_manager_secret_names" {
  description = "Map of region to Secrets Manager secret name (when using Secrets Manager for credential storage)"
  value       = local.secret_storage_method == "secretsmanager" ? { for k, v in aws_secretsmanager_secret.distributor_secret : k => v.name } : {}
}

# SSM Parameter Outputs (per region, when using Parameter Store)
output "ssm_parameter_falcon_cloud_names" {
  description = "Map of region to SSM parameter name storing the Falcon cloud region (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_cloud : k => v.name } : {}
}

output "ssm_parameter_falcon_cloud_arns" {
  description = "Map of region to SSM parameter ARN storing the Falcon cloud region (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_cloud : k => v.arn } : {}
}

output "ssm_parameter_falcon_client_id_names" {
  description = "Map of region to SSM parameter name storing the Falcon client ID (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_client_id : k => v.name } : {}
}

output "ssm_parameter_falcon_client_id_arns" {
  description = "Map of region to SSM parameter ARN storing the Falcon client ID (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_client_id : k => v.arn } : {}
}

output "ssm_parameter_falcon_client_secret_names" {
  description = "Map of region to SSM parameter name storing the Falcon client secret (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_client_secret : k => v.name } : {}
}

output "ssm_parameter_falcon_client_secret_arns" {
  description = "Map of region to SSM parameter ARN storing the Falcon client secret (when using Parameter Store)"
  value       = local.secret_storage_method == "parameterstore" ? { for k, v in aws_ssm_parameter.falcon_client_secret : k => v.arn } : {}
}

# Configuration Information
output "action" {
  description = "The action being performed (Install or Uninstall)"
  value       = var.action
}

output "secret_storage_method" {
  description = "The method used for storing Falcon API credentials"
  value       = local.secret_storage_method_mappings[local.secret_storage_method]
}

output "falcon_cloud_region" {
  description = "The Falcon cloud region being used"
  value       = var.falcon_cloud
}

output "falcon_cloud_api_endpoint" {
  description = "The Falcon API endpoint for the configured cloud region"
  value       = local.cloud_mappings[local.falcon_cloud]
}

# Operational Information
output "association_schedule" {
  description = "The cron schedule expression for the SSM association"
  value       = var.cron_schedule_expression
}

output "association_max_concurrency" {
  description = "Maximum concurrency setting for the SSM association"
  value       = var.association_max_concurrency
}

output "association_max_errors" {
  description = "Maximum errors setting for the SSM association"
  value       = var.association_max_errors
}
