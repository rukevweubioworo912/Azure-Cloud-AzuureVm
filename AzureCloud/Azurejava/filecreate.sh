#!/bin/bash

# Set project name
PROJECT_NAME="springboot-node-app"

# Create folder structure
mkdir -p $PROJECT_NAME/src/main/java/com/example/demo
mkdir -p $PROJECT_NAME/src/main/resources/static
mkdir -p $PROJECT_NAME/src/main/resources
mkdir -p $PROJECT_NAME/terraform
mkdir -p $PROJECT_NAME/.github/workflows

echo "Creating Java files..."
# DemoApplication.java
cat > $PROJECT_NAME/src/main/java/com/example/demo/DemoApplication.java <<EOL
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@SpringBootApplication
@Controller
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/")
    public String home() {
        return "index"; // refers to index.html in /static
    }
}
EOL

echo "Creating application.properties..."
# application.properties
cat > $PROJECT_NAME/src/main/resources/application.properties <<EOL
server.port=8080
spring.mvc.view.prefix=/static/
spring.mvc.view.suffix=.html
EOL

echo "Creating index.html..."
# index.html
cat > $PROJECT_NAME/src/main/resources/static/index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>Spring Boot App</title>
</head>
<body>
    <h1>Welcome to My Spring Boot App!</h1>
    <p>This is served from the static folder.</p>
</body>
</html>
EOL

echo "Creating Dockerfile..."
# Dockerfile
cat > $PROJECT_NAME/Dockerfile <<EOL
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN ./mvnw clean package -DskipTests
COPY target/demo-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOL

echo "Creating .dockerignore..."
# .dockerignore
cat > $PROJECT_NAME/.dockerignore <<EOL
target/
*.jar
*.log
EOL

echo "Creating Terraform files..."
# terraform/main.tf
cat > $PROJECT_NAME/terraform/main.tf <<EOL
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_app_service_plan" "plan" {
  name                = "\${var.app_name}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_app_service" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|\${azurerm_container_registry.acr.login_server}/\${var.app_name}:latest"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://\${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
  }
}
EOL

# terraform/variables.tf
cat > $PROJECT_NAME/terraform/variables.tf <<EOL
variable "resource_group_name" {
  default = "myResourceGroup"
}

variable "location" {
  default = "eastus"
}

variable "app_name" {
  default = "springboot-node-app"
}

variable "acr_name" {
  default = "springbootnodeacr"
}
EOL

# terraform/outputs.tf
cat > $PROJECT_NAME/terraform/outputs.tf <<EOL
output "app_url" {
  value = azurerm_app_service.app.default_site_hostname
}
EOL

echo "Creating GitHub Actions workflow..."
# GitHub Actions deploy.yml
cat > $PROJECT_NAME/.github/workflows/deploy.yml <<EOL
name: Deploy Spring Boot App to Azure

on:
  push:
    branches:
      - main

env:
  ACR_NAME: springbootnodeacr
  APP_NAME: springboot-node-app
  RESOURCE_GROUP: myResourceGroup
  LOCATION: eastus
  IMAGE_TAG: latest

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      - run: terraform init
        working-directory: ./terraform
      - run: terraform apply -auto-approve
        working-directory: ./terraform

  build-and-deploy:
    runs-on: ubuntu-latest
    needs: terraform
    steps:
      - uses: actions/checkout@v3

      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: \${{ secrets.AZURE_CREDENTIALS }}

      - name: Build Docker Image
        run: |
          docker build -t \$ACR_NAME.azurecr.io/\$APP_NAME:\$IMAGE_TAG .

      - name: Push to Azure Container Registry
        run: |
          echo \${{ secrets.ACR_PASSWORD }} | docker login \$ACR_NAME.azurecr.io -u \${{ secrets.ACR_USERNAME }} --password-stdin
          docker push \$ACR_NAME.azurecr.io/\$APP_NAME:\$IMAGE_TAG

      - name: Deploy to Azure App Service
        run: |
          az webapp config container set \
            --name \$APP_NAME \
            --resource-group \$RESOURCE_GROUP \
            --docker-custom-image-name \$ACR_NAME.azurecr.io/\$APP_NAME:\$IMAGE_TAG \
            --docker-registry-server-url https://\$ACR_NAME.azurecr.io \
            --docker-registry-server-user \${{ secrets.ACR_USERNAME }} \
            --docker-registry-server-password \${{ secrets.ACR_PASSWORD }}

      - name: Stream Logs from Azure App Service
        run: az webapp log tail --name \$APP_NAME --resource-group \$RESOURCE_GROUP
EOL

echo "All files created successfully!"
