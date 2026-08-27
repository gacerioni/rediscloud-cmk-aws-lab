# Phase 2 only: a real database on the CMK-encrypted subscription.
# (A subscription in encryption_key_pending does not accept databases yet.)
resource "rediscloud_subscription_database" "db" {
  count = var.cmk_grant_done ? 1 : 0

  subscription_id              = rediscloud_subscription.cmk_lab.id
  name                         = var.database_name
  dataset_size_in_gb           = var.dataset_size_in_gb
  throughput_measurement_by    = "operations-per-second"
  throughput_measurement_value = var.throughput_ops_sec
  replication                  = var.replication
  enable_tls                   = var.enable_tls
}
