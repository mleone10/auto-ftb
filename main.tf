# Remote State Configuration
terraform {
  backend "s3" {
    bucket = "leone-ftb-server"
    key    = "admin/stack.tfstate"
    region = "us-east-1"
  }
}

# Provider Config
provider "aws" {
  region = "us-east-1"
}

# Auto-Scaling Group
resource "aws_autoscaling_group" "ftbAsg" {
  launch_configuration = "${aws_launch_configuration.ftbLc.id}"
  load_balancers       = ["${aws_elb.ftbElb.id}"]
  desired_capacity     = 1
  min_size             = 0
  max_size             = 1
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

# Elastic Load Balancer
resource "aws_elb" "ftbElb" {
  name               = "ftbElb"
  availability_zones = "${var.availability_zones}"

  listener {
    instance_port     = 25565
    instance_protocol = "http"
    lb_port           = 25565
    lb_protocol = "http"
  }
}

# Launch Configuration
resource "aws_launch_configuration" "ftbLc" {
  image_id      = "${data.aws_ami.ftbAmi.id}"
  instance_type = "${var.instance_type}"
  key_name      = "ftbServer"
}

# AMI
data "aws_ami" "ftbAmi" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}
