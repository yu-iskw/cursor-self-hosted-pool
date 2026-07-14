# Network Profile

Normalizes supported outbound-connectivity profiles and outputs a
`worker_pool_network` object for `modules/cursor-worker-pool`.

Does not own the enterprise VPC. The `approved_egress_control` input records
dependency on org egress enforcement; it does not prove allowlisting.
