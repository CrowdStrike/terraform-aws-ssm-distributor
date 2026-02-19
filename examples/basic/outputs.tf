output "iam_role_arn" {
  description = "ARN of the IAM role created for SSM automation"
  value       = module.crowdstrike_distributor.iam_role_arn
}

output "deployed_regions" {
  description = "List of regions where Falcon sensor is deployed"
  value       = module.crowdstrike_distributor.deployed_regions
}

output "association_ids" {
  description = "Map of SSM association IDs by region"
  value       = module.crowdstrike_distributor.ssm_association_ids
}
