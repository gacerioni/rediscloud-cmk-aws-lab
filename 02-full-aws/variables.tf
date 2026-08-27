# ----------------------------------------------------------------------------
# Credentials
# ----------------------------------------------------------------------------
variable "rediscloud_api_key" {
  description = "Redis Cloud account API key (or use REDISCLOUD_ACCESS_KEY)"
  type        = string
  sensitive   = true
  default     = null
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud user secret key (or use REDISCLOUD_SECRET_KEY)"
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_profile" {
  description = "AWS CLI profile (null = default credential chain)"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Payment method (looked up via data source, never hardcode IDs)
# ----------------------------------------------------------------------------
variable "credit_card_type" {
  description = "Card type registered on the account (e.g. Visa, Mastercard)"
  type        = string
}

variable "credit_card_last_four" {
  description = "Last four digits of the registered card (optional if the account has a single card of that type)"
  type        = string
  default     = null
}

# ----------------------------------------------------------------------------
# Subscription
# ----------------------------------------------------------------------------
variable "subscription_name" {
  description = "Name of the Redis Cloud Pro subscription"
  type        = string
  default     = "cmk-lab-full"
}

variable "aws_region" {
  description = "AWS region for the subscription and the KMS key"
  type        = string
  default     = "sa-east-1"
}

variable "networking_deployment_cidr" {
  description = "CIDR /24 for the subscription network"
  type        = string
  default     = "10.43.0.0/24"
}

variable "cloud_account_id" {
  description = "Redis Cloud cloud account ID (1 = Redis-managed AWS account)"
  type        = string
  default     = "1"
}

variable "dataset_size_in_gb" {
  description = "Dataset size for the creation plan"
  type        = number
  default     = 1
}

variable "throughput_ops_sec" {
  description = "Throughput for the creation plan (ops/sec)"
  type        = number
  default     = 1000
}

# ----------------------------------------------------------------------------
# CMK flow (two applies, per the official provider guide)
# ----------------------------------------------------------------------------
variable "kms_key_alias" {
  description = "Alias for the KMS key this lab creates"
  type        = string
  default     = "rediscloud-cmk-lab"
}

variable "redis_role_arn" {
  description = "Phase 2: paste the customer_managed_key_aws_role_arn output from phase 1. Drives the KMS key policy grant."
  type        = string
  default     = null
}

variable "cmk_grant_done" {
  description = "Phase gate. false = 1st apply (creates key + subscription, returns the Redis role ARN). true = 2nd apply (grants the role on the key policy and activates CMK)."
  type        = bool
  default     = false
}
