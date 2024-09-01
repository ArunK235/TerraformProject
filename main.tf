
locals {
  resource_group_name = "terraformRG1"
  location = "West Europe"
  virtual_network = {
    name = "app-network235"
    address_space= ["10.0.0.0/16"]
  }
  subnets = [
    {
      name="subnetA"
      address_prefix = "10.0.0.0/24"
    },
    {
      name           = "subnetB"
      address_prefix = "10.0.1.0/24"
    }
  ]
}

resource "azurerm_resource_group" "terraformRG" {
  name     = local.resource_group_name
  location = local.location
}


resource "azurerm_virtual_network" "appnetwork235" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = local.virtual_network.address_space
 
  depends_on = [ azurerm_resource_group.terraformRG ]

}
resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]
  depends_on = [ azurerm_virtual_network.appnetwork235 ]
}
resource "azurerm_subnet" "subnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefix]
  depends_on = [ azurerm_virtual_network.appnetwork235 ]
}
resource "azurerm_network_interface" "appinterface235" {
  count = 3
  name                = "app-interface235-${count.index + 1}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.appip[count.index].id
  }
  depends_on = [ azurerm_subnet.subnetA ]
}

resource "azurerm_public_ip" "appip" {
  count = 3
  name                = "app-ip235-${count.index + 1}"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"

  depends_on = [ azurerm_resource_group.terraformRG ]
}
resource "azurerm_network_security_group" "appnsg" {
  name                = "app-nsg235"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  
  }
  security_rule {
      name                       = "AllowHTTP"
      priority                   = 310
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }
  depends_on = [ azurerm_resource_group.terraformRG ]
}

resource "azurerm_subnet_network_security_group_association" "appnsglink" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.appnsg.id

}


resource "azurerm_linux_virtual_machine" "linuxvm" {
  count = 3
  name                = "linux-vm${count.index + 1}"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.appinterface235[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/12345/Downloads/my_new_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  depends_on = [ azurerm_network_interface.appinterface235, azurerm_resource_group.terraformRG ]
}
  
