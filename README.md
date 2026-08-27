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
- A second apply passes your key ARN in the `customer_managed_key` block, the
  subscription activates encrypting persistent storage with your key, and a
  real database is created on top of it.

### The two ARNs (where the official guide gets confusing)

There are two different ARNs in this flow and they exist at different times:

| ARN | What it is | When it exists |
|---|---|---|
| `resource_name` (KMS key ARN) | YOUR key | before phase 1 (you create it first) |
| `customer_managed_key_aws_role_arn` | the Redis-side IAM role that reads your key | only AFTER phase 1 |

The role ARN lives in a Redis-side AWS account that varies per subscription
(observed empirically: two subscriptions returned roles in two different AWS
accounts), so pre-granting is impossible. That is the whole reason for the
two applies: subscription first (to learn the role), grant in AWS, then key.

This repo makes the two phases explicit with the `cmk_grant_done` variable
(a `dynamic "customer_managed_key"` block gated on it), so both applies exit
cleanly instead of relying on a half-failed first apply.

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

- Phase 1: subscription created in `encryption_key_pending` in under a minute,
  role ARN returned. The console shows the same ARN and an activation deadline
  (7 days; the pending subscription is auto-deleted if never activated).
- Phase 2: KMS key + key policy grant, apply activated the subscription in
  about 10 minutes and created a real database on it (about 3 more minutes).
- Smoke test against the database endpoint (TLS):

```
redis-cli --tls -h <endpoint> -p <port> -a <password> ping   # PONG
```

### Gotchas found in practice

- A subscription in `encryption_key_pending` CANNOT be destroyed
  (`403 SUBSCRIPTION_NOT_ACTIVE`). Either finish phase 2 and then destroy,
  or let the 7 day auto-delete clean it up.
- The KMS key must be in the same region as the subscription.

## If phase 1 returns 400 CUSTOMER_MANAGED_PERSISTENT_STORAGE_ENCRYPTION_KEY_IS_NOT_SUPPORTED

The request is syntactically fine and the rejection comes from the Redis Cloud
API: CMK is enabled per account. Open a ticket with Redis support (include the
account ID and the payload) to confirm enablement for the account.
