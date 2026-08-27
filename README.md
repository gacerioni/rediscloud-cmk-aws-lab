# Golden path: Customer Managed Keys (CMK) on Redis Cloud AWS with Terraform

Infrastructure-as-code golden path for enabling Customer Managed Keys
(CMK/BYOK) on a Redis Cloud Pro subscription on AWS, using the official
two-apply flow from the provider guide. Provider `RedisLabs/rediscloud ~> 2.19`
(AWS CMK support landed in 2.17.0). Validated end to end against a real
account (see below).

CMK availability is enabled per Redis Cloud account. If your account is not
enabled yet, phase 1 returns a 400 (see the last section); ask your Redis
account team to enable it, then this repo is ready to run as-is.

Reference: [CMK guide](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs/guides/cmk-guide)

## How CMK works on AWS (short version)

- You own the KMS key. Redis Cloud never creates KMS resources in your account.
- Enabling `customer_managed_key_enabled = true` puts the subscription in
  `encryption_key_pending` and exposes `customer_managed_key_aws_role_arn`,
  an IAM role on the Redis side.
- You grant that role on your KMS key policy (Encrypt, Decrypt, ReEncrypt*,
  GenerateDataKey*, DescribeKey, CreateGrant, ListGrants, RevokeGrant).
- A second apply passes your key ARN in the `customer_managed_key` block and
  the subscription activates encrypting persistent storage with your key.

## Two variants

| Dir | What it does | AWS provider |
|---|---|---|
| `01-mvp-byo-kms` | You create the KMS key by hand; Terraform only drives Redis Cloud | no |
| `02-full-aws` | Terraform creates the KMS key, the key policy grant and the subscription | yes |

## Running (either variant)

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in
export REDISCLOUD_ACCESS_KEY=...
export REDISCLOUD_SECRET_KEY=...
terraform init
```

Phase 1:

```bash
terraform apply
# note the customer_managed_key_aws_role_arn output
```

Phase 2, MVP (grant done by hand on the key policy first):

```bash
terraform apply -var cmk_grant_done=true -var kms_key_arn=arn:aws:kms:...
```

Phase 2, full AWS (Terraform writes the grant itself):

```bash
terraform apply -var cmk_grant_done=true -var redis_role_arn=<output of phase 1>
```

No IDs are hardcoded: payment method comes from a data source
(`card_type` + `last_four_numbers`), account specifics come from tfvars.

## Validated end to end (2026-08-27, Redis SA account)

Both phases ran against a real account in `sa-east-1` with the Redis internal
cloud account (`cloud_account_id = 1`):

- Phase 1: subscription created in `encryption_key_pending` in 27s, role ARN
  returned. The console shows the same ARN and an activation deadline
  (7 days; the pending subscription is auto-deleted if never activated).
- Phase 2: KMS key + key policy grant, apply activated the subscription in
  about 10 minutes, encrypting persistent storage with the customer key.

### Gotchas found in practice

- A subscription in `encryption_key_pending` CANNOT be destroyed
  (`403 SUBSCRIPTION_NOT_ACTIVE`). Either finish phase 2 and then destroy,
  or let the 7 day auto-delete clean it up.
- The KMS key must be in the same region as the subscription.

## If phase 1 returns 400 CUSTOMER_MANAGED_PERSISTENT_STORAGE_ENCRYPTION_KEY_IS_NOT_SUPPORTED

The request is syntactically fine and the rejection comes from the Redis Cloud
API: CMK is enabled per account. Open a ticket with Redis support (include the
account ID and the payload) to confirm enablement for the account.
