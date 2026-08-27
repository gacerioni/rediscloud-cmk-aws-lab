# CMK on Redis Cloud Pro (AWS), BYO KMS key.
# Official flow (two applies): terraform-provider-rediscloud/docs/guides/cmk-guide.md
#
#   1. terraform apply                      -> subscription enters encryption_key_pending
#                                              and outputs the Redis IAM role ARN
#   2. grant that role on your KMS key policy (AWS console or CLI)
#   3. terraform apply -var cmk_grant_done=true -var kms_key_arn=arn:aws:kms:...
#                                           -> subscription activates with your key

data "rediscloud_payment_method" "card" {
  card_type         = var.credit_card_type
  last_four_numbers = var.credit_card_last_four
}

resource "rediscloud_subscription" "cmk_lab" {
  name              = var.subscription_name
  payment_method    = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id

  customer_managed_key_enabled = true

  cloud_provider {
    provider         = "AWS"
    cloud_account_id = var.cloud_account_id
    region {
      region                     = var.aws_region
      networking_deployment_cidr = var.networking_deployment_cidr
    }
  }

  # Phase 2 only: point the subscription at your KMS key.
  dynamic "customer_managed_key" {
    for_each = var.cmk_grant_done ? [1] : []
    content {
      resource_name = var.kms_key_arn
    }
  }

  creation_plan {
    dataset_size_in_gb           = var.dataset_size_in_gb
    quantity                     = 1
    replication                  = false
    support_oss_cluster_api      = false
    throughput_measurement_by    = "operations-per-second"
    throughput_measurement_value = var.throughput_ops_sec
  }

  lifecycle {
    precondition {
      condition     = !var.cmk_grant_done || var.kms_key_arn != null
      error_message = "Phase 2 (cmk_grant_done = true) requires kms_key_arn."
    }
  }
}
