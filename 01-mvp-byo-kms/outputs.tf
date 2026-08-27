output "subscription_id" {
  value = rediscloud_subscription.cmk_lab.id
}

output "customer_managed_key_aws_role_arn" {
  description = "Grant THIS role on your KMS key policy (kms:Encrypt, kms:Decrypt, kms:ReEncrypt*, kms:GenerateDataKey*, kms:DescribeKey, kms:CreateGrant, kms:ListGrants, kms:RevokeGrant), then run phase 2."
  value       = rediscloud_subscription.cmk_lab.customer_managed_key_aws_role_arn
}

output "database_public_endpoint" {
  description = "Endpoint of the database created on phase 2"
  value       = var.cmk_grant_done ? rediscloud_subscription_database.db[0].public_endpoint : null
}

output "database_password" {
  sensitive = true
  value     = var.cmk_grant_done ? rediscloud_subscription_database.db[0].password : null
}
