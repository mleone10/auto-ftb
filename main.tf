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
  name                 = "ftbAsg"
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
  security_groups    = ["${aws_security_group.ftbSg.id}"]

  listener {
    instance_port     = 25565
    instance_protocol = "tcp"
    lb_port           = 25565
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    target              = "TCP:22"
  }
}

# Launch Configuration
resource "aws_launch_configuration" "ftbLc" {
  name_prefix     = "ftbLc-"
  image_id        = "${data.aws_ami.ftbAmi.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "ftbServer"
  security_groups = ["${aws_security_group.ftbSg.id}"]
  user_data       = "${file("initializeServer")}"
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

# Route 53 A Record
resource "aws_route53_record" "ftbR53" {
  zone_id = "${var.domain_zone_id}"
  name    = "${var.server_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.ftbElb.dns_name}"
    zone_id                = "${aws_elb.ftbElb.zone_id}"
    evaluate_target_health = true
  }
}

# VPC
resource "aws_vpc" "ftbVpc" {
  cidr_block = "10.0.0.0/16"
}

# Server Security Group
resource "aws_security_group" "ftbSg" {
  name        = "ftbSg"
  description = "Allows access over 25565 from anywhere"

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
