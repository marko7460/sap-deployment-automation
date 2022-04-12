variable "org_id" {}
variable "media_bucket" {}
variable "folder_id" {}
variable "billing_account_id" {}

module "test_setup" {
  source             = "../../../terraform/modules/test-setup"
  media_bucket       = var.media_bucket
  org_id             = var.org_id
  folder_id          = var.folder_id
  billing_account_id = var.billing_account_id
}
output "setup_output" {
  sensitive = true
  value     = module.test_setup
}
output "subnetwork" {
  value = module.test_setup.vpc
}
output "private_key_openssh" {
  sensitive = true
  value     = module.test_setup.private_key_openssh
}
output "public_key_openssh" {
  value = module.test_setup.public_key_openssh
}
output "bastion_ip" {
  value = module.test_setup.bastion_ip
}
output "region" {
  value = module.test_setup.region
}
output "sap_service_account" {
  value = module.test_setup.sap_service_account
}
output "media_bucket" {
  value = module.test_setup.media_bucket
}
output "project_id" {
  value = module.test_setup.project_id
}