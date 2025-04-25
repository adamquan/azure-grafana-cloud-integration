variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "org_slug" {
  type        = string
  description = "Grafana Cloud Organization Slug"
}

variable "grafana_cloud_region" {
  description = "The Grafana Cloud region to deploy resources in"
  type        = string
  default     = "prod-us-east-0"
}


variable "org_id" {
  description = "Grafana Cloud Organization ID"
  type        = string
}

variable "grafana_tf_access_policy_token" {
  description = "Grafana TF Access Policy Token"
  type        = string
  sensitive   = true
}

