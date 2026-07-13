variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "container_image" {
  description = "Cursor worker image pinned by digest, for example REGION-docker.pkg.dev/PROJECT/REPOSITORY/IMAGE@sha256:..."
  type        = string
}

variable "cursor_api_key_secret_id" {
  type = string
}

variable "cursor_api_key_secret_version" {
  type    = string
  default = "latest"
}
