variable "web_server_location" {}
variable "web_server_rg" {}
variable "web_server_rg2" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_address_prefix" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "web_server_subnets" {}
variable "terraform_script_version" {}
variable "domain_name_label" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "public_ip" {}
variable "object_id" {}
variable "object_sp_id" {
  default = "f3bfb2bf-c061-4fcf-933c-258a70423c95"
}

resource "azurerm_resource_group" "web_server_rg2" {
    name                            = "${var.web_server_rg2}"
    location                        = "${var.web_server_location}"
}


resource "azurerm_key_vault" "test-CapitalOnTap-2" {
  name                              = "test-CapitalOnTap-2"
  location                          = "${var.web_server_location}"
  resource_group_name               = "${azurerm_resource_group.web_server_rg2.name}"
  enabled_for_disk_encryption       = true
  enabled_for_deployment            = true
  enabled_for_template_deployment   = true
  tenant_id                         = "${var.tenant_id}"
  sku_name                          = "standard"

  access_policy {
    tenant_id                       = "${var.tenant_id}"
    object_id                       = "${var.object_id}"

    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get","getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts"
      ,"manageissuers",
      "setissuers",
      "update",
    ]

    storage_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "regeneratekey",
      "restore",
      "set",
      "update",
    ]
  }

  access_policy {
    tenant_id                       = "${var.tenant_id}"
    object_id                       = "${var.object_sp_id}"
    
    key_permissions = [
      "backup",
      "create",
      "decrypt",
      "delete",
      "encrypt",
      "get",
      "import",
      "list",
      "purge",
      "recover",
      "restore",
      "sign",
      "unwrapKey",
      "update",
      "verify",
      "wrapKey",
    ]

    secret_permissions = [
      "backup",
      "get",
      "list",
      "purge",
      "recover",
      "restore",
      "set",
    ]

    certificate_permissions = [
      "create",
      "delete",
      "deleteissuers",
      "get","getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts"
      ,"manageissuers",
      "setissuers",
      "update",
    ]

    storage_permissions = [
      "backup",
      "delete",
      "get",
      "list",
      "purge",
      "recover",
      "regeneratekey",
      "restore",
      "set",
      "update",
    ]
  }

  network_acls {
    default_action                  = "Deny"
    bypass                          = "AzureServices"

    #Change public IP according to your local public IP address on terraform.tfvars
    ip_rules                        = "${var.public_ip}"
  }

}

