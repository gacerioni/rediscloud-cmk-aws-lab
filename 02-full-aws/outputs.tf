output "subscription_id" {
  value = rediscloud_subscription.cmk_lab.id
}

output "customer_managed_key_aws_role_arn" {
  description = "Paste this into phase 2 as -var redis_role_arn=..."
  value       = rediscloud_subscription.cmk_lab.customer_managed_key_aws_role_arn
}

output "kms_key_arn" {
  value = aws_kms_key.cmk.arn
}
