# CMK on Redis Cloud Pro (AWS), end to end. Terraform creates the KMS key,
# the subscription, and the key policy grant.
# Official flow (two applies): terraform-provider-rediscloud/docs/guides/cmk-guide.md
#
#   1. terraform apply
#        -> creates the KMS key and the subscription (encryption_key_pending)
#        -> outputs customer_managed_key_aws_role_arn
#   2. terraform apply -var cmk_grant_done=true -var redis_role_arn=<output of 1>
#        -> writes the key policy grant, then activates CMK on the subscription

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

  # Phase 2 only: point the subscription at the key created in kms.tf.
  dynamic "customer_managed_key" {
    for_each = var.cmk_grant_done ? [1] : []
    content {
      resource_name = aws_kms_key.cmk.arn
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

  # The key policy grant must land before the subscription consumes the key.
  depends_on = [aws_kms_key_policy.cmk]

  lifecycle {
    precondition {
      condition     = !var.cmk_grant_done || var.redis_role_arn != null
      error_message = "Phase 2 (cmk_grant_done = true) requires redis_role_arn (output of phase 1)."
    }
  }
}
