resource "azurerm_resource_group" "resourcegroup" {
  name     = var.rgname
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-prod"
  address_space       = [element(var.address_space, 0)]
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "sub" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [element(var.address_prefixes, 0)]
}


resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic${count.index}"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windowsmachine" {
    count = 2
  name                = "vm-prod-${count.index}"
  resource_group_name = azurerm_resource_group.resourcegroup.name
  location            = azurerm_resource_group.resourcegroup.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [element(azurerm_network_interface.nic.*.id,count.index)]  

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}