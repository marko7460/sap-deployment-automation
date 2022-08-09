/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "random_string" "name_suffix" {
  length  = 6
  upper   = false
  special = false
}

module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 10.1"

  name              = var.project_name
  random_project_id = true
  org_id            = var.org_id
  billing_account   = var.billing_account_id
  folder_id         = var.folder_id
  activate_apis = [
    "compute.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

locals {
  random_suffix = var.random_suffix ? "-${random_string.name_suffix.result}" : ""
  network_name  = "${var.network_name}${local.random_suffix}"
  router_name   = "router-${var.network_name}${local.random_suffix}"
}

resource "google_service_account" "sap_service_account" {
  project      = module.project.project_id
  account_id   = "sap-sa-test"
  display_name = "SAP service account for VMs"
}

resource "google_storage_bucket" "media_bucket" {
  project                     = module.project.project_id
  location                    = "US"
  name                        = "${module.project.project_id}-media-bucket"
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "media_bucket_role" {
  bucket = google_storage_bucket.media_bucket.name
  member = "serviceAccount:${google_service_account.sap_service_account.email}"
  role   = "roles/storage.admin"
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 4.0"

  project_id       = module.project.project_id
  network_name     = local.network_name
  routing_mode     = "GLOBAL"
  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges
  firewall_rules   = var.firewall_rules
}

# Create firewall rule to allow communication b/w instances in subnet
resource "google_compute_firewall" "sap_firewall_all" {
  project       = module.vpc.project_id
  name          = "sap-allow-all-${random_string.name_suffix.result}"
  network       = module.vpc.network_name
  source_ranges = module.vpc.subnets_ips
  target_tags   = var.network_tags

  allow {
    protocol = "all"
  }
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  version       = "~> 1.2"
  project_id    = module.project.project_id
  region        = var.region
  router        = local.router_name
  create_router = true
  network       = module.vpc.network_name
}

resource "google_storage_bucket" "state_bucket" {
  project                     = module.project.project_id
  location                    = "US"
  name                        = "${module.project.project_id}-${var.tf_state_bucket_suffix}"
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Create firewall rule to allow iap connection to SAP instances
resource "google_compute_firewall" "iap" {
  project                 = module.vpc.project_id
  name                    = "iap-${random_string.name_suffix.result}"
  network                 = module.vpc.network_name
  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.sap_service_account.email]

  allow {
    protocol = "TCP"
    ports    = [22]
  }
}
