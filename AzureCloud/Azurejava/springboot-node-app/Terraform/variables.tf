variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "acr_name" {
  type = string
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

variable "app_service_plan_name" {
  type = string
}

variable "app_service_plan_sku" {
  type    = string
  default = "B1"
}

variable "app_service_name" {
  type = string
}

variable "docker_image_name" {
  type = string
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}
