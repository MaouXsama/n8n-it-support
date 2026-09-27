output "resource_group_name" {
  description = "Name of the n8n resource group."
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the n8n VM."
  value       = azurerm_public_ip.vm.ip_address
}

output "temporary_hostname" {
  description = "Azure temporary hostname for HTTPS access."
  value       = azurerm_public_ip.vm.fqdn
}

output "vm_name" {
  description = "Name of the n8n VM."
  value       = azurerm_linux_virtual_machine.app.name
}

output "managed_identity_client_id" {
  description = "Client ID of the VM managed identity."
  value       = azurerm_user_assigned_identity.app.client_id
}

output "postgresql_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.app.fqdn
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault."
  value       = azurerm_key_vault.app.name
}
