<!-- BEGIN_TF_DOCS -->
![CrowdStrike SSM Distributor terraform module](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)<br/>

# AWS Falcon Sensor Deployment Terraform Module

This Terraform module automates the deployment and maintenance of the CrowdStrike Falcon Sensor across AWS EC2 instances using AWS Systems Manager (SSM) Distributor.

Key features:
- Multi-region deployment using AWS Provider v6 resource-level region support
- Automated sensor deployment via AWS Systems Manager State Manager
- Multi-platform support (Linux and Windows)
- Flexible credential storage (Parameter Store or Secrets Manager)
- Customer-managed KMS encryption support per region
- Configurable deployment schedules

> [!NOTE]
> This module creates a State Manager association in each specified region that runs periodically to ensure all EC2 instances have the Falcon sensor installed and up to date.

## Pre-requisites

### Generate API Keys

CrowdStrike API keys are required to use this module. It is highly recommended that you create a dedicated API client with only the required scopes.

1. In the CrowdStrike console, navigate to **Support and resources** > **API Clients & Keys**. Click **Add new API Client**.
2. Add the following required scopes:

<table>
    <tr>
        <th>Scope Name</th>
        <th>Permission</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Sensor Download</td>
        <td><strong>Read</strong></td>
        <td>Required to download sensor installation packages</td>
    </tr>
</table>

