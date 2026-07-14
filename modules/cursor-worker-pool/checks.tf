check "no_expired_exceptions" {
  assert {
    condition     = length(local.expired_exceptions) == 0
    error_message = "One or more policy exceptions have expired: ${join(", ", local.expired_exceptions)}. Renew the ticket or remove the exception."
  }
}

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

check "secret_versions_pinned" {
  assert {
    condition     = local.secret_versions_ok
    error_message = "Secret versions must be pinned (not \"latest\") unless exception allow_secret_version_latest is set."
  }
}

check "image_registry_allowlist" {
  assert {
    condition     = local.registry_ok
    error_message = "image.repository is not under security.allowed_image_registry_prefixes."
  }
}

check "restricted_network" {
  assert {
    condition     = local.restricted_ok || local.allow_unrestricted_egress
    error_message = "restricted network profile requires network_id, subnetwork_id, route_all_traffic=true, and approved_egress_control (or allow_unrestricted_egress exception)."
  }
}

check "unrestricted_requires_exception" {
  assert {
    condition     = var.network.profile != "unrestricted" || local.allow_unrestricted_egress
    error_message = "network.profile=unrestricted requires exceptions.allow_unrestricted_egress."
  }
}
