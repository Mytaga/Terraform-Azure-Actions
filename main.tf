terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.11.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "TaskBoardRG12"
    storage_account_name = "taskboardstoragemytag"
    container_name       = "taskboardcontainer"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "37542477-e91b-403f-a0b2-2ff7e39c3bf6"
  features {
  }
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "mytaga" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_service_plan" "mytaga" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.mytaga.name
  location            = azurerm_resource_group.mytaga.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "mytaga" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.mytaga.name
  location            = azurerm_service_plan.mytaga.location
  service_plan_id     = azurerm_service_plan.mytaga.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.mytaga.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.mytaga.name};User ID=${azurerm_mssql_server.mytaga.administrator_login};Password=${azurerm_mssql_server.mytaga.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_mssql_server" "mytaga" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.mytaga.name
  location                     = azurerm_resource_group.mytaga.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "mytaga" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.mytaga.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"
  zone_redundant = false
}

resource "azurerm_mssql_firewall_rule" "mytaga" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.mytaga.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_app_service_source_control" "mytaga" {
  app_id                 = azurerm_linux_web_app.mytaga.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}

