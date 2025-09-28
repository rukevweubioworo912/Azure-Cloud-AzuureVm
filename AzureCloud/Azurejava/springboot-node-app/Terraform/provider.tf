 terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  tenant_id       = "30fe8ff1-adc6-444d-ba94-1238894df42c"
  subscription_id = "a2b28c85-1948-4263-90ca-bade2bac4df4"
skip_provider_registration = "true"
}
