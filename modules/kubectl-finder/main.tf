# necessary because the kubectl binaries are hosted on an S3 bucket in us-west-2 and could otherwise not be detected
# when Toolkit is used in another region
provider "aws" {
  region = "us-west-2"
  alias = "kubectl_s3_region"
}

data "aws_s3_objects" "kubectl_files" {
  bucket = "amazon-eks"
  start_after = "${var.kubectl_version}"

  provider = aws.kubectl_s3_region
}

locals {
  kubectl_files = [ for file in data.aws_s3_objects.kubectl_files.keys : file if length(regexall("^${var.kubectl_version}.\\d+/[\\d-]+/bin/linux/amd64/kubectl$", file)) > 0]
  longest_files = local.kubectl_files == [] ? 0 : max([ for file in local.kubectl_files : length(file) ]...)
  long_files_only = local.longest_files == 0 ? [] : [ for file in local.kubectl_files : file if (length(file)) == local.longest_files ]
  latest_file = local.long_files_only == [] ? null : reverse(sort(local.long_files_only))[0]
  kubectl_download_url = "https://amazon-eks.s3.us-west-2.amazonaws.com/${local.latest_file}"
}
