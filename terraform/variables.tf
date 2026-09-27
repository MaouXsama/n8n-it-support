variable "project_name" {
  description = "Short project name used in Azure resource names."
  type        = string
  default     = "n8n-project"
}

variable "location" {
  description = "Azure region for the deployment."
  type        = string
  default     = "East US"
}

variable "postgres_location" {
  description = "Azure region for the PostgreSQL Flexible Server."
  type        = string
  default     = "Canada Central"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "vm_size" {
  description = "Azure VM size for the initial deployment."
  type        = string
  default     = "Standard_D2as_v7"
}

variable "admin_username" {
  description = "Linux administrator username. Use an SSH key, not a password."
  type        = string
  default     = "n8nadmin"
}

variable "ssh_public_key" {
  description = "SSH public key used to access the Linux VM."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to access SSH. Restrict this to your own public IP."
  type        = string
}

variable "allowed_web_cidr" {
  description = "CIDR allowed to access the web application."
  type        = string
  default     = "0.0.0.0/0"
}

variable "postgres_admin_login" {
  description = "Administrator login for PostgreSQL Flexible Server."
  type        = string
  default     = "n8nadmin"
}

variable "postgres_admin_password" {
  description = "Administrator password for PostgreSQL Flexible Server. Store this in a secure variable or Key Vault."
  type        = string
  sensitive   = true
}
