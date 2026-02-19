# Basic Example

This example demonstrates a simple deployment of the CrowdStrike Falcon Sensor across multiple AWS regions.

## Architecture Overview

This deployment creates the following resources:

- **IAM Role** (Global): Single IAM role for SSM automation with managed policies
- **SSM Parameters** (Per Region): Falcon credentials stored in Parameter Store
- **SSM Associations** (Per Region): State Manager associations to deploy sensors
- **SSM Document Validation** (Per Region): Data sources to validate CrowdStrike SSM document availability

## Deploy

1. Set your CrowdStrike API credentials:

```bash
export TF_VAR_falcon_client_id="your-client-id"
export TF_VAR_falcon_client_secret="your-client-secret"
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

  regions = ["us-east-1", "us-west-2", "eu-west-1", "ap-southeast-1"]

  # ... rest of configuration
}
```

Then apply the changes:

```bash
terraform apply
```

## Destroy

To remove all resources created by this example:

```bash
terraform destroy
```

This will remove the IAM role, SSM parameters, and associations from all regions.
