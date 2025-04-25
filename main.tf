provider "azurerm" {
  features {}
}

module "grafanacloud" {
  source = "./modules/grafanacloud"
  azure_subscription_id = var.azure_subscription_id
  grafana_cloud_region = var.grafana_cloud_region
  org_slug = var.org_slug
  org_id = var.org_id
  grafana_tf_access_policy_token = var.grafana_tf_access_policy_token
}
