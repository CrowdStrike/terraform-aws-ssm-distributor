
# Regions and IAM Configuration
variable "regions" {
  description = "List of AWS regions where CrowdStrike Falcon Sensor will be deployed. The module will create regional resources in each specified region."
  type        = list(string)
  validation {
    condition     = length(var.regions) > 0
    error_message = "At least one region must be specified."
  }
}

variable "iam_role_name" {
  description = "Name of the IAM role that will be created for SSM automation. This is a global resource."
  type        = string
  default     = "CrowdStrikeSSMAutomationRole"
}

variable "permissions_boundary" {
  description = "Optional permissions boundary ARN to apply to the IAM role."
  type        = string
  default     = null
}

variable "action" {
  description = "Action to perform: 'Install' to install the Falcon sensor, or 'Uninstall' to remove it."
  type        = string
  default     = "Install"

  validation {
    condition     = contains(["Install", "Uninstall"], var.action)
    error_message = "Action must be either 'Install' or 'Uninstall'."
  }
}

# State Manager Association Variables

variable "linux_package_version" {
  description = "The version of the CrowdStrike Falcon Sensor package to install on Linux. Example 7.0.4.2333, installs N-1 version if no version is specified."
  type        = string
  default     = ""
}

variable "windows_package_version" {
  description = "The version of the CrowdStrike Falcon Sensor package to install on Windows. Example 7.0.4.2333, installs N-1 version if no version is specified."
  type        = string
  default     = ""
}

variable "linux_installer_params" {
  description = "The parameters to pass to the Linux installer at install time."
  type        = string
  default     = ""
}

variable "windows_installer_params" {
  description = "The parameters to pass to the Windows installer at install time."
  type        = string
  default     = ""
}

variable "cron_schedule_expression" {
  description = "The cron schedule expression for the AWS State Manager association. Defaults to daily at 2 AM UTC."
  type        = string
  default     = "cron(0 2 ? * * *)"
}

# Falcon API Credentials Variables 
variable "secret_storage_method" {
  description = "The method to use for storing the Falcon API credentials. Defaults to SSM."
  type        = string
  default     = "ParameterStore"

  validation {
    condition     = contains(["parameterstore", "secretsmanager"], lower(var.secret_storage_method))
    error_message = "Secret Storage Method must be one of ParameterStore or SecretsManager. (case-insensitive)"
  }
}

variable "secrets_manager_secret_name" {
  description = "The name of the Secrets Manager secret that will be created to store the Falcon API credentials."
  type        = string
  default     = "CrowdStrike/Falcon/Distributor"

  validation {
    condition     = length(var.secrets_manager_secret_name) <= 64
    error_message = "Secret Name must be less than or equal to 64 characters."
  }
}

variable "falcon_cloud" {
  description = "The Falcon Cloud Region to use."
  type        = string

  validation {
    condition     = contains(["us-1", "us-2", "eu-1", "us-gov-1", "us-gov-2"], lower(var.falcon_cloud))
    error_message = "Cloud must be one of us-1, us-2, eu-1, us-gov-1 or us-gov-2. (case-insensitive)"
  }
}

variable "falcon_client_id" {
  description = "The Client ID of the Falcon API Credentials"
  type        = string
  sensitive   = true
}

variable "falcon_client_secret" {
  description = "The Client Secret of the Falcon API Credentials"
  type        = string
  sensitive   = true
}

variable "falcon_cloud_ssm_parameter_name" {
  description = "The name of the SSM parameter that will be created to store the Falcon Cloud Region."
  type        = string
  default     = "/CrowdStrike/Falcon/Cloud"
}

variable "falcon_client_id_ssm_parameter_name" {
  description = "The name of the SSM parameter that will be created to store the Falcon API Client ID."
  type        = string
  default     = "/CrowdStrike/Falcon/ClientId"
}

variable "falcon_client_secret_ssm_parameter_name" {
  description = "The name of the SSM parameter that will be created to store the Falcon API Client Secret."
  type        = string
  default     = "/CrowdStrike/Falcon/ClientSecret"
}

# Miscellaneous

variable "ssm_document_name" {
  description = "The name of the SSM document to use for sensor deployment. Defaults to the official CrowdStrike document."
  type        = string
  default     = "CrowdStrike-FalconSensorDeploy"
}

variable "association_name_prefix" {
  description = "Prefix for the SSM association name. The region name will be appended automatically (e.g., 'prefix-us-east-1')."
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Whether to create a customer-managed KMS key for encryption. Defaults to false to use AWS managed keys."
  type        = bool
  default     = false
}

variable "kms_key_alias" {
  description = "Alias for the KMS key when create_kms_key is true."
  type        = string
  default     = "crowdstrike-distributor"
}

variable "kms_key_id" {
  description = "ID of an existing KMS key to use for encryption. If not provided and create_kms_key is false, AWS managed keys will be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "association_max_concurrency" {
  description = "Maximum number of instances that can run the association at the same time."
  type        = string
  default     = "50%"
}

variable "association_max_errors" {
  description = "Maximum number of errors allowed before stopping the association execution."
  type        = string
  default     = "0"
}

variable "apply_only_at_cron_interval" {
  description = "By default, when you create a new association, the system runs it immediately and then according to the schedule you specified. Set this to true to prevent the association from running immediately after creation or when a target comes online. The association will only run at the scheduled cron interval."
  type        = bool
  default     = false
}

variable "association_targets" {
  description = <<-EOT
    Optional target for the SSM association. When not set, all managed instances are targeted.

    Specify exactly one of:
      - key = "InstanceIds",       values = ["*"]             — all managed instances (default)
      - key = "tag:<TagKey>",      values = ["<value>", ...]  — instances matching an EC2 tag
      - key = "ResourceGroup",     values = ["<group-name>"]  — instances in an AWS Resource Group

    Note: CrowdStrike-FalconSensorDeploy is an Automation document and supports only one tag key
    as a target filter. To AND multiple tags together, create an AWS Resource Groups group with
    the desired tag filters and use key = "ResourceGroup".
  EOT
  type = object({
    key    = string
    values = list(string)
  })
  default = null

  validation {
    condition     = var.association_targets == null || length(var.association_targets.values) >= 1
    error_message = "association_targets.values must contain at least one entry."
  }
}
