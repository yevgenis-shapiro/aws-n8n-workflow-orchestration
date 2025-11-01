data "aws_region" "current" {}

locals {
  ami-id = data.aws_ami.amazonlinux2.image_id
}

data "aws_ami" "amazonlinux2" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-2.0.????????.?-x86_64-gp2" "Name=state,Values=available" --query "reverse(sort_by(Images, &Name))[:1].ImageId" --output text --region us-west-2
