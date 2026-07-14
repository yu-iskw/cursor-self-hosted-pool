locals {
  repo_slug = lower(replace("${var.repository.owner}-${var.repository.name}", "/[^a-z0-9-]/", "-"))

  name_hash = substr(sha1("${var.repository.owner}/${var.repository.name}/${var.environment}"), 0, 4)

  # Cloud Run Worker Pool names must be 49 characters or fewer.
  generated_name = lower(
    substr(
      join("-", compact([
        var.name_prefix,
        local.repo_slug,
        var.environment,
        local.name_hash,
      ])),
      0,
      49
    )
  )

  worker_pool_name = coalesce(var.name_override, local.generated_name)

  image_reference = "${var.image.repository}@${var.image.digest}"

  runtime_is_default_compute_sa = can(regex(
    "^[0-9]+-compute@developer\\.gserviceaccount\\.com$",
    var.runtime_service_account_email
  ))

  allow_unrestricted_egress         = contains(keys(var.exceptions), "allow_unrestricted_egress")
  allow_mutable_secrets             = contains(keys(var.exceptions), "allow_secret_version_latest")
  allow_disable_deletion_protection = contains(keys(var.exceptions), "allow_disable_deletion_protection")

  expired_exceptions = [
    for k, v in var.exceptions : k
    if timecmp("${v.expires_on}T00:00:00Z", plantimestamp()) < 0
  ]

  cpu_number = tonumber(replace(var.capacity.cpu, "/[^0-9.]/", ""))

  memory_gib = (
    endswith(var.capacity.memory, "Gi") ? tonumber(trimsuffix(var.capacity.memory, "Gi")) :
    endswith(var.capacity.memory, "G") ? tonumber(trimsuffix(var.capacity.memory, "G")) :
    endswith(var.capacity.memory, "Mi") ? tonumber(trimsuffix(var.capacity.memory, "Mi")) / 1024 :
    tonumber(replace(var.capacity.memory, "/[^0-9.]/", ""))
  )

  secret_versions_ok = alltrue([
    for k, v in merge(
      { for sk, sv in var.secret_environment_variables : "env:${sk}" => sv.version },
      { for sk, sv in var.secret_mounts : "mount:${sk}" => sv.version }
    ) :
    (!var.security.require_pinned_secret_versions || local.allow_mutable_secrets) ? true : v != "latest"
  ])

  registry_ok = length(var.security.allowed_image_registry_prefixes) == 0 || anytrue([
    for p in var.security.allowed_image_registry_prefixes :
    startswith(var.image.repository, p)
  ])

  vpc_configured = (
    try(var.network.connector_id, null) != null ||
    (try(var.network.network_id, null) != null && try(var.network.subnetwork_id, null) != null)
  )

  restricted_ok = var.network.profile != "restricted" || (
    local.vpc_configured &&
    var.network.route_all_traffic &&
    try(var.network.approved_egress_control.resource_id, null) != null
  )

  required_labels = {
    managed-by          = "terraform"
    component           = "cursor-self-hosted-pool"
    repository          = substr(replace(lower("${var.repository.owner}_${var.repository.name}"), "/[^a-z0-9_-]/", "-"), 0, 63)
    repository-owner    = substr(replace(lower(var.repository.owner), "/[^a-z0-9_-]/", "-"), 0, 63)
    environment         = var.environment
    team                = substr(replace(lower(var.team), "/[^a-z0-9_-]/", "-"), 0, 63)
    cost-center         = substr(replace(lower(var.cost_center), "/[^a-z0-9_-]/", "-"), 0, 63)
    data-classification = substr(replace(lower(var.data_classification), "/[^a-z0-9_-]/", "-"), 0, 63)
    module-version      = replace(var.module_version_label, "/[^a-z0-9_.-]/", "-")
  }

  labels = merge(local.required_labels, var.labels)

  egress = (
    var.network.profile == "private-only" ? "PRIVATE_RANGES_ONLY" :
    var.network.route_all_traffic ? "ALL_TRAFFIC" :
    "PRIVATE_RANGES_ONLY"
  )

  deletion_protection = (
    var.security.deletion_protection && !local.allow_disable_deletion_protection
  )
}
