# Provider Config
provider "aws" {
  region = "us-east-1"
}

# Auto-Scaling Group
resource "aws_autoscaling_group" "ftbAsg" {
}

# Launch Configuration
resource "aws_launch_configuration" "ftbLc" {
}

# AMI
data "aws_ami" "ftbAmi" {
}

