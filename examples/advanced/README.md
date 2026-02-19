# Advanced Example

This example demonstrates deployment of the CrowdStrike Falcon Sensor with Secrets Manager, customer-managed KMS encryption, and advanced configuration options.

## Architecture Overview

This deployment creates the following resources:

- **IAM Role** (Global): IAM role for SSM automation with managed policies and permissions boundary
- **KMS Keys** (Per Region): Customer-managed KMS keys for encryption at rest
- **KMS Aliases** (Per Region): Aliases for easy key identification
- **Secrets Manager Secrets** (Per Region): Falcon credentials stored with encryption
- **SSM Associations** (Per Region): State Manager associations with custom concurrency and error handling
- **SSM Document Validation** (Per Region): Data sources to validate CrowdStrike SSM document availability

## Deploy

1. Create a `terraform.tfvars` file:

```hcl
falcon_cloud         = "us-1"
falcon_client_id     = "your-client-id"
falcon_client_secret = "your-client-secret"

# Optional
permissions_boundary_arn = "arn:aws:iam::123456789012:policy/YourBoundary"
linux_sensor_version     = "7.10.0.16303"
windows_sensor_version   = "7.10.0.16303"
```

2. Initialize and apply:

```bash
terraform init
terraform apply
```

## Adding Regions

To deploy the Falcon sensor to additional regions, update the `regions` list in `main.tf`:

```hcl
module "crowdstrike_distributor" {
  source = "../../"

  regions = ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1", "eu-central-1"]

  # ... rest of configuration
}
```

Then apply the changes:

```bash
terraform apply
```

The module will automatically create KMS keys, Secrets Manager secrets, and associations in the new regions.

## Destroy

To remove all resources created by this example:

```bash
terraform destroy
```

This will remove the IAM role, KMS keys, Secrets Manager secrets, and associations from all regions.
