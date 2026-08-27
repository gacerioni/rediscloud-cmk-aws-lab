output "subscription_id" {
  value = rediscloud_subscription.cmk_lab.id
}

output "customer_managed_key_aws_role_arn" {
  description = "Grant THIS role on your KMS key policy (kms:Encrypt, kms:Decrypt, kms:ReEncrypt*, kms:GenerateDataKey*, kms:DescribeKey, kms:CreateGrant, kms:ListGrants, kms:RevokeGrant), then run phase 2."
  value       = rediscloud_subscription.cmk_lab.customer_managed_key_aws_role_arn
}
