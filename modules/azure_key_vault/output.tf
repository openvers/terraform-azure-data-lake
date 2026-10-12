output "key_vault_id" {
  description = "Azure Key Vault ID"
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "Azure Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}

output "key_name" {
  description = "Azure Key Vault Name"
  value       = azurerm_key_vault_key.this.name
}

output "key_id" {
  description = "Azure Key Vault Key ID"
  value       = azurerm_key_vault_key.this.id
}