3. Click **Add** to create the API client. The next screen will display the API **CLIENT ID**, **SECRET**, and **BASE URL**. You will need the CLIENT ID and SECRET for this module.

    <details><summary>picture</summary>
    <p>

    ![api-client-keys](https://github.com/CrowdStrike/aws-ssm-distributor/blob/main/official-package/assets/api-client-keys.png)

    </p>
    </details>

> [!NOTE]
> This page is only shown once. Make sure you copy **CLIENT ID** and **SECRET** to a secure location.

### SSM Distributor Package

Ensure the CrowdStrike Falcon Sensor Distributor package is available in your AWS regions. The module validates package availability automatically in each specified region.

### SSM Agent on EC2 Instances

Ensure the AWS Systems Manager Agent is installed and running on all target EC2 instances. Most AWS-provided AMIs include the SSM Agent by default.

> [!NOTE]
> This module automatically creates an IAM role for SSM automation with the necessary permissions to deploy and manage the Falcon sensor. You can optionally specify a permissions boundary if required by your organization's policies.

## Scheduling

The association runs on a schedule defined by `cron_schedule_expression`. The default schedule is `cron(0 2 ? * * *)` which runs daily at 2 AM UTC.

You can customize the schedule by updating the `cron_schedule_expression` parameter:

```hcl
cron_schedule_expression = "cron(0 2 ? * * *)" # Daily at 2 AM UTC
```

### Event Driven Execution

This association will run automatically upon initial deployment of the module and subsequent changes.

State Manager also runs the association after any of the following activity occurs on a target node:

- A managed node comes online for the first time.
- A managed node comes online after missing a scheduled association run.
- A managed node comes online after being stopped for more than 30 days.

### Preventing associations from running when a target changes

To prevent an association from running automatically upon deployment and when a target changes, you can set `apply_only_at_cron_interval = true`. When enabled, the association will only run at the scheduled cron interval.

This is useful when you prefer strict control over when sensors are deployed to reduce cost and avoid automatic deployments outside your maintenance windows.

For more information about scheduling options and when associations are automatically applied, review the [AWS Systems Manager State Manager documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/state-manager-about.html#state-manager-about-scheduling).

## Usage

```hcl
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.36.0 |
## Resources

| Name | Type |
|------|------|
| [aws_iam_role.ssm_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policies_exclusive.ssm_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policies_exclusive) | resource |
| [aws_iam_role_policy.secrets_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachments_exclusive.ssm_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachments_exclusive) | resource |
| [aws_kms_alias.distributor_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.distributor_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.distributor_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.distributor_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_ssm_association.sensor_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_parameter.falcon_client_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.falcon_client_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.falcon_cloud](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_iam_policy_document.secrets_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_ssm_document.falcon_sensor_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_document) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action"></a> [action](#input\_action) | Action to perform: 'Install' to install the Falcon sensor, or 'Uninstall' to remove it. | `string` | `"Install"` | no |
| <a name="input_apply_only_at_cron_interval"></a> [apply\_only\_at\_cron\_interval](#input\_apply\_only\_at\_cron\_interval) | By default, when you create a new association, the system runs it immediately and then according to the schedule you specified. Set this to true to prevent the association from running immediately after creation or when a target comes online. The association will only run at the scheduled cron interval. | `bool` | `false` | no |
| <a name="input_association_max_concurrency"></a> [association\_max\_concurrency](#input\_association\_max\_concurrency) | Maximum number of instances that can run the association at the same time. | `string` | `"50%"` | no |
| <a name="input_association_max_errors"></a> [association\_max\_errors](#input\_association\_max\_errors) | Maximum number of errors allowed before stopping the association execution. | `string` | `"0"` | no |
| <a name="input_association_name_prefix"></a> [association\_name\_prefix](#input\_association\_name\_prefix) | Prefix for the SSM association name. The region name will be appended automatically (e.g., 'prefix-us-east-1'). | `string` | `""` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a customer-managed KMS key for encryption. Defaults to false to use AWS managed keys. | `bool` | `false` | no |
| <a name="input_cron_schedule_expression"></a> [cron\_schedule\_expression](#input\_cron\_schedule\_expression) | The cron schedule expression for the AWS State Manager association. Defaults to daily at 2 AM UTC. | `string` | `"cron(0 2 ? * * *)"` | no |
| <a name="input_falcon_client_id"></a> [falcon\_client\_id](#input\_falcon\_client\_id) | The Client ID of the Falcon API Credentials | `string` | n/a | yes |
| <a name="input_falcon_client_id_ssm_parameter_name"></a> [falcon\_client\_id\_ssm\_parameter\_name](#input\_falcon\_client\_id\_ssm\_parameter\_name) | The name of the SSM parameter that will be created to store the Falcon API Client ID. | `string` | `"/CrowdStrike/Falcon/ClientId"` | no |
| <a name="input_falcon_client_secret"></a> [falcon\_client\_secret](#input\_falcon\_client\_secret) | The Client Secret of the Falcon API Credentials | `string` | n/a | yes |
| <a name="input_falcon_client_secret_ssm_parameter_name"></a> [falcon\_client\_secret\_ssm\_parameter\_name](#input\_falcon\_client\_secret\_ssm\_parameter\_name) | The name of the SSM parameter that will be created to store the Falcon API Client Secret. | `string` | `"/CrowdStrike/Falcon/ClientSecret"` | no |
| <a name="input_falcon_cloud"></a> [falcon\_cloud](#input\_falcon\_cloud) | The Falcon Cloud Region to use. | `string` | n/a | yes |
| <a name="input_falcon_cloud_ssm_parameter_name"></a> [falcon\_cloud\_ssm\_parameter\_name](#input\_falcon\_cloud\_ssm\_parameter\_name) | The name of the SSM parameter that will be created to store the Falcon Cloud Region. | `string` | `"/CrowdStrike/Falcon/Cloud"` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role that will be created for SSM automation. This is a global resource. | `string` | `"CrowdStrikeSSMAutomationRole"` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | Alias for the KMS key when create\_kms\_key is true. | `string` | `"crowdstrike-distributor"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ID of an existing KMS key to use for encryption. If not provided and create\_kms\_key is false, AWS managed keys will be used. | `string` | `null` | no |
| <a name="input_linux_installer_params"></a> [linux\_installer\_params](#input\_linux\_installer\_params) | The parameters to pass to the Linux installer at install time. | `string` | `""` | no |
| <a name="input_linux_package_version"></a> [linux\_package\_version](#input\_linux\_package\_version) | The version of the CrowdStrike Falcon Sensor package to install on Linux. Example 7.0.4.2333, installs N-1 version if no version is specified. | `string` | `""` | no |
| <a name="input_permissions_boundary"></a> [permissions\_boundary](#input\_permissions\_boundary) | Optional permissions boundary ARN to apply to the IAM role. | `string` | `null` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | List of AWS regions where CrowdStrike Falcon Sensor will be deployed. The module will create regional resources in each specified region. | `list(string)` | n/a | yes |
| <a name="input_secret_storage_method"></a> [secret\_storage\_method](#input\_secret\_storage\_method) | The method to use for storing the Falcon API credentials. Defaults to SSM. | `string` | `"ParameterStore"` | no |
| <a name="input_secrets_manager_secret_name"></a> [secrets\_manager\_secret\_name](#input\_secrets\_manager\_secret\_name) | The name of the Secrets Manager secret that will be created to store the Falcon API credentials. | `string` | `"CrowdStrike/Falcon/Distributor"` | no |
| <a name="input_ssm_document_name"></a> [ssm\_document\_name](#input\_ssm\_document\_name) | The name of the SSM document to use for sensor deployment. Defaults to the official CrowdStrike document. | `string` | `"CrowdStrike-FalconSensorDeploy"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_windows_installer_params"></a> [windows\_installer\_params](#input\_windows\_installer\_params) | The parameters to pass to the Windows installer at install time. | `string` | `""` | no |
| <a name="input_windows_package_version"></a> [windows\_package\_version](#input\_windows\_package\_version) | The version of the CrowdStrike Falcon Sensor package to install on Windows. Example 7.0.4.2333, installs N-1 version if no version is specified. | `string` | `""` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_action"></a> [action](#output\_action) | The action being performed (Install or Uninstall) |
| <a name="output_association_max_concurrency"></a> [association\_max\_concurrency](#output\_association\_max\_concurrency) | Maximum concurrency setting for the SSM association |
| <a name="output_association_max_errors"></a> [association\_max\_errors](#output\_association\_max\_errors) | Maximum errors setting for the SSM association |
| <a name="output_association_schedule"></a> [association\_schedule](#output\_association\_schedule) | The cron schedule expression for the SSM association |
| <a name="output_deployed_regions"></a> [deployed\_regions](#output\_deployed\_regions) | List of regions where the Falcon sensor deployment is configured |
| <a name="output_falcon_cloud_api_endpoint"></a> [falcon\_cloud\_api\_endpoint](#output\_falcon\_cloud\_api\_endpoint) | The Falcon API endpoint for the configured cloud region |
| <a name="output_falcon_cloud_region"></a> [falcon\_cloud\_region](#output\_falcon\_cloud\_region) | The Falcon cloud region being used |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM role created for SSM automation |
| <a name="output_iam_role_id"></a> [iam\_role\_id](#output\_iam\_role\_id) | The ID of the IAM role created for SSM automation |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | The name of the IAM role created for SSM automation |
| <a name="output_kms_key_aliases"></a> [kms\_key\_aliases](#output\_kms\_key\_aliases) | Map of region to KMS key alias (if create\_kms\_key is true) |
| <a name="output_kms_key_arns"></a> [kms\_key\_arns](#output\_kms\_key\_arns) | Map of region to KMS key ARN (if create\_kms\_key is true) |
| <a name="output_kms_key_ids"></a> [kms\_key\_ids](#output\_kms\_key\_ids) | Map of region to KMS key ID (if create\_kms\_key is true) |
| <a name="output_secret_storage_method"></a> [secret\_storage\_method](#output\_secret\_storage\_method) | The method used for storing Falcon API credentials |
| <a name="output_secrets_manager_secret_arns"></a> [secrets\_manager\_secret\_arns](#output\_secrets\_manager\_secret\_arns) | Map of region to Secrets Manager secret ARN (when using Secrets Manager for credential storage) |
| <a name="output_secrets_manager_secret_names"></a> [secrets\_manager\_secret\_names](#output\_secrets\_manager\_secret\_names) | Map of region to Secrets Manager secret name (when using Secrets Manager for credential storage) |
| <a name="output_ssm_association_ids"></a> [ssm\_association\_ids](#output\_ssm\_association\_ids) | Map of region to SSM association ID for CrowdStrike Falcon sensor deployment |
| <a name="output_ssm_association_names"></a> [ssm\_association\_names](#output\_ssm\_association\_names) | Map of region to SSM association name |
| <a name="output_ssm_document_names"></a> [ssm\_document\_names](#output\_ssm\_document\_names) | Map of region to SSM document name used for sensor deployment |
| <a name="output_ssm_document_versions"></a> [ssm\_document\_versions](#output\_ssm\_document\_versions) | Map of region to SSM document version being used |
| <a name="output_ssm_parameter_falcon_client_id_arns"></a> [ssm\_parameter\_falcon\_client\_id\_arns](#output\_ssm\_parameter\_falcon\_client\_id\_arns) | Map of region to SSM parameter ARN storing the Falcon client ID (when using Parameter Store) |
| <a name="output_ssm_parameter_falcon_client_id_names"></a> [ssm\_parameter\_falcon\_client\_id\_names](#output\_ssm\_parameter\_falcon\_client\_id\_names) | Map of region to SSM parameter name storing the Falcon client ID (when using Parameter Store) |
| <a name="output_ssm_parameter_falcon_client_secret_arns"></a> [ssm\_parameter\_falcon\_client\_secret\_arns](#output\_ssm\_parameter\_falcon\_client\_secret\_arns) | Map of region to SSM parameter ARN storing the Falcon client secret (when using Parameter Store) |
| <a name="output_ssm_parameter_falcon_client_secret_names"></a> [ssm\_parameter\_falcon\_client\_secret\_names](#output\_ssm\_parameter\_falcon\_client\_secret\_names) | Map of region to SSM parameter name storing the Falcon client secret (when using Parameter Store) |
| <a name="output_ssm_parameter_falcon_cloud_arns"></a> [ssm\_parameter\_falcon\_cloud\_arns](#output\_ssm\_parameter\_falcon\_cloud\_arns) | Map of region to SSM parameter ARN storing the Falcon cloud region (when using Parameter Store) |
| <a name="output_ssm_parameter_falcon_cloud_names"></a> [ssm\_parameter\_falcon\_cloud\_names](#output\_ssm\_parameter\_falcon\_cloud\_names) | Map of region to SSM parameter name storing the Falcon cloud region (when using Parameter Store) |
<!-- END_TF_DOCS -->