provider "azurerm" {
  features {}
}

module "grafanacloud" {
  source = "./modules/grafanacloud"
  azure_subscription_id = var.azure_subscription_id
  azure_location = var.azure_location
  grafana_cloud_region = var.grafana_cloud_region
  org_slug = var.org_slug
  org_id = var.org_id
  grafana_tf_access_policy_token = var.grafana_tf_access_policy_token
  loki_token = var.loki_token
  loki_user = var.loki_user
  loki_endpoint = var.loki_endpoint
}
