# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "org_id" {}
variable "folder_id" {}
variable "billing_account_id" {}
variable "product_id" {}
variable "image_family" {}
variable "image_project" {}
variable "media_bucket" {}
variable "counter" {
  default = 0
}

module "test_setup" {
  source             = "../../../terraform/modules/test-setup"
  project_name       = "hana-scaleup-${var.counter}"
  org_id             = var.org_id
  folder_id          = var.folder_id
  billing_account_id = var.billing_account_id
  subnets = [{
    subnet_name           = "hana-scaleup-${var.counter}"
    subnet_ip             = "10.9.${var.counter}.0/24"
    subnet_region         = "us-west1"
    subnet_private_access = true
  }]
}

resource "local_file" "playbook_vars" {
  filename = "${path.module}/vars.yml"
  content = templatefile("${path.module}/templates/vars.yaml.tmpl", {
    project       = module.test_setup.project_id
    zone          = "us-west1-b"
    subnet        = "hana-scaleup-${var.counter}"
    network       = module.test_setup.vpc.network_name
    state_bucket  = module.test_setup.state_bucket
    media_bucket  = module.test_setup.media_bucket
    image_family  = var.image_family
    image_project = var.image_project
    product_id    = var.product_id
    sa            = module.test_setup.sap_service_account_id
  })
}

resource "null_resource" "copy_install_media" {
  triggers = {
    id = md5(var.billing_account_id)
  }
  provisioner "local-exec" {
    command = <<EOT
gsutil -q -m cp -r  gs://${var.media_bucket}/* gs://${module.test_setup.media_bucket}/
EOT
  }
  depends_on = [module.test_setup]
}

output "setup_output" {
  sensitive = true
  value     = module.test_setup
}
output "subnetwork" {
  value = module.test_setup.vpc
}
output "region" {
  value = module.test_setup.region
}
output "sap_service_account" {
  value = module.test_setup.sap_service_account_email
}
output "media_bucket" {
  value = module.test_setup.media_bucket
}
output "project_id" {
  value = module.test_setup.project_id
}
output "playbook_vars" {
  value = local_file.playbook_vars.filename
}