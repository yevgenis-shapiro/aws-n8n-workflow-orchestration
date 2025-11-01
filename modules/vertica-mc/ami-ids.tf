locals {
  ami-id = (var.custom-ami-id == "") ? data.aws_ami.vertica.image_id : var.custom-ami-id
}

data "aws_ami" "vertica" {
  owners = ["679593333241"]
  most_recent = true
  include_deprecated = true

  filter {
    name   = "name"
    values = ["Vertica ${var.vertica-version}*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
