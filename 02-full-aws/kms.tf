# The customer-side key. Redis Cloud NEVER creates KMS resources in your
# account: you own the key, and you grant the Redis-side IAM role on its
# key policy. That grant is the only cross-account permission involved.

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cmk" {
  description             = "Redis Cloud CMK lab"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.cmk.key_id
}

# Phase 2: grant the Redis subscription role on the key policy.
# Permissions list comes from the official CMK guide of the provider.
resource "aws_kms_key_policy" "cmk" {
  count  = var.redis_role_arn == null ? 0 : 1
  key_id = aws_kms_key.cmk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountRootFullAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "RedisCloudCMKAccess"
        Effect    = "Allow"
        Principal = { AWS = var.redis_role_arn }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant",
        ]
        Resource = "*"
      },
    ]
  })
}
