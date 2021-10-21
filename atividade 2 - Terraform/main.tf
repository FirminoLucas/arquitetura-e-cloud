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
#Criar o grupo de recursos (requisito para a criação da VM)
resource "azurerm_resource_group" "atividade2firmino" {
  name     = "atividade2"
  location = "West US"
}

#criar a rede virtual
resource "azurerm_virtual_network" "atividade2network" {
  name                = "virtualNetwork1"
  #onde ela fica
  location            = azurerm_resource_group.atividade2firmino.location
  #nome do resource group
  resource_group_name = azurerm_resource_group.atividade2firmino.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]


}
#criar a sub rede
resource "azurerm_subnet" "atividade2subnetwork" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.atividade2firmino.name
  virtual_network_name = azurerm_virtual_network.atividade2network.name
  address_prefixes     = ["10.0.1.0/24"]
  
}
#criar o ip publico para o vm
resource "azurerm_public_ip" "atividade2publicip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.atividade2firmino.name
  location            = azurerm_resource_group.atividade2firmino.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
#Criar interface de rede
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
#criar o firewall
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
    destination_port_range     = "22" #apenas a porta 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
#criar regra do firewall para o MySql
resource "azurerm_network_security_rule" "atividade2security" {
  name                        = "mysql"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3306" #usar a porta 3306 para o sql
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.atividade2firmino.name
  network_security_group_name = azurerm_network_security_group.atividade2security.name
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
#instalar o mysql na vm#
 resource "null_resource" "mysql" {
   triggers = {
      order = azurerm_virtual_machine.main.id
    }

  provisioner "remote-exec" {
    connection {
        type="ssh"
        user="testadmin"
        password="Password1234!"
        host = azurerm_public_ip.atividade2publicip.ip_address
  }
    #comando para instalar via 'terminal'da vm
    inline = [
      "sudo apt update",
      "sudo apt-get install -y mysql-server ",
      "sudo service mysql start"
    ]
  }
}

  ########## Instancia MySql PaaS #########
  
  #resource "azurerm_mysql_server" "atividade2sql" {
  #name                = "atividade2mysqlserverfirmino"
  #location            = azurerm_resource_group.atividade2firmino.location
  #resource_group_name = azurerm_resource_group.atividade2firmino.name

  #administrator_login          = "mysqladminun"
  #administrator_login_password = "H@Sh1CoR3!"

  #sku_name   = "B_Gen5_2"
  #storage_mb = 5120
  #version    = "5.7"

  #auto_grow_enabled                 = true
  #backup_retention_days             = 7
  #geo_redundant_backup_enabled      = false
  #infrastructure_encryption_enabled = false
  #public_network_access_enabled     = true
  #ssl_enforcement_enabled           = true
  #ssl_minimal_tls_version_enforced  = "TLS1_2"
  #}
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.atividade2netinter.id
  network_security_group_id = azurerm_network_security_group.atividade2security.id
}