resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_postgresql_flexible_server" "app" {
  name                   = "${var.project_name}-pg-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.postgres_location
  version                = "16"
  administrator_login    = var.postgres_admin_login
  administrator_password = var.postgres_admin_password
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"
  backup_retention_days  = 7
  auto_grow_enabled      = true
  tags                   = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "n8n"
  server_id = azurerm_postgresql_flexible_server.app.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "n8n_vm" {
  name             = "allow-n8n-vm"
  server_id        = azurerm_postgresql_flexible_server.app.id
  start_ip_address = azurerm_public_ip.vm.ip_address
  end_ip_address   = azurerm_public_ip.vm.ip_address
}
