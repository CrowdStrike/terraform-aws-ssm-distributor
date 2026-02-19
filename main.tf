locals {
  falcon_cloud          = lower(var.falcon_cloud)
  secret_storage_method = lower(var.secret_storage_method)
  regions_set           = toset(var.regions)

  cloud_mappings = {
    us-1 = "api.crowdstrike.com"
    us-2 = "api.us-2.crowdstrike.com"
    eu-1 = "api.eu-1.crowdstrike.com"
  }

  secret_storage_method_mappings = {
    parameterstore = "ParameterStore"
    secretsmanager = "SecretsManager"
  }

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "crowdstrike-falcon-distributor"
      ManagedBy   = "terraform"
      CreatedDate = timestamp()
    }
  )
}

# IAM role for SSM automation
data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ssm_assume_role" {
  name                 = var.iam_role_name
  assume_role_policy   = data.aws_iam_policy_document.ssm_assume_role.json
  permissions_boundary = var.permissions_boundary
}

resource "aws_iam_role_policy_attachments_exclusive" "ssm_assume_role" {
  role_name   = aws_iam_role.ssm_assume_role.name
  policy_arns = lower(var.secret_storage_method) == "secretsmanager" ? [
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    ] : [
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
  ]
}

# Data source to validate SSM document exists in each region
data "aws_ssm_document" "falcon_sensor_deploy" {
  for_each = local.regions_set

  region          = each.value
  name            = var.ssm_document_name
  document_format = "YAML"
}

# KMS key for encryption (optional, per region)
resource "aws_kms_key" "distributor_key" {
  for_each = var.create_kms_key ? local.regions_set : []

  region              = each.value
  description         = "KMS key for CrowdStrike Distributor encryption in ${each.value}"
  enable_key_rotation = true

  tags = local.common_tags
}

resource "aws_kms_alias" "distributor_key_alias" {
  for_each = var.create_kms_key ? local.regions_set : []

  region        = each.value
  name          = "alias/${var.kms_key_alias}-${each.value}"
  target_key_id = aws_kms_key.distributor_key[each.key].key_id
}

# Falcon API Credentials via Secrets Manager (per region)
resource "aws_secretsmanager_secret" "distributor_secret" {
  for_each = local.secret_storage_method == "secretsmanager" ? local.regions_set : []

  region      = each.value
  name        = "${var.secrets_manager_secret_name}-${each.value}"
  description = "Falcon API Credentials for CrowdStrike Distributor in ${each.value}"
  kms_key_id  = var.create_kms_key ? aws_kms_key.distributor_key[each.key].arn : var.kms_key_id

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "distributor_secret_version" {
  for_each = local.secret_storage_method == "secretsmanager" ? local.regions_set : []

  region    = each.value
  secret_id = aws_secretsmanager_secret.distributor_secret[each.key].id
  secret_string = jsonencode({
    Cloud        = local.cloud_mappings[local.falcon_cloud]
    ClientId     = var.falcon_client_id
    ClientSecret = var.falcon_client_secret
  })

  depends_on = [aws_secretsmanager_secret.distributor_secret]
}

# Falcon API Credentials via Parameter Store (per region)
resource "aws_ssm_parameter" "falcon_cloud" {
  for_each = local.secret_storage_method == "parameterstore" ? local.regions_set : []

  region      = each.value
  name        = var.falcon_cloud_ssm_parameter_name
  type        = "String"
  value       = local.cloud_mappings[local.falcon_cloud]
  description = "Falcon Cloud Region for CrowdStrike Distributor"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "falcon_client_id" {
  for_each = local.secret_storage_method == "parameterstore" ? local.regions_set : []

  region      = each.value
  name        = var.falcon_client_id_ssm_parameter_name
  type        = "SecureString"
  value       = var.falcon_client_id
  description = "Falcon Client ID for CrowdStrike Distributor"
  key_id      = var.create_kms_key ? aws_kms_key.distributor_key[each.key].arn : var.kms_key_id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "falcon_client_secret" {
  for_each = local.secret_storage_method == "parameterstore" ? local.regions_set : []

  region      = each.value
  name        = var.falcon_client_secret_ssm_parameter_name
  type        = "SecureString"
  value       = var.falcon_client_secret
  description = "Falcon Client Secret for CrowdStrike Distributor"
  key_id      = var.create_kms_key ? aws_kms_key.distributor_key[each.key].arn : var.kms_key_id

  tags = local.common_tags
}

# SSM Association for sensor deployment (per region)
resource "aws_ssm_association" "sensor_deploy" {
  for_each = local.regions_set

  region           = each.value
  association_name = var.association_name_prefix != "" ? "${var.association_name_prefix}-${each.value}" : "CrowdStrike-Sensor-Deploy-${each.value}"
  document_version = data.aws_ssm_document.falcon_sensor_deploy[each.key].document_version

  name = data.aws_ssm_document.falcon_sensor_deploy[each.key].name

  schedule_expression = var.cron_schedule_expression

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }

  automation_target_parameter_name = "InstanceIds"
  max_concurrency                  = var.association_max_concurrency
  max_errors                       = var.association_max_errors

  parameters = {
    Action                   = var.action
    AutomationAssumeRole     = aws_iam_role.ssm_assume_role.arn
    FalconCloud              = var.falcon_cloud_ssm_parameter_name
    FalconClientId           = var.falcon_client_id_ssm_parameter_name
    FalconClientSecret       = var.falcon_client_secret_ssm_parameter_name
    SecretStorageMethod      = local.secret_storage_method_mappings[local.secret_storage_method]
    SecretsManagerSecretName = local.secret_storage_method == "secretsmanager" ? aws_secretsmanager_secret.distributor_secret[each.key].name : var.secrets_manager_secret_name
    LinuxPackageVersion      = var.linux_package_version
    LinuxInstallerParams     = var.linux_installer_params
    WindowsPackageVersion    = var.windows_package_version
    WindowsInstallerParams   = var.windows_installer_params
  }

  depends_on = [
    data.aws_ssm_document.falcon_sensor_deploy,
    aws_ssm_parameter.falcon_cloud,
    aws_ssm_parameter.falcon_client_id,
    aws_ssm_parameter.falcon_client_secret,
    aws_secretsmanager_secret_version.distributor_secret_version,
    aws_iam_role_policy_attachments_exclusive.ssm_assume_role,
  ]
}
