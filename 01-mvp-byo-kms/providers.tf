terraform {
  required_version = ">= 1.5.0"

  required_providers {
    rediscloud = {
      source  = "RedisLabs/rediscloud"
      version = "~> 2.19"
    }
  }
}

# Credentials resolve from variables when set, otherwise from the
# REDISCLOUD_ACCESS_KEY / REDISCLOUD_SECRET_KEY environment variables.
provider "rediscloud" {
  api_key    = var.rediscloud_api_key
  secret_key = var.rediscloud_secret_key
}
