provider "google" {}

module "gcp_sap_hana" {
  source                     = "./modules/sap_hana"
  subnetwork                 = var.subnetwork
  linux_image_family         = var.linux_image_family
  linux_image_project        = var.linux_image_project
  instance_name              = var.instance_name
  instance_type              = var.instance_type
  subnetwork_project         = var.subnetwork_project
  project_id                 = var.project_id
  region                     = var.region
  zone                       = var.zone
  service_account_email      = var.service_account_email
  boot_disk_type             = var.boot_disk_type
  boot_disk_size             = var.boot_disk_size
  autodelete_disk            = "true"
  pd_ssd_size                = max(834, (local.hana_log_size + local.hana_data_size + local.hana_shared_size + local.hana_usr_size))
  pd_hdd_size                = local.hana_backup_size
  sap_hana_deployment_bucket = var.sap_hana_deployment_bucket
  sap_deployment_debug       = "false"
  post_deployment_script     = var.post_deployment_script
  startup_script             = file(var.startup_script)
  sap_hana_sid               = var.sap_hana_sid
  sap_hana_instance_number   = var.sap_hana_instance_number
  sap_hana_sidadm_password   = var.sap_hana_sidadm_password
  sap_hana_system_password   = var.sap_hana_system_password
  network_tags               = var.network_tags
  sap_hana_sidadm_uid        = 900
  sap_hana_sapsys_gid        = 900
  public_ip                  = var.public_ip
  address_name               = "${var.instance_name}-reservedip"
}
