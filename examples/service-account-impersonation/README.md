# Service Account Impersonation

Pattern: minimal pool runtime identity + explicit `roles/iam.serviceAccountTokenCreator`
on one narrowly scoped target service account. Audit token-generation events and
avoid transitive impersonation chains.
