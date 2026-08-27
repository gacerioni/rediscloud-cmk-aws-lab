# ----------------------------------------------------------------------------
# Credentials (leave null to use REDISCLOUD_ACCESS_KEY / REDISCLOUD_SECRET_KEY)
# ----------------------------------------------------------------------------
variable "rediscloud_api_key" {
  description = "Redis Cloud account API key"
  type        = string
  sensitive   = true
  default     = null
}

variable "rediscloud_secret_key" {
  description = "Redis Cloud user secret key"
  type        = string
  sensitive   = true
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
  default     = "cmk-lab"
}

variable "aws_region" {
  description = "AWS region for the subscription (e.g. sa-east-1)"
  type        = string
  default     = "sa-east-1"
}

variable "networking_deployment_cidr" {
  description = "CIDR /24 for the subscription network"
  type        = string
  default     = "10.42.0.0/24"
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
variable "kms_key_arn" {
  description = "ARN of YOUR AWS KMS key (created manually for this MVP). Required on phase 2."
  type        = string
  default     = null
}

variable "cmk_grant_done" {
  description = "Phase gate. false = 1st apply (returns the Redis IAM role ARN). Set to true AFTER granting that role on your KMS key policy, then apply again."
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# Database (created on phase 2, on top of the CMK-encrypted subscription)
# ----------------------------------------------------------------------------
variable "database_name" {
  description = "Name of the database created after CMK activation"
  type        = string
  default     = "cmk-lab-db"
}

variable "replication" {
  description = "In-region replication for the database"
  type        = bool
  default     = false
}

variable "enable_tls" {
  description = "Require TLS on the database endpoint"
  type        = bool
  default     = true
}
