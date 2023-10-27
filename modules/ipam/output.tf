output "ipv4_ipam_pool_id" {
  description = "ipam pool id"
  value = var.ipam_pool == null ? 0 : local.ipam_pools[data.aws_region.current.id][var.ipam_pool]
}