resource "azurerm_key_vault_certificate" "test-CapitalOnTapCert-2" {
  name         = "generated-cert-2"
  key_vault_id = "${azurerm_key_vault.test-CapitalOnTap-2.id}"
  

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["internal.contoso.com", "domain.hello.world"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

resource "azurerm_resource_group" "web_server_rg"{
    name                            = "${var.web_server_rg}"
    location                        = "${var.web_server_location}"
}

resource "azurerm_virtual_network" "web_server_vnet" {
    name                            = "${var.resource_prefix}-vnet"
    location                        = "${var.web_server_location}"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    address_space                   = ["${var.web_server_address_space}"]
}

resource "azurerm_subnet" "web_server_subnet" {
    name                            = "${var.resource_prefix}-subnet"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    virtual_network_name            = "${azurerm_virtual_network.web_server_vnet.name}"
    address_prefix                  = "${var.web_server_address_prefix}"
    network_security_group_id       = "${count.index == 0 ? "${azurerm_network_security_group.web_server_nsg.id}" : ""}"
    count                           = "${length(var.web_server_subnets)}"
}

resource "azurerm_public_ip" "web_server_lb_public_ip" {
    name                            = "${var.resource_prefix}-public-ip"
    location                        = "${var.web_server_location}"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    public_ip_address_allocation    = "static"
    domain_name_label               = "${var.domain_name_label}"
}

resource "azurerm_network_security_group" "web_server_nsg" {
    name                            = "${var.resource_prefix}-nsg"
    location                        = "${var.web_server_location}"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_http" {
    name                            = "HTTP Inbound"
    priority                        = "100"
    direction                       = "Inbound"
    access                          = "Allow"
    protocol                        = "TCP"
    source_port_range               = "*"
    destination_port_range          = "3389"
    source_address_prefix           = "*"
    destination_address_prefix      = "*"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    network_security_group_name     = "${azurerm_network_security_group.web_server_nsg.name}"
}

resource "azurerm_virtual_machine_scale_set" "web_server" {
    name                            = "${var.resource_prefix}-scale-set"
    location                        = "${var.web_server_location}"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    upgrade_policy_mode             = "manual"

    sku{
        name                        = "Standard_B1s"
        tier                        = "Standard"
        capacity                    = "${var.web_server_count}"
    }

    storage_profile_image_reference {
        publisher                   = "MicrosoftWindowsServer"
        offer                       = "WindowsServer"
        sku                         = "2016-Datacenter-Server-Core-smalldisk"
        version                     = "latest"
    }

    storage_profile_os_disk {
        name                        = ""
        caching                     = "ReadWrite"
        create_option               = "FromImage"
        managed_disk_type           = "Standard_LRS"
    }

    os_profile {
        computer_name_prefix        = "${var.web_server_name}"
        admin_username              = "webserver"
        admin_password              = "Passw0rd-1"
    }

    os_profile_windows_config {
        winrm {
            protocol                = "https"
            certificate_url         = "${azurerm_key_vault.test-CapitalOnTap-2.vault_uri}secrets/${azurerm_key_vault_certificate.test-CapitalOnTapCert-2.name}/${azurerm_key_vault_certificate.test-CapitalOnTapCert-2.version}"
        }
    }

    os_profile_secrets {
        source_vault_id             = "${azurerm_key_vault.test-CapitalOnTap-2.id}"

        vault_certificates {
            certificate_url         = "${azurerm_key_vault.test-CapitalOnTap-2.vault_uri}secrets/${azurerm_key_vault_certificate.test-CapitalOnTapCert-2.name}/${azurerm_key_vault_certificate.test-CapitalOnTapCert-2.version}"
            certificate_store       = "*"
        }
    }

    network_profile {
        name                        = "web_server_network_profile"
        primary                     = "true"

        ip_configuration {
            name                    = "${var.web_server_name}"
            primary                 = "true"
            subnet_id               = "${azurerm_subnet.web_server_subnet.*.id[0]}"
            load_balancer_backend_address_pool_ids  = ["${azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id}"]
        }
    }
}

resource "azurerm_lb" "web_server_lb" {
    name                            = "${var.resource_prefix}-lb"
    location                        = "${var.web_server_location}"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"

    frontend_ip_configuration {
        name                        = "${var.resource_prefix}-lb-frontend-ip"
        public_ip_address_id        = "${azurerm_public_ip.web_server_lb_public_ip.id}"
    }
}

resource "azurerm_lb_backend_address_pool" "web_server_lb_backend_pool" {
    name                            = "${var.resource_prefix}-lb-backend-pool"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id                 = "${azurerm_lb.web_server_lb.id}"                        
}

resource "azurerm_lb_probe" "web_server_lb_http_probe" {
    name                            = "${var.resource_prefix}-lb-http-probe"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id                 = "${azurerm_lb.web_server_lb.id}" 
    protocol                        = "tcp"
    port                            = "80"
}

resource "azurerm_lb_rule" "web_server_lb_http_rule" {
    name                            = "${var.resource_prefix}-lb-http-rul"
    resource_group_name             = "${azurerm_resource_group.web_server_rg.name}"
    loadbalancer_id                 = "${azurerm_lb.web_server_lb.id}" 
    protocol                        = "tcp"
    frontend_port                   = "80"
    backend_port                    = "80"
    frontend_ip_configuration_name  = "${var.resource_prefix}-lb-frontend-ip"
    probe_id                        = "${azurerm_lb_probe.web_server_lb_http_probe.id}"
    backend_address_pool_id         = "${azurerm_lb_backend_address_pool.web_server_lb_backend_pool.id}"
}









