locals {
  udx_rpm_files = tolist(fileset(var.itom_software_directory, "itom-di-pulsarudx*.rpm"))
  udx_rpm_file  = reverse(sort(local.udx_rpm_files))
  udx_rpm_file_check = local.udx_rpm_file[0] //To check if rpm file is missing and throw error in terraform plan itself
}
