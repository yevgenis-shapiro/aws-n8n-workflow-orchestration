locals {
  ami-id-tmp = (length(data.aws_ami_ids.amazonvertica.ids) == 0) ? data.aws_ami.vertica.image_id : tolist(data.aws_ami_ids.amazonvertica.ids)[length(data.aws_ami_ids.amazonvertica.ids)-1]
  ami-id = (var.custom-ami-id == "") ? local.ami-id-tmp : var.custom-ami-id
}

data "aws_ami_ids" "amazonvertica" {
  owners = ["679593333241"]
  sort_ascending = true

  filter {
    name   = "name"
    values = ["Vertica ${var.vertica-version}*Amazon Linux*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "vertica" {
  owners = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["Vertica ${var.vertica-version}*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}