web_server_location         = "westus2"
web_server_rg               = "web-rg"
web_server_rg2              = "keyvault"
resource_prefix             = "web-server"
web_server_address_space    = "1.0.0.0/22"
web_server_address_prefix   = "1.0.1.0/24"
web_server_name             = "web"
environment                 = "production"
web_server_count            = "2"
web_server_subnets          = ["1.0.1.0/24","1.0.2.0/24"]
terraform_script_version    = "1.00"
domain_name_label           = "capital-tf-2"
public_ip                   = ["82.38.39.81"]