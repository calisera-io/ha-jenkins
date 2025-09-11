provider "aws" {
  shared_config_files      = [var.shared_config_file]
  shared_credentials_files = [var.shared_credentials_file]
  profile                  = var.profile
  region                   = var.region
}


provider "vault" {
  address = "http://127.0.0.1:8200"
}