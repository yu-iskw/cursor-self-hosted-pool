# Plan-only assertions (capacity bounds, unrestricted-profile exception).
# Apply-blocking security rules live as lifecycle.precondition on the worker
# pool resources in main.tf (identity, network, secrets, registry, exceptions).
check "capacity_within_policy" {
  assert {
    condition = (
      var.capacity.instance_count <= var.capacity_policy.maximum_instance_count &&
      local.cpu_number >= var.capacity_policy.minimum_cpu &&
      local.cpu_number <= var.capacity_policy.maximum_cpu &&
      local.memory_gib >= var.capacity_policy.minimum_memory_gib &&
      local.memory_gib <= var.capacity_policy.maximum_memory_gib
    )
    error_message = "capacity exceeds capacity_policy bounds (cpu/memory/instance_count)."
  }
}

check "unrestricted_requires_exception" {
  assert {
    condition     = var.network.profile != "unrestricted" || local.allow_unrestricted_egress
    error_message = "network.profile=unrestricted requires exceptions.allow_unrestricted_egress."
  }
}
