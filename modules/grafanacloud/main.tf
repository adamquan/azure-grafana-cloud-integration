#needed items for Grafana cloud integration as per https://grafana.com/docs/grafana-cloud/monitor-infrastructure/monitor-cloud-provider/azure/collect-azure-serverless/config-azure-metrics-serverless/

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    grafana = {
        source = "grafana/grafana"
        version = ">= 3.18.0"
    }
  }
}

data "azurerm_client_config" "current" {}

# Create Azure AD Application for Grafana Cloud
resource "azuread_application" "grafana" {
  display_name = "grafana-cloud-azure-metrics-integration"
  owners = [data.azurerm_client_config.current.object_id]
}

# Create Azure AD Service Principal for Grafana Cloud
resource "azuread_service_principal" "grafana" {
  client_id = azuread_application.grafana.client_id
  owners = [data.azurerm_client_config.current.object_id]
}

# Create Service Principal password
resource "azuread_service_principal_password" "grafana" {
  service_principal_id = azuread_service_principal.grafana.id
}

# Assign Monitoring Reader role to the Service Principal
resource "azurerm_role_assignment" "grafana" {
  scope                = "/subscriptions/${var.azure_subscription_id}"
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.grafana.id
}

# Configure provider for Azure integration
provider "grafana" {
  cloud_access_policy_token  = var.grafana_tf_access_policy_token
  cloud_provider_access_token = var.grafana_tf_access_policy_token
  cloud_provider_url         = "https://cloud-provider-api-${var.grafana_cloud_region}.grafana.net"
}


data "grafana_cloud_stack" "stack" {
  provider = grafana
  slug = var.org_slug
}

resource "grafana_cloud_provider_azure_credential" "azurecred" {
  stack_id = data.grafana_cloud_stack.stack.id
  name = "azure-credential"

  client_id = azuread_application.grafana.client_id
  client_secret = azuread_service_principal_password.grafana.value
  tenant_id = data.azurerm_client_config.current.tenant_id
}


# logs integration via Azure event hub using serverless integration
# Doc: https://grafana.com/docs/grafana-cloud/monitor-infrastructure/monitor-cloud-provider/azure/config-azure-logs-azure-function/?pg=blog&plcmt=body-txt
provider "azurerm" {
  features {
  }
}

data "http" "template" {
  url = "https://raw.githubusercontent.com/grafana/azure_eventhub_to_loki/refs/tags/0.0.7/azdeploy.json"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Unsuccessful status code attempting to download template"
    }
  }
}

resource "azurerm_resource_group" "logexport" {
  name     = "adam-logexport"
  location = "${var.azure_location}"
}

resource "azurerm_resource_group_template_deployment" "logexport" {
  name                = "${azurerm_resource_group.logexport.name}-deploy"
  resource_group_name = azurerm_resource_group.logexport.name
  deployment_mode     = "Complete"
  template_content    = data.http.template.response_body

  parameters_content = jsonencode({
    "lokiEndpoint" = {
      value = "${var.loki_endpoint}"
    }
    "lokiUsername" = {
      value = "${var.loki_user}"
    }
    "lokiPassword" = {
      value = "${var.loki_token}"
    }
    "packageUri" = {
      value = "https://github.com/grafana/azure_eventhub_to_loki/releases/download/0.0.7/logexport.0.0.7.zip"
    }
  })
}