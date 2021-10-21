terraform {
    required_version = ">= 0.13"
    required_providers {
        azurerm = {

        
            source = "hashicorp/azurerm"
            version = ">= 2.46.0"
        }
    }

}
provider "azurerm" {
    skip_provider_registration = true
    features {
  
    }
}

resource "azurerm_resource_group" "atividade2firmino" {
  name     = "atividade2"
  location = "West US"
}

resource "azurerm_virtual_network" "atividade2network" {
  name                = "virtualNetwork1"
  #onde ela fica
  location            = azurerm_resource_group.atividade2firmino.location
  #nome do resource group
  resource_group_name = azurerm_resource_group.atividade2firmino.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]


}
resource "azurerm_subnet" "atividade2subnetwork" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.atividade2firmino.name
  virtual_network_name = azurerm_virtual_network.atividade2network.name
  address_prefixes     = ["10.0.1.0/24"]
  
}
resource "azurerm_public_ip" "atividade2publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.atividade2firmino.name
  location            = azurerm_resource_group.atividade2firmino.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_security_group" "atividade2security" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.atividade2firmino.location
  resource_group_name = azurerm_resource_group.atividade2firmino.name

  security_rule {
    name                       = "SSH" #será SSH na porta abaixo
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306" #apenas a porta 3306
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
resource "azurerm_network_interface" "atividade2netinter" {
  name                = "example-nic"
  location            = azurerm_resource_group.atividade2firmino.location
  resource_group_name = azurerm_resource_group.atividade2firmino.name

  ip_configuration {
    name                          = "internal" #pode ser qualquer coisa
    subnet_id                     = azurerm_subnet.atividade2subnetwork.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.atividade2publicip.id
  }
}

########### criar a maquina virtual #################

resource "azurerm_virtual_machine" "main" {
  name                  = "atividade2-vm"
  location              = azurerm_resource_group.atividade2firmino.location
  resource_group_name   = azurerm_resource_group.atividade2firmino.name
  network_interface_ids = [azurerm_network_interface.atividade2netinter.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
  resource "azurerm_mysql_server" "atividade2sql" {
  name                = "mysqlserver"
  location            = azurerm_resource_group.atividade2firmino.location
  resource_group_name = azurerm_resource_group.atividade2firmino.name

  administrator_login          = "mysqladminun"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
  }
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.atividade2netinter.id
  network_security_group_id = azurerm_network_security_group.atividade2security.id
}